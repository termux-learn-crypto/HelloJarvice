import 'package:flutter/services.dart';

class WakeWordService {
  static const _channel = MethodChannel('com.hey.mery/wake_word');
  bool _isRunning = false;
  VoidCallback? onWakeWordDetected;

  Future<bool> initialize() async {
    try {
      final result = await _channel.invokeMethod('initEngine');
      return result == true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> startListening() async {
    try {
      final result = await _channel.invokeMethod('startListening');
      _isRunning = result == true;
      if (_isRunning) {
        _channel.setMethodCallHandler((call) async {
          if (call.method == 'onWakeWordDetected') {
            onWakeWordDetected?.call();
          }
        });
      }
      return _isRunning;
    } catch (e) {
      return false;
    }
  }

  Future<void> stopListening() async {
    try {
      await _channel.invokeMethod('stopListening');
      _isRunning = false;
    } catch (e) {}
  }

  bool get isRunning => _isRunning;

  void dispose() {
    stopListening();
  }
}
