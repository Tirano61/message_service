import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:message_service/feactures/conversation/data/models/conversations_model.dart';
import 'package:message_service/feactures/conversation/domain/entities/converstion_entity.dart';

abstract class ConversationRemoteDataSource {
  Future<ConversationEntity> createConversation({
  required String token,
  required String userId,
  required String title,
  String? type,
  });
  Future<List<ConversationEntity>> getConversations({
    required String token,
    String? type, // 'user' | 'tecnico'
  });
  Future<List<ConversationEntity>> getAllConversations({
    required String token,
    required String userId,
  });
  Future<void> deleteConversation({required String token, required String conversationId, String? sessionToken});
}

class ConversationRemoteDataSourceImpl implements ConversationRemoteDataSource {
  ConversationRemoteDataSourceImpl({String? baseUrl})
      : _baseUrl = baseUrl ?? 'http://10.0.2.2:3000'; // Usa http://localhost:3000 si corres en escritorio

  final String _baseUrl;

  @override
  Future<ConversationEntity> createConversation({
    required String token,
    required String userId,
    required String title,
    String? type,
  }) async {
    // Choose exact backend endpoints for role-specific creation
    String path;
    if (type != null && type.isNotEmpty) {
      final t = type.toLowerCase();
      if (t == 'tecnico' || t == 'technical') {
        path = '$_baseUrl/conversation/create-tecnico';
      } else if (t == 'sales' || t == 'seller' || t == 'vendedor') {
        path = '$_baseUrl/conversation/create-sales';
      } else {
        // unknown type: fallback to default create
        path = '$_baseUrl/conversation/create';
      }
    } else {
      path = '$_baseUrl/conversation/create';
    }
    final url = Uri.parse(path);
    final headers = {
      'Content-Type': 'application/json',
    };
    if (token.isNotEmpty) {
      headers['auth'] = token;
    }
    final payload = <String, dynamic>{'title': title};
    // "user" must be a UUID and only sent when the user is authenticated
    if (userId.isNotEmpty) {
      payload['user'] = userId;
    }

    final response = await http.post(
      url,
      headers: headers,
      body: jsonEncode(payload),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      final data = jsonDecode(response.body);
      // Intentamos mapear una respuesta tipo { id, title, messages?, userId? }
      final model = ConversationsModel.fromJson(data);
      return model.toEntity();
    } else {
      throw Exception('Failed to create conversation: ${response.statusCode} ${response.body}');
    }
  }

  @override
  Future<List<ConversationEntity>> getConversations({
    required String token,
    String? type,
  }) async {
    final path = type == null || type.isEmpty
        ? '$_baseUrl/conversation'
        : '$_baseUrl/conversation?type=$type';
    final url = Uri.parse(path);

    final headers = {
      'Content-Type': 'application/json',
    };
    if (token.isNotEmpty) {
      headers['auth'] = token;
    }
    final response = await http.get(
      url,
      headers: headers,
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data is List) {
        return data
            .map((e) => ConversationsModel.fromJson(e).toEntity())
            .toList();
      } else {
        throw Exception('Unexpected response format for conversations list');
      }
    } else {
      throw Exception('Failed to fetch conversations: ${response.statusCode} ${response.body}');
    }
  }
  
  @override
  Future<List<ConversationEntity>> getAllConversations({required String token, required String userId}) async {
    final url = Uri.parse('$_baseUrl/conversation/all');
    final headers = {
      'Content-Type': 'application/json',
    };
    if (token.isNotEmpty) {
      headers['auth'] = token;
    }
    final response = await http.get(
      url,
      headers: headers,
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data is List) {
        return data
            .map((e) => ConversationsModel.fromJson(e).toEntity())
            .toList();
      } else {
        throw Exception('Unexpected response format for conversations list');
      }
    } else {
      throw Exception('Failed to fetch conversations: ${response.statusCode} ${response.body}');
    }
  }

  @override
  Future<void> deleteConversation({required String token, required String conversationId, String? sessionToken}) async {
    // Si sessionToken está presente, usarlo como query param para eliminar una conversación anónima
    final path = (sessionToken != null && sessionToken.isNotEmpty)
        ? '$_baseUrl/conversation/$conversationId?session_token=$sessionToken'
        : '$_baseUrl/conversation/$conversationId';
    final url = Uri.parse(path);
    final headers = {
      'Content-Type': 'application/json',
    };
    if (token.isNotEmpty) headers['auth'] = token;

    final response = await http.delete(url, headers: headers);
    if (response.statusCode == 200 || response.statusCode == 204) {
      return;
    } else {
      throw Exception('Failed to delete conversation: ${response.statusCode} ${response.body}');
    }
  }
}
