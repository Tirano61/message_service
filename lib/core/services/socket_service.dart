import 'package:message_service/core/session_manager.dart';
import 'package:socket_io_client/socket_io_client.dart' as socketIO;

class SocketService {
  static final SocketService _instance = SocketService._internal();
  factory SocketService() => _instance;
  late socketIO.Socket socket;

  SocketService._internal();

  void connect({required String token}) {
    final builder = socketIO.OptionBuilder().setTransports(['websocket']);

    // If JWT token provided (user logged in) use it. Otherwise, if there is an anonymous
    // session (session_token + conversationId) use that. Do not mix both.
    if (token.isNotEmpty) {
      builder.setAuth({'token': token});
    } else {
      final sToken = SessionManager().sessionToken;
      final convId = SessionManager().conversationId;
      if (sToken != null && sToken.isNotEmpty && convId != null && convId.isNotEmpty) {
        builder.setAuth({'conversationId': convId, 'session_token': sToken});
      }
    }

    socket = socketIO.io(
      'http://10.0.2.2:3000',
      builder.build(),
    );

    socket.connect();

    socket.onConnect((_) {
      print('Connected to socket server');
    });

    socket.onDisconnect((_) {
      print('Disconnected from socket server');
    });

    socket.onConnectError((data) {
      print('Connection Error: $data');
    });
  }

  void disconnect() {
    socket.disconnect();
  }

  void on(String event, Function(dynamic) handler) {
    socket.on(event, handler);
  }

  void once(String event, dynamic handler) {
    socket.once(event, handler);
  }

  void off(String event, [dynamic handler]) {
    if (handler != null) {
      socket.off(event, handler);
    } else {
      socket.off(event);
    }
  }

  void emit(String event, dynamic data) {
    print('Emitting event: $event with data: $data');
    socket.emit(event, data);
  }
}