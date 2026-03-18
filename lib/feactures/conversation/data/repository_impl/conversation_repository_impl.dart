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
  Future<void> deleteConversation(String conversationId, {String? token, String? sessionToken}) async {
    // Eliminar remotamente primero
    await remoteDataSource.deleteConversation(
      token: token ?? '',
      conversationId: conversationId,
      sessionToken: sessionToken,
    );
    
    // Si el servidor eliminó exitosamente, eliminar localmente
    await localDataSource.deleteConversation(conversationId);
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
  Future<List<ConversationEntity>> getAllConversations(String token, String userId) async {
    // Consultar al servidor todas las conversaciones del usuario y sincronizar localmente.
    final remoteList = await remoteDataSource.getAllConversations(token: token, userId: userId);

    final remoteIds = remoteList.map((c) => c.id).toSet();
    final localList = await localDataSource.getConversations();

    // Purgar conversaciones locales que ya no existen en servidor.
    for (final local in localList) {
      if (!remoteIds.contains(local.id)) {
        try {
          await localDataSource.deleteConversation(local.id);
        } catch (_) {}
      }
    }

    // Upsert de conversaciones remotas.
    for (final conv in remoteList) {
      try {
        await localDataSource.insertConversation(conv);
      } catch (_) {}
    }

    return localDataSource.getConversations();
  }
  
  @override
  Future<String> getConversation(String conversationId) {
    // TODO: implement getConversation
    throw UnimplementedError();
  }
}
