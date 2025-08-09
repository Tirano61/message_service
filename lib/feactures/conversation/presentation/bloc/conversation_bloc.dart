import 'package:bloc/bloc.dart';
import 'package:message_service/feactures/conversation/data/datasource/conversation_remote_datasource.dart';
import 'package:message_service/feactures/conversation/domain/entities/converstion_entity.dart';
import 'package:meta/meta.dart';

part 'conversation_event.dart';
part 'conversation_state.dart';

class ConversationBloc extends Bloc<ConversationEvent, ConversationState> {
  final ConversationRemoteDataSource conversationDataSource;

  ConversationBloc({required this.conversationDataSource}) : super(ConversationInitial()) {
    on<CreateConversationEvent>(_onCreateConversation);
    on<LoadConversationsEvent>(_onLoadConversations);
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

      if (previous is ConversationLoadedState) {
        final updated = List<ConversationEntity>.from(previous.conversations)..insert(0, newConv);
        emit(ConversationLoadedState(conversations: updated));
      } else {
        emit(ConversationLoadedState(conversations: [newConv]));
      }
    } catch (e) {
      emit(ConversationErrorState(message: e.toString()));
    }
  }

  Future<void> _onLoadConversations( event, emit ) async {
    emit(ConversationLoadingState());
    try {
      final list = await conversationDataSource.getAllConversations(
        token: event.token,
        userId: event.userId,
      );
      emit(ConversationLoadedState(conversations: list));
    } catch (e) {
      emit(ConversationErrorState(message: e.toString()));
    }
  }
}
