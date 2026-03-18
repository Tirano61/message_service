import 'package:bloc/bloc.dart';
import 'package:message_service/feactures/conversation/domain/repository/conversation_reository.dart';
import 'package:message_service/feactures/conversation/domain/entities/converstion_entity.dart';
import 'package:meta/meta.dart';
import 'package:message_service/core/session_manager.dart';
import 'package:message_service/feactures/message/data/datasource/local_message_datasource.dart';

part 'conversation_event.dart';
part 'conversation_state.dart';

class ConversationBloc extends Bloc<ConversationEvent, ConversationState> {
  final ConversationRepository conversationRepository;

  ConversationBloc({required this.conversationRepository}) : super(ConversationInitial()) {
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
        // repository.deleteConversation should remove remotely and we also remove local state above
        await conversationRepository.deleteConversation(
          id,
          token: e.token,
          sessionToken: e.sessionToken,
        );
      } catch (err) {
        emit(ConversationErrorState(message: 'Error al eliminar en servidor: ${err.toString()}'));
      }
    }
  }

  Future<void> _onCreateConversation(event, emit) async {
    final previous = state;
    emit(ConversationLoadingState());
    try {
  final newConv = await conversationRepository.createConversation(event.userId ?? '', event.title, event.token, event.type);
      try {
        // ignore: avoid_print
        print('[DEBUG] Created conversation title from repo: "${newConv.title}"');
      } catch (_) {}

      // Store conversation ID for navigation (always needed)
      SessionManager().conversationId = newConv.id;
      
      // Store session token only for anonymous conversations (backend type 'anonimo').
      final isAnonymousType = event.type == 'anonimo';
      if (isAnonymousType && newConv.sessionToken != null && newConv.sessionToken!.isNotEmpty) {
        SessionManager().sessionToken = newConv.sessionToken;
      }
      // HTTP-only: No socket connection needed

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
      final e = event as LoadConversationsEvent;

      // Si hay token, intentamos sincronizar con servidor para evitar stale local.
      if (e.token.isNotEmpty) {
        try {
          await conversationRepository.getAllConversations(e.token, '');
        } catch (_) {
          // Si falla sync remoto, seguimos con local para no bloquear UI.
        }
      }

      final list = await conversationRepository.getConversations(type: e.type);
      emit(ConversationLoadedState(conversations: list));
    } catch (e) {
      emit(ConversationErrorState(message: e.toString()));
    }
  }
}
