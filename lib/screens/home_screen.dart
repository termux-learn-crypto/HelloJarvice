import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/conversation_model.dart';
import '../database/database_helper.dart';
import '../services/stt_service.dart';
import '../services/tts_service.dart';
import '../services/wake_word_service.dart';
import '../core/semantic_interpreter.dart';
import '../core/action_planner.dart';
import '../core/capability_executor.dart';
import '../core/response_generator.dart';
import '../core/capability_registry.dart';
import '../core/capability_result.dart';
import '../models/action_plan.dart';
import '../widgets/voice_button.dart';
import '../widgets/conversation_tile.dart';
import 'control_center_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final SttService _stt = SttService();
  final TtsService _tts = TtsService();
  final WakeWordService _wakeWord = WakeWordService();
  final DatabaseHelper _db = DatabaseHelper();

  List<Conversation> _conversations = [];
  bool _isListening = false;
  bool _wakeWordActive = false;
  bool _processing = false;
  String _liveText = '';
  String _statusMessage = '';
  String _wakeWordState = 'stopped';

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    CapabilityRegistry.instance.initialize();

    try {
      await _tts.initialize();
    } catch (e) {
      debugPrint('TTS init failed: $e');
    }

    try {
      bool sttReady = await _stt.initialize();
      if (!sttReady && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _stt.lastError.isNotEmpty
                  ? _stt.lastError
                  : 'Speech recognition available nahi hai. Device check karein.',
            ),
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } catch (e) {
      debugPrint('STT init failed: $e');
    }

    try {
      await _tts.speak('Namaste, main Jarvis hoon. Kaise madad kar sakta hoon?');
    } catch (e) {
      debugPrint('TTS speak failed: $e');
    }

    _loadHistory();
    _initWakeWord();
  }

  Future<void> _initWakeWord() async {
    try {
      bool initialized = await _wakeWord.initialize();
      if (initialized && mounted) {
        _wakeWord.onWakeWordDetected = () {
          if (!_processing) {
            _startListening();
          }
        };
        _wakeWord.onStateChanged = (state) {
          if (mounted) {
            setState(() => _wakeWordState = state);
          }
        };
        bool started = await _wakeWord.startListening();
        if (mounted) {
          setState(() {
            _wakeWordActive = started;
            _wakeWordState = started ? 'listening' : 'stopped';
          });
        }
      }
    } catch (e) {
      debugPrint('Wake word init failed: $e');
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
      await _wakeWord.pauseListening();
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
      final errorMsg = _stt.lastError.isNotEmpty
          ? _stt.lastError
          : 'Kuch suna nahi. Phir se boliye.';
      setState(() {
        _isListening = false;
        _processing = false;
        _liveText = '';
        _statusMessage = errorMsg;
      });
      if (_wakeWordActive) {
        await _wakeWord.resumeListening();
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

    setState(() => _isListening = false);

    List<Goal> goals = SemanticInterpreter.instance.interpret(text);
    ActionPlan plan = ActionPlanner.instance.createPlan(goals, text);
    CapabilityResult result = await CapabilityExecutor.instance.executePlan(plan);
    String reply = ResponseGenerator.instance.generateResponse(result);

    _addConversation(text, reply, false);
    setState(() => _statusMessage = '');

    await _tts.speak(reply);

    setState(() => _processing = false);

    if (_wakeWordActive) {
      await _wakeWord.resumeListening();
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

  String _getWakeWordStatusText() {
    switch (_wakeWordState) {
      case 'listening':
        return 'Listening...';
      case 'paused':
        return 'Paused';
      case 'processing_command':
        return 'Processing...';
      case 'wake_word_detected':
        return 'Detected!';
      case 'starting':
        return 'Starting...';
      case 'error':
        return 'Error';
      default:
        return 'Stopped';
    }
  }

  Color _getWakeWordStatusColor() {
    switch (_wakeWordState) {
      case 'listening':
        return Colors.green;
      case 'paused':
        return Colors.orange;
      case 'processing_command':
        return Colors.blue;
      case 'wake_word_detected':
        return Colors.lightGreen;
      case 'starting':
        return Colors.yellow;
      case 'error':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            const Icon(Icons.smart_toy, size: 28),
            const SizedBox(width: 8),
            const Text('Hello Jarvice'),
          ],
        ),
        actions: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            margin: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              color: _getWakeWordStatusColor().withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _getWakeWordStatusColor(),
                  ),
                ),
                const SizedBox(width: 4),
                Text(
                  _getWakeWordStatusText(),
                  style: TextStyle(
                    fontSize: 11,
                    color: _getWakeWordStatusColor(),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 4),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => ControlCenterScreen(ttsService: _tts)),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline),
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
                        const SizedBox(height: 16),
                        Text(
                          'Boliye... main sun raha hoon',
                          style: TextStyle(fontSize: 18, color: Colors.grey.shade600),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '"Call mummy" ya "Mausam kya hai" ya "Volume badhao"',
                          style: TextStyle(fontSize: 14, color: Colors.grey.shade400),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Hindi, English, Hinglish sab chalega',
                          style: TextStyle(fontSize: 12, color: Colors.grey.shade400),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    reverse: true,
                    padding: const EdgeInsets.only(top: 8, bottom: 80),
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
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              margin: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: _isListening
                    ? Colors.redAccent.withValues(alpha: 0.1)
                    : Colors.grey.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: _isListening
                      ? Colors.redAccent.withValues(alpha: 0.3)
                      : Colors.grey.withValues(alpha: 0.2),
                ),
              ),
              child: Column(
                children: [
                  if (_isListening)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const SizedBox(
                          width: 12,
                          height: 12,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.redAccent,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _statusMessage,
                          style: const TextStyle(
                            color: Colors.redAccent,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  if (_liveText.isNotEmpty) ...[
                    if (_isListening) const SizedBox(height: 8),
                    Text(
                      _liveText,
                      style: const TextStyle(
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
                      style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
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
