import 'package:speech_to_text/speech_to_text.dart' as stt;

class SttService {
  final stt.SpeechToText _speech = stt.SpeechToText();
  bool _available = false;
  bool _listening = false;

  Future<bool> initialize() async {
    _available = await _speech.initialize(
      onStatus: (status) {},
      onError: (error) {},
    );
    return _available;
  }

  Future<String> listen() async {
    if (!_available) {
      await initialize();
    }
    if (!_available) return '';

    String result = '';
    _listening = true;

    await _speech.listen(
      onResult: (val) {
        result = val.recognizedWords;
      },
      localeId: 'hi_IN',
      listenMode: stt.ListenMode.dictation,
    );

    await Future.delayed(const Duration(seconds: 4));
    await stopListening();

    return result;
  }

  Future<void> stopListening() async {
    if (_listening) {
      await _speech.stop();
      _listening = false;
    }
  }

  bool get isListening => _listening;
  bool get isAvailable => _available;

  void dispose() {
    _speech.stop();
  }
}
