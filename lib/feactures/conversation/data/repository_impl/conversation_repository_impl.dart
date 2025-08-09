import 'package:message_service/feactures/conversation/data/datasource/conversation_remote_datasource.dart';
import 'package:message_service/feactures/conversation/domain/entities/converstion_entity.dart';
import 'package:message_service/feactures/conversation/domain/repository/conversation_reository.dart';


class ConversationRepositoryImpl implements ConversationRepository {
  final ConversationRemoteDataSource remoteDataSource;


  ConversationRepositoryImpl({
    required this.remoteDataSource,
  });

  @override
  Future<ConversationEntity> createConversation(String userId, String title, String token) async {
    return remoteDataSource.createConversation(
      token: token,
      userId: userId,
      title: title,
    );
  }

  @override
  Future<void> deleteConversation(String conversationId) {
    // TODO: implementar usando remoteDataSource cuando el endpoint esté disponible
    throw UnimplementedError();
  }

  @override
  Future<String> getConversationDetails(String conversationId) {
    // TODO: implementar usando remoteDataSource cuando el endpoint esté disponible
    throw UnimplementedError();
  }

  @override
  Future<List<ConversationEntity>> getConversations() {
    // TODO: implementar usando remoteDataSource cuando el endpoint esté disponible
    throw UnimplementedError();
  }

  @override
  Future<void> updateConversation(String conversationId, String title, String description) {
    // TODO: implementar usando remoteDataSource cuando el endpoint esté disponible
    throw UnimplementedError();
  }
}
