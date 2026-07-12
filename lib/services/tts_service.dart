import 'package:flutter_tts/flutter_tts.dart';
import 'package:shared_preferences/shared_preferences.dart';

class TtsService {
  final FlutterTts _tts = FlutterTts();
  bool _speaking = false;
  double _speechRate = 0.4;
  double _pitch = 1.0;

  Future<void> initialize() async {
    final prefs = await SharedPreferences.getInstance();
    _speechRate = prefs.getDouble('tts_speed') ?? 0.4;
    _pitch = prefs.getDouble('tts_pitch') ?? 1.0;

    await _tts.setLanguage('hi-IN');
    await _tts.setSpeechRate(_speechRate);
    await _tts.setPitch(_pitch);
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

  Future<void> updateSettings({double? speechRate, double? pitch}) async {
    final prefs = await SharedPreferences.getInstance();
    if (speechRate != null) {
      _speechRate = speechRate;
      await prefs.setDouble('tts_speed', speechRate);
      await _tts.setSpeechRate(speechRate);
    }
    if (pitch != null) {
      _pitch = pitch;
      await prefs.setDouble('tts_pitch', pitch);
      await _tts.setPitch(pitch);
    }
  }

  double get speechRate => _speechRate;
  double get pitch => _pitch;

  Future<void> stop() async {
    await _tts.stop();
    _speaking = false;
  }

  bool get isSpeaking => _speaking;

  void dispose() {
    _tts.stop();
  }
}
