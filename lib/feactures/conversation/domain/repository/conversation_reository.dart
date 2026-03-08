

import 'package:message_service/feactures/conversation/domain/entities/converstion_entity.dart';

abstract class ConversationRepository {
  /// Crea una conversación. `type` debe ser 'sales', 'tecnico' o 'anonimo'.
  Future<ConversationEntity> createConversation(String userId, String title, String token, String type );
  Future<List<ConversationEntity>> getConversations({String? type});
  Future<void> deleteConversation(String conversationId, {String? token, String? sessionToken});
  Future<void> updateConversation(String conversationId, String title, String description);
  Future<String> getConversation(String conversationId);  
  Future<ConversationEntity> getAllConversations(String token, String userId);  

} 