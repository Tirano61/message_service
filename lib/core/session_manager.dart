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
}
