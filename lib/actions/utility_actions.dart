import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:clipboard/clipboard.dart';
import 'package:flutter/services.dart';

class UtilityActions {
  static final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  static Future<void> initializeNotifications() async {
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const initSettings = InitializationSettings(android: androidSettings);
    await _notifications.initialize(initSettings);
  }

  static Future<String> setAlarm(String? timeStr) async {
    if (timeStr == null || timeStr.isEmpty) {
      return 'Kya time set karun?';
    }

    const androidDetails = AndroidNotificationDetails(
      'alarm_channel',
      'Alarm',
      channelDescription: 'Alarm notifications',
      importance: Importance.high,
      priority: Priority.high,
    );
    const details = NotificationDetails(android: androidDetails);

    await _notifications.show(
      0,
      'Alarm',
      'Alarm set for $timeStr',
      details,
    );

    return '$timeStr ka alarm set kar diya';
  }

  static Future<String> createNote(String content) async {
    await FlutterClipboard.copy(content);
    return 'Note copy kar liya: $content';
  }

  static Future<String> setReminder(String text) async {
    const androidDetails = AndroidNotificationDetails(
      'reminder_channel',
      'Reminder',
      channelDescription: 'Reminder notifications',
      importance: Importance.high,
      priority: Priority.high,
    );
    const details = NotificationDetails(android: androidDetails);

    await _notifications.show(
      1,
      'Reminder',
      text,
      details,
    );

    return 'Reminder set kar diya: $text';
  }

  static Future<String> launchApp(String appName) async {
    Map<String, String> appPackages = {
      'youtube': 'com.google.android.youtube',
      'whatsapp': 'com.whatsapp',
      'instagram': 'com.instagram.android',
      'facebook': 'com.facebook.katana',
      'twitter': 'com.twitter.android',
      'maps': 'com.google.android.apps.maps',
      'chrome': 'com.android.chrome',
      'camera': 'com.android.camera',
      'dialer': 'com.android.dialer',
      'calculator': 'com.android.calculator2',
      'settings': 'com.android.settings',
      'play store': 'com.android.vending',
      'gmail': 'com.google.android.gm',
    };

    String? package = appPackages[appName.toLowerCase()];
    if (package != null) {
      try {
        const _channel = MethodChannel('com.hey.mery/system');
        await _channel.invokeMethod('launchApp', {'package': package});
      } catch (e) {}
      return '$appName khol raha hoon';
    }
    return '$appName nahi mila';
  }
}
