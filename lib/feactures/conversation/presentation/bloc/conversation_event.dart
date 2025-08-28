part of 'conversation_bloc.dart';



@immutable
sealed class ConversationEvent {}

class CreateConversationEvent extends ConversationEvent {
	final String token;
	final String userId;
	final String title;

	CreateConversationEvent({
		required this.token,
		required this.userId,
		required this.title,
	});
}

	class LoadConversationsEvent extends ConversationEvent {
		final String token;
		final String? type; // 'user' | 'tecnico'

		LoadConversationsEvent({required this.token, this.type});
	}

	class DeleteConversationEvent extends ConversationEvent {
		final String conversationId;
		final String token;

		DeleteConversationEvent({required this.conversationId, this.token = ''});
	}
