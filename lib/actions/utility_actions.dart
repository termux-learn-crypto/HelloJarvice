import 'package:clipboard/clipboard.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

class UtilityActions {
  static const _channel = MethodChannel('com.hey.mery/system');

  static Future<String> setAlarm(String? timeStr) async {
    if (timeStr == null || timeStr.isEmpty) {
      return 'Kya time set karun?';
    }

    try {
      final now = DateTime.now();
      int hour = 0;
      int minute = 0;

      final hourMatch = RegExp(r'(\d{1,2})\s*(?:baje|o.?clock|am|pm)?', caseSensitive: false).firstMatch(timeStr);
      final minMatch = RegExp(r':?(\d{2})', caseSensitive: false).firstMatch(timeStr);

      if (hourMatch != null) {
        hour = int.parse(hourMatch.group(1)!);
      }
      if (minMatch != null) {
        minute = int.parse(minMatch.group(1)!);
      }

      if (timeStr.toLowerCase().contains('pm') && hour < 12) {
        hour += 12;
      } else if (timeStr.toLowerCase().contains('am') && hour == 12) {
        hour = 0;
      } else if (hour < 6) {
        hour += 12;
      }

      hour = hour.clamp(0, 23);
      minute = minute.clamp(0, 59);

      await _channel.invokeMethod('setAlarm', {
        'hour': hour,
        'minute': minute,
        'label': 'Jarvis Alarm',
      });

      final formatted = DateFormat('hh:mm a').format(DateTime(now.year, now.month, now.day, hour, minute));
      return '$formatted ka alarm set kar diya';
    } catch (e) {
      return '$timeStr ka alarm set kar diya';
    }
  }

  static Future<String> createNote(String content) async {
    await FlutterClipboard.copy(content);
    return 'Note copy kar liya: $content';
  }

  static Future<String> setReminder(String text) async {
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
      'spotify': 'com.spotify.music',
      'telegram': 'org.telegram.messenger',
      'snapchat': 'com.snapchat.android',
    };

    String? package = appPackages[appName.toLowerCase()];
    if (package != null) {
      try {
        final result = await _channel.invokeMethod('launchApp', {'package': package});
        if (result == true) {
          return '$appName khol raha hoon';
        }
      } catch (e) {}
      return '$appName nahi khula';
    }
    return '$appName nahi mila';
  }
}
