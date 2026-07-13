import 'dart:io';
import 'command_router.dart';

class DiagnosticsService {
  static final DiagnosticsService _instance = DiagnosticsService._internal();
  factory DiagnosticsService() => _instance;
  DiagnosticsService._internal();

  Future<Map<String, dynamic>> getDiagnostics() async {
    final deviceInfo = await CommandRouter.getDeviceInfo();
    final battery = await CommandRouter.getBatteryLevel();
    final accessibility = await CommandRouter.isAccessibilityEnabled();
    final notifications = await CommandRouter.isNotificationListenerEnabled();
    final shizuku = await CommandRouter.getShizukuStatus();
    final root = await CommandRouter.getRootStatus();

    return {
      'androidVersion': Platform.operatingSystemVersion,
      'sdkVersion': Platform.version,
      'manufacturer': deviceInfo.data['manufacturer'] ?? 'Unknown',
      'model': deviceInfo.data['model'] ?? 'Unknown',
      'batteryLevel': battery.data['level'] ?? -1,
      'isCharging': battery.data['charging'] ?? false,
      'accessibilityEnabled': accessibility.data['enabled'] ?? false,
      'notificationListenerEnabled': notifications.data['enabled'] ?? false,
      'shizukuStatus': shizuku.data['status'] ?? 'unknown',
      'rootAvailable': root.data['available'] ?? false,
      'appName': 'Hello Jarvice',
      'appVersion': '1.0.0',
    };
  }

  String formatDiagnostics(Map<String, dynamic> diag) {
    final buffer = StringBuffer();
    buffer.writeln('=== JARVICE DIAGNOSTICS ===');
    buffer.writeln('');
    buffer.writeln('DEVICE');
    buffer.writeln('  Manufacturer: ${diag['manufacturer']}');
    buffer.writeln('  Model: ${diag['model']}');
    buffer.writeln('  Android: ${diag['androidVersion']}');
    buffer.writeln('');
    buffer.writeln('BATTERY');
    buffer.writeln('  Level: ${diag['batteryLevel']}%');
    buffer.writeln('  Charging: ${diag['isCharging']}');
    buffer.writeln('');
    buffer.writeln('CAPABILITIES');
    buffer.writeln('  Accessibility: ${diag['accessibilityEnabled'] ? 'ON' : 'OFF'}');
    buffer.writeln('  Notification Access: ${diag['notificationListenerEnabled'] ? 'ON' : 'OFF'}');
    buffer.writeln('  Shizuku: ${diag['shizukuStatus']}');
    buffer.writeln('  Root: ${diag['rootAvailable'] ? 'AVAILABLE' : 'NOT AVAILABLE'}');
    buffer.writeln('');
    buffer.writeln('APP');
    buffer.writeln('  Name: ${diag['appName']}');
    buffer.writeln('  Version: ${diag['appVersion']}');
    buffer.writeln('');
    buffer.writeln('==========================');
    return buffer.toString();
  }
}
