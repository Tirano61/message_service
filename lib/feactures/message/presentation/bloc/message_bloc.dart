import 'package:bloc/bloc.dart';
import 'package:message_service/feactures/message/data/datasource/message_datasource.dart';
import 'package:meta/meta.dart';

part 'message_event.dart';
part 'message_state.dart';

class MessageBloc extends Bloc<MessageEvent, MessageState> {

  final MessageDataSource messageDataSource;

  MessageBloc({required this.messageDataSource}) : super(MessageInitialState()) {
    on<ConnectServerEvent>((event, emit) {
           
      try {
        final connect =  messageDataSource.connectToServer();
        emit(ServerConnectedState());
       // Assuming empty list for initial state
      } catch (e) {
        emit(MessageErrorState(e.toString()));
      }
    });
    on<LoadMessageEvent>((event, emit)async {
      emit(MessageLoadingState());
      final messages = await messageDataSource.getMessage();
      
      try {
      
        
        
      } catch (e) {
        emit(MessageErrorState(e.toString()));
      }
    });
  }

}
