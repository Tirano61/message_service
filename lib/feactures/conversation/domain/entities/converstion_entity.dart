
import 'package:message_service/feactures/message/domain/entities/message_entity.dart';

class ConversationEntity {
  final String id;
  final String? title;
  final List<MessageEntity> messages;

  ConversationEntity({required this.id, this.title, required this.messages});
}
