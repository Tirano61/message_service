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
          final currentUserId = event.currentUserId ?? (userEntity.token.isNotEmpty ? userEntity.id : null);
          final display = prepareDisplayMessages(rawMaps, currentUserId: currentUserId, source: 'repo');
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
        final currentUserId = event.currentUserId ?? (userEntity.token.isNotEmpty ? userEntity.id : null);
        final display = prepareDisplayMessages(rawMaps, currentUserId: currentUserId, source: 'repo');
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
      senderId = 'local';
    }
        final messageEntity = MessageEntity(
          id: uuid.v4(), // Generate a unique ID for the message
          content: event.message,
            sender: 'user', // always send role 'user' for outbound HTTP
          created_at: DateTime.now().toUtc(),
          senderId: senderId,
        );
        // Verificación y log rápidos antes de enviar (no imprimir token completo)
        final convIdNow = event.conversationId ?? SessionManager().conversationId;
        final hasSession = (SessionManager().sessionToken ?? '').isNotEmpty;
        final jwtToken = (event is dynamic && (event.jwtToken != null && event.jwtToken!.isNotEmpty))
          ? event.jwtToken
          : (userEntity.token.isNotEmpty ? userEntity.token : null);
        final hasJwt = (jwtToken ?? '').isNotEmpty;
        try {
          print('[DEBUG] SendMessage: convId=$convIdNow hasSession=$hasSession hasJwt=$hasJwt senderId=$senderId');
        } catch (_) {}
        if (convIdNow == null || convIdNow.isEmpty) {
          emit(MessageErrorState('No conversation ID available for send'));
          return;
        }

        final result = await messageRepository.sendMessage(messageEntity, conversationId: convIdNow, jwtToken: jwtToken);
        
        // Emitir estado con los mensajes recibidos (userMessage y botResponse)
        emit(MessageSentState(
          userMessage: result['userMessage'],
          botResponse: result['botResponse'],
        ));

        // Also emit display-ready maps for the returned messages so UI can append them
        try {
          final List<Map<String, dynamic>> appended = [];
          if (result['userMessage'] != null) {
            appended.addAll(prepareDisplayMessages([result['userMessage']!.toJson()], currentUserId: (userEntity.token.isNotEmpty ? userEntity.id : null), source: 'sent'));
          }
          if (result['botResponse'] != null) {
            appended.addAll(prepareDisplayMessages([result['botResponse']!.toJson()], currentUserId: (userEntity.token.isNotEmpty ? userEntity.id : null), source: 'sent'));
          }
          if (appended.isNotEmpty) {
            emit(MessagesDisplayLoadedState(appended));
          }
        } catch (_) {}
        
      } catch (e) {
        // Imprimir el error completo en consola para debug
        print('[DEBUG] Error al enviar mensaje: $e');
        emit(MessageErrorState(e.toString()));
      }
    });

  }


}
