import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// Helper: mapping status (String dari ServerService) -> warna, label, ikon.
/// Status yang mungkin dikembalikan service: 'Online', 'Degraded', 'Offline'.
extension HealthStatusStyle on String {
  Color get statusColor {
    switch (this) {
      case 'Online':
        return const Color(0xFF22C55E); // hijau
      case 'Degraded':
        return const Color(0xFFF59E0B); // amber/oranye
      default: // 'Offline'
        return const Color(0xFFEF4444); // merah
    }
  }

  String get statusLabel {
    switch (this) {
      case 'Online':
        return 'Online / Normal';
      case 'Degraded':
        return 'Slow / Degraded';
      default:
        return 'Offline / Error';
    }
  }

  IconData get statusIcon {
    switch (this) {
      case 'Online':
        return Icons.check_circle_rounded;
      case 'Degraded':
        return Icons.warning_amber_rounded;
      default:
        return Icons.cancel_rounded;
    }
  }
}

/// Card besar untuk menampilkan status satu service.
/// Menerima Map hasil kembalian ServerService:
/// {'service': ..., 'status': ..., 'latency': ...}
class ServiceCard extends StatelessWidget {
  final Map<String, dynamic> health;
  final IconData serviceIcon;
  final DateTime checkedAt;

  const ServiceCard({
    super.key,
    required this.health,
    required this.serviceIcon,
    required this.checkedAt,
  });

  @override
  Widget build(BuildContext context) {
    final String name = health['service'] as String;
    final String status = health['status'] as String;
    final String latency = health['latency'] as String;
    final color = status.statusColor;
    final timeFormat = DateFormat('HH:mm:ss');

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.35), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.12),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Row(
          children: [
            // Ikon service dengan latar warna status
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(serviceIcon, color: color, size: 32),
            ),
            const SizedBox(width: 16),
            // Nama service + detail
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    status == 'Offline'
                        ? 'Tidak ada respons'
                        : 'Latency: $latency',
                    style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Dicek: ${timeFormat.format(checkedAt)}',
                    style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                  ),
                ],
              ),
            ),
            // Badge status berwarna
            Column(
              children: [
                Icon(status.statusIcon, color: color, size: 28),
                const SizedBox(height: 4),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    status,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
