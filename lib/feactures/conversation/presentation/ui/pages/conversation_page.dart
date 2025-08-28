import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:message_service/feactures/auth/presentation/bloc/auth_bloc.dart';
import 'package:message_service/feactures/conversation/domain/entities/converstion_entity.dart';
import 'package:message_service/feactures/conversation/presentation/bloc/conversation_bloc.dart';
import 'package:message_service/feactures/message/presentation/ui/pages/message_page.dart';
import 'package:message_service/core/session_manager.dart';
import 'package:message_service/core/services/socket_service.dart';
import 'package:message_service/feactures/message/data/datasource/message_remote_datasource.dart';
import 'package:message_service/feactures/message/data/datasource/local_message_datasource.dart';

// Página menú según rol
class ConversationPage extends StatelessWidget {
  const ConversationPage({super.key});

  @override
  Widget build(BuildContext context) {
    final authState = context.watch<AuthBloc>().state;
    String role = 'user';
    if (authState is AuthAuthenticatedState) {
      role = authState.user.role;
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Conversaciones')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _RoleCard(
              title: 'Conversaciones usuario',
              icon: Icons.chat_bubble_outline,
              color: Colors.blue,
              onTap: () => _openList(context, 'user'),
            ),
            if (role.toLowerCase() == 'tecnico') ...[
              const SizedBox(height: 16),
              _RoleCard(
                title: 'Conversaciones técnico',
                icon: Icons.build_outlined,
                color: Colors.deepPurple,
                onTap: () => _openList(context, 'tecnico'),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _openList(BuildContext context, String type) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => ConversationListPage(type: type)),
    );
  }
}

class _RoleCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  const _RoleCard({
    required this.title,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 2,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: color.withOpacity(0.15),
                child: Icon(icon, color: color),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
              ),
              const Icon(Icons.chevron_right),
            ],
          ),
        ),
      ),
    );
  }
}

// Página que lista conversaciones (placeholder usando el Bloc existente)
class ConversationListPage extends StatefulWidget {
  final String type; // 'user' o 'tecnico'
  const ConversationListPage({super.key, required this.type});

  @override
  State<ConversationListPage> createState() => _ConversationListPageState();
}

