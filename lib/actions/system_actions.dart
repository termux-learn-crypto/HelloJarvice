import 'package:flutter/services.dart';

class SystemActions {
  static const _channel = MethodChannel('com.hey.mery/system');

  static Future<String> toggleWiFi(String state) async {
    try {
      await _channel.invokeMethod('toggleWifi', {'state': state == 'on'});
      return state == 'on' ? 'WiFi on kar diya' : 'WiFi off kar diya';
    } catch (e) {
      return 'WiFi control ke liye permission nahi hai';
    }
  }

  static Future<String> toggleBluetooth(String state) async {
    try {
      await _channel.invokeMethod('toggleBluetooth', {'state': state == 'on'});
      return state == 'on' ? 'Bluetooth on kar diya' : 'Bluetooth off kar diya';
    } catch (e) {
      return 'Bluetooth control ke liye permission nahi hai';
    }
  }

  static Future<String> toggleFlashlight(String state) async {
    try {
      await _channel.invokeMethod('toggleFlashlight', {'state': state == 'on'});
      return state == 'on' ? 'Flashlight on kar diya' : 'Flashlight off kar diya';
    } catch (e) {
      return 'Flashlight control nahi ho paya';
    }
  }

  static Future<String> openSettings(String? section) async {
    try {
      return 'Settings open ki';
    } catch (e) {
      return 'Settings open nahi ho paya';
    }
  }
}
