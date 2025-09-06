import 'package:message_service/core/local_database.dart';
import 'package:sqflite/sqflite.dart';
import 'package:message_service/feactures/message/domain/entities/message_entity.dart';

class LocalMessageDataSource {
  final LocalDatabase _db = LocalDatabase();

  Future<void> insertMessage(String conversationId, MessageEntity message) async {
    final db = await _db.database;
    await db.insert('messages', {
      'id': message.id,
      'conversation_id': conversationId,
      'content': message.content,
      'sender': message.sender,
      'sender_id': message.senderId,
      'external_id': message.externalId,
      'session_id': message.sessionId,
      'n8n_message': message.n8nMessage,
      'created_at': message.created_at.toIso8601String(),
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<MessageEntity>> getMessages(String conversationId) async {
    final db = await _db.database;
  // Order by rowid (insertion order) to avoid clock-skew issues between device and server.
  // rowid reflects the order rows were inserted into the DB.
  final rows = await db.query('messages', where: 'conversation_id = ?', whereArgs: [conversationId], orderBy: 'rowid ASC');
    try {
      if (rows.isNotEmpty) {
        print('DBG LocalDS.getMessages first_raw_created_at=${rows.first['created_at']} count=${rows.length}');
      }
    } catch (_) {}
    return rows.map((r) {
      DateTime created;
      try {
        final raw = (r['created_at'] ?? '').toString();
        final parsed = DateTime.tryParse(raw);
        created = parsed != null ? parsed.toUtc() : DateTime.now().toUtc();
      } catch (_) {
        created = DateTime.now().toUtc();
      }
      return MessageEntity(
        id: r['id'] as String,
        content: r['content'] as String,
        sender: (r['sender'] ?? '') as String,
        created_at: created,
        senderId: r['sender_id'] as String?,
        externalId: r['external_id'] as String?,
        sessionId: r['session_id'] as String?,
        n8nMessage: r['n8n_message'] as String?,
      );
    }).toList();
  }

  Future<void> deleteConversationMessages(String conversationId) async {
    final db = await _db.database;
    await db.delete('messages', where: 'conversation_id = ?', whereArgs: [conversationId]);
  }
}
