class SessionManager {
  static final SessionManager _instance = SessionManager._internal();
  factory SessionManager() => _instance;

  SessionManager._internal();

  String? sessionToken;
  String? conversationId;
}
