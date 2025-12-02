

// ignore_for_file: non_constant_identifier_names

class MessageEntity {
  final String id;
  final String content;
  final String sender;
  final DateTime created_at;
  final String? senderId;
  final String? externalId;
  final String? sessionId;
  final String? n8nMessage;

  MessageEntity({
    required this.id,
    required this.content,
    required this.sender,
  required this.created_at,
  this.senderId,
  this.externalId,
  this.sessionId,
  this.n8nMessage,
  
  });

  factory MessageEntity.fromJson(Map<String, dynamic> json) {
    // El servidor usa `created_at`; algunos payloads pueden traer `timestamp`.
    // Soportamos ambos, además de epoch (int) y strings ISO.
    final raw = json['created_at'] ?? json['timestamp'];
    DateTime timestamp;

    if (raw == null) {
      timestamp = DateTime.now().toUtc();
    } else if (raw is DateTime) {
      timestamp = raw.toUtc();
    } else if (raw is double) {
      // treat as epoch ms if large, otherwise epoch s
      final numVal = raw.toInt();
      timestamp = numVal > 1000000000000
          ? DateTime.fromMillisecondsSinceEpoch(numVal, isUtc: true)
          : DateTime.fromMillisecondsSinceEpoch(numVal * 1000, isUtc: true);
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

    try {
      print('DBG MessageEntity.fromJson raw_created_at=${raw ?? 'null'} parsed=${timestamp.toIso8601String()} id=${json['id'] ?? ''} content=${json['content'] ?? ''}');
    } catch (_) {}

    // Accept multiple aliases for sender/role and sender id
    final senderVal = (json['sender'] ?? json['from'] ?? json['role'] ?? json['type'] ?? '') as String;
    final senderIdVal = (json['sender_id'] ?? json['senderId'] ?? json['user_id'] ?? json['userId'] ?? json['from_id']) as String?;

    return MessageEntity(
      id: (json['id'] ?? '').toString(),
      content: (json['content'] ?? '').toString(),
  sender: senderVal,
  created_at: timestamp,
      senderId: senderIdVal,
      externalId: json['external_id'] as String?,
      sessionId: json['session_id'] as String?,
      n8nMessage: json['n8n_message'] as String?,
      
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'content': content,
  'sender': sender,
  'created_at': created_at.toIso8601String(),
  'sender_id': senderId,
  'external_id': externalId,
  'session_id': sessionId,
  'n8n_message': n8nMessage,
    };
  }
}
