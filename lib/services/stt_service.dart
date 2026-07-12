import 'package:speech_to_text/speech_to_text.dart' as stt;

class SttService {
  final stt.SpeechToText _speech = stt.SpeechToText();
  bool _available = false;
  bool _listening = false;
  String? _lastError;

  Future<bool> initialize() async {
    try {
      _available = await _speech.initialize(
        onStatus: (status) {},
        onError: (error) {
          _lastError = error.errorMsg;
          _available = false;
        },
      );
    } catch (e) {
      _available = false;
      _lastError = e.toString();
    }
    return _available;
  }

  Future<String> listen({String? localeId}) async {
    if (!_available) {
      await initialize();
    }
    if (!_available) return '';

    String result = '';
    bool gotResult = false;
    _listening = true;

    String selectedLocale = localeId ?? _detectLocale();

    try {
      await _speech.listen(
        onResult: (val) {
          if (val.recognizedWords.isNotEmpty) {
            result = val.recognizedWords;
            gotResult = true;
          }
        },
        localeId: selectedLocale,
        listenMode: stt.ListenMode.dictation,
      );

      await Future.delayed(const Duration(seconds: 4));
      await stopListening();

      if (!gotResult && selectedLocale == 'hi_IN') {
        return await listen(localeId: 'en_US');
      }
    } catch (e) {
      _lastError = e.toString();
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
  String? get lastError => _lastError;

  void dispose() {
    _speech.stop();
  }
}
