import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/conversation_model.dart';
import '../database/database_helper.dart';
import '../services/stt_service.dart';
import '../services/tts_service.dart';
import '../services/wake_word_service.dart';
import '../services/intent_parser.dart';
import '../services/action_handler.dart';
import '../widgets/voice_button.dart';
import '../widgets/conversation_tile.dart';
import 'settings_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final SttService _stt = SttService();
  final TtsService _tts = TtsService();
  final WakeWordService _wakeWord = WakeWordService();
  final IntentParser _parser = IntentParser();
  final DatabaseHelper _db = DatabaseHelper();

  List<Conversation> _conversations = [];
  bool _isListening = false;
  bool _wakeWordActive = false;
  bool _processing = false;

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    await _tts.initialize();
    await _stt.initialize();
    await _tts.speak('Namaste, main Jarvis hoon. Kaise madad kar sakta hoon?');
    _loadHistory();
    _initWakeWord();
  }

  Future<void> _initWakeWord() async {
    bool initialized = await _wakeWord.initialize();
    if (initialized && mounted) {
      _wakeWord.onWakeWordDetected = () {
        if (!_processing) {
          _startListening();
        }
      };
      bool started = await _wakeWord.startListening();
      if (mounted) {
        setState(() => _wakeWordActive = started);
      }
    }
  }

  Future<void> _loadHistory() async {
    List<Conversation> convos = await _db.getConversations();
    if (mounted) {
      setState(() => _conversations = convos);
    }
  }

  Future<void> _startListening() async {
    if (_processing) return;
    setState(() {
      _isListening = true;
      _processing = true;
    });

    String text = await _stt.listen();

    if (text.isEmpty) {
      setState(() {
        _isListening = false;
        _processing = false;
      });
      return;
    }

    _addConversation(text, '', true);
    setState(() => _isListening = false);

    IntentResult intent = _parser.parse(text);
    String reply = await ActionHandler.execute(intent);

    _addConversation(text, reply, false);
    await _tts.speak(reply);

    setState(() => _processing = false);
  }

  Future<void> _addConversation(String text, String reply, bool isUser) async {
    String now = DateFormat('HH:mm').format(DateTime.now());
    Conversation conv = Conversation(
      text: text,
      reply: reply,
      timestamp: now,
      isUser: isUser,
    );

    await _db.insertConversation(conv);

    if (mounted) {
      setState(() {
        _conversations.insert(0, conv);
      });
    }
  }

  @override
  void dispose() {
    _stt.dispose();
    _tts.dispose();
    _wakeWord.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Icon(Icons.smart_toy, size: 28),
            SizedBox(width: 8),
            Text('Hello Jarvice'),
          ],
        ),
        actions: [
          Icon(
            _wakeWordActive ? Icons.hearing : Icons.hearing_disabled,
            color: _wakeWordActive ? Colors.green : Colors.grey,
          ),
          SizedBox(width: 8),
          IconButton(
            icon: Icon(Icons.settings),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => SettingsScreen(ttsService: _tts)),
              );
            },
          ),
          IconButton(
            icon: Icon(Icons.delete_outline),
            onPressed: () async {
              await _db.clearConversations();
              setState(() => _conversations.clear());
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: _conversations.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.mic, size: 64, color: Colors.grey.shade300),
                        SizedBox(height: 16),
                        Text(
                          'Boliye... main sun raha hoon',
                          style: TextStyle(fontSize: 18, color: Colors.grey),
                        ),
                        SizedBox(height: 8),
                        Text(
                          '\"Call mummy\" ya \"Mausam kya hai\"',
                          style: TextStyle(fontSize: 14, color: Colors.grey.shade400),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    reverse: true,
                    padding: EdgeInsets.only(top: 8, bottom: 80),
                    itemCount: _conversations.length,
                    itemBuilder: (context, index) {
                      return ConversationTile(
                        conversation: _conversations[index],
                      );
                    },
                  ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: VoiceButton(
                isListening: _isListening,
                onTap: _startListening,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
