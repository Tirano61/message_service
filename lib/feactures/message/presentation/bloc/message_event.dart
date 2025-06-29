part of 'message_bloc.dart';

@immutable
sealed class MessageEvent {}

class ConnectServerEvent extends MessageEvent {}

class LoadMessageEvent extends MessageEvent {}

class SendMessageEvent extends MessageEvent {
  final String message;

  SendMessageEvent(this.message); 
}