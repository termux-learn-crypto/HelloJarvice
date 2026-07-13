import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:shared_preferences/shared_preferences.dart';

class TtsService {
  final FlutterTts _tts = FlutterTts();
  bool _speaking = false;
  double _speechRate = 0.4;
  double _pitch = 1.0;
  Completer<void>? _speakCompleter;

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
      if (_speakCompleter != null && !_speakCompleter!.isCompleted) {
        _speakCompleter!.complete();
      }
    });
  }

  static final _hinglishWords = RegExp(
    r'\b(haan|bolo|ji|batao|karo|khol|band|suno|sun|dekh|jao|aao|chalo|chalao|volume|awaaz|torch|flashlight|wifi|bluetooth|battery|camera|settings|alarm|timer|reminder|phone|call|message|sms|whatsapp|google|search|play|pause|stop|next|back|home|mute|unmute|screen|scroll|copy|paste|delete|share|rotate|brightness|roshni|dhoondo|bhejo|likho|bajao|ghatao|badhao|kam|zyada|poora|full|low|max|min|on|off|enable|disable|start|open|close|quit|exit|done|ho gaya|raha hai|diya|laga|kar diya|set|create|get|check)\b',
    caseSensitive: false,
  );

  bool _isHinglish(String text) {
    if (RegExp(r'[\u0900-\u097F]').hasMatch(text)) return true;
    final words = text.toLowerCase().split(RegExp(r'\s+'));
    int hinglishCount = 0;
    for (final word in words) {
      if (_hinglishWords.hasMatch(word)) hinglishCount++;
    }
    return hinglishCount >= 1;
  }

  Future<void> speak(String text) async {
    _speaking = true;
    _speakCompleter = Completer<void>();

    if (_isHinglish(text)) {
      await _tts.setLanguage('hi-IN');
    } else {
      await _tts.setLanguage('en-US');
    }

    await _tts.speak(text);
  }

  Future<void> speakAndWait(String text) async {
    await speak(text);
    await _speakCompleter?.future;
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
    if (_speakCompleter != null && !_speakCompleter!.isCompleted) {
      _speakCompleter!.complete();
    }
  }

  bool get isSpeaking => _speaking;

  void dispose() {
    _tts.stop();
  }
}
