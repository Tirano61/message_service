import 'package:bloc/bloc.dart';
import 'package:message_service/feactures/conversation/data/datasource/conversation_remote_datasource.dart';
import 'package:message_service/feactures/conversation/domain/entities/converstion_entity.dart';
import 'package:meta/meta.dart';
import 'package:message_service/core/session_manager.dart';
import 'package:message_service/feactures/message/data/datasource/local_message_datasource.dart';
import 'package:message_service/core/services/socket_service.dart';

part 'conversation_event.dart';
part 'conversation_state.dart';

class ConversationBloc extends Bloc<ConversationEvent, ConversationState> {
  final ConversationRemoteDataSource conversationDataSource;

  ConversationBloc({required this.conversationDataSource}) : super(ConversationInitial()) {
    on<CreateConversationEvent>(_onCreateConversation);
    on<LoadConversationsEvent>(_onLoadConversations);
    on<DeleteConversationEvent>(_onDeleteConversation);
  }

  Future<void> _onDeleteConversation(event, emit) async {
    final e = event as DeleteConversationEvent;
    final id = e.conversationId;
    final previous = state;
    if (previous is ConversationLoadedState) {
      // Remove locally first (user requested local deletion even if server fails)
      final updated = List<ConversationEntity>.from(previous.conversations)
        ..removeWhere((c) => c.id == id);
      emit(ConversationLoadedState(conversations: updated));
      // Eliminar mensajes y fingerprints locales asociados a la conversación
      try {
        SessionManager().messagesByConversation.remove(id);
        SessionManager().messageFingerprintCounts.remove(id);
        final local = LocalMessageDataSource();
        await local.deleteConversationMessages(id);
      } catch (_) {}
      // Intentar borrar en servidor; si falla, reportar el error pero no hacer rollback local
      try {
        await conversationDataSource.deleteConversation(token: e.token, conversationId: id, sessionToken: e.sessionToken);
      } catch (err) {
        emit(ConversationErrorState(message: 'Error al eliminar en servidor: ${err.toString()}'));
      }
    }
  }

  Future<void> _onCreateConversation(event, emit) async {
    final previous = state;
    emit(ConversationLoadingState());
    try {
      final newConv = await conversationDataSource.createConversation(
        token: event.token,
        userId: event.userId,
        title: event.title,
      );

      // If backend returned a session token (conversación anónima), store and connect
      // Only store session_token when the creation was anonymous (no userId provided)
      if ((event.userId == null || event.userId.isEmpty) && newConv.sessionToken != null && newConv.sessionToken!.isNotEmpty) {
        SessionManager().sessionToken = newConv.sessionToken;
        SessionManager().conversationId = newConv.id;
        try {
          // Pass empty token so SocketService chooses the anonymous session stored in SessionManager
          SocketService().connect(token: '');
        } catch (_) {}
      }

      if (previous is ConversationLoadedState) {
        final updated = List<ConversationEntity>.from(previous.conversations)..insert(0, newConv);
  emit(ConversationLoadedState(conversations: updated));
  emit(ConversationCreatedState(conversation: newConv));
      } else {
  emit(ConversationLoadedState(conversations: [newConv]));
  emit(ConversationCreatedState(conversation: newConv));
      }
    } catch (e) {
      emit(ConversationErrorState(message: e.toString()));
    }
  }

  Future<void> _onLoadConversations( event, emit ) async {
    emit(ConversationLoadingState());
    try {
      List<ConversationEntity> list;
      if (event.type != null && event.type!.isNotEmpty) {
        list = await conversationDataSource.getConversations(token: event.token, type: event.type);
      } else if ((event as dynamic).userId != null) {
        // fallback to getAllConversations if userId provided
        list = await conversationDataSource.getAllConversations(token: event.token, userId: (event as dynamic).userId);
      } else {
        list = await conversationDataSource.getConversations(token: event.token);
      }
      emit(ConversationLoadedState(conversations: list));
    } catch (e) {
      emit(ConversationErrorState(message: e.toString()));
    }
  }
}
