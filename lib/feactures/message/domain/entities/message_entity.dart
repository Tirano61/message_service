

class MessageEntity {
  final String id;
  final String content;
  final String senderId;
  final DateTime timestamp;

  MessageEntity({
    required this.id,
    required this.content,
    required this.senderId,
    required this.timestamp,
  });

  factory MessageEntity.fromJson(Map<String, dynamic> json) {
    return MessageEntity(
      id: json['id'],
      content: json['content'],
      senderId: json['senderId'],
      timestamp: DateTime.parse(json['timestamp']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'content': content,
      'senderId': senderId,
      'timestamp': timestamp.toIso8601String(),
    };
  }
}
