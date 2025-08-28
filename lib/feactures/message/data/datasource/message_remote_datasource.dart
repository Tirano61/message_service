import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:message_service/feactures/message/domain/entities/message_entity.dart';

abstract class MessageRemoteDataSource {
  Future<List<MessageEntity>> getMessages({required String token, required String conversationId});
}

class MessageRemoteDataSourceImpl implements MessageRemoteDataSource {
  MessageRemoteDataSourceImpl({String? baseUrl}) : _baseUrl = baseUrl ?? 'http://10.0.2.2:3000';

  final String _baseUrl;

  @override
  Future<List<MessageEntity>> getMessages({required String token, required String conversationId}) async {
    final url = Uri.parse('$_baseUrl/conversation/$conversationId/messages');
    final headers = {'Content-Type': 'application/json'};
    if (token.isNotEmpty) headers['auth'] = token;
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
}
