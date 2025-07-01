import 'package:bloc/bloc.dart';
import 'package:flutter/material.dart';
import 'package:message_service/feactures/auth/domain/entities/user.dart';
import 'package:message_service/feactures/message/data/datasource/message_datasource.dart';
import 'package:message_service/feactures/message/domain/entities/message_entity.dart';
import 'package:uuid/uuid.dart';

part 'message_event.dart';
part 'message_state.dart';

class MessageBloc extends Bloc<MessageEvent, MessageState> {

  final MessageDataSource messageDataSource;
  final UserEntity userEntity;
  MessageBloc({required this.messageDataSource, required this.userEntity}) : super(MessageInitialState()) {
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

    on<SendMessageEvent>((event, emit) async {
      emit(MessageLoadingState());
      try {
        final Uuid uuid = Uuid();
        final messageEntity = MessageEntity(
          id: uuid.v4(), // Generate a unique ID for the message
          content: event.message,
          senderId: userEntity.id, // Example sender ID
          timestamp: DateTime.now(),
        );
        await messageDataSource.sendMessage(messageEntity);
        final messages = await messageDataSource.getMessage();
        emit(MessageLoadedState( messages.content));
      } catch (e) {
        emit(MessageErrorState(e.toString()));
      }
    });

  }


}
