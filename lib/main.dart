import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'services/server_service.dart';
import 'widgets/service_card.dart';
import 'widgets/shimmer_card.dart';

void main() {
  runApp(const ServerHealthApp());
}

class ServerHealthApp extends StatelessWidget {
  const ServerHealthApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Server Health-Check Dashboard',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: const Color(0xFF6366F1),
        scaffoldBackgroundColor: const Color(0xFFF4F5FB),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF6366F1),
          foregroundColor: Colors.white,
        ),
      ),
      home: const DashboardPage(),
    );
  }
}

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  /// Hasil health-check ketiga service (Map dari ServerService).
  /// Index: [0] Database, [1] API Gateway, [2] Storage.
  List<Map<String, dynamic>>? _results;
  bool _isLoading = false;

  /// Timer live yang berjalan saat fetching (update tiap 100 ms).
  double _liveElapsed = 0;

  /// Durasi fetch terakhir — bukti bahwa parallel fetching hanya
  /// memakan waktu delay terlama (~3 detik), bukan 6 detik.
  double? _lastFetchDuration;
  DateTime? _lastRefreshAt;

  Timer? _ticker;
  Stopwatch? _stopwatch;

  @override
  void initState() {
    super.initState();
    _fetchAll();
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  /// Mengambil status KETIGA service secara PARALEL menggunakan Future.wait.
  ///
  /// Delay: Database 2s, API Gateway 3s, Storage 1s.
  /// Total waktu = delay terlama = ~3 detik (bukan 2+3+1 = 6 detik).
  Future<void> _fetchAll() async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
      _liveElapsed = 0;
    });

    _stopwatch = Stopwatch()..start();
    _ticker?.cancel();
    _ticker = Timer.periodic(const Duration(milliseconds: 100), (_) {
      setState(() {
        _liveElapsed = _stopwatch!.elapsedMilliseconds / 1000.0;
      });
    });

    try {
      // === INTI PRAKTIKUM: PARALLEL FETCHING ===
      final results = await Future.wait([
        ServerService.checkDatabase(), // 2 detik
        ServerService.checkApiGateway(), // 3 detik (terlama)
        ServerService.checkStorage(), // 1 detik
      ]);

      _stopwatch!.stop();
      final elapsed = _stopwatch!.elapsedMilliseconds / 1000.0;

      // Bukti di console: total ~3 detik, bukan 6 detik.
      debugPrint(
        '[Future.wait] Parallel fetch selesai dalam '
        '${elapsed.toStringAsFixed(2)} detik '
        '(sequential akan memakan ~6 detik)',
      );

      if (!mounted) return;
      setState(() {
        _results = results;
        _lastFetchDuration = elapsed;
        _lastRefreshAt = DateTime.now();
      });
    } finally {
      _ticker?.cancel();
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final timeFormat = DateFormat('HH:mm:ss');

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Server Health-Check Dashboard',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        actions: [
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.only(right: 16),
              child: Center(
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    color: Colors.white,
                  ),
                ),
              ),
            )
          else
            IconButton(
              icon: const Icon(Icons.refresh_rounded),
              tooltip: 'Refresh',
              onPressed: _fetchAll,
            ),
        ],
      ),
      // === PULL TO REFRESH ===
      body: RefreshIndicator(
        onRefresh: _fetchAll,
        color: const Color(0xFF6366F1),
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            const SizedBox(height: 16),
            _buildSummaryCard(timeFormat),
            const SizedBox(height: 8),
            // Transisi halus antara shimmer (loading) dan data asli.
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 400),
              child: _isLoading && _results == null
                  ? const Column(
                      key: ValueKey('shimmer'),
                      children: [
                        ShimmerCard(),
                        ShimmerCard(),
                        ShimmerCard(),
                      ],
                    )
                  : Column(
                      key: const ValueKey('content'),
                      children: [
                        if (_results != null) ...[
                          ServiceCard(
                            health: _results![0],
                            serviceIcon: Icons.storage_rounded,
                            checkedAt: _lastRefreshAt ?? DateTime.now(),
                          ),
                          ServiceCard(
                            health: _results![1],
                            serviceIcon: Icons.api_rounded,
                            checkedAt: _lastRefreshAt ?? DateTime.now(),
                          ),
                          ServiceCard(
                            health: _results![2],
                            serviceIcon: Icons.cloud_rounded,
                            checkedAt: _lastRefreshAt ?? DateTime.now(),
                          ),
                        ],
                      ],
                    ),
            ),
            const SizedBox(height: 12),
            Center(
              child: Text(
                'Tarik layar ke bawah untuk refresh',
                style: TextStyle(fontSize: 12, color: Colors.grey[500]),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  /// Card ringkasan: menampilkan timer live & durasi fetch terakhir
  /// sebagai bukti parallel fetching bekerja.
  Widget _buildSummaryCard(DateFormat timeFormat) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF6366F1).withValues(alpha: 0.35),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.speed_rounded, color: Colors.white, size: 22),
              const SizedBox(width: 8),
              const Text(
                'Parallel Fetching (Future.wait)',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _summaryItem(
                label: _isLoading ? 'Sedang memuat...' : 'Fetch terakhir',
                value: _isLoading
                    ? '${_liveElapsed.toStringAsFixed(1)} s'
                    : _lastFetchDuration != null
                        ? '${_lastFetchDuration!.toStringAsFixed(2)} s'
                        : '-',
              ),
              _summaryItem(
                label: 'Target (delay terlama)',
                value: '~3.0 s',
              ),
              _summaryItem(
                label: 'Jika sequential',
                value: '~6.0 s',
              ),
            ],
          ),
          if (_lastRefreshAt != null) ...[
            const SizedBox(height: 12),
            Text(
              'Terakhir diperbarui: ${timeFormat.format(_lastRefreshAt!)}',
              style: const TextStyle(color: Colors.white70, fontSize: 12),
            ),
          ],
        ],
      ),
    );
  }

  Widget _summaryItem({required String label, required String value}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(color: Colors.white70, fontSize: 11),
        ),
      ],
    );
  }
}
