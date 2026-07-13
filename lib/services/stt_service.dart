import 'package:flutter/foundation.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

class SttService {
  final stt.SpeechToText _speech = stt.SpeechToText();
  bool _available = false;
  bool _listening = false;
  String _lastError = '';
  String _selectedLocale = 'en_US';

  Future<bool> initialize() async {
    try {
      _available = await _speech.initialize(
        onStatus: (status) {
          debugPrint('STT status: $status');
        },
        onError: (error) {
          debugPrint('STT init error: ${error.errorMsg} (perm: ${error.permanent})');
        },
      );
      if (_available) {
        _selectedLocale = await _findBestLocale();
      }
    } catch (e) {
      debugPrint('STT initialize exception: $e');
      _available = false;
    }
    return _available;
  }

  Future<String> _findBestLocale() async {
    try {
      final locales = await _speech.locales();
      final codes = locales.map((l) => l.localeId).toList();

      for (final code in ['hi_IN', 'hi-IN']) {
        if (codes.contains(code)) return code;
      }
      for (final code in ['en_IN', 'en-US', 'en_US']) {
        if (codes.contains(code)) return code;
      }
      if (codes.isNotEmpty) return codes.first;
    } catch (e) {
      debugPrint('STT locale detection failed: $e');
    }
    return 'en_US';
  }

  Future<String> listen({String? localeId, void Function(String)? onLiveResult}) async {
    _lastError = '';

    if (!_available) {
      await initialize();
    }
    if (!_available) {
      _lastError = 'Speech recognition available nahi hai';
      return '';
    }

    String result = '';
    _listening = true;

    String selectedLocale = localeId ?? _selectedLocale;

    try {
      final options = stt.SpeechListenOptions(
        localeId: selectedLocale,
        listenMode: stt.ListenMode.deviceDefault,
        cancelOnError: false,
        partialResults: true,
      );

      await _speech.listen(
        onResult: (val) {
          if (val.recognizedWords.isNotEmpty) {
            result = val.recognizedWords;
            onLiveResult?.call(result);
          }
        },
        listenOptions: options,
      );

      await Future.delayed(const Duration(seconds: 8));
      await stopListening();

      if (result.isEmpty && selectedLocale.startsWith('hi')) {
        return await listen(localeId: 'en_US', onLiveResult: onLiveResult);
      }
    } catch (e) {
      debugPrint('STT listen exception: $e');
      _lastError = 'Sunne mein dikkat aa rahi hai: $e';
      await stopListening();
    }

    return result;
  }

  Future<void> stopListening() async {
    if (_listening) {
      try {
        await _speech.stop();
      } catch (_) {}
      _listening = false;
    }
  }

  bool get isListening => _listening;
  bool get isAvailable => _available;
  String get lastError => _lastError;

  void dispose() {
    _speech.stop();
  }
}
