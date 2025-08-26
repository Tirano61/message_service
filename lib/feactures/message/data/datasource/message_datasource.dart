



import 'dart:async';

import 'package:message_service/core/services/socket_service.dart';
import 'package:message_service/core/session_manager.dart';
import 'package:message_service/feactures/message/domain/entities/message_entity.dart';

abstract class MessageDataSource {

  Future<MessageEntity> getMessage();
  Future<void> sendMessage(MessageEntity message);
  Future<void> deleteMessage(String messageId);
  void connectToServer(String token);
  void listenForMessages(Function(dynamic) onMessage);

}


class MessageDataSourceImpl implements MessageDataSource {
  final SocketService _socketService;

  MessageDataSourceImpl({
    required SocketService socketService,
  }) : _socketService = socketService ;

  @override
  Future<MessageEntity> getMessage() async {
    final completer = Completer<MessageEntity>();
    // El servidor emite 'message_received' para nuevos mensajes — usar once para no completar varias veces
    _socketService.once('message_received', (data) {
      try {
        data = data as Map<String, dynamic>;
        MessageEntity message = MessageEntity.fromJson(data);
        if (!completer.isCompleted) completer.complete(message);
      } catch (e) {
        if (!completer.isCompleted) completer.completeError(e);
      }
    });
    return completer.future;
  }

  @override
  Future<void> sendMessage(MessageEntity message)async {
    final sessionToken = SessionManager().sessionToken;
    final conversationId = SessionManager().conversationId;
    if (sessionToken != null && sessionToken.isNotEmpty && conversationId != null && conversationId.isNotEmpty) {
      final payload = {
        'conversationId': conversationId,
        'session_token': sessionToken,
        'sender': message.sender,
        'content': message.content
      };
      return _socketService.emit('client-send-user', payload);
    }
  }

  @override
  Future<void> deleteMessage(String messageId)async {
    return _socketService.emit('delete_message', messageId);
    
  }
  
  @override
  void connectToServer(String token) {
  // Only use the provided JWT token; do not substitute session_token here.
  _socketService.connect(token: token);
  }
  
  @override
  void listenForMessages(Function(dynamic p1) onMessage) {
    _socketService.on('message_received', onMessage);
  }
}
