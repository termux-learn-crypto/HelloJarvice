import 'package:flutter/material.dart';

class VoiceButton extends StatefulWidget {
  final VoidCallback onTap;
  final bool isListening;

  const VoiceButton({
    super.key,
    required this.onTap,
    this.isListening = false,
  });

  @override
  State<VoiceButton> createState() => _VoiceButtonState();
}

class _VoiceButtonState extends State<VoiceButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _pulseAnim;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    _pulseAnim = Tween<double>(begin: 1.0, end: 1.3).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeInOut),
    );
  }

  @override
  void didUpdateWidget(VoiceButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isListening && !oldWidget.isListening) {
      _animController.repeat(reverse: true);
    } else if (!widget.isListening && oldWidget.isListening) {
      _animController.stop();
      _animController.animateTo(0.0, duration: const Duration(milliseconds: 300));
    }
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      child: AnimatedBuilder(
        animation: _pulseAnim,
        builder: (context, child) {
          return Transform.scale(
            scale: widget.isListening ? _pulseAnim.value : 1.0,
            child: Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: widget.isListening
                    ? Colors.redAccent
                    : Theme.of(context).primaryColor,
                boxShadow: [
                  BoxShadow(
                    color: (widget.isListening
                            ? Colors.redAccent
                            : Theme.of(context).primaryColor)
                        .withValues(alpha: 0.4),
                    blurRadius: widget.isListening ? 30 : 20,
                    spreadRadius: widget.isListening ? 10 : 5,
                  ),
                ],
              ),
              child: Icon(
                widget.isListening ? Icons.mic : Icons.mic_none,
                color: Colors.white,
                size: 40,
              ),
            ),
          );
        },
      ),
    );
  }
}
