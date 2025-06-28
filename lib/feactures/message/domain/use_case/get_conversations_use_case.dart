
import 'package:message_service/feactures/message/domain/entities/converstion_entity.dart';
import 'package:message_service/feactures/message/domain/repository/message_repository.dart';

class GetConversationsUseCase {
  final MessageRepository _messageRepository;

  GetConversationsUseCase(this._messageRepository);

  Future<List<ConversationEntity>> getConversations() async {
    return await _messageRepository.getConversations();
  }

}
