



import 'dart:async';

import 'package:message_service/core/services/socket_service.dart';
import 'package:message_service/core/session_manager.dart';
import 'package:message_service/feactures/message/data/datasource/local_message_datasource.dart';
import 'package:message_service/feactures/message/domain/entities/message_entity.dart';

abstract class MessageDataSource {

  Future<MessageEntity> getMessage();
  Future<void> sendMessage(MessageEntity message);
  Future<void> deleteMessage(String messageId);
  void connectToServer(String token);
  void listenForMessages(Function(dynamic) onMessage);

}


class MessageDataSourceImpl implements MessageDataSource {
  final SocketService _socketService;

  MessageDataSourceImpl({
    required SocketService socketService,
  }) : _socketService = socketService ;

  final LocalMessageDataSource _local = LocalMessageDataSource();

  @override
  Future<MessageEntity> getMessage() async {
    final completer = Completer<MessageEntity>();
  // El servidor emite 'message' para nuevos mensajes — usar once para no completar varias veces
  _socketService.once('message', (data) {
      try {
    // Debug: inspeccionar payload entrante
    // ignore: avoid_print
    print('[MessageDataSource] received data: $data');
        data = data as Map<String, dynamic>;
        MessageEntity message = MessageEntity.fromJson(data);
        // Generar huella simple para detección de duplicados/reenvíos
        final fingerprint = '${message.sender}|${message.content}|${message.created_at.toUtc().toIso8601String()}';
        final convId = SessionManager().conversationId;
        if (convId != null && convId.isNotEmpty) {
          final counts = SessionManager().messageFingerprintCounts.putIfAbsent(convId, () => {});
          final current = counts.putIfAbsent(fingerprint, () => 0);
          counts[fingerprint] = current + 1;
          // ignore: avoid_print
          print('[MessageDataSource] fingerprint="${fingerprint}" count=${counts[fingerprint]} (conversation=$convId)');
          if (counts[fingerprint]! > 1) {
            // ignore: avoid_print
            print('[MessageDataSource] WARNING: posible reenvío/duplicado detectado para fingerprint en conversation $convId');
          }
        }
        // Guardar mensaje recibido en SessionManager para persistencia temporal (evitar duplicados)
        if (convId != null && convId.isNotEmpty) {
          // Insertar en la DB local (si no existe, conflict replace manejará)
          try {
            _local.insertMessage(convId, message);
          } catch (_) {}
          // Mantener copia temporal en SessionManager por compatibilidad
          final list = SessionManager().messagesByConversation.putIfAbsent(convId, () => []);
          final created = message.created_at.toIso8601String();
          final exists = list.any((m) => (m['text'] == message.content) && (m['created_at'] == created));
          if (!exists) {
            list.add({'text': message.content, 'sender': message.sender, 'created_at': created});
          }
        }
        if (!completer.isCompleted) completer.complete(message);
      } catch (e) {
        if (!completer.isCompleted) completer.completeError(e);
      }
    });
    return completer.future;
  }

  @override
  Future<void> sendMessage(MessageEntity message)async {
    final sessionToken = SessionManager().sessionToken;
    final conversationId = SessionManager().conversationId;
    if (sessionToken != null && sessionToken.isNotEmpty && conversationId != null && conversationId.isNotEmpty) {
      final payload = {
        'conversationId': conversationId,
        'session_token': sessionToken,
        'sender': message.sender,
        'content': message.content
      };
        // Guardar mensaje enviado localmente en la DB y en SessionManager
        try {
          await _local.insertMessage(conversationId, message);
        } catch (_) {}
        final list = SessionManager().messagesByConversation.putIfAbsent(conversationId, () => []);
        final createdLocal = message.created_at.toIso8601String();
        final existsLocal = list.any((m) => (m['text'] == message.content) && (m['created_at'] == createdLocal));
        if (!existsLocal) {
          list.add({'text': message.content, 'sender': message.sender, 'created_at': createdLocal, 'local': true});
        }
        // Log fingerprint y contador al enviar
        final fingerprint = '${message.sender}|${message.content}|${message.created_at.toUtc().toIso8601String()}';
        final counts = SessionManager().messageFingerprintCounts.putIfAbsent(conversationId, () => {});
        final current = counts.putIfAbsent(fingerprint, () => 0);
        counts[fingerprint] = current + 1;
        // ignore: avoid_print
        print('[MessageDataSource] sent fingerprint="${fingerprint}" count=${counts[fingerprint]} (conversation=$conversationId)');
        return _socketService.emit('client-send-user', payload);
    }
  }

  @override
  Future<void> deleteMessage(String messageId)async {
    return _socketService.emit('delete_message', messageId);
    
  }
  
  @override
  void connectToServer(String token) {
  // Only use the provided JWT token; do not substitute session_token here.
  _socketService.connect(token: token);
  }
  
  @override
  void listenForMessages(Function(dynamic p1) onMessage) {
    _socketService.on('message', onMessage);
  }
}
