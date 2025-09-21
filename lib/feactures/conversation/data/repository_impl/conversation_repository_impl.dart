import 'package:message_service/feactures/conversation/data/datasource/conversation_remote_datasource.dart';
import 'package:message_service/feactures/conversation/data/datasource/local_conversation_datasource.dart';
import 'package:message_service/feactures/conversation/domain/entities/converstion_entity.dart';
import 'package:message_service/feactures/conversation/domain/repository/conversation_reository.dart';


class ConversationRepositoryImpl implements ConversationRepository {
  final ConversationRemoteDataSource remoteDataSource;
  final LocalConversationDataSource localDataSource = LocalConversationDataSourceImpl();


  ConversationRepositoryImpl({
    required this.remoteDataSource,
  });

  @override
  Future<ConversationEntity> createConversation( String userId, String title, String token, String type ) async {
    final conv = await remoteDataSource.createConversation(
      token: token,
      userId: userId,
      title: title,
      type: type,
    );
    // Persistir localmente para que aparezca en la lista tras reinicios
    try {
      await localDataSource.insertConversation(conv);
    } catch (_) {}
    return conv;
  }

  @override
  Future<void> deleteConversation(String conversationId) {
    // TODO: implementar usando remoteDataSource cuando el endpoint esté disponible
    throw UnimplementedError();
  }

  // getConversation implementado más abajo por la interfaz

  @override
  Future<List<ConversationEntity>> getConversations({String? type}) {
    // Leer desde almacenamiento local (opcionalmente filtrando por type)
    return localDataSource.getConversations(type: type);
  }

  @override
  Future<void> updateConversation(String conversationId, String title, String description) {
    // TODO: implementar usando remoteDataSource cuando el endpoint esté disponible
    throw UnimplementedError();
  }
  
  @override
  Future<ConversationEntity> getAllConversations(String token, String userId) {
    // Consultar al servidor todas las conversaciones del usuario y sincronizar localmente
    return remoteDataSource.getAllConversations(token: token, userId: userId).then((list) async {
      // Guardar/actualizar localmente
      for (var conv in list) {
        try {
          await localDataSource.insertConversation(conv);
        } catch (_) {}
      }
      // Devolver la primera como placeholder (método firma discordante con uso actual)
      if (list.isNotEmpty) return list.first;
      throw Exception('No conversations found');
    });
  }
  
  @override
  Future<String> getConversation(String conversationId) {
    // TODO: implement getConversation
    throw UnimplementedError();
  }
}
