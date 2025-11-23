import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:message_service/feactures/auth/presentation/bloc/auth_bloc.dart';
import 'package:message_service/feactures/conversation/presentation/bloc/conversation_bloc.dart';
import 'package:message_service/feactures/auth/presentation/ui/pages/login_page.dart';
import 'package:message_service/core/session_manager.dart';
import 'package:message_service/feactures/message/presentation/ui/pages/message_page.dart';

// Página menú según rol (minimal y estable)
class ConversationPage extends StatelessWidget {
  const ConversationPage({super.key});

  @override
  Widget build(BuildContext context) {
    final String? userRole = context.select<AuthBloc, String?>((bloc) {
      final st = bloc.state;
      if (st is AuthAuthenticatedState) return st.user.role; // ej "sales,tecnico" o "sales"
      return null;
    });

    final bool isAuthenticated = userRole != null;
    final roles = (userRole ?? '').split(',').map((s) => s.trim()).where((s) => s.isNotEmpty).toList();
    final bool hasSales = roles.contains('sales');
    final bool hasTecnico = roles.contains('tecnico');

    // TODO(debug): temporal - imprimir role del usuario para depuración
    try {
      if (isAuthenticated) {
        // imprimir solo en modo debug para no saturar logs en release
        // ignore: avoid_print
        print('[DEBUG] ConversationPage auth user role: "$userRole"');
      } else {
        // ignore: avoid_print
        print('[DEBUG] ConversationPage auth state: ${userRole.runtimeType}');
      }
    } catch (e) {
      // ignore: avoid_print
      print('[DEBUG] ConversationPage error al leer authState: $e');
    }

    // Usuario no autenticado: solo tarjeta anonymous
    if (!isAuthenticated) {
      return Scaffold(
        appBar: AppBar(title: const Text('Conversaciones')),
        body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _RoleCard(
                title: 'Conversaciones anónimas',
                icon: Icons.person_outline,
                color: Colors.grey,
                onTap: () => _openList(context, 'general'),
              ),
            ],
          ),
        ),
      );
    }

    // Usuario autenticado: mostrar tarjetas según roles

    return MultiBlocListener(
      listeners: [
        BlocListener<ConversationBloc, ConversationState>(
          listener: (context, state) {
            if (state is ConversationErrorState) {
              final msg = state.message.isNotEmpty ? state.message : 'Error de conexión';
              ScaffoldMessenger.of(context)
                ..hideCurrentSnackBar()
                ..showSnackBar(SnackBar(content: Text(msg), backgroundColor: Colors.red));
            }
          },
        ),
        BlocListener<AuthBloc, AuthState>(
          listener: (context, state) {
            if (state is AuthAuthenticatedState) {
              Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => Login()));
            }
          },
        ),
      ],
      child: Builder(builder: (context) {
        return Scaffold(
          appBar: AppBar(title: const Text('Conversaciones')),
          body: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _RoleCard(
                  title: 'Conversaciones anónimas',
                  icon: Icons.person_outline,
                  color: Colors.grey,
                  onTap: () => _openList(context, 'general'),
                ),
                const SizedBox(height: 16),
                // Mostrar técnico si tiene el rol tecnico
                if (hasTecnico) ...[
                  _RoleCard(
                    title: 'Conversaciones técnico',
                    icon: Icons.build_outlined,
                    color: Colors.deepPurple,
                    onTap: () => _openList(context, 'tecnico'),
                  ),
                  const SizedBox(height: 16),
                ],
                // Mostrar ventas si tiene el rol sales
                if (hasSales) ...[
                  _RoleCard(
                    title: 'Conversaciones vendedores',
                    icon: Icons.storefront_outlined,
                    color: Colors.orange,
                    onTap: () => _openList(context, 'sales'),
                  ),
                ],
                // Parte que depende del ConversationBloc: usar BlocBuilder
                Expanded(
                  child: BlocBuilder<ConversationBloc, ConversationState>(
                    builder: (context, convState) {
                      if (convState is ConversationLoadingState) return const Center(child: CircularProgressIndicator());
                      if (convState is ConversationLoadedState) return ListView(/*...*/);
                      if (convState is ConversationErrorState) return Center(child: Text('Error: ${convState.message}'));
                      return const SizedBox.shrink();
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      }),
    );
  }

  void _openList(BuildContext context, String type) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => ConversationListPage(type: type)));
  }
}

