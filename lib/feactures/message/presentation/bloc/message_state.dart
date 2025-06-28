part of 'message_bloc.dart';

@immutable
sealed class MessageState {}

final class MessageInitial extends MessageState {}

final class MessageLoading extends MessageState {}

final class MessageLoaded extends MessageState {
  final List<Map<String, dynamic>> messages;

  MessageLoaded(this.messages);
}

final class MessageError extends MessageState {
  final String error;

  MessageError(this.error);
}
