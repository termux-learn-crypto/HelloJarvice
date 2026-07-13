import 'package:flutter/foundation.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

class SttService {
  final stt.SpeechToText _speech = stt.SpeechToText();
  bool _available = false;
  bool _listening = false;
  String _lastError = '';

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
    } catch (e) {
      debugPrint('STT initialize exception: $e');
      _available = false;
    }
    return _available;
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

    String selectedLocale = localeId ?? _detectLocale();

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
        listenFor: const Duration(seconds: 8),
      );

      await Future.delayed(const Duration(seconds: 8));
      await stopListening();

      if (result.isEmpty && selectedLocale == 'hi_IN') {
        return await listen(localeId: 'en_US', onLiveResult: onLiveResult);
      }
    } catch (e) {
      debugPrint('STT listen exception: $e');
      _lastError = 'Sunne mein dikkat aa rahi hai: $e';
      await stopListening();
    }

    return result;
  }

  String _detectLocale() {
    return 'hi_IN';
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
