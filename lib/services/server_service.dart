import 'dart:async';
import 'dart:math';

class ServerService {
  static final Random _random = Random();

  // Cek Status Database (Delay 2 Detik)
  static Future<Map<String, dynamic>> checkDatabase() async {
    await Future.delayed(const Duration(seconds: 2));
    bool isOk = _random.nextDouble() > 0.2; // 80% peluang normal
    return {
      'service': 'Database Server',
      'status': isOk ? 'Online' : 'Offline',
      'latency': '${_random.nextInt(50) + 10} ms',
    };
  }

  // Cek Status API Gateway (Delay 3 Detik)
  static Future<Map<String, dynamic>> checkApiGateway() async {
    await Future.delayed(const Duration(seconds: 3));
    bool isOk = _random.nextDouble() > 0.3;
    return {
      'service': 'API Gateway',
      'status': isOk ? 'Online' : 'Degraded',
      'latency': '${_random.nextInt(150) + 100} ms',
    };
  }

  // Cek Status Storage (Delay 1 Detik)
  static Future<Map<String, dynamic>> checkStorage() async {
    await Future.delayed(const Duration(seconds: 1));
    return {
      'service': 'Storage Service',
      'status': 'Online',
      'latency': '${_random.nextInt(30) + 5} ms',
    };
  }
}
