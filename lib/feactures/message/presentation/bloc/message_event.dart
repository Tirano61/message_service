part of 'message_bloc.dart';

@immutable
sealed class MessageEvent {}

class ConnectServerEvent extends MessageEvent {
  final String token; // JWT when user logged in, empty for anonymous
  ConnectServerEvent({this.token = ''});
}

class LoadMessageEvent extends MessageEvent {
  final String? conversationId;
  final String? token;
  final String? currentUserId;
  LoadMessageEvent({this.conversationId, this.token, this.currentUserId});
}

class LoadMessagesListEvent extends MessageEvent {
  final String conversationId;
  final String? token;
  final String? currentUserId;
  LoadMessagesListEvent({required this.conversationId, this.token, this.currentUserId});
}

class SendMessageEvent extends MessageEvent {
  final String message;
  final String? senderId; // optional sender id provided by UI (auth user id or 'local')
  final String? jwtToken;

  SendMessageEvent(this.message, {this.senderId, this.jwtToken});
}