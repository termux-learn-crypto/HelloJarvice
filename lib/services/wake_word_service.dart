import 'package:flutter/services.dart';

class WakeWordService {
  static const _channel = MethodChannel('com.hey.mery/wake_word');
  bool _isRunning = false;
  String _currentState = 'stopped';
  VoidCallback? onWakeWordDetected;
  Function(String)? onStateChanged;

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
          } else if (call.method == 'onWakeWordStateChanged') {
            final state = call.arguments;
            if (state is Map) {
              _currentState = state['state']?.toString() ?? 'unknown';
            } else if (state is String) {
              _currentState = state;
            }
            onStateChanged?.call(_currentState);
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
      _currentState = 'stopped';
      onStateChanged?.call(_currentState);
    } catch (_) {}
  }

  Future<void> pauseListening() async {
    try {
      await _channel.invokeMethod('pauseListening');
      _currentState = 'paused';
      onStateChanged?.call(_currentState);
    } catch (_) {}
  }

  Future<void> resumeListening() async {
    try {
      await _channel.invokeMethod('resumeListening');
      _currentState = 'listening';
      onStateChanged?.call(_currentState);
    } catch (_) {}
  }

  bool get isRunning => _isRunning;
  String get currentState => _currentState;

  void dispose() {
    stopListening();
  }
}
