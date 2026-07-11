import 'package:flutter_tts/flutter_tts.dart';

class TtsService {
  final FlutterTts _tts = FlutterTts();
  bool _speaking = false;

  Future<void> initialize() async {
    await _tts.setLanguage('hi-IN');
    await _tts.setSpeechRate(0.4);
    await _tts.setPitch(1.0);
    await _tts.setVolume(1.0);

    _tts.setCompletionHandler(() {
      _speaking = false;
    });
  }

  Future<void> speak(String text) async {
    _speaking = true;

    bool hasHindi = RegExp(r'[\u0900-\u097F]').hasMatch(text);
    if (hasHindi) {
      await _tts.setLanguage('hi-IN');
    } else {
      await _tts.setLanguage('en-US');
    }

    await _tts.speak(text);
  }

  Future<void> stop() async {
    await _tts.stop();
    _speaking = false;
  }

  bool get isSpeaking => _speaking;

  void dispose() {
    _tts.stop();
  }
}
