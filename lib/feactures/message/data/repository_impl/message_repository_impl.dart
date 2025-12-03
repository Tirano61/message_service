import 'package:message_service/feactures/message/data/datasource/local_message_datasource.dart';
import 'package:message_service/feactures/message/data/datasource/message_remote_datasource.dart';
import 'package:message_service/feactures/message/domain/entities/message_entity.dart';
import 'package:message_service/feactures/message/domain/repository/message_repository.dart';
import 'package:message_service/core/session_manager.dart';

class MessageRepositoryImpl implements MessageRepository {
  
  final MessageRemoteDataSource _remoteDataSource;
  final LocalMessageDataSource _localDataSource = LocalMessageDataSource();

  MessageRepositoryImpl({required MessageRemoteDataSource remoteDataSource}) 
    : _remoteDataSource = remoteDataSource;

  @override
  void connectToServer(String token) {
    // HTTP-only: No connection needed
  }

  @override
  void listenForMessages(Function(dynamic) onMessage) {
    // HTTP-only: Use polling instead of real-time listening
  }

  @override
  Future<void> deleteMessage(String messageId) {
    throw UnimplementedError('Delete message not implemented for HTTP-only mode');
  }

  @override
  Future<MessageEntity> getMessage() {
    throw UnimplementedError('Real-time message receiving not supported in HTTP-only mode. Use getListMessages instead.');
  }
  
  @override
  Future<Map<String, MessageEntity>> sendMessage(MessageEntity message, {String? conversationId, String? jwtToken}) async {
    final sessionToken = SessionManager().sessionToken;
    final convId = conversationId ?? SessionManager().conversationId;
    // Allow sending if we have a conversationId and either a session token (anonymous)
    // or a jwtToken (authenticated user).
    if (convId != null && convId.isNotEmpty &&
        ((sessionToken != null && sessionToken.isNotEmpty) || (jwtToken != null && jwtToken.isNotEmpty))) {
      try {
        final result = await _remoteDataSource.sendMessage(
          conversationId: convId,
          sessionToken: sessionToken,
          sender: message.sender,
          content: message.content,
          jwtToken: jwtToken,
        );
        
        // Persistir ambos mensajes localmente después del envío exitoso
        if (result['userMessage'] != null) {
          try {
            final um = result['userMessage']!;
            final normalizedUser = MessageEntity(
              id: um.id,
              content: um.content,
              sender: 'user',
              created_at: um.created_at,
              senderId: message.senderId ?? um.senderId,
              externalId: um.externalId,
              sessionId: um.sessionId,
              n8nMessage: um.n8nMessage,
            );
            await _localDataSource.insertMessage(convId, normalizedUser);
            // Replace the returned userMessage with the normalized one so callers see the corrected sender
            result['userMessage'] = normalizedUser;
          } catch (_) {}
        }
        if (result['botResponse'] != null) {
          try {
            final br = result['botResponse']!;
            final normalizedBot = MessageEntity(
              id: br.id,
              content: br.content,
              sender: 'bot',
              created_at: br.created_at,
              senderId: br.senderId,
              externalId: br.externalId,
              sessionId: br.sessionId,
              n8nMessage: br.n8nMessage,
            );
            await _localDataSource.insertMessage(convId, normalizedBot);
            result['botResponse'] = normalizedBot;
          } catch (_) {}
        }
        
        return result;
      } catch (e) {
        // Sin fallback a socket - solo HTTP
        throw Exception('Failed to send message via HTTP: $e');
      }
    }
    throw Exception('Missing session token or conversation ID');
  }
  
  @override
  Future<List<MessageEntity>> getListMessages({required String conversationId, String? token}) async {
    // HTTP-only: try remote first, then local fallback
    if (token != null && token.isNotEmpty) {
      try {
        final remoteList = await _remoteDataSource.getMessages(token: token, conversationId: conversationId);
        // Persist remote results into local DB to keep it in sync (replace on conflict)
        for (final m in remoteList) {
          try {
            await _localDataSource.insertMessage(conversationId, m);
          } catch (_) {}
        }
        return remoteList;
      } catch (e) {
        // Remote failed; fallback to local DB
        return _localDataSource.getMessages(conversationId);
      }
    }
    // Default: return local DB messages
    return _localDataSource.getMessages(conversationId);
  }
  

}