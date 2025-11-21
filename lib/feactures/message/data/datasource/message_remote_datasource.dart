import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:message_service/feactures/message/domain/entities/message_entity.dart';

abstract class MessageRemoteDataSource {
  Future<List<MessageEntity>> getMessages({required String token, required String conversationId});
  Future<Map<String, MessageEntity>> sendMessage({
    required String conversationId,
    required String sessionToken,
    required String sender,
    required String content,
    String? jwtToken,
  });
}

class MessageRemoteDataSourceImpl implements MessageRemoteDataSource {
  MessageRemoteDataSourceImpl({String? baseUrl}) : _baseUrl = baseUrl ?? 'http://10.0.2.2:3000';

  final String _baseUrl;

  @override
  Future<List<MessageEntity>> getMessages({required String token, required String conversationId}) async {
    final url = Uri.parse('$_baseUrl/conversation/$conversationId/message');
    final headers = {'Content-Type': 'application/json'};
    if (token.isNotEmpty) headers['Authorization'] = 'Bearer $token';
    final response = await http.get(url, headers: headers);
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data is List) {
        return data.map((e) {
          try {
            return MessageEntity.fromJson(e as Map<String, dynamic>);
          } catch (_) {
            // Fallback: construct minimal message
            return MessageEntity(id: '', content: e['content']?.toString() ?? '', sender: e['sender']?.toString() ?? '', created_at: DateTime.now().toUtc());
          }
        }).toList();
      } else {
        throw Exception('Unexpected response format for messages list');
      }
    } else {
      throw Exception('Failed to fetch messages: ${response.statusCode} ${response.body}');
    }
  }

  @override
  Future<Map<String, MessageEntity>> sendMessage({
    required String conversationId,
    required String sessionToken,
    required String sender,
    required String content,
    String? jwtToken,
  }) async {
    final url = Uri.parse('$_baseUrl/messages/send');
    final headers = {'Content-Type': 'application/json'};
    
    // Usar Bearer token si está disponible, sino usar session_token
    if (jwtToken != null && jwtToken.isNotEmpty) {
      headers['Authorization'] = 'Bearer $jwtToken';
    }
    
    final payload = {
      'conversationId': conversationId,
      'session_token': sessionToken,
      'sender': sender,
      'content': content,
    };
    
    final response = await http.post(
      url,
      headers: headers,
      body: jsonEncode(payload),
    );
    
    if (response.statusCode == 200 || response.statusCode == 201) {
      final data = jsonDecode(response.body);
      
      // Verificar que la respuesta tenga la estructura esperada
      if (data['success'] != true) {
        throw Exception('Server response indicates failure: ${data['message'] ?? 'Unknown error'}');
      }
      
      final result = <String, MessageEntity>{};
      
      // Procesar userMessage
      if (data['userMessage'] != null) {
        try {
          result['userMessage'] = MessageEntity.fromJson(data['userMessage'] as Map<String, dynamic>);
        } catch (e) {
          throw Exception('Failed to parse userMessage: $e');
        }
      }
      
      // Procesar botResponse
      if (data['botResponse'] != null) {
        try {
          result['botResponse'] = MessageEntity.fromJson(data['botResponse'] as Map<String, dynamic>);
        } catch (e) {
          throw Exception('Failed to parse botResponse: $e');
        }
      }
      
      return result;
    } else {
      throw Exception('Failed to send message: ${response.statusCode} ${response.body}');
    }
  }
}
