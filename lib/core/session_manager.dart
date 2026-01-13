import 'package:shared_preferences/shared_preferences.dart';

class SessionManager {
  static final SessionManager _instance = SessionManager._internal();
  factory SessionManager() => _instance;

  SessionManager._internal();

  String? sessionToken;
  String? conversationId;
  // Mensajes temporales por conversationId
  final Map<String, List<Map<String, dynamic>>> messagesByConversation = {};
  // Conteo de huellas (fingerprints) de mensajes por conversationId para detectar duplicados/reenvíos
  // fingerprint -> count
  final Map<String, Map<String, int>> messageFingerprintCounts = {};

  static const _tokenKey = 'session_token';
  static const _conversationIdKey = 'conversation_id';

  Future<void> saveSession() async {
    final prefs = await SharedPreferences.getInstance();
    if (sessionToken != null) {
      await prefs.setString(_tokenKey, sessionToken!);
    } else {
      await prefs.remove(_tokenKey);
    }
    if (conversationId != null) {
      await prefs.setString(_conversationIdKey, conversationId!);
    } else {
      await prefs.remove(_conversationIdKey);
    }
  }

  Future<void> loadSession() async {
    final prefs = await SharedPreferences.getInstance();
    sessionToken = prefs.getString(_tokenKey);
    conversationId = prefs.getString(_conversationIdKey);
  }

  Future<void> clearSession() async {
    sessionToken = null;
    conversationId = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    await prefs.remove(_conversationIdKey);
  }
}
