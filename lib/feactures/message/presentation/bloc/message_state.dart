part of 'message_bloc.dart';

@immutable
sealed class MessageState {}

final class ServerConnectedState extends MessageState {}

final class MessageInitialState extends MessageState {}

final class MessageLoadingState extends MessageState {}

final class MessageLoadedState extends MessageState {
  final MessageEntity message;

  MessageLoadedState(this.message);
}

final class MessagesListLoadedState extends MessageState {
  final List<MessageEntity> messages;

  MessagesListLoadedState(this.messages);
}

final class MessageErrorState extends MessageState {
  final String error;

  MessageErrorState(this.error);
}
