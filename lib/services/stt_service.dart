import 'package:speech_to_text/speech_to_text.dart' as stt;

class SttService {
  final stt.SpeechToText _speech = stt.SpeechToText();
  bool _available = false;
  bool _listening = false;

  Future<bool> initialize() async {
    try {
      _available = await _speech.initialize(
        onStatus: (status) {},
        onError: (error) {},
      );
    } catch (e) {
      _available = false;
    }
    return _available;
  }

  Future<String> listen({String? localeId, void Function(String)? onLiveResult}) async {
    if (!_available) {
      await initialize();
    }
    if (!_available) return '';

    String result = '';
    _listening = true;

    String selectedLocale = localeId ?? _detectLocale();

    try {
      await _speech.listen(
        onResult: (val) {
          if (val.recognizedWords.isNotEmpty) {
            result = val.recognizedWords;
            onLiveResult?.call(result);
          }
        },
        localeId: selectedLocale,
        listenMode: stt.ListenMode.dictation,
        cancelOnError: true,
      );

      await Future.delayed(const Duration(seconds: 5));
      await stopListening();

      if (result.isEmpty && selectedLocale == 'hi_IN') {
        return await listen(localeId: 'en_US', onLiveResult: onLiveResult);
      }
    } catch (e) {
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

  void dispose() {
    _speech.stop();
  }
}
