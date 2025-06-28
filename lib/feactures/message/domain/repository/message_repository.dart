
import 'package:message_service/feactures/message/domain/entities/message_entity.dart';

abstract class MessageRepository {
  Future<void> sendMessage(String message);
  Future<List<MessageEntity>> getMessages();
  Future<void> deleteMessage(String messageId);
}
