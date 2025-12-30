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
        appBar: AppBar(
          title: const Row(
            children: [
              Icon(Icons.scale, size: 24),
              SizedBox(width: 8),
              Text('Atención al Cliente'),
            ],
          ),
          backgroundColor: const Color(0xFF1565C0),
        ),
        body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [const Color(0xFF1565C0).withOpacity(0.05), Colors.white],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Icon(
                  Icons.scale,
                  size: 100,
                  color: const Color(0xFF1565C0).withOpacity(0.7),
                ),
                const SizedBox(height: 24),
                const Text(
                  'Balanzas Electrónicas',
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1565C0),
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                const Text(
                  'Sistema de Atención y Soporte',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.black54,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 48),
                _RoleCard(
                  title: 'Iniciar Consulta',
                  icon: Icons.chat,
                  color: const Color(0xFF1565C0),
                  onTap: () => _openList(context, 'general'),
                ),
              ],
            ),
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
          appBar: AppBar(
            elevation: 0,
            flexibleSpace: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF1565C0), Color(0xFF1976D2)], // Azul corporativo
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
            ),
            title: const Row(
              children: [
                Icon(Icons.scale, size: 24), // Icono de balanza
                SizedBox(width: 8),
                Text('Centro de Atención'),
              ],
            ),
          ),
          body: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [const Color(0xFF1565C0).withOpacity(0.03), Colors.white],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'Selecciona el tipo de atención',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 20),
                  _RoleCard(
                    title: 'Consultas Generales',
                    icon: Icons.help_outline,
                    color: const Color(0xFF455A64),
                    onTap: () => _openList(context, 'general'),
                  ),
                  const SizedBox(height: 12),
                  // Mostrar técnico si tiene el rol tecnico
                  if (hasTecnico) ...[
                    _RoleCard(
                      title: 'Soporte Técnico',
                      icon: Icons.engineering,
                      color: const Color(0xFF1565C0),
                      onTap: () => _openList(context, 'tecnico'),
                    ),
                    const SizedBox(height: 12),
                  ],
                  // Mostrar ventas si tiene el rol sales
                  if (hasSales) ...[
                    _RoleCard(
                      title: 'Ventas y Marketing',
                      icon: Icons.video_library,
                      color: const Color(0xFF2E7D32),
                      onTap: () => _openList(context, 'sales'),
                    ),
                    const SizedBox(height: 12),
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
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 3,
      shadowColor: color.withOpacity(0.3),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: LinearGradient(
              colors: [color.withOpacity(0.1), Colors.white],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            leading: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 28),
            ),
            title: Text(
              title,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            trailing: Icon(Icons.arrow_forward_ios, color: color, size: 18),
          ),
        ),
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
          // Store conversation id/session token in SessionManager
          try {
            SessionManager().conversationId = state.conversation.id;
            if (state.conversation.sessionToken != null && state.conversation.sessionToken!.isNotEmpty) {
              SessionManager().sessionToken = state.conversation.sessionToken;
            }
          } catch (_) {}
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
          elevation: 0,
          flexibleSpace: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [_getColorByType(widget.type), _getColorByType(widget.type).withOpacity(0.7)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),
          title: Row(
            children: [
              Icon(_getIconByType(widget.type), size: 24),
              const SizedBox(width: 8),
              Text('Conversaciones ${_getTypeName(widget.type)}'),
            ],
          ),
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
            if (convs.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.inbox_outlined,
                      size: 80,
                      color: Colors.grey[300],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Sin conversaciones activas',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Presiona + para iniciar una nueva atención',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[500],
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              );
            }
              // Debug: imprimir títulos para verificar contenido
              try {
                // ignore: avoid_print
                print('[DEBUG] ConversationListPage titles: ${convs.map((c) => c.title).toList()}');
              } catch (_) {}
            return ListView.builder(
              padding: const EdgeInsets.all(8.0),
              itemCount: convs.length,
              itemBuilder: (ctx, i) {
                final c = convs[i];
                String formatDate(DateTime? dt) {
                  if (dt == null) return '';
                  try {
                    final local = dt.toLocal();
                    final now = DateTime.now();
                    final difference = now.difference(local);
                    
                    if (difference.inDays == 0) {
                      final hh = local.hour.toString().padLeft(2, '0');
                      final mm = local.minute.toString().padLeft(2, '0');
                      return 'Hoy $hh:$mm';
                    } else if (difference.inDays == 1) {
                      return 'Ayer';
                    } else if (difference.inDays < 7) {
                      return '${difference.inDays} días';
                    } else {
                      final d = local.day.toString().padLeft(2, '0');
                      final m = local.month.toString().padLeft(2, '0');
                      return '$d/$m/${local.year}';
                    }
                  } catch (_) {
                    return '';
                  }
                }

                final subtitle = (c.createdAt != null && (c.createdAt is DateTime))
                    ? formatDate(c.createdAt)
                    : 'Nueva conversación';

                final pushTitle = (c.title != null && c.title!.isNotEmpty) ? c.title! : (c.createdAt != null ? formatDate(c.createdAt) : 'Chat');

                try {
                  // ignore: avoid_print
                  print('[DEBUG] ConversationListItem id=${c.id} title=${c.title}');
                } catch (_) {}
                return Dismissible(
                  key: Key(c.id),
                  direction: DismissDirection.endToStart,
                  background: Container(
                    margin: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 8.0),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Colors.red, Colors.redAccent],
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.only(right: 24.0),
                    child: const Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.delete_forever, color: Colors.white, size: 32),
                        SizedBox(height: 4),
                        Text(
                          'Eliminar',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  confirmDismiss: (direction) async {
                    return await showDialog<bool>(
                      context: ctx,
                      builder: (BuildContext context) {
                        return AlertDialog(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          icon: const Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 48),
                          title: const Text(
                            'Confirmar eliminación',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          content: Text(
                            '¿Estás seguro de que deseas eliminar "${c.title ?? 'Sin título'}"?\n\nEsta acción no se puede deshacer.',
                            textAlign: TextAlign.center,
                          ),
                          actions: <Widget>[
                            TextButton(
                              onPressed: () => Navigator.of(context).pop(false),
                              child: const Text('Cancelar'),
                            ),
                            ElevatedButton(
                              onPressed: () => Navigator.of(context).pop(true),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.red,
                                foregroundColor: Colors.white,
                              ),
                              child: const Text('Eliminar'),
                            ),
                          ],
                        );
                      },
                    );
                  },
                  onDismissed: (direction) {
                    // Obtener token del AuthBloc si el usuario está autenticado
                    final authState = context.read<AuthBloc>().state;
                    String token = '';
                    if (authState is AuthAuthenticatedState) {
                      token = authState.user.token;
                    }
                    
                    context.read<ConversationBloc>().add(
                      DeleteConversationEvent(
                        conversationId: c.id,
                        token: token,
                        sessionToken: c.sessionToken,
                      ),
                    );
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Row(
                          children: [
                            const Icon(Icons.check_circle, color: Colors.white),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text('Conversación "${c.title ?? 'Sin título'}" eliminada'),
                            ),
                          ],
                        ),
                        backgroundColor: Colors.green,
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    );
                  },
                  child: Card(
                    margin: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 8.0),
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      leading: CircleAvatar(
                        radius: 28,
                        backgroundColor: _getColorByType(widget.type),
                        child: Icon(
                          _getIconByType(widget.type),
                          color: Colors.white,
                          size: 28,
                        ),
                      ),
                      title: Text(
                        (c.title != null && c.title!.isNotEmpty) ? c.title! : 'Sin Título',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      subtitle: Padding(
                        padding: const EdgeInsets.only(top: 4.0),
                        child: Row(
                          children: [
                            const Icon(Icons.access_time, size: 14, color: Colors.grey),
                            const SizedBox(width: 4),
                            Text(
                              subtitle,
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      ),
                      trailing: const Icon(Icons.chevron_right, color: Colors.grey),
                      onTap: () {
                        try {
                          // debug print on tap
                          try { print('[DEBUG] Opening conversation id=${c.id} sessionToken=${c.sessionToken} type=${c.type}'); } catch (_) {}
                          // Ensure SessionManager has conversation id and session token
                          try {
                            SessionManager().conversationId = c.id;
                            if (c.sessionToken != null && c.sessionToken!.isNotEmpty) SessionManager().sessionToken = c.sessionToken;
                          } catch (_) {}
                          Navigator.push(
                            ctx,
                            MaterialPageRoute(
                              builder: (_) => MessagePage(conversationId: c.id, title: pushTitle),
                            ),
                          );
                        } catch (e) {
                          // Mostrar snackbar con detalle para ayudar a depurar en tiempo de ejecución
                          try {
                            ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(content: Text('Error al abrir chat: ${e.toString()}')));
                          } catch (_) {}
                        }
                      },
                    ),
                  ),
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

  // Helper para obtener color según tipo de conversación
  Color _getColorByType(String type) {
    switch (type.toLowerCase()) {
      case 'tecnico':
        return const Color(0xFF1565C0); // Azul corporativo oscuro
      case 'sales':
        return const Color(0xFF2E7D32); // Verde profesional
      case 'user':
        return const Color(0xFF6A1B9A); // Morado corporativo
      case 'general':
      case 'anonymous':
      case 'anonimo':
        return const Color(0xFF455A64); // Gris azulado profesional
      default:
        return Colors.grey;
    }
  }

  // Helper para obtener icono según tipo de conversación
  IconData _getIconByType(String type) {
    switch (type.toLowerCase()) {
      case 'tecnico':
        return Icons.build_circle; // Soporte técnico de equipos
      case 'sales':
        return Icons.campaign; // Marketing y material promocional
      case 'user':
        return Icons.business; // Clientes corporativos
      case 'general':
      case 'anonymous':
      case 'anonimo':
        return Icons.help_center; // Consultas generales
      default:
        return Icons.forum;
    }
  }

  // Helper para obtener nombre legible del tipo
  String _getTypeName(String type) {
    switch (type.toLowerCase()) {
      case 'tecnico':
        return 'Soporte Técnico';
      case 'sales':
        return 'Ventas y Marketing';
      case 'user':
        return 'Clientes';
      case 'general':
      case 'anonymous':
      case 'anonimo':
        return 'Consultas';
      default:
        return type;
    }
  }
}

