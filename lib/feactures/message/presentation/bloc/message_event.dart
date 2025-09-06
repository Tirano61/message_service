part of 'message_bloc.dart';

@immutable
sealed class MessageEvent {}

class ConnectServerEvent extends MessageEvent {
  final String token; // JWT when user logged in, empty for anonymous
  ConnectServerEvent({this.token = ''});
}

class LoadMessageEvent extends MessageEvent {}

class SendMessageEvent extends MessageEvent {
  final String message;
  final String? senderId; // optional sender id provided by UI (auth user id or 'local')

  SendMessageEvent(this.message, {this.senderId});
}