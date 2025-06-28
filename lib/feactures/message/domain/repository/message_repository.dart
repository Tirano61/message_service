

import 'package:message_service/feactures/message/domain/entities/converstion_entity.dart';
import 'package:message_service/feactures/message/domain/entities/message_entity.dart';

abstract class MessageRepository {
  Future<void> sendMessage(String message);
  Future<List<MessageEntity>> getMessages();
  Future<List<ConversationEntity>> getConversations();
  Future<void> deleteMessage(String messageId);
  Future<void> deleteConversation(String conversationId);
}
