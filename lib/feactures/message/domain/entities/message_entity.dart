

// ignore_for_file: non_constant_identifier_names

class MessageEntity {
  final String id;
  final String content;
  final String sender;
  final DateTime created_at;

  MessageEntity({
    required this.id,
    required this.content,
    required this.sender,
    required this.created_at,
  });

  factory MessageEntity.fromJson(Map<String, dynamic> json) {
    // El servidor usa `created_at`; algunos payloads pueden traer `timestamp`.
    // Soportamos ambos, además de epoch (int) y strings ISO.
    final raw = json['created_at'] ?? json['timestamp'];
    DateTime timestamp;

    if (raw == null) {
      timestamp = DateTime.now().toUtc();
    } else if (raw is int) {
      // Si el entero es grande (>1e12) lo tratamos como ms, si no como s
      timestamp = raw > 1000000000000
          ? DateTime.fromMillisecondsSinceEpoch(raw, isUtc: true)
          : DateTime.fromMillisecondsSinceEpoch(raw * 1000, isUtc: true);
    } else if (raw is String) {
      try {
        timestamp = DateTime.parse(raw).toUtc();
      } catch (_) {
        timestamp = DateTime.now().toUtc();
      }
    } else {
      timestamp = DateTime.now().toUtc();
    }

    return MessageEntity(
      id: json['id'] as String,
      content: json['content'] as String,
      sender: json['sender'] as String,
      created_at: timestamp,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'content': content,
      'sender': sender,
      'created_at': created_at.toIso8601String(),
    };
  }
}
