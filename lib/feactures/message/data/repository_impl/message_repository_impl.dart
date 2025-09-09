import 'package:message_service/feactures/message/data/datasource/message_datasource.dart';
import 'package:message_service/feactures/message/data/datasource/local_message_datasource.dart';
import 'package:message_service/feactures/message/data/datasource/message_remote_datasource.dart';
import 'package:message_service/feactures/message/domain/entities/message_entity.dart';
import 'package:message_service/feactures/message/domain/repository/message_repository.dart';

class MessageRepositoryImpl implements MessageRepository {
  
  final MessageDataSourceImpl _messageDataSourceImpl;
  // Optional remote datasource; if not provided callers should pass token when requesting remote
  final MessageRemoteDataSource? _remoteDataSource;
  final LocalMessageDataSource _localDataSource = LocalMessageDataSource();

  MessageRepositoryImpl(this._messageDataSourceImpl, {MessageRemoteDataSource? remoteDataSource}) : _remoteDataSource = remoteDataSource;

  @override
  void connectToServer(String token) {
    _messageDataSourceImpl.connectToServer(token);
  }

  @override
  void listenForMessages(Function(dynamic) onMessage) {
    return _messageDataSourceImpl.listenForMessages(onMessage);
  }

  @override
  Future<void> deleteMessage(String messageId) {
    return _messageDataSourceImpl.deleteMessage(messageId);
  }

  @override
  Future<MessageEntity> getMessage() {
    return _messageDataSourceImpl.getMessage();
  }
  
  @override
  sendMessage(MessageEntity message) {
    return _messageDataSourceImpl.sendMessage(message);
  }
  
  @override
  Future<List<MessageEntity>> getListMessages({required String conversationId, String? token}) async {
    // If a token is provided and we have a remote datasource, prefer remote fetch and persist into local DB.
    if (token != null && token.isNotEmpty && _remoteDataSource != null) {
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