

class MessagesModel {

  final String id;
  final String senderId;
  final String content;
  final DateTime timestamp;

  MessagesModel({
    required this.id,
    required this.senderId,
    required this.content,
    required this.timestamp,
  });

  factory MessagesModel.fromJson(Map<String, dynamic> json) {
    return MessagesModel(
      id        : json['id'] as String,
      senderId  : json['senderId'] as String,
      content   : json['content'] as String,
      timestamp : DateTime.parse(json['timestamp'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id'       : id,
      'senderId' : senderId,
      'content'  : content,
      'timestamp': timestamp.toIso8601String(),
    };
  }

}