



import 'dart:async';

import 'package:message_service/core/services/socket_service.dart';
import 'package:message_service/feactures/message/domain/entities/message_entity.dart';

abstract class MessageDataSource {

  Future<MessageEntity> getMessage();
  Future<void> sendMessage(MessageEntity message);
  Future<void> deleteMessage(String messageId);
  void connectToServer();
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
    _socketService.on('message_received', (data) {
      data = data as Map<String, dynamic>;
      MessageEntity message = MessageEntity.fromJson(data);
      completer.complete(message);
    });
    return completer.future;
  }

  @override
  Future<void> sendMessage(MessageEntity message)async {
    return _socketService.emit('send_message', message);
  }

  @override
  Future<void> deleteMessage(String messageId)async {
    return _socketService.emit('delete_message', messageId);
    
  }
  
  @override
  void connectToServer() {
    _socketService.connect();
  }
  
  @override
  void listenForMessages(Function(dynamic p1) onMessage) {
    _socketService.on('message_received', onMessage);
  }
}
