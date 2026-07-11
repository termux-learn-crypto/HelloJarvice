# Jarvis Voice Assistant - Complete Plan

## App Name: Hello Jarvice
## Package Name: com.hey.mery

## Architecture
- Wake Word: OpenWakeWord ONNX model (Hey Jarvis pre-trained)
- STT: speech_to_text plugin (Google STT)
- TTS: flutter_tts (Hindi + English)
- NLP: Keyword-based parser (Hindi + English)
- Background: Android Foreground Service (MethodChannel)

## Features
1. Wake word detection (OpenWakeWord ONNX via native code)
2. Speech-to-text
3. Intent parsing (Hindi + English)
4. Actions: WiFi, BT, Calls, WhatsApp, Weather, Alarms, Search, Flashlight, Time, Notes
5. Text-to-speech reply
6. Background service with notification
7. Conversation history (SQLite)
8. Settings screen

## Folder Structure
```
jarvis_assistant/
├── lib/
│   ├── main.dart
│   ├── app.dart
│   ├── models/
│   │   └── conversation_model.dart
│   ├── services/
│   │   ├── wake_word_service.dart
│   │   ├── stt_service.dart
│   │   ├── tts_service.dart
│   │   ├── intent_parser.dart
│   │   ├── action_handler.dart
│   │   └── permission_service.dart
│   ├── actions/
│   │   ├── system_actions.dart
│   │   ├── communication_actions.dart
│   │   ├── web_actions.dart
│   │   ├── utility_actions.dart
│   │   └── media_actions.dart
│   ├── screens/
│   │   ├── home_screen.dart
│   │   ├── settings_screen.dart
│   │   └── permissions_screen.dart
│   ├── widgets/
│   │   ├── voice_button.dart
│   │   └── conversation_tile.dart
│   └── database/
│       └── database_helper.dart
├── android/
│   └── app/src/main/java/com/hey/mery/wake_word/
│       ├── WakeWordEngine.java
│       └── AudioCapture.java
├── assets/
│   └── models/
│       └── hey_jarvis.onnx (user needs to download)
├── pubspec.yaml
└── .github/workflows/build_apk.yml
```

## Build via GitHub Actions (no laptop needed)
1. Create GitHub repo
2. Push all files
3. GitHub Actions auto-builds APK
4. Download APK from Actions artifacts
