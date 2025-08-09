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
}
