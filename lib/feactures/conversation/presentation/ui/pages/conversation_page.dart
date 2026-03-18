import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:message_service/feactures/auth/presentation/bloc/auth_bloc.dart';
import 'package:message_service/feactures/conversation/presentation/bloc/conversation_bloc.dart';
import 'package:message_service/feactures/auth/presentation/ui/pages/login_page.dart';
import 'package:message_service/core/session_manager.dart';
import 'package:message_service/feactures/message/presentation/ui/pages/message_page.dart';
import 'package:message_service/feactures/auth/data/datasources/user_login_data_sourse.dart';
import 'package:message_service/feactures/conversation/domain/entities/converstion_entity.dart';

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
    final bool hasDeveloper = roles.contains('developer');
    final bool hasSales = roles.contains('sales') || hasDeveloper;
    final bool hasTecnico = roles.contains('tecnico') || hasDeveloper;
    final String userInitials = context.select<AuthBloc, String>((bloc) {
      final st = bloc.state;
      if (st is! AuthAuthenticatedState) return 'U';
      final fullName = st.user.fullName.trim();
      if (fullName.isEmpty) return 'U';
      final parts = fullName.split(RegExp(r'\s+')).where((e) => e.isNotEmpty).toList();
      if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
      return '${parts.first.substring(0, 1)}${parts.last.substring(0, 1)}'.toUpperCase();
    });

    // Usuario no autenticado: solo tarjeta anonimo
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
                Image.asset(
                  'assets/images/logo.png',
                  height: MediaQuery.of(context).size.height * 0.25,
                  fit: BoxFit.contain,
                ),
                SizedBox(height: MediaQuery.of(context).size.height * 0.03),
                Text(
                  'Balanzas Hook',
                  style: TextStyle(
                    fontSize: MediaQuery.of(context).size.height * 0.03,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1565C0),
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: MediaQuery.of(context).size.height * 0.015),
                Text(
                  'Sistema de Atención y Soporte',
                  style: TextStyle(
                    fontSize: MediaQuery.of(context).size.height * 0.02,
                    color: Colors.black54,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 48),
                _RoleCard(
                  title: 'Iniciar Consulta',
                  subtitle: 'Consulta rápida sin iniciar sesión',
                  icon: Icons.chat,
                  color: const Color(0xFF1565C0),
                  onTap: () => _openList(context, 'anonimo'),
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
            if (state is AuthInitialState) {
              Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => Login()));
            }
          },
        ),
      ],
      child: Builder(builder: (context) {
        return Scaffold(
          backgroundColor: const Color(0xFFF7F9FD),
          appBar: AppBar(
            backgroundColor: Colors.white,
            elevation: 0,
            scrolledUnderElevation: 0,
            titleSpacing: 16,
            title: const Text(
              'Centro de Atención',
              style: TextStyle(
                color: Color(0xFF0F172A),
                fontWeight: FontWeight.w700,
                fontSize: 20,
              ),
            ),
            actions: [
              PopupMenuButton<String>(
                tooltip: 'Opciones de cuenta',
                onSelected: (value) {
                  if (value == 'logout') {
                    _logout(context);
                  }
                },
                itemBuilder: (context) => const [
                  PopupMenuItem<String>(
                    value: 'logout',
                    child: Row(
                      children: [
                        Icon(Icons.logout, size: 18),
                        SizedBox(width: 8),
                        Text('Cerrar sesión'),
                      ],
                    ),
                  ),
                ],
                child: Container(
                  margin: const EdgeInsets.only(right: 14),
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: const Color(0xFF2454F2),
                    borderRadius: BorderRadius.circular(9),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    userInitials,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 11,
                    ),
                  ),
                ),
              ),
            ],
          ),
          body: Container(
            color: const Color(0xFFF7F9FD),
            child: Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(16, 18, 16, 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          '¿En qué podemos\nayudarte hoy?',
                          style: TextStyle(
                            fontSize: 34,
                            height: 1.05,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF0F172A),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Seleccioná el tipo de consulta',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: Colors.grey.shade500,
                          ),
                        ),
                        const SizedBox(height: 18),
                        Text(
                          'CANALES DISPONIBLES',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: Colors.grey.shade500,
                            letterSpacing: 1.6,
                          ),
                        ),
                        const SizedBox(height: 10),
                        _RoleCard(
                          title: 'Consultas Generales',
                          subtitle: 'Información y dudas del sistema',
                          icon: Icons.info,
                          color: const Color(0xFF2454F2),
                          onTap: () => _openList(context, 'anonimo'),
                        ),
                        const SizedBox(height: 10),
                        if (hasTecnico) ...[
                          _RoleCard(
                            title: 'Soporte Técnico',
                            subtitle: 'Resolución de errores y fallas',
                            icon: Icons.build,
                            color: const Color(0xFF0FA48D),
                            onTap: () => _openList(context, 'tecnico'),
                          ),
                          const SizedBox(height: 10),
                        ],
                        if (hasSales) ...[
                          _RoleCard(
                            title: 'Ventas y Marketing',
                            subtitle: 'Catálogo, precios y propuestas',
                            icon: Icons.trending_up,
                            color: const Color(0xFFD97706),
                            onTap: () => _openList(context, 'sales'),
                          ),
                          const SizedBox(height: 10),
                        ],
                        if (hasDeveloper) ...[
                          _RoleCard(
                            title: 'Soporte Developer',
                            subtitle: 'APIs, integración y desarrollo',
                            icon: Icons.developer_mode,
                            color: const Color(0xFF6A1B9A),
                            onTap: () => _openList(context, 'developer'),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  decoration: const BoxDecoration(
                    color: Color(0xFFF8FAFC),
                    border: Border(top: BorderSide(color: Color(0xFFE5E7EB))),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        decoration: const BoxDecoration(
                          color: Color(0xFF0FA48D),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Asistentes con IA · Disponible 24/7',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade500,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
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

  Future<void> _logout(BuildContext context) async {
    final authState = context.read<AuthBloc>().state;
    String? token;

    if (authState is AuthAuthenticatedState) {
      token = authState.user.token;
    }

    if (token != null && token.isNotEmpty) {
      try {
        final dataSource = UserLoginDataSourceImpl();
        await dataSource.logOut(token);
      } catch (_) {}
    }

    context.read<AuthBloc>().add(AuthLogoutEvent());

    if (context.mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const Login()),
      );
    }
  }
}

class _RoleCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  const _RoleCard({required this.title, required this.subtitle, required this.icon, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          decoration: BoxDecoration(
            color: color.withOpacity(0.07),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: color.withOpacity(0.28), width: 1),
          ),
          child: IntrinsicHeight(
            child: Row(
              children: [
                Container(
                  width: 4,
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(12),
                      bottomLeft: Radius.circular(12),
                    ),
                  ),
                ),
                Expanded(
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    leading: Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      alignment: Alignment.center,
                      child: Icon(icon, color: color, size: 18),
                    ),
                    title: Text(
                      title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF1F2937),
                      ),
                    ),
                    subtitle: Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    trailing: Icon(Icons.chevron_right, color: Colors.grey.shade400, size: 20),
                  ),
                ),
              ],
            ),
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
  String? _selectedConversationId;

  @override
  void initState() {
    super.initState();
    // Cargar conversaciones del tipo solicitado después del primer frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authState = context.read<AuthBloc>().state;
      String token = '';
      if (authState is AuthAuthenticatedState) {
        token = authState.user.token;
      }
      if (token.isEmpty) {
        token = SessionManager().sessionToken ?? '';
      }
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

          // Mostrar confirmación (snackbar) al crear la conversación
          try {
            final title = state.conversation.title ?? 'Conversación';
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Row(
                  children: [
                    const Icon(Icons.check_circle, color: Colors.white),
                    const SizedBox(width: 12),
                    Expanded(child: Text('"$title" creada correctamente')),
                  ],
                ),
                backgroundColor: Colors.green,
                behavior: SnackBarBehavior.floating,
              ),
            );
          } catch (_) {}

          // Navegar automáticamente a MessagePage cuando se crea una conversación
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => MessagePage(
                conversationId: state.conversation.id,
                title: state.conversation.title ?? 'Chat',
                conversationType: widget.type,
              ),
            ),
          );
        }

        if (state is ConversationErrorState) {
          final msg = state.message.isNotEmpty ? state.message : 'Error de conexión';
          try {
            ScaffoldMessenger.of(context)
              ..hideCurrentSnackBar()
              ..showSnackBar(SnackBar(content: Text(msg), backgroundColor: Colors.red));
          } catch (_) {}
        }
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFF3F5F9),
        appBar: AppBar(
          backgroundColor: const Color(0xFFF3F5F9),
          elevation: 0,
          scrolledUnderElevation: 0,
          automaticallyImplyLeading: false,
          titleSpacing: 0,
          title: Padding(
            padding: const EdgeInsets.only(left: 16),
            child: Row(
              children: [
                InkWell(
                  borderRadius: BorderRadius.circular(10),
                  onTap: () => Navigator.of(context).pop(),
                  child: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: const Color(0xFFEFF2F7),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFFD8DEE9)),
                    ),
                    child: const Icon(Icons.chevron_left, size: 20, color: Color(0xFF6B7280)),
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  'Inicio',
                  style: TextStyle(
                    color: Colors.grey.shade500,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          actions: [
            if (widget.type == 'anonimo' && !isAuthenticated)
              TextButton(
                onPressed: () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => Login())),
                child: const Text('Iniciar sesión', style: TextStyle(color: Color(0xFF2454F2))),
              ),
            const SizedBox(width: 8),
          ],
        ),
        body: BlocBuilder<ConversationBloc, ConversationState>(
          builder: (context, state) {
            if (state is ConversationLoadingState) {
              return const Center(child: CircularProgressIndicator());
            }

            if (state is ConversationErrorState) {
              return Center(child: Text('Error: ${state.message}'));
            }

            if (state is! ConversationLoadedState) {
              return const SizedBox.shrink();
            }

            final convs = state.conversations;
            final baseColor = _getColorByType(widget.type);

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 6, 20, 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              _getTypeName(widget.type),
                              style: const TextStyle(
                                fontSize: 34,
                                height: 1.05,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF0F172A),
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: baseColor.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(999),
                              border: Border.all(color: baseColor.withOpacity(0.35)),
                            ),
                            child: Text(
                              'Activo',
                              style: TextStyle(
                                color: baseColor,
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '${convs.length} conversaciones · ${_assistantNameByType(widget.type)}',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey.shade600,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                if (convs.isEmpty)
                  Expanded(
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.inbox_outlined, size: 74, color: Colors.grey[350]),
                          const SizedBox(height: 14),
                          Text(
                            'Sin conversaciones activas',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: Colors.grey[700],
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Pulsa + Nueva para iniciar una atención',
                            style: TextStyle(fontSize: 13, color: Colors.grey[500]),
                          ),
                        ],
                      ),
                    ),
                  )
                else
                  Expanded(
                    child: ListView.separated(
                      padding: const EdgeInsets.fromLTRB(16, 2, 16, 90),
                      itemCount: convs.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 8),
                      itemBuilder: (ctx, i) {
                        final c = convs[i];
                        final bool isSelected = _selectedConversationId == c.id;
                        final String title = (c.title != null && c.title!.trim().isNotEmpty)
                            ? c.title!.trim()
                            : 'Sin título';
                        final String detail = _extractConversationPreview(c);
                        final String timeLabel = _formatRelativeDate(c.createdAt);
                        final String chipLabel = _buildConversationChip(c, widget.type);
                        final String pushTitle = (c.title != null && c.title!.isNotEmpty)
                            ? c.title!
                            : (c.createdAt != null ? _formatRelativeDate(c.createdAt) : 'Chat');

                        return Dismissible(
                          key: Key(c.id),
                          direction: DismissDirection.endToStart,
                          background: Container(
                            decoration: BoxDecoration(
                              color: Colors.red,
                              borderRadius: BorderRadius.circular(14),
                            ),
                            alignment: Alignment.centerRight,
                            padding: const EdgeInsets.only(right: 22),
                            child: const Icon(Icons.delete_outline, color: Colors.white, size: 28),
                          ),
                          confirmDismiss: (direction) async {
                            return await showDialog<bool>(
                              context: ctx,
                              builder: (BuildContext context) {
                                return AlertDialog(
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                  icon: const Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 48),
                                  title: const Text('Confirmar eliminación', style: TextStyle(fontWeight: FontWeight.bold)),
                                  content: Text(
                                    '¿Estás seguro de que deseas eliminar "${c.title ?? 'Sin título'}"?\n\nEsta acción no se puede deshacer.',
                                    textAlign: TextAlign.center,
                                  ),
                                  actions: <Widget>[
                                    TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Cancelar')),
                                    ElevatedButton(
                                      onPressed: () => Navigator.of(context).pop(true),
                                      style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
                                      child: const Text('Eliminar'),
                                    ),
                                  ],
                                );
                              },
                            );
                          },
                          onDismissed: (direction) {
                            final authStateNow = context.read<AuthBloc>().state;
                            String token = '';
                            if (authStateNow is AuthAuthenticatedState) {
                              token = authStateNow.user.token;
                            }

                            if (_selectedConversationId == c.id) {
                              setState(() {
                                _selectedConversationId = null;
                              });
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
                                content: Text('Conversación "${c.title ?? 'Sin título'}" eliminada'),
                                backgroundColor: Colors.green,
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                          },
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              borderRadius: BorderRadius.circular(14),
                              onTap: () {
                                try {
                                  setState(() {
                                    _selectedConversationId = c.id;
                                  });
                                  SessionManager().conversationId = c.id;
                                  if (c.sessionToken != null && c.sessionToken!.isNotEmpty) {
                                    SessionManager().sessionToken = c.sessionToken;
                                  }
                                  Navigator.push(
                                    ctx,
                                    MaterialPageRoute(
                                      builder: (_) => MessagePage(
                                        conversationId: c.id,
                                        title: pushTitle,
                                        conversationType: widget.type,
                                      ),
                                    ),
                                  );
                                } catch (e) {
                                  ScaffoldMessenger.of(ctx).showSnackBar(
                                    SnackBar(content: Text('Error al abrir chat: ${e.toString()}')),
                                  );
                                }
                              },
                              child: Container(
                                decoration: BoxDecoration(
                                  color: isSelected ? baseColor.withOpacity(0.08) : Colors.white.withOpacity(0.66),
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(
                                    color: isSelected ? baseColor.withOpacity(0.48) : const Color(0xFFDCE2EC),
                                  ),
                                ),
                                child: IntrinsicHeight(
                                  child: Row(
                                    children: [
                                      if (isSelected)
                                        Container(
                                          width: 3,
                                          decoration: BoxDecoration(
                                            color: const Color(0xFF2454F2),
                                            borderRadius: const BorderRadius.only(
                                              topLeft: Radius.circular(14),
                                              bottomLeft: Radius.circular(14),
                                            ),
                                          ),
                                        ),
                                      Expanded(
                                        child: Padding(
                                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                                          child: Row(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Container(
                                                width: 38,
                                                height: 38,
                                                decoration: BoxDecoration(
                                                  color: baseColor.withOpacity(0.1),
                                                  borderRadius: BorderRadius.circular(10),
                                                  border: Border.all(color: baseColor.withOpacity(0.2)),
                                                ),
                                                alignment: Alignment.center,
                                                child: Icon(_getIconByType(widget.type), color: baseColor, size: 18),
                                              ),
                                              const SizedBox(width: 10),
                                              Expanded(
                                                child: Column(
                                                  crossAxisAlignment: CrossAxisAlignment.start,
                                                  children: [
                                                    Row(
                                                      children: [
                                                        Expanded(
                                                          child: Text(
                                                            title,
                                                            maxLines: 1,
                                                            overflow: TextOverflow.ellipsis,
                                                            style: const TextStyle(
                                                              fontSize: 15,
                                                              fontWeight: FontWeight.w700,
                                                              color: Color(0xFF1F2937),
                                                            ),
                                                          ),
                                                        ),
                                                        const SizedBox(width: 8),
                                                        Text(
                                                          timeLabel,
                                                          style: TextStyle(
                                                            fontSize: 11,
                                                            color: Colors.grey.shade500,
                                                            fontWeight: FontWeight.w500,
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                    const SizedBox(height: 2),
                                                    Text(
                                                      detail,
                                                      maxLines: 1,
                                                      overflow: TextOverflow.ellipsis,
                                                      style: TextStyle(
                                                        fontSize: 12,
                                                        color: Colors.grey.shade600,
                                                        fontWeight: FontWeight.w500,
                                                      ),
                                                    ),
                                                    const SizedBox(height: 6),
                                                    Container(
                                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                                      decoration: BoxDecoration(
                                                        color: const Color(0xFFF1F5F9),
                                                        borderRadius: BorderRadius.circular(6),
                                                        border: Border.all(color: const Color(0xFFE2E8F0)),
                                                      ),
                                                      child: Text(
                                                        chipLabel,
                                                        style: TextStyle(
                                                          fontSize: 10,
                                                          color: Colors.grey.shade600,
                                                          fontWeight: FontWeight.w600,
                                                        ),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
              ],
            );
          },
        ),
        floatingActionButton: _NewConversationFab(type: widget.type),
      ),
    );
  }

  String _formatRelativeDate(DateTime? dt) {
    if (dt == null) return 'sin fecha';
    try {
      final local = dt.toLocal();
      final now = DateTime.now();
      final difference = now.difference(local);
      if (difference.inDays > 0) {
        return 'hace ${difference.inDays} días';
      }
      if (difference.inHours > 0) {
        return 'hace ${difference.inHours} h';
      }
      if (difference.inMinutes > 0) {
        return 'hace ${difference.inMinutes} min';
      }
      return 'recién';
    } catch (_) {
      return 'sin fecha';
    }
  }

  String _assistantNameByType(String type) {
    switch (type.toLowerCase()) {
      case 'tecnico':
        return 'Asistente Técnico';
      case 'developer':
        return 'Asistente Dev';
      case 'sales':
        return 'Asistente Comercial';
      case 'anonimo':
        return 'Asistente General';
      default:
        return 'Asistente';
    }
  }

  String _contextChipByType(String type) {
    switch (type.toLowerCase()) {
      case 'tecnico':
        return 'TCP/IP - Puerto 5900';
      case 'developer':
        return 'Debug · API';
      case 'sales':
        return 'Propuesta comercial';
      case 'anonimo':
        return 'Consulta general';
      default:
        return 'Atención';
    }
  }

  String _buildConversationChip(ConversationEntity conversation, String type) {
    final firstUserMessage = _firstUserMessage(conversation);
    final title = (conversation.title ?? '').trim();
    final source = '$title $firstUserMessage'.trim();

    if (source.isNotEmpty) {
      final tokens = source
          .split(RegExp(r"[^A-Za-z0-9ÁÉÍÓÚáéíóúÑñ]+"))
          .map((w) => w.trim())
          .where((w) => w.length >= 3)
          .toList();

      final weighted = <String, int>{};
      for (final token in tokens) {
        if (_isStopWord(token)) continue;
        final key = _normalizeToken(token);
        if (key.isEmpty) continue;

        int score = weighted[key] ?? 0;
        score += 1;
        score += token.length >= 7 ? 1 : 0;
        if (RegExp(r'\d').hasMatch(token)) score += 3;
        if (_isTechnicalWord(key)) score += 3;
        weighted[key] = score;
      }

      if (weighted.isNotEmpty) {
        final sorted = weighted.entries.toList()
          ..sort((a, b) => b.value.compareTo(a.value));
        final selected = sorted.take(2).map((e) => _toTitle(e.key)).toList();
        final chip = selected.join(' · ');
        if (chip.isNotEmpty) return _trimChip(chip);
      }

      final fallbackWords = tokens.where((w) => !_isStopWord(w)).take(2).map(_toTitle).toList();
      if (fallbackWords.isNotEmpty) {
        return _trimChip(fallbackWords.join(' · '));
      }
    }

    return _contextChipByType(type);
  }

  String _firstUserMessage(ConversationEntity conversation) {
    final msgs = conversation.messages ?? const [];
    for (final m in msgs) {
      final sender = m.sender.toLowerCase().trim();
      final content = m.content.trim();
      if (content.isEmpty) continue;
      if (sender == 'user' || sender == 'local') return content;
    }
    for (final m in msgs) {
      final content = m.content.trim();
      if (content.isNotEmpty) return content;
    }
    return '';
  }

  bool _isStopWord(String word) {
    const stopWords = {
      'de', 'la', 'el', 'los', 'las', 'del', 'que', 'con', 'para', 'por', 'una', 'uno', 'unos', 'unas',
      'como', 'sin', 'sobre', 'entre', 'desde', 'hasta', 'muy', 'mas', 'más', 'hola', 'buenas', 'quiero',
      'necesito', 'tengo', 'ayuda', 'favor', 'buen', 'dia', 'días', 'hoy', 'ayer'
    };
    return stopWords.contains(_normalizeToken(word));
  }

  bool _isTechnicalWord(String normalizedWord) {
    const technical = {
      'wifi', 'tcp', 'ip', 'puerto', 'impresora', 'balanza', 'ticket', 'tickets', 'sincronizacion',
      'servidor', 'conexion', 'conectividad', 'api', 'token', 'login', 'error', 'calibracion',
      'firmware', 'catalogo', 'precio', 'precios', 'ventas', 'marketing', 'stock', 'n8n'
    };
    return technical.contains(normalizedWord);
  }

  String _normalizeToken(String value) {
    var v = value.toLowerCase().trim();
    const replace = {
      'á': 'a',
      'é': 'e',
      'í': 'i',
      'ó': 'o',
      'ú': 'u',
      'ñ': 'n',
    };
    replace.forEach((k, val) {
      v = v.replaceAll(k, val);
    });
    return v;
  }

  String _toTitle(String value) {
    if (value.isEmpty) return value;
    final lower = value.toLowerCase();
    return lower[0].toUpperCase() + lower.substring(1);
  }

  String _trimChip(String value) {
    final clean = value.trim();
    if (clean.length <= 24) return clean;
    return '${clean.substring(0, 24).trimRight()}...';
  }

  String _extractConversationPreview(ConversationEntity conversation) {
    final msgs = conversation.messages ?? const [];

    if (msgs.isNotEmpty) {
      for (final m in msgs) {
        final sender = m.sender.toLowerCase().trim();
        final content = m.content.trim();
        if (content.isEmpty) continue;
        if (sender == 'user' || sender == 'local') {
          return _trimPreview(content);
        }
      }

      for (final m in msgs) {
        final content = m.content.trim();
        if (content.isNotEmpty) {
          return _trimPreview(content);
        }
      }
    }

    return 'Sin vista previa';
  }

  String _trimPreview(String text) {
    if (text.length <= 48) return text;
    return '${text.substring(0, 48).trimRight()}...';
  }

  // Helper para obtener color según tipo de conversación
  Color _getColorByType(String type) {
    switch (type.toLowerCase()) {
      case 'tecnico':
        return const Color(0xFF0FA48D); // Verde/teal soporte técnico
      case 'developer':
        return const Color(0xFF6A1B9A); // Morado para developer
      case 'sales':
        return const Color(0xFFD97706); // Naranja ventas y marketing
      case 'anonimo':
        return const Color(0xFF2454F2); // Azul consultas generales
      default:
        return Colors.grey;
    }
  }

  // Helper para obtener icono según tipo de conversación
  IconData _getIconByType(String type) {
    switch (type.toLowerCase()) {
      case 'tecnico':
        return Icons.build; // Soporte técnico de equipos
      case 'developer':
        return Icons.developer_mode; // Icono para developer
      case 'sales':
        return Icons.trending_up; // Marketing y material promocional
      case 'anonimo':
        return Icons.info; // Consultas generales
      default:
        return Icons.forum;
    }
  }

  // Helper para obtener nombre legible del tipo
  String _getTypeName(String type) {
    switch (type.toLowerCase()) {
      case 'tecnico':
        return 'Soporte Técnico';
      case 'developer':
        return 'Developer';
      case 'sales':
        return 'Ventas y Marketing';
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
      icon: const Icon(Icons.add, size: 18),
      label: const Text(
        'Nueva',
        style: TextStyle(fontWeight: FontWeight.w700),
      ),
      backgroundColor: const Color(0xFF2454F2),
      foregroundColor: Colors.white,
      elevation: 10,
      extendedPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 2),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
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
          // Permitir 'anonimo' (conversación anónima) siempre, validar otros roles
          if (type != 'anonimo' && !user.hasRole(type)) {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('No tienes permisos para crear conversaciones de tipo "$type".')));
            return;
          }
          context.read<ConversationBloc>().add(CreateConversationEvent(token: user.token, userId: user.id, title: result, type: type));
        } else {
          if (type != 'anonimo') {
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
          // Para conversaciones anónimas, enviar title="", user="", type="anonimo"
          context.read<ConversationBloc>().add(CreateConversationEvent(token: '', userId: '', title: '', type: 'anonimo'));
        }
      },
    );
  }
}