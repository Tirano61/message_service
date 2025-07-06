import 'package:socket_io_client/socket_io_client.dart' as IO;

class SocketService {
  static final SocketService _instance = SocketService._internal();
  factory SocketService() => _instance;
  late IO.Socket socket;

  SocketService._internal();

  void connect() {
    socket = IO.io(
      "http://10.0.2.2:3000",
      IO.OptionBuilder()
          .setTransports(['websocket'])
          .build(),
    );
    
    socket.connect();

    socket.onConnect((_) {
      print("Connected to socket server");
    });

    socket.onDisconnect((_) {
      print("Disconnected from socket server");
    });

    socket.onConnectError((data) {
      print("Connection Error: $data");
    });
  }

  void disconnect() {
    socket.disconnect();
  }

  void on(String event, Function(dynamic) handler) {
    socket.on(event, handler);
  }

  void emit(String event, dynamic data) {
    print("Emitting event: $event with data: $data");
    socket.emit(event, data);
  }
}