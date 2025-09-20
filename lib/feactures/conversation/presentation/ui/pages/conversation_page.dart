import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:message_service/feactures/auth/presentation/bloc/auth_bloc.dart';
import 'package:message_service/feactures/conversation/presentation/bloc/conversation_bloc.dart';
import 'package:message_service/feactures/auth/presentation/ui/pages/login_page.dart';

// Página menú según rol (minimal y estable)
class ConversationPage extends StatelessWidget {
  const ConversationPage({super.key});

  @override
  Widget build(BuildContext context) {
    final authState = context.watch<AuthBloc>().state;

    // TODO(debug): temporal - imprimir role del usuario para depuración
    try {
      if (authState is AuthAuthenticatedState) {
        // imprimir solo en modo debug para no saturar logs en release
        // ignore: avoid_print
        print('[DEBUG] ConversationPage auth user role: "${authState.user.role}"');
      } else {
        // ignore: avoid_print
        print('[DEBUG] ConversationPage auth state: ${authState.runtimeType}');
      }
    } catch (e) {
      // ignore: avoid_print
      print('[DEBUG] ConversationPage error al leer authState: $e');
    }

    // Usuario no autenticado: solo tarjeta anonymous
    if (authState is! AuthAuthenticatedState) {
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
                onTap: () => _openList(context, 'anonymous'),
              ),
            ],
          ),
        ),
      );
    }

  // Usuario autenticado: mostrar tarjetas según roles
  final user = authState.user;

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
        // Sólo leer LO NECESARIO del AuthBloc: evita rebuilds por cambios irrelevantes
        final String? role = context.select<AuthBloc, String?>((bloc) {
          final s = bloc.state;
          return s is AuthAuthenticatedState ? s.user.role : null;
        });

        return Scaffold(
          appBar: AppBar(title: const Text('Conversaciones')),
          body: Column(
            children: [
              // UI condicional por role (reconstruye solo si cambia role)
              if (role != null && role.contains('sales')) ...[
                _RoleCard(
                  title: 'Conversaciones vendedores',
                  icon: Icons.storefront_outlined,
                  color: Colors.orange,
                  onTap: () => _openList(context, 'sales'),
                ),
                const SizedBox(height: 16),
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

class ConversationListPage extends StatelessWidget {
  final String type;
  const ConversationListPage({super.key, required this.type});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Lista de $type')),
      body: Center(child: Text('Aquí iría la lista de conversaciones de tipo "$type"')),
      floatingActionButton: _NewConversationFab(type: type),
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
          if (type != 'anonymous' && !user.hasRole(type)) {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('No tienes permisos para crear conversaciones de tipo "$type".')));
            return;
          }
          context.read<ConversationBloc>().add(CreateConversationEvent(token: user.token, userId: user.id, title: result, type: type));
        } else {
          if (type != 'anonymous') {
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
          context.read<ConversationBloc>().add(CreateConversationEvent(token: '', userId: '', title: result, type: 'anonymous'));
        }
      },
    );
  }
}