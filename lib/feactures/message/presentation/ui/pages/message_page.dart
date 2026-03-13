import 'dart:async';
import 'package:flutter/material.dart';
import 'package:message_service/feactures/message/presentation/bloc/message_bloc.dart';
import 'package:message_service/feactures/auth/presentation/bloc/auth_bloc.dart';
import 'package:message_service/core/session_manager.dart';
// local datasource is now accessed via the MessageBloc/repository
import 'package:message_service/feactures/message/data/utils/message_display_mapper.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_markdown/flutter_markdown.dart';

class MessagePage extends StatefulWidget {
  final String conversationId;
  final String title;
  final String conversationType;
  final List<dynamic>? initialMessages;
  const MessagePage({
    super.key,
    this.conversationId = '',
    this.title = 'Messages',
    this.conversationType = '',
    this.initialMessages,
  });

  @override
  State<MessagePage> createState() => _MessagePageState();
}

class _MessagePageState extends State<MessagePage> {
  int _seqCounter = 0;
  bool _preserveServerOrder = false;
  // Mensajes iniciales: empezar vacío y cargar desde el BLoC/SessionManager
  final List<Map<String, dynamic>> messages = [];

  final TextEditingController _controller = TextEditingController();
  late final ScrollController _scrollController;

  @override
  void dispose() {
    _controller.dispose();
  _scrollController.dispose();
    super.dispose();
  }

