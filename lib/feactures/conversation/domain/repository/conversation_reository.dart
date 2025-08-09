

import 'package:message_service/feactures/conversation/domain/entities/converstion_entity.dart';

abstract class ConversationRepository {
  Future<ConversationEntity> createConversation(String userId, String title, String token);
  Future<List<ConversationEntity>> getConversations();
  Future<void> deleteConversation(String conversationId);
  Future<void> updateConversation(String conversationId, String title, String description);
  Future<String> getConversationDetails(String conversationId);  

} 