class _ConversationListPageState extends State<ConversationListPage> {
  @override
  void initState() {
    super.initState();
    final authState = context.read<AuthBloc>().state;
    if (authState is AuthAuthenticatedState) {
      context.read<ConversationBloc>().add(LoadConversationsEvent(token: authState.user.token, type: widget.type));
    } else {
      // anonymous: load public/anonymous conversations (backend should support type='anonymous')
      context.read<ConversationBloc>().add(LoadConversationsEvent(token: '', type: 'anonymous'));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
  appBar: AppBar(title: Text('Lista de ${widget.type}')),
      body: BlocListener<ConversationBloc, ConversationState>(
        listener: (context, state) {
          if (state is ConversationCreatedState) {
            // navigate to message page for the created conversation
            Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => MessagePage(conversationId: state.conversation.id, title: state.conversation.title ?? 'Conversación', initialMessages: state.conversation.messages?.map((m) => m.toJson()).toList())));
          }
        },
        child: BlocBuilder<ConversationBloc, ConversationState>(
          builder: (context, state) {
          if (state is ConversationLoadingState) {
            return const Center(child: CircularProgressIndicator());
          } else if (state is ConversationLoadedState) {
            final List<ConversationEntity> conversations = state.conversations;
            if (conversations.isEmpty) {
              return const Center(child: Text('No hay conversaciones.'));
            }
            return ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: conversations.length,
              itemBuilder: (context, index) {
                final conversation = conversations[index];
                final displayTitle = conversation.title ?? 'Sin título';
                final created = conversation.createdAt;
                final dateText = created != null ?
                  '${created.toLocal().day}/${created.toLocal().month}/${created.toLocal().year} ${created.toLocal().hour}:${created.toLocal().minute.toString().padLeft(2,'0')}'
                  : '';

                return Dismissible(
                  key: Key(conversation.id),
                  direction: DismissDirection.endToStart,
                  background: Container(
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    color: Colors.red,
                    child: const Icon(Icons.delete, color: Colors.white),
                  ),
                  onDismissed: (_) {
                    // Dispatch delete event to bloc (incluir token si el usuario está autenticado)
                    final authState = context.read<AuthBloc>().state;
                    final token = (authState is AuthAuthenticatedState) ? authState.user.token : '';
                    context.read<ConversationBloc>().add(DeleteConversationEvent(conversationId: conversation.id, token: token));
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Conversación eliminada')));
                  },
                  child: Card(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: 2,
                    margin: const EdgeInsets.symmetric(vertical: 8),
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      title: Text(displayTitle, style: const TextStyle(fontWeight: FontWeight.w600)),
                      subtitle: Text(dateText),
                      onTap: () async {
                        // If conversation has sessionToken, store it so MessageDataSource will use it
                        if (conversation.sessionToken != null && conversation.sessionToken!.isNotEmpty) {
                          SessionManager().sessionToken = conversation.sessionToken;
                          SessionManager().conversationId = conversation.id;
                          // Ensure socket connects using anonymous session
                          try {
                            SocketService().connect(token: '');
                          } catch (_) {}
                        }
                        final convId = conversation.id;
                        // 1) Intentar obtener mensajes desde DB local
                        try {
                          final localDs = LocalMessageDataSource();
                          final localList = await localDs.getMessages(convId);
                          if (localList.isNotEmpty) {
                            final serializedLocal = localList.map((m) => m.toJson()).toList();
                            Navigator.push(context, MaterialPageRoute(builder: (_) => MessagePage(conversationId: convId, title: conversation.title ?? 'Conversación', initialMessages: serializedLocal)));
                            return;
                          }
                        } catch (_) {
                          // continue to remote fetch
                        }

                        // 2) Si no hay local, pedir historial al servidor
                        try {
                          final remote = MessageRemoteDataSourceImpl();
                          final authState = context.read<AuthBloc>().state;
                          final token = (authState is AuthAuthenticatedState) ? authState.user.token : '';
                          final msgs = await remote.getMessages(token: token, conversationId: convId);
                          final serialized = msgs.map((m) => m.toJson()).toList();
                          // Guardar localmente para futuras entradas (solo texto/sender/created_at)
                          try {
                            SessionManager().messagesByConversation[convId] = serialized.map((e) => {'text': e['content'] ?? e['message'] ?? '', 'sender': e['sender'] ?? '', 'created_at': e['created_at'] ?? ''}).toList();
                          } catch (_) {}
                          Navigator.push(context, MaterialPageRoute(builder: (_) => MessagePage(conversationId: convId, title: conversation.title ?? 'Conversación', initialMessages: serialized)));
                        } catch (_) {
                          // Si falla la petición remota, abrir con lo que pueda
                          Navigator.push(context, MaterialPageRoute(builder: (_) => MessagePage(conversationId: convId, title: conversation.title ?? 'Conversación', initialMessages: conversation.messages?.map((m) => m.toJson()).toList())));
                        }
                      },
                    ),
                  ),
                );
              },
            );
          } else if (state is ConversationErrorState) {
            return Center(child: Text('Error: ${state.message}'));
          }
          return const SizedBox.shrink();
          },
        ),
      ),
    floatingActionButton: _NewConversationFab(type: widget.type),
    );
  }
}

class _NewConversationFab extends StatelessWidget {
  final String type;
  const _NewConversationFab({required this.type});

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton(
      tooltip: 'Nueva conversación',
      child: const Icon(Icons.add),
      onPressed: () async {
        final titleController = TextEditingController();
        final result = await showDialog<String>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Nueva conversación'),
            content: TextField(
              controller: titleController,
              decoration: const InputDecoration(
                labelText: 'Título',
                border: OutlineInputBorder(),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Cancelar'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(ctx, titleController.text.trim()),
                child: const Text('Crear'),
              ),
            ],
          ),
        );

        if (result != null && result.isNotEmpty) {
          final authState = context.read<AuthBloc>().state;
          if (authState is AuthAuthenticatedState) {
            final token = authState.user.token;
            final userId = authState.user.id;
            context.read<ConversationBloc>().add(
              CreateConversationEvent(token: token, userId: userId, title: result),
            );
          } else {
            // anonymous creation: pass empty token/userId; server will create an anonymous conversation and return session_token
            context.read<ConversationBloc>().add(
              CreateConversationEvent(token: '', userId: '', title: result),
            );
          }
        }
      },
    );
  }
}