class _RoleCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  const _RoleCard({required this.title, required this.icon, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 2,
      child: ListTile(
        leading: CircleAvatar(backgroundColor: color.withOpacity(0.12), child: Icon(icon, color: color)),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}

class ConversationListPage extends StatefulWidget {
  final String type;
  const ConversationListPage({super.key, required this.type});

  @override
  State<ConversationListPage> createState() => _ConversationListPageState();
}

class _ConversationListPageState extends State<ConversationListPage> {
  @override
  void initState() {
    super.initState();
    // Cargar conversaciones del tipo solicitado después del primer frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final token = SessionManager().sessionToken ?? '';
      context.read<ConversationBloc>().add(LoadConversationsEvent(token: token, type: widget.type));
    });
  }

  @override
  Widget build(BuildContext context) {
    // Detectar si el usuario está autenticado para mostrar botón de login en anónimos
    final authState = context.read<AuthBloc>().state;
    final bool isAuthenticated = authState is AuthAuthenticatedState;

    return BlocListener<ConversationBloc, ConversationState>(
      listener: (context, state) {
        if (state is ConversationCreatedState) {
          // Navegar automáticamente a MessagePage cuando se crea una conversación
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => MessagePage(
                conversationId: state.conversation.id,
                title: state.conversation.title ?? 'Chat',
              ),
            ),
          );
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text('Lista de ${widget.type}'),
        actions: [
          // Si es lista anónima y no está autenticado, mostrar botón para ir al login
          if ((widget.type == 'anonymous' || widget.type == 'anonimo') && !isAuthenticated)
            TextButton(
              onPressed: () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => Login())),
              child: const Text('Iniciar sesión', style: TextStyle(color: Colors.white)),
            ),
        ],
      ),
      body: BlocBuilder<ConversationBloc, ConversationState>(
        builder: (context, state) {
          if (state is ConversationLoadingState) return const Center(child: CircularProgressIndicator());
          if (state is ConversationLoadedState) {
            final convs = state.conversations;
            if (convs.isEmpty) return Center(child: Text('No hay conversaciones de tipo "${widget.type}"'));
            return ListView.builder(
              itemCount: convs.length,
              itemBuilder: (ctx, i) {
                final c = convs[i];
                return ListTile(
                  title: Text(c.title ?? '(sin título)'),
                  subtitle: Text(c.id),
                  onTap: () {
                    try {
                      Navigator.push(
                        ctx,
                        MaterialPageRoute(
                          builder: (_) => MessagePage(conversationId: c.id, title: c.title ?? 'Chat'),
                        ),
                      );
                    } catch (e) {
                      // Mostrar snackbar con detalle para ayudar a depurar en tiempo de ejecución
                      try {
                        ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(content: Text('Error al abrir chat: ${e.toString()}')));
                      } catch (_) {}
                    }
                  },
                );
              },
            );
          }
          if (state is ConversationErrorState) return Center(child: Text('Error: ${state.message}'));
          return const SizedBox.shrink();
        },
      ),
        floatingActionButton: _NewConversationFab(type: widget.type),
      ),
    );
  }
}

// FAB compacto con validación de roles antes de crear conversación
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
            content: TextField(controller: titleController, decoration: const InputDecoration(labelText: 'Título')),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
              ElevatedButton(onPressed: () => Navigator.pop(ctx, titleController.text.trim()), child: const Text('Crear')),
            ],
          ),
        );

        if (result == null || result.isEmpty) return;

        final authState = context.read<AuthBloc>().state;
        if (authState is AuthAuthenticatedState) {
          final user = authState.user;
          // Permitir 'general' (conversación anónima) siempre, validar otros roles
          if (type != 'general' && type != 'anonimo' && !user.hasRole(type)) {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('No tienes permisos para crear conversaciones de tipo "$type".')));
            return;
          }
          context.read<ConversationBloc>().add(CreateConversationEvent(token: user.token, userId: user.id, title: result, type: type));
        } else {
          if (type != 'general' && type != 'anonymous') {
            final goLogin = await showDialog<bool>(
              context: context,
              builder: (ctx) => AlertDialog(
                title: const Text('Acceso restringido'),
                content: const Text('Debes iniciar sesión para crear o ver este tipo de conversaciones. ¿Ir al login?'),
                actions: [
                  TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
                  ElevatedButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Ir al login')),
                ],
              ),
            );
            if (goLogin == true) Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => Login()));
            return;
          }
          // Para conversaciones anónimas, enviar title="", user="", type="general"
          context.read<ConversationBloc>().add(CreateConversationEvent(token: '', userId: '', title: '', type: 'general'));
        }
      },
    );
  }
}