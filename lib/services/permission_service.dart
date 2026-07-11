import 'package:permission_handler/permission_handler.dart';

class PermissionService {
  static Future<bool> requestMicrophonePermission() async {
    var status = await Permission.microphone.request();
    return status.isGranted;
  }

  static Future<bool> requestNotificationPermission() async {
    var status = await Permission.notification.request();
    return status.isGranted;
  }

  static Future<bool> requestLocationPermission() async {
    var status = await Permission.location.request();
    return status.isGranted;
  }

  static Future<bool> allPermissionsGranted() async {
    var mic = await Permission.microphone.isGranted;
    var notif = await Permission.notification.isGranted;
    return mic && notif;
  }

  static Future<Map<String, bool>> checkAllPermissions() async {
    return {
      'microphone': await Permission.microphone.isGranted,
      'notification': await Permission.notification.isGranted,
      'location': await Permission.location.isGranted,
    };
  }
}
