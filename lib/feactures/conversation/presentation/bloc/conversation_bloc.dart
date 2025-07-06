import 'package:bloc/bloc.dart';
import 'package:message_service/feactures/conversation/domain/entities/converstion_entity.dart';
import 'package:meta/meta.dart';

part 'conversation_event.dart';
part 'conversation_state.dart';

class ConversationBloc extends Bloc<ConversationEvent, ConversationState> {
  ConversationBloc() : super(ConversationInitial()) {
    on<ConversationEvent>((event, emit) {
      // TODO: implement event handler
    });
  }
}
