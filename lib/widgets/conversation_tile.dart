import 'package:flutter/material.dart';
import '../models/conversation_model.dart';

class ConversationTile extends StatelessWidget {
  final Conversation conversation;

  const ConversationTile({super.key, required this.conversation});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Column(
        crossAxisAlignment: conversation.isUser
            ? CrossAxisAlignment.end
            : CrossAxisAlignment.start,
        children: [
          if (conversation.isUser)
            _buildBubble(
              context,
              conversation.text,
              Colors.blueAccent,
              isUser: true,
            )
          else ...[
            _buildBubble(
              context,
              conversation.text,
              Colors.grey.shade200,
              isUser: true,
            ),
            if (conversation.reply.isNotEmpty)
              _buildBubble(
                context,
                conversation.reply,
                Colors.indigo.shade100,
                isUser: false,
                isReply: true,
              ),
          ],
        ],
      ),
    );
  }

  Widget _buildBubble(
    BuildContext context,
    String text,
    Color color, {
    bool isUser = true,
    bool isReply = false,
  }) {
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: EdgeInsets.only(
          top: 2,
          left: isUser ? 50 : 0,
          right: isUser ? 0 : 50,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(20),
            topRight: const Radius.circular(20),
            bottomLeft: isUser ? const Radius.circular(20) : Radius.zero,
            bottomRight: isUser ? Radius.zero : const Radius.circular(20),
          ),
        ),
        child: Text(
          text,
          style: TextStyle(
            color: isUser ? Colors.white : Colors.black87,
            fontSize: isReply ? 14 : 16,
            fontStyle: isReply ? FontStyle.italic : FontStyle.normal,
          ),
        ),
      ),
    );
  }
}
