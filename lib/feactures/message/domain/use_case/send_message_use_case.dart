



import 'package:message_service/feactures/message/domain/entities/message_entity.dart';
import 'package:message_service/feactures/message/domain/repository/message_repository.dart';

class SendMessageUseCase {
  final MessageRepository messageRepository;
  SendMessageUseCase({required this.messageRepository});

  sendMessage(String conversationId, MessageEntity message) {
    return messageRepository.sendMessage(message, conversationId: conversationId);
  }

}