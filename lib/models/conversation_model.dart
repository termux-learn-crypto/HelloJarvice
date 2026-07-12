class Conversation {
  final int? id;
  final String text;
  final String reply;
  final String timestamp;
  final bool isUser;

  Conversation({
    this.id,
    required this.text,
    required this.reply,
    required this.timestamp,
    required this.isUser,
  });

  Map<String, dynamic> toMap() {
    final map = <String, dynamic>{
      'text': text,
      'reply': reply,
      'timestamp': timestamp,
      'isUser': isUser ? 1 : 0,
    };
    if (id != null) {
      map['id'] = id;
    }
    return map;
  }

  factory Conversation.fromMap(Map<String, dynamic> map) {
    return Conversation(
      id: map['id'],
      text: map['text'],
      reply: map['reply'],
      timestamp: map['timestamp'],
      isUser: map['isUser'] == 1,
    );
  }
}
