import 'package:flutter/material.dart';
import '../services/tts_service.dart';

class SettingsScreen extends StatefulWidget {
  final TtsService ttsService;

  const SettingsScreen({super.key, required this.ttsService});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late double _speechRate;
  late double _pitch;

  @override
  void initState() {
    super.initState();
    _speechRate = widget.ttsService.speechRate;
    _pitch = widget.ttsService.pitch;
  }

  Future<void> _updateSpeed(double val) async {
    setState(() => _speechRate = val);
    await widget.ttsService.updateSettings(speechRate: val);
  }

  Future<void> _updatePitch(double val) async {
    setState(() => _pitch = val);
    await widget.ttsService.updateSettings(pitch: val);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.all(16),
                  child: Text(
                    'Voice Settings',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
                ListTile(
                  title: const Text('Speed'),
                  subtitle: Slider(
                    value: _speechRate,
                    min: 0.1,
                    max: 1.0,
                    divisions: 9,
                    label: _speechRate.toStringAsFixed(1),
                    onChanged: _updateSpeed,
                  ),
                ),
                ListTile(
                  title: const Text('Pitch'),
                  subtitle: Slider(
                    value: _pitch,
                    min: 0.5,
                    max: 2.0,
                    divisions: 15,
                    label: _pitch.toStringAsFixed(1),
                    onChanged: _updatePitch,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.all(16),
                  child: Text(
                    'About',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
                const ListTile(
                  leading: Icon(Icons.info),
                  title: Text('Version'),
                  subtitle: Text('1.0.0'),
                ),
                const ListTile(
                  leading: Icon(Icons.code),
                  title: Text('Wake Word'),
                  subtitle: Text('Hey Jarvis (OpenWakeWord)'),
                ),
                const ListTile(
                  leading: Icon(Icons.language),
                  title: Text('Languages'),
                  subtitle: Text('Hindi, English'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
