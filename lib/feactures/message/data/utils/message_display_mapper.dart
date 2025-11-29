import 'package:message_service/feactures/message/data/models/messages_model.dart';

/// Normalize raw server payloads (or caller-provided maps) into UI-ready maps.
/// Each returned map has keys: text, sender, created_at (ISO), timestamp (ISO), isMe (bool), source.
List<Map<String, dynamic>> prepareDisplayMessages(List<dynamic> rawMessages, {String? currentUserId, String source = 'initial'}) {
  final out = <Map<String, dynamic>>[];
  for (var i = 0; i < rawMessages.length; i++) {
    final r = rawMessages[i];
    try {
      if (r is Map<String, dynamic>) {
        final model = MessagesModel.fromJson(r);
        final createdIso = model.createdAt.toIso8601String();
        final sender = (model.sender ?? '').toString();
        final senderId = (model.senderId ?? '').toString();

        // Determine isMe using the following precedence:
        // 1) explicit role string 'user' -> true, 'bot' -> false
        // 2) senderId or sender equals currentUserId
        // 3) fallback false
        bool isMe = false;
        if (sender.isNotEmpty) {
          final s = sender.toLowerCase();
          if (s == 'user') {
            isMe = true;
          } else if (s == 'bot') {
            isMe = false;
          } else if (currentUserId != null && (sender == currentUserId || senderId == currentUserId)) {
            isMe = true;
          }
        } else if (senderId.isNotEmpty && currentUserId != null) {
          isMe = senderId == currentUserId;
        }

        out.add({
          'text': model.content,
          'sender': sender.isNotEmpty ? sender : senderId,
          'senderId': senderId,
          'created_at': createdIso,
          'timestamp': createdIso,
          'isMe': isMe,
          'source': source,
        });
      }
    } catch (_) {
      // ignore malformed entries
    }
  }
  return out;
}
