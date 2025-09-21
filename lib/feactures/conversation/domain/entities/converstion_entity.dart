
import 'package:message_service/feactures/message/domain/entities/message_entity.dart';

class ConversationEntity {
  final String id;
  final String? title;
  final List<MessageEntity>? messages;
  final String? userId;
  final String? sessionToken;
  final String? type;
  final DateTime? createdAt; // token para sesiones anónimas
  final DateTime? updatedAt; // token para sesiones anónimas

  ConversationEntity({
    required this.id,
    this.title,
    required this.messages,
    required this.userId,
    this.sessionToken,
    this.type,
    this.createdAt,
    this.updatedAt,
  });
}
