
import 'package:message_service/feactures/conversation/domain/entities/converstion_entity.dart';
import 'package:message_service/feactures/message/domain/entities/message_entity.dart';

class ConversationsModel {

  final String id;
  final String title;
  final List<String> messages;
  final String userId;
  final String? sessionToken;

  ConversationsModel({
    required this.id,
    required this.title,
    required this.messages,
    required this.userId,
    this.sessionToken,
  });

  factory ConversationsModel.fromJson(dynamic json) {
    return ConversationsModel(
      id: json['id'] ?? json['_id'] ?? '',
      title: json['title'] ?? '',
      messages: (json['messages'] as List?)?.map((e) => e.toString()).toList() ?? <String>[],
  userId: json['userId'] ?? json['user_id'] ?? '',
  sessionToken: json['session_token'] ?? json['sessionToken'] ?? null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'messages': messages,
  'userId': userId,
  'session_token': sessionToken,
    };
  }

  factory ConversationsModel.fromEntity(ConversationEntity entity) {
    return ConversationsModel(
      id: entity.id,
      title: entity.title ?? '',
      messages: (entity.messages ?? []).map((message) => message.id).toList(),
      userId: entity.userId ?? '',
    );
  }
  ConversationEntity toEntity() {
    return ConversationEntity(
  id: id,
  title: title.isNotEmpty ? title : null,
  messages: messages.map((messageId) => MessageEntity(id: messageId, content: '',  created_at: DateTime.now(), sender: '')).toList(),
  userId: userId, // Aquí deberías asignar el userId correspondiente
  sessionToken: sessionToken,
    );
  }


  

}