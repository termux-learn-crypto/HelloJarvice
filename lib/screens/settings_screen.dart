import 'package:flutter/material.dart';
import '../services/tts_service.dart';
import 'control_center_screen.dart';

class SettingsScreen extends StatelessWidget {
  final TtsService ttsService;

  const SettingsScreen({super.key, required this.ttsService});

  @override
  Widget build(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => ControlCenterScreen(ttsService: ttsService)),
      );
    });

    return Scaffold(
      body: const Center(child: CircularProgressIndicator()),
    );
  }
}
