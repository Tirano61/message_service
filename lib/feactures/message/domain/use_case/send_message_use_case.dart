



import 'package:message_service/feactures/message/domain/repository/message_repository.dart';

class SendMessageUseCase {
  final MessageRepository messageRepository;
  SendMessageUseCase({required this.messageRepository});

  Future<void> sendMessage(String message) {
    return messageRepository.sendMessage(message);
  }

}