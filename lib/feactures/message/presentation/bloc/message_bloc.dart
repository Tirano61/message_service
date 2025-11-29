import 'package:bloc/bloc.dart';
import 'package:flutter/material.dart';
import 'package:message_service/feactures/auth/domain/entities/user.dart';
import 'package:message_service/feactures/message/domain/repository/message_repository.dart';
import 'package:message_service/feactures/message/domain/entities/message_entity.dart';
import 'package:message_service/feactures/message/data/utils/message_display_mapper.dart';
import 'package:uuid/uuid.dart';
import 'package:message_service/core/session_manager.dart';

part 'message_event.dart';
part 'message_state.dart';

class MessageBloc extends Bloc<MessageEvent, MessageState> {

  final MessageRepository messageRepository;
  final UserEntity userEntity;
  MessageBloc({required this.messageRepository, required this.userEntity}) : super(MessageInitialState()) {
    on<ConnectServerEvent>((event, emit) {
      try {
        messageRepository.connectToServer(event.token);
        emit(ServerConnectedState());
      } catch (e) {
        emit(MessageErrorState(e.toString()));
      }
    });
    on<LoadMessageEvent>((event, emit) async {
      emit(MessageLoadingState());
      try {
        // HTTP-only: load messages list from repository
        String? convId = event.conversationId ?? SessionManager().conversationId;
        final token = event.token ?? SessionManager().sessionToken;
        
        if (convId != null && convId.isNotEmpty) {
          final list = await messageRepository.getListMessages(conversationId: convId, token: token);
          // Emit entity list for domain consumers
          emit(MessagesListLoadedState(list));
          // Also emit display-ready maps so UI doesn't need heavy normalization
          final rawMaps = list.map((e) => e.toJson()).toList();
          final display = prepareDisplayMessages(rawMaps, currentUserId: (userEntity.token.isNotEmpty ? userEntity.id : null), source: 'repo');
          emit(MessagesDisplayLoadedState(display));
        } else {
          emit(MessageErrorState('No conversation ID available'));
        }
      } catch (e) {
        emit(MessageErrorState(e.toString()));
      }
    });

    on<LoadMessagesListEvent>((event, emit) async {
      emit(MessageLoadingState());
      try {
        final list = await messageRepository.getListMessages(conversationId: event.conversationId, token: event.token);
        emit(MessagesListLoadedState(list));
        final rawMaps = list.map((e) => e.toJson()).toList();
        final display = prepareDisplayMessages(rawMaps, currentUserId: (userEntity.token.isNotEmpty ? userEntity.id : null), source: 'repo');
        emit(MessagesDisplayLoadedState(display));
      } catch (e) {
        emit(MessageErrorState(e.toString()));
      }
    });

    on<SendMessageEvent>((event, emit) async {
      // No need to block UI waiting server echo; send and return
      try {
        final Uuid uuid = Uuid();
    String senderId;
    if (event.senderId != null && event.senderId!.isNotEmpty) {
      senderId = event.senderId!;
    } else if (userEntity.id.isNotEmpty) {
      senderId = userEntity.id;
    } else {
      // For anonymous flows, mark sender as literal 'user' so server can identify it
      senderId = 'user';
    }
        final messageEntity = MessageEntity(
          id: uuid.v4(), // Generate a unique ID for the message
          content: event.message,
            sender: senderId, // use provided senderId or user id or session token
          created_at: DateTime.now().toUtc(),
        );
        
        // Enviar mensaje y recibir respuesta con userMessage y botResponse
        // Pasar JWT token si el usuario está autenticado
        final jwtToken = userEntity.token.isNotEmpty ? userEntity.token : null;
        final result = await messageRepository.sendMessage(messageEntity, jwtToken: jwtToken);
        
        // Emitir estado con los mensajes recibidos (userMessage y botResponse)
        emit(MessageSentState(
          userMessage: result['userMessage'],
          botResponse: result['botResponse'],
        ));
        
      } catch (e) {
        // Imprimir el error completo en consola para debug
        print('[DEBUG] Error al enviar mensaje: $e');
        emit(MessageErrorState(e.toString()));
      }
    });

  }


}
