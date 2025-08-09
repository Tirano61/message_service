import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:message_service/feactures/conversation/data/models/conversations_model.dart';
import 'package:message_service/feactures/conversation/domain/entities/converstion_entity.dart';

abstract class ConversationRemoteDataSource {
  Future<ConversationEntity> createConversation({
    required String token,
    required String userId,
    required String title,
  });
  Future<List<ConversationEntity>> getConversations({
    required String token,
    String? type, // 'user' | 'tecnico'
  });
  Future<List<ConversationEntity>> getAllConversations({
    required String token,
    required String userId,
  });
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
  }) async {
    final url = Uri.parse('$_baseUrl/conversation/create');
    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'userId': userId,
        'title': title,
      }),
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

    final response = await http.get(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
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
    final response = await http.get(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
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
}
