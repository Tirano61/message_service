
import 'package:message_service/feactures/message/domain/entities/message_entity.dart';

abstract class MessageRepository {
  sendMessage(MessageEntity message);
  Future<MessageEntity> getMessage();
  Future<void> deleteMessage(String messageId);
  connectToServer(String token);
  listenForMessages(Function(dynamic) onMessage);
}
