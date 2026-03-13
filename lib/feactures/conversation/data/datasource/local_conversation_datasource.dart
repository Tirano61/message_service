import 'dart:convert';

import 'package:message_service/core/local_database.dart';
import 'package:sqflite/sqflite.dart';
import 'package:message_service/feactures/conversation/data/models/conversations_model.dart';
import 'package:message_service/feactures/conversation/domain/entities/converstion_entity.dart';
import 'package:message_service/feactures/message/domain/entities/message_entity.dart';
import 'package:message_service/feactures/message/data/datasource/local_message_datasource.dart';

abstract class LocalConversationDataSource {
  Future<void> insertConversation(ConversationEntity conv);
  Future<List<ConversationEntity>> getConversations({String? type});
  Future<void> deleteConversation(String conversationId);
}

class LocalConversationDataSourceImpl implements LocalConversationDataSource {
  final LocalDatabase _db = LocalDatabase();
  final LocalMessageDataSource _localMessageDataSource = LocalMessageDataSource();

  @override
  Future<void> insertConversation(ConversationEntity conv) async {
    final db = await _db.database;
    final model = ConversationsModel.fromEntity(conv);
    await db.insert('conversations', {
      'id': model.id,
      'title': model.title,
      'user_id': model.userId,
      'session_id': model.sessionToken,
      'type': model.type,
      'metadata': jsonEncode({
        'created_at': model.createdAt?.toIso8601String(),
        'updated_at': model.updatedAt?.toIso8601String(),
      }),
      'created_at': model.createdAt?.toIso8601String(),
      'updated_at': model.updatedAt?.toIso8601String(),
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  @override
  Future<List<ConversationEntity>> getConversations({String? type}) async {
    final db = await _db.database;
    List<Map<String, Object?>> rows;
    if (type != null && type.isNotEmpty) {
      rows = await db.query('conversations', where: 'type = ?', whereArgs: [type], orderBy: 'rowid DESC');
    } else {
      rows = await db.query('conversations', orderBy: 'rowid DESC');
    }
    final conversations = await Future.wait(rows.map((r) async {
      try {
        // ignore: avoid_print
        print('[DEBUG] local conversation row: $r');
      } catch (_) {}

      DateTime? created;
      DateTime? updated;
      try {
        created = r['created_at'] != null ? DateTime.tryParse(r['created_at'] as String)?.toUtc() : null;
      } catch (_) {}
      try {
        updated = r['updated_at'] != null ? DateTime.tryParse(r['updated_at'] as String)?.toUtc() : null;
      } catch (_) {}

      final conversationId = r['id'] as String;
      List<MessageEntity> messages = const <MessageEntity>[];
      try {
        messages = await _localMessageDataSource.getMessages(conversationId);
      } catch (_) {
        messages = const <MessageEntity>[];
      }

      return ConversationEntity(
        id: conversationId,
        title: (r['title'] ?? '') as String?,
        messages: messages,
        userId: (r['user_id'] ?? '') as String?,
        sessionToken: r['session_id'] as String?,
        createdAt: created,
        updatedAt: updated,
      );
    }).toList());

    return conversations;
  }

  @override
  Future<void> deleteConversation(String conversationId) async {
    final db = await _db.database;
    await db.delete('conversations', where: 'id = ?', whereArgs: [conversationId]);
  }
}
