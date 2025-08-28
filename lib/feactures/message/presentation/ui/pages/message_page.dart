import 'package:flutter/material.dart';
import 'package:message_service/feactures/message/presentation/bloc/message_bloc.dart';
import 'package:message_service/core/services/socket_service.dart';
import 'package:message_service/feactures/auth/presentation/bloc/auth_bloc.dart';
import 'package:message_service/core/session_manager.dart';
import 'package:message_service/feactures/message/data/datasource/local_message_datasource.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class MessagePage extends StatefulWidget {
  final String conversationId;
  final String title;
  final List<dynamic>? initialMessages;
  const MessagePage({super.key, this.conversationId = '', this.title = 'Messages', this.initialMessages});

  @override
  State<MessagePage> createState() => _MessagePageState();
}

class _MessagePageState extends State<MessagePage> {
  final List<Map<String, dynamic>> messages = [
    {'text': 'Hola, ¿cómo estás?', 'isMe': false},
    {'text': '¡Hola! Todo bien, ¿y tú?', 'isMe': true},
    {'text': 'Muy bien, gracias.', 'isMe': false},
    {'text': '¿En qué puedo ayudarte?', 'isMe': true},
  ];

  final TextEditingController _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
  @override
  void initState() {  
    super.initState();
  context.read<MessageBloc>().add(ConnectServerEvent());
  // Start listening for incoming messages (listen once)
  context.read<MessageBloc>().add(LoadMessageEvent());
    // Inicializar mensajes si vienen como parámetro
    final authState = context.read<AuthBloc>().state;
    if (widget.initialMessages != null && widget.initialMessages!.isNotEmpty) {
      messages.clear();
      for (final m in widget.initialMessages!) {
        if (m is Map<String, dynamic>) {
          messages.add({'text': m['content'] ?? m['message'] ?? '', 'isMe': _isMine(m, authState)});
        }
      }
    } else {
      // si no vinieron mensajes como parámetro, intentar cargar desde DB local
      final convId = widget.conversationId.isNotEmpty ? widget.conversationId : SessionManager().conversationId;
      if (convId != null && convId.isNotEmpty) {
        try {
          final localDs = LocalMessageDataSource();
          localDs.getMessages(convId).then((list) {
            if (list.isNotEmpty) {
              setState(() {
                messages.clear();
                for (final m in list) {
                  messages.add({'text': m.content, 'isMe': (m.sender == (authState is AuthAuthenticatedState ? authState.user.id : null))});
                }
              });
            }
          });
        } catch (_) {}
      }
    }
    // Merge temporales almacenados en SessionManager
    final convId = widget.conversationId.isNotEmpty ? widget.conversationId : SessionManager().conversationId;
    if (convId != null && convId.isNotEmpty) {
      final stored = SessionManager().messagesByConversation[convId];
      if (stored != null && stored.isNotEmpty) {
        for (final m in stored) {
          messages.add({'text': m['text'] ?? '', 'isMe': (m['sender'] == (authState is AuthAuthenticatedState ? authState.user.id : null))});
        }
      }
    }
    // Aquí podrías inicializar la conexión al servidor o cualquier otra configuración necesaria.
  }

  bool _isMine(Map<String, dynamic> m, dynamic authState) {
    final sender = m['sender']?.toString() ?? '';
    if (authState is AuthAuthenticatedState) {
      return sender == authState.user.id || sender == authState.user.role;
    }
    return false;
  }

  void _sendMessage() {
    final text = _controller.text.trim();
    if (text.isNotEmpty) {
      setState(() {
        context.read<MessageBloc>().add(SendMessageEvent(text));
        messages.add({'text': text, 'isMe': true});

      });
      _controller.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          tooltip: 'Volver',
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
        centerTitle: true,
        elevation: 6,
        title: Text(widget.title),
        actions: [
          BlocBuilder<MessageBloc, MessageState>(
            builder: (context, state) {
              // Preferir el estado real del socket si está disponible
              try {
                final connected = SocketService().isConnected();
                return Icon(Icons.connect_without_contact, color: connected ? Colors.green : Colors.red);
              } catch (_) {
                // Fallback al estado del bloc
                final iconColor = state is ServerConnectedState ? Colors.green : Colors.red;
                return Icon(Icons.connect_without_contact, color: iconColor);
              }
            },
          ),
        ],
      ),
      body: BlocListener<MessageBloc, MessageState>(
        listener: (context, state) {
          if (state is MessageLoadedState) {
            final msg = state.message;
            // deduplicar por contenido+timestamp
            final exists = messages.any((m) => m['text'] == msg.content && (m['timestamp'] ?? '') == msg.created_at.toIso8601String());
            if (!exists) {
              setState(() {
                messages.add({'text': msg.content, 'isMe': _isMine(msg.toJson(), context.read<AuthBloc>().state), 'timestamp': msg.created_at.toIso8601String()});
              });
            }
            // Escuchar el siguiente mensaje
            context.read<MessageBloc>().add(LoadMessageEvent());
          }
        },
        child: Column(
          children: [
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(12),
                itemCount: messages.length,
                itemBuilder: (context, index) {
                  final message = messages[index];
                  final isMe = message['isMe'] as bool;
                  return Align(
                    alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                    child: Container(
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      decoration: BoxDecoration(
                        color: isMe ? Colors.lightBlue[100] : Colors.grey[300],
                        borderRadius: BorderRadius.only(
                          topLeft: const Radius.circular(16),
                          topRight: const Radius.circular(16),
                          bottomLeft: isMe ? const Radius.circular(16) : const Radius.circular(0),
                          bottomRight: isMe ? const Radius.circular(0) : const Radius.circular(16),
                        ),
                      ),
                      child: Text(
                        message['text'] as String,
                        style: const TextStyle(fontSize: 16),
                      ),
                    ),
                  );
                },
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              color: Colors.white,
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      decoration: const InputDecoration(
                        hintText: 'Escribe un mensaje...',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.all(Radius.circular(24)),
                          borderSide: BorderSide.none,
                        ),
                        filled: true,
                        fillColor: Color(0xFFF0F0F0),
                        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 0),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.send, color: Colors.blue),
                    onPressed: _sendMessage,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}