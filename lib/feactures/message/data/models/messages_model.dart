

class MessagesModel {

  final String id;
  final String content;
  final String? sender; // display name or role (e.g. 'bot' or 'user')
  final String? senderId; // canonical identifier (user id or session token)
  final DateTime createdAt;
  final String? externalId;
  final String? sessionId;
  final String? n8nMessage;
  

  MessagesModel({
    required this.id,
    required this.content,
    required this.createdAt,
    this.sender,
    this.senderId,
    this.externalId,
    this.sessionId,
  this.n8nMessage,
  });

  factory MessagesModel.fromJson(Map<String, dynamic> json) {
    // support payload wrapping: { payload: { ... } } or direct message map
    final data = (json['payload'] is Map<String, dynamic>) ? json['payload'] as Map<String, dynamic> : json;

    // pick created_at / timestamp / createdAt
    final raw = data['created_at'] ?? data['timestamp'] ?? data['createdAt'] ?? data['time'];
    DateTime created;
    if (raw == null) {
      created = DateTime.now().toUtc();
    } else if (raw is DateTime) {
      created = raw.toUtc();
    } else if (raw is double) {
      final numVal = raw.toInt();
      created = numVal > 1000000000000 ? DateTime.fromMillisecondsSinceEpoch(numVal, isUtc: true) : DateTime.fromMillisecondsSinceEpoch(numVal * 1000, isUtc: true);
    } else if (raw is int) {
      created = raw > 1000000000000 ? DateTime.fromMillisecondsSinceEpoch(raw, isUtc: true) : DateTime.fromMillisecondsSinceEpoch(raw * 1000, isUtc: true);
    } else if (raw is String) {
      try {
        created = DateTime.parse(raw).toUtc();
      } catch (_) {
        created = DateTime.now().toUtc();
      }
    } else {
      created = DateTime.now().toUtc();
    }

    

    // Try multiple aliases for sender/role and sender id
    final senderVal = (data['sender'] ?? data['role'] ?? data['type'])?.toString();
    final senderIdVal = (data['sender_id'] ?? data['senderId'] ?? data['user_id'] ?? data['userId'] ?? data['from_id'])?.toString();

    return MessagesModel(
      id: (data['id'] ?? '').toString(),
      content: (data['content'] ?? data['message'] ?? '').toString(),
      createdAt: created,
      sender: senderVal,
      senderId: senderIdVal,
      externalId: (data['external_id'] ?? data['externalId'])?.toString(),
      sessionId: (data['session_id'] ?? data['sessionId'])?.toString(),
      n8nMessage: (data['n8n_message'] ?? data['n8nMessage'])?.toString(),
      
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'content': content,
      'sender': sender,
      'sender_id': senderId,
      'created_at': createdAt.toIso8601String(),
      'external_id': externalId,
      'session_id': sessionId,
      'n8n_message': n8nMessage,
    }..removeWhere((key, value) => value == null);
  }

}