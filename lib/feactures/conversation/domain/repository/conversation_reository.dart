

import 'package:message_service/feactures/conversation/domain/entities/converstion_entity.dart';

abstract class ConversationRepository {
  Future<void> createConversation(String title, String description);
  Future<List<ConversationEntity>> getConversations();
  Future<void> deleteConversation(String conversationId);
  Future<void> updateConversation(String conversationId, String title, String description);
  Future<String> getConversationDetails(String conversationId);  

} 