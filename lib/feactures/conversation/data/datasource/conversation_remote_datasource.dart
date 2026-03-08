import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:message_service/core/config.dart';
import 'package:message_service/feactures/conversation/data/models/conversations_model.dart';
import 'package:message_service/feactures/conversation/domain/entities/converstion_entity.dart';

abstract class ConversationRemoteDataSource {
  Future<ConversationEntity> createConversation({
  required String token,
  required String userId,
  required String title,
  required String type,
  });
  Future<List<ConversationEntity>> getConversations({
    required String token,
    String? type, // 'sales' | 'tecnico' | 'anonimo'
  });
  Future<List<ConversationEntity>> getAllConversations({
    required String token,
    required String userId,
  });
  Future<void> deleteConversation({required String token, required String conversationId, String? sessionToken});
}

class ConversationRemoteDataSourceImpl implements ConversationRemoteDataSource {
  ConversationRemoteDataSourceImpl({String? baseUrl})
      : _baseUrl = baseUrl ?? AppConfig.baseUrl;

  final String _baseUrl;
  
  http.Client _getClient() => AppConfig.getHttpClient();

  @override
  Future<ConversationEntity> createConversation({
    required String token,
    required String userId,
    required String title,
    String? type,
  }) async {
    const allowedTypes = {'sales', 'tecnico', 'anonimo', 'developer'};
    final normalizedType = (type ?? 'anonimo').toLowerCase();
    if (!allowedTypes.contains(normalizedType)) {
      throw Exception('Invalid conversation type "$normalizedType". Allowed: sales, tecnico, anonimo, developer');
    }

    // Choose exact backend endpoints for role-specific creation
    String path;
    if (normalizedType.isNotEmpty) {
      final t = normalizedType;
      if (t == 'tecnico') {
        path = '$_baseUrl/conversation/create-tecnico';
      } else if (t == 'sales') {
        path = '$_baseUrl/conversation/create-sales';
      } else if (t == 'developer') {
        path = '$_baseUrl/conversation/create-developer';
      } else {
        // anonimo and any non role-specific type use default create endpoint
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
      headers['Authorization'] = 'Bearer $token';
    }
    // An anonimo conversation may be created without auth token.
    final isAnonymous = normalizedType == 'anonimo' && token.isEmpty;

    final payload = <String, dynamic>{
      'title': isAnonymous ? "" : title,
      'user': isAnonymous ? "" : userId,
      'type': normalizedType,
    };

    final client = _getClient();
    final response = await client.post(
      url,
      headers: headers,
      body: jsonEncode(payload),
    );
    client.close();

    if (response.statusCode == 200 || response.statusCode == 201) {
      final data = jsonDecode(response.body);
      try {
        // ignore: avoid_print
        print('[DEBUG] createConversation response: $data');
      } catch (_) {}
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
      headers['Authorization'] = 'Bearer $token';
    }
    final client = _getClient();
    final response = await client.get(
      url,
      headers: headers,
    );
    client.close();

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
      headers['Authorization'] = 'Bearer $token';
    }
    final client = _getClient();
    final response = await client.get(
      url,
      headers: headers,
    );
    client.close();

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
        ? '$_baseUrl/conversation/$conversationId?session_id=$sessionToken'
        : '$_baseUrl/conversation/$conversationId';
    final url = Uri.parse(path);
    final headers = {
      'Content-Type': 'application/json',
    };
    if (token.isNotEmpty) headers['Authorization'] = 'Bearer $token';

    final client = _getClient();
    final response = await client.delete(url, headers: headers);
    client.close();
    if (response.statusCode == 200 || response.statusCode == 204) {
      return;
    } else {
      throw Exception('Failed to delete conversation: ${response.statusCode} ${response.body}');
    }
  }
}
