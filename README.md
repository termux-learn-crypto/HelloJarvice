# Hello Jarvice - Voice Assistant App

## Setup Instructions

### Step 1: Download the Wake Word Model

1. Go to https://github.com/dscripka/openWakeWord/releases/tag/v0.5.1
2. Download `hey_jarvis_v0.1.onnx` file
3. Rename it to `hey_jarvis.onnx`
4. Place it in: `assets/models/hey_jarvis.onnx`
   (Already included in the repo!)

### Step 2: Push to GitHub

1. Create a new GitHub repository (use GitHub mobile app)
2. Push all these files to the `main` branch
3. GitHub Actions will automatically build the APK

### Step 3: Download APK

1. Go to your repo on GitHub
2. Click "Actions" tab
3. Click the latest workflow run
4. Download "HelloJarvice-APK" artifact
5. Install the APK on your phone

## Commands Supported

### System
- "WiFi on karo" / "WiFi off karo"
- "Bluetooth on karo" / "Bluetooth off karo"
- "Flashlight on karo" / "Flashlight off karo"

### Communication
- "Call mummy"
- "WhatsApp Divya bhejo kal milte hain"

### Information
- "Mausam kya hai Delhi ka"
- "Time kya hai"
- "Search for recipe" / "Google pe recipe search karo"

### Utilities
- "Alarm set karo 7 baje"
- "Note likho meeting 2 baje"
- "YouTube pe song chalao"
- "Open WhatsApp"

## Tech Stack
- Flutter (Dart)
- OpenWakeWord (ONNX model)
- speech_to_text (Google STT)
- flutter_tts (TTS Hindi + English)