  @override
  void initState() {  
    super.initState();
    _scrollController = ScrollController();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<MessageBloc>().add(ConnectServerEvent());
      final authStateInit = context.read<AuthBloc>().state;
      final currentUserIdInit = (authStateInit is AuthAuthenticatedState) ? authStateInit.user.id.toString() : null;
      context.read<MessageBloc>().add(LoadMessageEvent(conversationId: widget.conversationId, currentUserId: currentUserIdInit));
    });
    // Inicializar mensajes si vienen como parámetro
    final authState = context.read<AuthBloc>().state;
    if (widget.initialMessages != null && widget.initialMessages!.isNotEmpty) {
      _preserveServerOrder = true;
      messages.clear();
      final currentUserId = (authState is AuthAuthenticatedState) ? authState.user.id.toString() : null;
      final prepared = prepareDisplayMessages(widget.initialMessages!, currentUserId: currentUserId, source: 'initial');
      for (final m in prepared) {
        messages.add({...m, 'seq': _seqCounter++, 'source': m['source'] ?? 'initial'});
      }
      // Scroll to last after initial population
      setState(() { _normalizeAndSortMessages(); });
      WidgetsBinding.instance.addPostFrameCallback((_) { _scrollToEnd(); });

    } else {
      // si no vinieron mensajes como parámetro, pedir la lista al BLoC (repositorio)
      final convId = widget.conversationId.isNotEmpty ? widget.conversationId : SessionManager().conversationId;
      if (convId != null && convId.isNotEmpty) {
        // pasar token si está disponible; el repositorio decidirá usar remoto o local
        final token = SessionManager().sessionToken;
        final authState2 = context.read<AuthBloc>().state;
        final currentUserId2 = (authState2 is AuthAuthenticatedState) ? authState2.user.id.toString() : null;
        context.read<MessageBloc>().add(LoadMessagesListEvent(conversationId: convId, token: token, currentUserId: currentUserId2));
      }
    }
    // Merge temporales almacenados en SessionManager
    final convId = widget.conversationId.isNotEmpty ? widget.conversationId : SessionManager().conversationId;
    if (convId != null && convId.isNotEmpty) {
      final stored = SessionManager().messagesByConversation[convId];
      if (stored != null && stored.isNotEmpty) {
        setState(() {
          for (final m in stored) {
            final text = (m['text'] ?? '').toString();
            final rawCreated = (m['created_at'] ?? '').toString();
            final createdIso = _toIsoTimestamp(rawCreated);
            final exists = messages.any((existing) {
              final et = (existing['text'] ?? '').toString();
              final ect = (existing['created_at'] ?? existing['timestamp'] ?? '').toString();
              return et == text && ect == createdIso && et.isNotEmpty;
            });
            if (!exists) {
              messages.add({'text': text, 'sender': m['sender'] ?? '', 'created_at': createdIso, 'timestamp': createdIso, 'isMe': false, 'local': false, 'seq': _seqCounter++, 'source': 'session'});
            }
          }
          _normalizeAndSortMessages();
        });
        // merged temporals (debug prints removed)
        // Scroll after merging temporals
        WidgetsBinding.instance.addPostFrameCallback((_) { _scrollToEnd(); });
      }
    }
    // Aquí podrías inicializar la conexión al servidor o cualquier otra configuración necesaria.
  }

  // _isMine removed: message ownership is determined inline where needed.

  String _toIsoTimestamp(dynamic raw) {
    if (raw == null) return DateTime.now().toUtc().toIso8601String();
    try {
      if (raw is int) {
        // if >1e12 treat as ms
        final dt = raw > 1000000000000 ? DateTime.fromMillisecondsSinceEpoch(raw, isUtc: true) : DateTime.fromMillisecondsSinceEpoch(raw * 1000, isUtc: true);
        return dt.toIso8601String();
      }
      if (raw is String) {
        final str = raw.trim();
        // numeric string?
        final numVal = int.tryParse(str);
        if (numVal != null) {
          final dt = numVal > 1000000000000 ? DateTime.fromMillisecondsSinceEpoch(numVal, isUtc: true) : DateTime.fromMillisecondsSinceEpoch(numVal * 1000, isUtc: true);
          return dt.toIso8601String();
        }
        final parsed = DateTime.tryParse(str);
        if (parsed != null) return parsed.toUtc().toIso8601String();
      }
    } catch (_) {}
    return DateTime.now().toUtc().toIso8601String();
  }

  void _scrollToEnd() {
    try {
      if (!_scrollController.hasClients) return;
      final position = _scrollController.position.maxScrollExtent;
      _scrollController.animateTo(
        position,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    } catch (_) {
      // fallback: jump
      try {
        if (_scrollController.hasClients) {
          _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
        }
      } catch (_) {}
    }
  }

  String _formatTime(String iso) {
    try {
      final dt = DateTime.tryParse(iso);
      if (dt == null) return '';
      final local = dt.toLocal();
      final h = local.hour.toString().padLeft(2, '0');
  final m = local.minute.toString().padLeft(2, '0');
  return '$h:$m';
    } catch (_) {
      return '';
    }
  }

  void _normalizeAndSortMessages() {
    final authState = context.read<AuthBloc>().state;
  final convId = widget.conversationId.isNotEmpty ? widget.conversationId : SessionManager().conversationId;
  final localTemps = (convId != null && convId.isNotEmpty) ? SessionManager().messagesByConversation[convId] ?? [] : [];
  // fingerprintCounts currently unused; kept in SessionManager for other diagnostics
    // Ensure each message has a timestamp and normalized isMe boolean
    for (var m in messages) {
      // normalize timestamp using helper to support int/string variants
      if (m['timestamp'] == null) {
        m['timestamp'] = _toIsoTimestamp(m['created_at']);
      } else {
        m['timestamp'] = _toIsoTimestamp(m['timestamp']);
      }

      // normalize isMe using sender role or ids
      var sender = (m['sender'] ?? '').toString().trim();
      final senderIdField = (m['senderId'] ?? m['sender_id'] ?? m['userId'] ?? m['user_id'] ?? '').toString().trim();

      // If explicit role strings are used by server (e.g., 'user'|'bot'), respect them
      if (sender.isNotEmpty) {
        if (sender.toLowerCase() == 'user') {
          m['isMe'] = true;
        } else if (sender.toLowerCase() == 'bot') {
          m['isMe'] = false;
        } else {
          // Unknown sender string: try id matching
          if (authState is AuthAuthenticatedState) {
            m['isMe'] = sender == authState.user.id.toString() || senderIdField == authState.user.id.toString();
          } else {
            // anonymous: treat 'local' as me
            m['isMe'] = sender == 'local' || senderIdField == 'local';
          }
        }
      } else {
        // No sender string: fallback to matching by senderId or heuristics against temporals
        if (senderIdField.isNotEmpty) {
          if (authState is AuthAuthenticatedState) {
            m['isMe'] = senderIdField == authState.user.id.toString();
          } else {
            m['isMe'] = senderIdField == 'local';
          }
        } else {
          // Heurística: si no hay sender ni senderId, comparar con mensajes temporales locales por text+created_at
          final created = (m['created_at'] ?? m['timestamp'] ?? '').toString();
          final matchTemp = localTemps.any((t) {
            final ttext = (t['text'] ?? '').toString();
            final tcreated = (t['created_at'] ?? '').toString();
            return ttext.isNotEmpty && ttext == (m['text'] ?? '') && (tcreated.isEmpty || tcreated == created);
          });
          if (matchTemp) {
            m['isMe'] = (authState is AuthAuthenticatedState) ? true : true; // temporales locales siempre son míos
          } else {
            m['isMe'] = false;
          }
        }
      }
      // Ensure sender field is set for later debug/usage
      m['sender'] = sender.isNotEmpty ? sender : senderIdField;
    }

    // If initialMessages were provided by the caller (server), preserve that order
    // and avoid resorting by timestamp which can be affected by clock skew.
    if (!_preserveServerOrder) {
      // sort ascending by timestamp
      messages.sort((a, b) {
        // if timestamp can't be parsed, treat it as far future so it appears at the end
        final ta = DateTime.tryParse(a['timestamp'] ?? '') ?? DateTime.utc(9999);
        final tb = DateTime.tryParse(b['timestamp'] ?? '') ?? DateTime.utc(9999);
        final cmp = ta.compareTo(tb);
        if (cmp != 0) return cmp;
        // tie-breaker: use seq (insertion order) if available
        final sa = (a['seq'] is int) ? a['seq'] as int : 0;
        final sb = (b['seq'] is int) ? b['seq'] as int : 0;
        return sa.compareTo(sb);
      });
    }
  }

  Color _typeColor() {
    switch (widget.conversationType.toLowerCase()) {
      case 'tecnico':
        return const Color(0xFF0FA48D);
      case 'sales':
        return const Color(0xFFD97706);
      case 'developer':
        return const Color(0xFF6A1B9A);
      case 'anonimo':
      default:
        return const Color(0xFF2454F2);
    }
  }

  IconData _typeIcon() {
    switch (widget.conversationType.toLowerCase()) {
      case 'tecnico':
        return Icons.build;
      case 'sales':
        return Icons.trending_up;
      case 'developer':
        return Icons.developer_mode;
      case 'anonimo':
      default:
        return Icons.info;
    }
  }

  void _sendMessage() {
    final text = _controller.text.trim();
    if (text.isNotEmpty) {
      setState(() {
        final authStateNow = context.read<AuthBloc>().state;
        final senderId = (authStateNow is AuthAuthenticatedState) ? authStateNow.user.id.toString() : 'local';
        final token = (authStateNow is AuthAuthenticatedState) ? authStateNow.user.token : null;
        context.read<MessageBloc>().add(SendMessageEvent(text, senderId: senderId, jwtToken: token, conversationId: widget.conversationId.isNotEmpty ? widget.conversationId : null));
        // Ensure local message timestamp is strictly greater than any existing timestamp
        DateTime maxTs = DateTime.now();
        for (final m in messages) {
          final t = DateTime.tryParse((m['timestamp'] ?? m['created_at'] ?? '').toString());
          if (t != null && t.isAfter(maxTs)) maxTs = t;
        }
        final nowTs = maxTs.add(const Duration(milliseconds: 1)).toIso8601String();
        messages.add({'text': text, 'isMe': true, 'timestamp': nowTs, 'created_at': nowTs, 'sender': senderId, 'local': true, 'seq': _seqCounter++, 'source': 'local'});
        _normalizeAndSortMessages();
      });

      _controller.clear();
      // Scroll to the newly added message
      WidgetsBinding.instance.addPostFrameCallback((_) { _scrollToEnd(); });
    }
  }

  // Método para construir texto con enlaces clickeables
  Widget _buildMessageText(String text, Color textColor) {
    // Si el texto contiene elementos markdown (encabezados, listas, énfasis)
    // o enlaces, renderizamos con MarkdownBody seleccionable.
    final markdownIndicators = RegExp(r'(\*\*|__|\* |\-|\n#{1,6} |\[.*\]\(.*\)|https?://)', caseSensitive: false);
    final isMarkdownLike = markdownIndicators.hasMatch(text);

    if (isMarkdownLike) {
      final base = MarkdownStyleSheet.fromTheme(Theme.of(context));
      final custom = base.copyWith(
        p: TextStyle(fontSize: 13.5, color: textColor, height: 1.25),
        h1: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: textColor),
        h2: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: textColor),
        h3: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700, color: textColor),
        em: TextStyle(fontStyle: FontStyle.italic, color: textColor),
        strong: TextStyle(fontWeight: FontWeight.w700, color: textColor),
        a: TextStyle(color: Colors.blueAccent, decoration: TextDecoration.underline, fontWeight: FontWeight.w600),
        code: TextStyle(fontFamily: 'monospace', fontSize: 13.5, color: Colors.indigo.shade900),
        blockquote: TextStyle(color: Colors.grey.shade800, fontStyle: FontStyle.italic),
        codeblockDecoration: BoxDecoration(
          color: Colors.grey.shade200,
          borderRadius: BorderRadius.circular(8),
        ),
        blockquotePadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        blockquoteDecoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(8),
          border: Border(left: BorderSide(color: Colors.grey.shade400, width: 4)),
        ),
      );

      return MarkdownBody(
        data: text,
        selectable: true,
        styleSheet: custom,
        onTapLink: (textLink, href, title) async {
          final url = href ?? textLink;
          try {
            final uri = Uri.parse(url);
            if (await canLaunchUrl(uri)) {
              await launchUrl(uri, mode: LaunchMode.externalApplication);
            } else {
              if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('No se pudo abrir: $url')));
            }
          } catch (_) {
            if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('URL inválida')));
          }
        },
      );
    }

    // Fallback simple: texto seleccionable
    return SelectableText(
      text,
      style: TextStyle(fontSize: 13, color: textColor),
    );
  }

  // _debugDump removed: kept out of production code. Re-add if needed for debugging.

  @override
  Widget build(BuildContext context) {
    final accentColor = _typeColor();
    final accentIcon = _typeIcon();

    return Scaffold(
      backgroundColor: const Color(0xFFF3F5F9),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF3F5F9),
        elevation: 0,
        scrolledUnderElevation: 0,
        leadingWidth: 56,
        leading: Padding(
          padding: const EdgeInsets.only(left: 12, top: 8, bottom: 8),
          child: InkWell(
            borderRadius: BorderRadius.circular(10),
            onTap: () => Navigator.of(context).pop(),
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFFEFF2F7),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFD8DEE9)),
              ),
              child: const Icon(Icons.chevron_left, size: 20, color: Color(0xFF6B7280)),
            ),
          ),
        ),
        titleSpacing: 0,
        title: Row(
          children: [
            Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                color: accentColor.withOpacity(0.16),
                borderRadius: BorderRadius.circular(8),
              ),
              alignment: Alignment.center,
              child: Icon(accentIcon, color: accentColor, size: 16),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Color(0xFF111827),
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      height: 1.15,
                    ),
                  ),
                  const SizedBox(height: 1),
                  Text(
                    '● Asistente IA activo',
                    style: TextStyle(
                      color: accentColor,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.more_horiz, color: Color(0xFF9CA3AF)),
            onPressed: () {},
          ),
        ],
      ),
      body: BlocListener<MessageBloc, MessageState>(
        listener: (context, state) {
          // MessageLoadedState is intentionally light here; the BLoC will emit
          // MessagesListLoadedState to update the full list (confirmed messages, stop animations).
            if (state is MessageLoadedState) {
            // no-op: list refresh handled by MessagesListLoadedState
            // continue listening for next message
            final authStateL = context.read<AuthBloc>().state;
            final currentUserIdL = (authStateL is AuthAuthenticatedState) ? authStateL.user.id.toString() : null;
            context.read<MessageBloc>().add(LoadMessageEvent(conversationId: widget.conversationId, currentUserId: currentUserIdL));
          }
          if (state is MessagesDisplayLoadedState) {
            try {
              final list = state.messages;
              setState(() {
                messages.clear();
                for (final m in list) {
                  // Incoming maps from mapper already have text, timestamp and isMe
                  messages.add({...m, 'local': false, 'seq': _seqCounter++, 'source': m['source'] ?? 'repo'});
                }
                _normalizeAndSortMessages();
              });
              WidgetsBinding.instance.addPostFrameCallback((_) { _scrollToEnd(); });
            } catch (_) {}
          }
          if (state is MessageSentState) {
            // After a successful send, reload the full messages list so the
            // server-confirmed user message and bot response are shown.
            try {
              final authStateS = context.read<AuthBloc>().state;
              final currentUserIdS = (authStateS is AuthAuthenticatedState) ? authStateS.user.id.toString() : null;
              context.read<MessageBloc>().add(LoadMessageEvent(conversationId: widget.conversationId, currentUserId: currentUserIdS));
            } catch (_) {}
          }
          // Generic error handling: if the state type name contains 'Error' try to show a message
          final stName = state.runtimeType.toString().toLowerCase();
          if (stName.contains('error') || stName.contains('senderror')) {
            try {
              final msg = (state as dynamic).message ?? 'Error al enviar mensaje';
              ScaffoldMessenger.of(context)
                ..hideCurrentSnackBar()
                ..showSnackBar(SnackBar(content: Text(msg), backgroundColor: Colors.red));
            } catch (_) {
              try {
                ScaffoldMessenger.of(context)
                  ..hideCurrentSnackBar()
                  ..showSnackBar(const SnackBar(content: Text('Error al enviar mensaje'), backgroundColor: Colors.red));
              } catch (_) {}
            }
          }
        },
        child: Column(
          children: [
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.fromLTRB(12, 8, 12, 10),
                controller: _scrollController,
                itemCount: messages.length,
                itemBuilder: (context, index) {
                  final message = messages[index];
                  final isMe = message['isMe'] as bool;
                  // Build the message bubble
                  final bubble = Container(
                    margin: const EdgeInsets.symmetric(vertical: 6),
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 14),
                    constraints: BoxConstraints(
                      maxWidth: MediaQuery.of(context).size.width * (isMe ? 0.72 : 0.85),
                    ),
                    decoration: BoxDecoration(
                      color: isMe ? accentColor.withOpacity(0.12) : Colors.white,
                      borderRadius: BorderRadius.only(
                        topLeft: const Radius.circular(14),
                        topRight: const Radius.circular(14),
                        bottomLeft: isMe ? const Radius.circular(14) : const Radius.circular(4),
                        bottomRight: isMe ? const Radius.circular(4) : const Radius.circular(14),
                      ),
                      border: isMe ? null : Border.all(color: const Color(0xFFE3E8F0)),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.04),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _buildMessageText(
                          message['text'] as String,
                          isMe ? const Color(0xFF09090A) : const Color(0xFF374151),
                        ),
                      ],
                    ),
                  );

                  final metadata = Padding(
                    padding: EdgeInsets.only(
                      left: isMe ? 0 : 4,
                      right: isMe ? 4 : 0,
                      top: 2,
                    ),
                    child: Text(
                      isMe
                          ? _formatTime((message['timestamp'] ?? message['created_at'] ?? '').toString())
                          : '${_formatTime((message['timestamp'] ?? message['created_at'] ?? '').toString())} · IA',
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.grey.shade500,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  );

                  // Render bubble and, if pending local message, show waiting dots below aligned to same side
                  return Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          if (!isMe)
                            Container(
                              width: 24,
                              height: 24,
                              margin: const EdgeInsets.only(right: 6, bottom: 22),
                              decoration: BoxDecoration(
                                color: accentColor.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(7),
                              ),
                              alignment: Alignment.center,
                              child: Icon(accentIcon, color: accentColor, size: 14),
                            ),
                          Column(
                            crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                            children: [bubble, metadata],
                          ),
                        ],
                      ),
                      // If this is a local optimistic message sent by the user, show
                      // the bot 'thinking' indicator (three dots) on the left until
                      // the server confirms and the list is reloaded.
                      if (message['local'] == true && isMe) ...[
                        const SizedBox(height: 6),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Container(
                            margin: const EdgeInsets.only(left: 8),
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              color: accentColor.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: const _WaitingDots(),
                          ),
                        ),
                        const SizedBox(height: 2),
                      ],
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: AnimatedPadding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        duration: const Duration(milliseconds: 160),
        curve: Curves.easeOut,
        child: SafeArea(
          bottom: true,
          child: Container(
            padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
            color: const Color(0xFFF3F5F9),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    minLines: 1,
                    maxLines: 4,
                    keyboardType: TextInputType.multiline,
                    textInputAction: TextInputAction.newline,
                    decoration: InputDecoration(
                      hintText: 'Escribe un mensaje...',
                      hintStyle: TextStyle(color: Colors.grey.shade500, fontSize: 14),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Color(0xFFD7DCE5)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: accentColor, width: 1.2),
                      ),
                      filled: true,
                      fillColor: Colors.white,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  decoration: BoxDecoration(
                    color: accentColor.withOpacity(0.42),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: accentColor.withOpacity(0.72),
                      width: 1,
                    ),
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: _sendMessage,
                      child: const SizedBox(
                        width: 44,
                        height: 44,
                        child: Icon(Icons.send_rounded, color: Colors.white, size: 20),
                      ),
                    ),
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

// Small animated dots widget shown while message is pending server confirmation
class _WaitingDots extends StatefulWidget {
  const _WaitingDots({Key? key}) : super(key: key);
  @override
  State<_WaitingDots> createState() => _WaitingDotsState();
}

class _WaitingDotsState extends State<_WaitingDots> {
  int _active = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(milliseconds: 400), (_) {
      setState(() {
        _active = (_active + 1) % 3;
      });
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(3, (i) {
        final visible = i == _active;
        return AnimatedOpacity(
          duration: const Duration(milliseconds: 300),
          opacity: visible ? 1.0 : 0.3,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 2.0),
            child: Container(width: 6, height: 6, decoration: const BoxDecoration(color: Colors.grey, shape: BoxShape.circle)),
          ),
        );
      }),
    );
  }
}