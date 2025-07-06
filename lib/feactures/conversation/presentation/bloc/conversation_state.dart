part of 'conversation_bloc.dart';

@immutable
sealed class ConversationState {}

final class ConversationInitial extends ConversationState {}


final class ConversationLoadingState extends ConversationState {}

final class ConversationLoadedState extends ConversationState {
  final List<ConversationEntity> conversations;

  ConversationLoadedState({required this.conversations});
}
final class ConversationErrorState extends ConversationState {
  final String message;

  ConversationErrorState({required this.message});
}