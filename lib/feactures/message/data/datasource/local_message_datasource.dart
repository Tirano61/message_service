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
      'created_at': message.created_at.toIso8601String(),
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<MessageEntity>> getMessages(String conversationId) async {
    final db = await _db.database;
    final rows = await db.query('messages', where: 'conversation_id = ?', whereArgs: [conversationId], orderBy: 'created_at ASC');
    return rows.map((r) => MessageEntity(
      id: r['id'] as String,
      content: r['content'] as String,
      sender: r['sender'] as String,
      created_at: DateTime.parse(r['created_at'] as String).toUtc(),
    )).toList();
  }

  Future<void> deleteConversationMessages(String conversationId) async {
    final db = await _db.database;
    await db.delete('messages', where: 'conversation_id = ?', whereArgs: [conversationId]);
  }
}
