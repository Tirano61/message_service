import 'dart:convert';

import 'package:message_service/core/local_database.dart';
import 'package:sqflite/sqflite.dart';
import 'package:message_service/feactures/conversation/data/models/conversations_model.dart';
import 'package:message_service/feactures/conversation/domain/entities/converstion_entity.dart';
import 'package:message_service/feactures/message/domain/entities/message_entity.dart';

abstract class LocalConversationDataSource {
  Future<void> insertConversation(ConversationEntity conv);
  Future<List<ConversationEntity>> getConversations({String? type});
  Future<void> deleteConversation(String conversationId);
}

class LocalConversationDataSourceImpl implements LocalConversationDataSource {
  final LocalDatabase _db = LocalDatabase();

  @override
  Future<void> insertConversation(ConversationEntity conv) async {
    final db = await _db.database;
    final model = ConversationsModel.fromEntity(conv);
    await db.insert('conversations', {
      'id': model.id,
      'title': model.title,
      'user_id': model.userId,
      'session_token': model.sessionToken,
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
    return rows.map((r) {
      DateTime? created;
      DateTime? updated;
      try {
        created = r['created_at'] != null ? DateTime.tryParse(r['created_at'] as String)?.toUtc() : null;
      } catch (_) {}
      try {
        updated = r['updated_at'] != null ? DateTime.tryParse(r['updated_at'] as String)?.toUtc() : null;
      } catch (_) {}
      return ConversationEntity(
        id: r['id'] as String,
        title: (r['title'] ?? '') as String?,
        messages: <MessageEntity>[],
        userId: (r['user_id'] ?? '') as String?,
        sessionToken: r['session_token'] as String?,
        createdAt: created,
        updatedAt: updated,
      );
    }).toList();
  }

  @override
  Future<void> deleteConversation(String conversationId) async {
    final db = await _db.database;
    await db.delete('conversations', where: 'id = ?', whereArgs: [conversationId]);
  }
}
