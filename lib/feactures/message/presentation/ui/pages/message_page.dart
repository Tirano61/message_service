import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
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
  final List<dynamic>? initialMessages;
  const MessagePage({super.key, this.conversationId = '', this.title = 'Messages', this.initialMessages});

  @override
  State<MessagePage> createState() => _MessagePageState();
}

class _MessagePageState extends State<MessagePage> {
  int _seqCounter = 0;
  bool _preserveServerOrder = false;
  final List<Map<String, dynamic>> messages = [
    {'text': 'Hola, ¿cómo estás?', 'isMe': false},
    {'text': '¡Hola! Todo bien, ¿y tú?', 'isMe': true},
    {'text': 'Muy bien, gracias.', 'isMe': false},
    {'text': '¿En qué puedo ayudarte?', 'isMe': true},
  ];

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
  final s = local.second.toString().padLeft(2, '0');
  return '$h:$m:$s';
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
        p: TextStyle(fontSize: 16.5, color: textColor, height: 1.25),
        h1: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: textColor),
        h2: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: textColor),
        h3: TextStyle(fontSize: 16.5, fontWeight: FontWeight.w700, color: textColor),
        em: TextStyle(fontStyle: FontStyle.italic, color: textColor),
        strong: TextStyle(fontWeight: FontWeight.w700, color: textColor),
        a: TextStyle(color: Colors.blueAccent, decoration: TextDecoration.underline, fontWeight: FontWeight.w600),
        code: TextStyle(fontFamily: 'monospace', fontSize: 14.0, color: Colors.indigo.shade900),
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
          if (url == null) return;
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
      style: TextStyle(fontSize: 16, color: textColor),
    );
  }

  // _debugDump removed: kept out of production code. Re-add if needed for debugging.

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
              // HTTP-only: always show disconnected (no real-time connection)
              return const Icon(Icons.connect_without_contact, color: Colors.red);
            },
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
                padding: const EdgeInsets.all(12),
                controller: _scrollController,
                itemCount: messages.length,
                itemBuilder: (context, index) {
                  final message = messages[index];
                  final isMe = message['isMe'] as bool;
                  // Build the message bubble
                  final bubble = Container(
                    margin: const EdgeInsets.symmetric(vertical: 6),
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                    decoration: BoxDecoration(
                      color: isMe ? const Color(0xFFB3E5FC) : const Color.fromARGB(255, 234, 216, 244),
                      borderRadius: BorderRadius.only(
                        topLeft: const Radius.circular(16),
                        topRight: const Radius.circular(16),
                        bottomLeft: isMe ? const Radius.circular(16) : const Radius.circular(0),
                        bottomRight: isMe ? const Radius.circular(0) : const Radius.circular(16),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _buildMessageText(
                          message['text'] as String,
                          isMe ? Colors.black : Colors.black87,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _formatTime((message['timestamp'] ?? message['created_at'] ?? '').toString()),
                          style: TextStyle(fontSize: 10, color: Colors.grey[600]),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          (message['source'] ?? '').toString(),
                          style: TextStyle(fontSize: 9, color: Colors.grey[500]),
                        ),
                      ],
                    ),
                  );

                  // Render bubble and, if pending local message, show waiting dots below aligned to same side
                  return Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                    children: [
                      Align(
                        alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                        child: bubble,
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
                              color: const Color.fromARGB(255, 234, 216, 244),
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
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              color: Colors.white,
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      onSubmitted: (_) => _sendMessage(),
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