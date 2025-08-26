import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:message_service/feactures/auth/presentation/bloc/auth_bloc.dart';
import 'package:message_service/feactures/conversation/domain/entities/converstion_entity.dart';
import 'package:message_service/feactures/conversation/presentation/bloc/conversation_bloc.dart';
import 'package:message_service/feactures/message/presentation/ui/pages/message_page.dart';

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
            Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const MessagePage()));
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
              itemCount: conversations.length,
              itemBuilder: (context, index) {
                final conversation = conversations[index];
                return ListTile(
                  title: Text(conversation.title ?? 'Sin título'),
                  subtitle: Text('Tipo: ${widget.type}'),
                  onTap: () {},
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