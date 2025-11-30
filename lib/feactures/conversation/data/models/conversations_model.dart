
import 'package:message_service/feactures/conversation/domain/entities/converstion_entity.dart';
import 'package:message_service/feactures/message/domain/entities/message_entity.dart';

class ConversationsModel {

  final String id;
  final String title;
  final String? type;
  final List<MessageEntity> messages;
  final String userId;
  final String? sessionToken;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  ConversationsModel({
    required this.id,
    required this.title,
    this.type,
  required this.messages,
  required this.userId,
  this.sessionToken,
  this.createdAt,
  this.updatedAt,
  });

  factory ConversationsModel.fromJson(dynamic json) {
    // Manejar userId desde diferentes estructuras de respuesta
    String extractedUserId = '';
    if (json['user_id'] != null && json['user_id'] is String) {
      // Sales/Tecnico: user_id directo
      extractedUserId = json['user_id'] as String;
    } else if (json['user'] != null && json['user'] is Map) {
      // Sales/Tecnico: objeto user anidado
      extractedUserId = (json['user'] as Map)['id']?.toString() ?? '';
    } else if (json['userId'] != null) {
      // Fallback: userId directo
      extractedUserId = json['userId']?.toString() ?? '';
    }
    // Para conversaciones general (anónimas): userId queda como cadena vacía

    // Normalize title: support nested structures and guard against malformed placeholder 'title'
    dynamic rawTitle = json['title'] ?? json['titulo'] ?? '';
    String normalizedTitle = '';
    if (rawTitle is String) {
      normalizedTitle = rawTitle.trim();
    } else if (rawTitle is Map) {
      // If server returns { title: { ... } } try to extract inner string
      normalizedTitle = (rawTitle['title'] ?? rawTitle['nombre'] ?? '').toString().trim();
    } else {
      normalizedTitle = rawTitle?.toString().trim() ?? '';
    }
    // Defensive: if the server mistakenly returned the literal key name 'title', treat as empty
    if (normalizedTitle.toLowerCase() == 'title') normalizedTitle = '';

    return ConversationsModel(
      id: json['id'] ?? json['_id'] ?? '',
      title: normalizedTitle,
      type: json['type'] ?? json['conversation_type'] ?? null,
      messages: (json['messages'] as List?)?.map((e) {
        if (e is Map<String, dynamic>) {
          return MessageEntity.fromJson(Map<String, dynamic>.from(e));
        } else if (e is String) {
          // If only id provided, create placeholder
          return MessageEntity(id: e, content: '', sender: '', created_at: DateTime.now().toUtc());
        } else {
          return MessageEntity(id: '', content: '', sender: '', created_at: DateTime.now().toUtc());
        }
      }).toList() ?? <MessageEntity>[],
      userId: extractedUserId,
      sessionToken: json['session_id'] ?? json['session_token'] ?? json['sessionToken'] ?? null,
  createdAt: _parseDate(json['created_at'] ?? json['createdAt']),
  updatedAt: _parseDate(json['updated_at'] ?? json['updatedAt']),
    );
  }

  static DateTime? _parseDate(dynamic raw) {
    if (raw == null) return null;
    if (raw is String) return DateTime.tryParse(raw)?.toUtc();
    if (raw is int) return raw > 1000000000000 ? DateTime.fromMillisecondsSinceEpoch(raw, isUtc: true) : DateTime.fromMillisecondsSinceEpoch(raw * 1000, isUtc: true);
    return null;
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      if (type != null) 'type': type,
  'messages': messages.map((m) => m.toJson()).toList(),
  'userId': userId,
  'session_id': sessionToken,
  if (createdAt != null) 'created_at': createdAt!.toIso8601String(),
  if (updatedAt != null) 'updated_at': updatedAt!.toIso8601String(),
    };
  }

  factory ConversationsModel.fromEntity(ConversationEntity entity) {
    return ConversationsModel(
      id: entity.id,
      title: entity.title ?? '',
  messages: entity.messages ?? [],
  userId: entity.userId ?? '',
  type: entity.type,
  createdAt: entity.createdAt,
  updatedAt: entity.updatedAt,
    );
  }
  ConversationEntity toEntity() {
    return ConversationEntity(
  id: id,
  title: title.isNotEmpty ? title : null,
  messages: messages,
  userId: userId, // Aquí deberías asignar el userId correspondiente
  sessionToken: sessionToken,
  type: type,
  createdAt: createdAt,
  updatedAt: updatedAt,
    );
  }


  

}