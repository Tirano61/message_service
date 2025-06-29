


import 'package:message_service/feactures/message/domain/entities/message_entity.dart';
import 'package:message_service/feactures/message/domain/repository/message_repository.dart';

class GetMessageUseCase {
  final MessageRepository messageRepository;

  GetMessageUseCase({required this.messageRepository});

  Future<MessageEntity> getMessage() {
    return messageRepository.getMessage();
  }
}