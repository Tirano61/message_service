part of 'conversation_bloc.dart';



@immutable
sealed class ConversationEvent {}

class CreateConversationEvent extends ConversationEvent {
	final String token;
	final String userId;
	final String title;
	final String? type; // optional: 'sales' | 'tecnico' | 'anonimo'

	CreateConversationEvent({
		required this.token,
		required this.userId,
		required this.title,
		required this.type,
	});
}

	class LoadConversationsEvent extends ConversationEvent {
		final String token;
		final String? type; // 'sales' | 'tecnico' | 'anonimo'

		LoadConversationsEvent({required this.token, this.type});
	}

	class DeleteConversationEvent extends ConversationEvent {
		final String conversationId;
		final String token;
		final String? sessionToken;

		DeleteConversationEvent({required this.conversationId, this.token = '', this.sessionToken});
	}
