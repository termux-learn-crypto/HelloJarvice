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
  String _liveText = '';
  String _statusMessage = '';

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    await _tts.initialize();
    bool sttReady = await _stt.initialize();
    if (!sttReady && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Speech recognition available nahi hai. Device check karein.'),
          duration: Duration(seconds: 4),
        ),
      );
    }
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
      _liveText = '';
      _statusMessage = 'Sun raha hoon...';
    });

    if (_wakeWordActive) {
      await _wakeWord.stopListening();
      await Future.delayed(const Duration(milliseconds: 500));
    }

    String text = await _stt.listen(
      onLiveResult: (live) {
        if (mounted) {
          setState(() => _liveText = live);
        }
      },
    );

    if (text.isEmpty) {
      setState(() {
        _isListening = false;
        _processing = false;
        _liveText = '';
        _statusMessage = 'Kuch suna nahi. Phir se boliye.';
      });
      if (_wakeWordActive) {
        await _wakeWord.startListening();
      }
      await Future.delayed(const Duration(seconds: 2));
      if (mounted) {
        setState(() => _statusMessage = '');
      }
      return;
    }

    setState(() {
      _liveText = '';
      _statusMessage = 'Processing...';
    });

    _addConversation(text, '', true);
    setState(() => _isListening = false);

    IntentResult intent = _parser.parse(text);
    String reply = await ActionHandler.execute(intent);

    _addConversation(text, reply, false);
    setState(() => _statusMessage = '');

    await _tts.speak(reply);

    setState(() => _processing = false);

    if (_wakeWordActive) {
      await _wakeWord.startListening();
    }
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
          if (_isListening || _liveText.isNotEmpty || _statusMessage.isNotEmpty)
            Container(
              width: double.infinity,
              padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              margin: EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: _isListening
                    ? Colors.redAccent.withValues(alpha: 0.1)
                    : Colors.grey.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: _isListening ? Colors.redAccent.withValues(alpha: 0.3) : Colors.grey.withValues(alpha: 0.2),
                ),
              ),
              child: Column(
                children: [
                  if (_isListening)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(
                          width: 12,
                          height: 12,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.redAccent,
                          ),
                        ),
                        SizedBox(width: 8),
                        Text(
                          _statusMessage,
                          style: TextStyle(
                            color: Colors.redAccent,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  if (_liveText.isNotEmpty) ...[
                    if (_isListening) SizedBox(height: 8),
                    Text(
                      _liveText,
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.black87,
                        fontWeight: FontWeight.w500,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                  if (!_isListening && _statusMessage.isNotEmpty && _liveText.isEmpty)
                    Text(
                      _statusMessage,
                      style: TextStyle(color: Colors.grey, fontSize: 14),
                      textAlign: TextAlign.center,
                    ),
                ],
              ),
            ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 16, top: 8),
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
