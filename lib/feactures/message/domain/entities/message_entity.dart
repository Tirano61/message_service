

class MessageEntity {
  final String id;
  final String content;
  final String sender;
  final DateTime timestamp;

  MessageEntity({
    required this.id,
    required this.content,
    required this.sender,
    required this.timestamp,
  });

  factory MessageEntity.fromJson(Map<String, dynamic> json) {
    return MessageEntity(
      id: json['id'],
      content: json['content'],
      sender: json['sender'],
      timestamp: DateTime.parse(json['timestamp']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'content': content,
      'sender': sender,
      'timestamp': timestamp.toIso8601String(),
    };
  }
}
