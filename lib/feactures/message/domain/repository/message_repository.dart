import 'package:message_service/feactures/message/domain/entities/message_entity.dart';

abstract class MessageRepository {
  Future<Map<String, MessageEntity>> sendMessage(MessageEntity message);
  Future<MessageEntity> getMessage();
  Future<List<MessageEntity>> getListMessages({required String conversationId, String? token});
  Future<void> deleteMessage(String messageId);
  connectToServer(String token);
  listenForMessages(Function(dynamic) onMessage);
}
