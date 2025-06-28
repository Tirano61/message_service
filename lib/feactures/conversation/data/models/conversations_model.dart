
import 'package:message_service/feactures/conversation/domain/entities/converstion_entity.dart';
import 'package:message_service/feactures/message/domain/entities/message_entity.dart';

class ConversationsModel {

  final String id;
  final String title;
  final List<String> messages;  

  ConversationsModel({
    required this.id,
    required this.title,
    required this.messages,
  });

  factory ConversationsModel.fromEntity(ConversationEntity entity) {
    return ConversationsModel(
      id: entity.id,
      title: entity.title ?? '',
      messages: entity.messages.map((message) => message.id).toList(),
    );
  }
  ConversationEntity toEntity() {
    return ConversationEntity(
      id: id,
      title: title.isNotEmpty ? title : null,
      messages: messages.map((messageId) => MessageEntity(id: messageId, content: '', senderId: '', timestamp: DateTime.now())).toList(),
    );
  }


  

}