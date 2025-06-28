
import 'package:message_service/feactures/conversation/domain/entities/converstion_entity.dart';
import 'package:message_service/feactures/conversation/domain/repository/conversation_reository.dart';

class GetConversationsUseCase {
  final ConversationRepository _conversationRepository;

  GetConversationsUseCase(this._conversationRepository);

  Future<List<ConversationEntity>> getConversations() async {
    return await _conversationRepository.getConversations();
  }

}