// FAB compacto con validación de roles antes de crear conversación
class _NewConversationFab extends StatelessWidget {
  final String type;
  const _NewConversationFab({required this.type});

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton.extended(
      tooltip: 'Nueva atención',
      icon: const Icon(Icons.add_box),
      label: const Text('Nueva'),
      backgroundColor: const Color(0xFF1565C0),
      onPressed: () async {
        final titleController = TextEditingController();
        final result = await showDialog<String>(
          context: context,
          builder: (ctx) => AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            icon: const Icon(Icons.assignment, color: Color(0xFF1565C0), size: 48),
            title: const Text(
              'Nueva Atención',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            content: TextField(
              controller: titleController,
              decoration: InputDecoration(
                labelText: 'Asunto',
                hintText: type == 'sales' 
                    ? 'Ej: Solicitar catálogo de productos'
                    : 'Ej: Calibración balanza modelo XYZ',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                prefixIcon: const Icon(Icons.description),
              ),
              autofocus: true,
              textCapitalization: TextCapitalization.sentences,
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Cancelar'),
              ),
              ElevatedButton.icon(
                onPressed: () => Navigator.pop(ctx, titleController.text.trim()),
                icon: const Icon(Icons.check),
                label: const Text('Iniciar'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1565C0),
                ),
              ),
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