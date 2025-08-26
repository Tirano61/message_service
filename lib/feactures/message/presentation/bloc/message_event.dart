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

  SendMessageEvent(this.message); 
}