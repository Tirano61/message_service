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
        messageDataSource.connectToServer(event.token);
        emit(ServerConnectedState());
      } catch (e) {
        emit(MessageErrorState(e.toString()));
      }
    });
    on<LoadMessageEvent>((event, emit)async {
      emit(MessageLoadingState());
      try {
  final msg = await messageDataSource.getMessage();
  emit(MessageLoadedState(msg.content));
      } catch (e) {
        emit(MessageErrorState(e.toString()));
      }
    });

    on<SendMessageEvent>((event, emit) async {
      // No need to block UI waiting server echo; send and return
      try {
        final Uuid uuid = Uuid();
        final messageEntity = MessageEntity(
          id: uuid.v4(), // Generate a unique ID for the message
          content: event.message,
          sender: userEntity.role, // Example sender ID
          created_at: DateTime.now().toUtc(),
        );
        await messageDataSource.sendMessage(messageEntity);
        // Optionally emit a local state if needed
      } catch (e) {
        emit(MessageErrorState(e.toString()));
      }
    });

  }


}
