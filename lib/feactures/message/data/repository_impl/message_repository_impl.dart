import 'package:message_service/core/services/socket_service.dart';
import 'package:message_service/feactures/message/data/datasource/message_datasource.dart';
import 'package:message_service/feactures/message/domain/entities/message_entity.dart';
import 'package:message_service/feactures/message/domain/repository/message_repository.dart';

class MessageRepositoryImpl implements MessageRepository {
  
  final MessageDataSourceImpl _messageDataSourceImpl;

  MessageRepositoryImpl(this._messageDataSourceImpl);

  void connectToServer(String token) {
    _messageDataSourceImpl.connectToServer(token);
  }

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
  

}