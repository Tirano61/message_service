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
  context.read<MessageBloc>().add(ConnectServerEvent());
  // Start listening for incoming messages (listen once)
  context.read<MessageBloc>().add(LoadMessageEvent());
  // debug: show which conversation and whether initialMessages were provided
  try { debugPrint('DBG initState convId=${widget.conversationId} initialMessages=${widget.initialMessages?.length ?? 0}'); } catch (_) {}
    // Inicializar mensajes si vienen como parámetro
    final authState = context.read<AuthBloc>().state;
    if (widget.initialMessages != null && widget.initialMessages!.isNotEmpty) {
      _preserveServerOrder = true;
       messages.clear();
          // build stable timestamps for messages: prefer server-created time, otherwise synthesize
      final nowBase = DateTime.now().toUtc().subtract(Duration(milliseconds: widget.initialMessages!.length + 1));
      for (var i = 0; i < widget.initialMessages!.length; i++) {
        final m = widget.initialMessages![i];
        if (m is Map<String, dynamic>) {
          // preserve sender and created_at when present (support different payload keys)
          final sender = (m['sender'] ?? m['from'] ?? m['user_id'] ?? m['userId'] ?? '').toString();
          final createdRaw = m['created_at'] ?? m['timestamp'] ?? m['time'] ?? m['date'] ?? '';
          final normalizedMap = Map<String, dynamic>.from(m);
          normalizedMap['sender'] = sender;
          String createdIso;
          if (createdRaw != null && (createdRaw is String || createdRaw is int) && createdRaw.toString().trim().isNotEmpty) {
            createdIso = _toIsoTimestamp(createdRaw);
          } else {
            // synthesize a monotonic timestamp based on list position so ordering is stable
            createdIso = nowBase.add(Duration(milliseconds: i)).toIso8601String();
          }
          normalizedMap['created_at'] = createdIso;
          final isMeVal = _isMine(normalizedMap, authState);
          messages.add({'text': m['content'] ?? m['message'] ?? '', 'sender': sender, 'created_at': createdIso, 'timestamp': createdIso, 'isMe': isMeVal, 'seq': _seqCounter++, 'source': 'initial'});
        }
      }
  // Scroll to last after initial population
      setState(() { _normalizeAndSortMessages(); });
        WidgetsBinding.instance.addPostFrameCallback((_) { 
        _scrollToEnd();
      });
    // debug dump
    _debugDump('initial');
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
                    // preserve created_at/timestamp from DB so ordering is correct
                    final ts = m.created_at.toIso8601String();
                    messages.add({'text': m.content, 'isMe': (m.sender == (authState is AuthAuthenticatedState ? authState.user.id : null)), 'timestamp': ts, 'created_at': ts, 'sender': m.sender, 'local': false, 'seq': _seqCounter++, 'source': 'db'});
                  }
                });
                // Normalize, sort and scroll after rendering
                setState(() { _normalizeAndSortMessages(); });
              WidgetsBinding.instance.addPostFrameCallback((_) { 
                _scrollToEnd();
              });
              // debug dump
              _debugDump('db_loaded');
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

  bool _isMine(Map<String, dynamic> m, dynamic authState) {
    final sender = m['sender']?.toString() ?? '';
  // merged temporals (debug prints removed)
    // Scroll after merging temporals
  WidgetsBinding.instance.addPostFrameCallback((_) { _scrollToEnd(); });
    _debugDump('merged_session');
    if (authState is AuthAuthenticatedState) {
      return sender == authState.user.id || sender == authState.user.role;
    }
    return false;
  }

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

  void _debugDump(String tag) {
    try {
      final sample = messages.take(12).map((m) {
        final tsRaw = (m['timestamp'] ?? m['created_at'] ?? '').toString();
        final parsed = DateTime.tryParse(tsRaw);
        final ts = parsed != null ? parsed.toUtc().toIso8601String() : 'INVALID';
        final src = (m['source'] ?? 'unknown').toString();
        final seq = (m['seq'] ?? 0).toString();
        final isMe = (m['isMe'] ?? false).toString();
        final text = (m['text'] ?? '').toString();
        final short = text.length > 24 ? text.substring(0, 24) + '...' : text;
        return '{seq:$seq src:$src isMe:$isMe ts:$ts text:"$short"}';
      }).join('\n');
      debugPrint('DBG DUMP $tag count=${messages.length}\n$sample');
    } catch (_) {
      try { debugPrint('DBG DUMP $tag failed to dump messages'); } catch (_) {}
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

      // normalize isMe using string comparison to avoid type mismatches
      var sender = (m['sender'] ?? '').toString();
      if (sender.isEmpty) {
        // Heurística: si no hay sender, comparar con mensajes temporales locales por text+created_at
        final created = (m['created_at'] ?? m['timestamp'] ?? '').toString();
        final matchTemp = localTemps.any((t) {
          final ttext = (t['text'] ?? '').toString();
          final tcreated = (t['created_at'] ?? '').toString();
          return ttext.isNotEmpty && ttext == (m['text'] ?? '') && (tcreated.isEmpty || tcreated == created);
        });
        if (matchTemp) {
          sender = (authState is AuthAuthenticatedState) ? authState.user.id.toString() : 'local';
        }
      }
      if (authState is AuthAuthenticatedState) {
        m['isMe'] = sender.isNotEmpty && sender == authState.user.id.toString();
      } else {
        // anonymous: if sender was inferred as 'local' mark isMe true
        m['isMe'] = sender == 'local';
      }
      m['sender'] = sender;
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
        context.read<MessageBloc>().add(SendMessageEvent(text, senderId: senderId));
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
  _debugDump('local_sent');
      _controller.clear();
  // Scroll to the newly added message
  WidgetsBinding.instance.addPostFrameCallback((_) { _scrollToEnd(); });
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
              // normalize server timestamp to UTC ISO so comparison is stable
              final serverTs = _toIsoTimestamp(msg.created_at.toUtc().toIso8601String());
            final text = msg.content;
            // Try to find a matching local (optimistic) message and replace it instead of duplicating
            final matchIndex = messages.indexWhere((m) {
              final mt = (m['text'] ?? '').toString();
                final mtsRaw = (m['timestamp'] ?? m['created_at'] ?? '').toString();
                final mts = mtsRaw.isEmpty ? '' : _toIsoTimestamp(mtsRaw);
                final isLocal = m['local'] == true;
                return isLocal && mt == text && (mts.isEmpty || mts == serverTs);
            });
            setState(() {
                if (matchIndex != -1) {
                // replace local message record with server-acknowledged message
                messages[matchIndex] = {'text': text, 'isMe': _isMine(msg.toJson(), context.read<AuthBloc>().state), 'timestamp': serverTs, 'created_at': serverTs, 'sender': msg.sender.toString(), 'local': false, 'seq': _seqCounter++, 'source': 'server'};
              } else {
                // no local match, add normally
                final exists = messages.any((m) {
                  final mtsRaw = (m['timestamp'] ?? m['created_at'] ?? '').toString();
                  final mts = mtsRaw.isEmpty ? '' : _toIsoTimestamp(mtsRaw);
                  return m['text'] == text && mts == serverTs;
                });
                  if (!exists) {
                  messages.add({'text': text, 'isMe': _isMine(msg.toJson(), context.read<AuthBloc>().state), 'timestamp': serverTs, 'created_at': serverTs, 'sender': msg.sender.toString(), 'local': false, 'seq': _seqCounter++, 'source': 'server'});
                }
              }
              _normalizeAndSortMessages();
            });
            _debugDump('onServerMsg');
            WidgetsBinding.instance.addPostFrameCallback((_) { 
              _scrollToEnd();
            });
            // Escuchar el siguiente mensaje
            context.read<MessageBloc>().add(LoadMessageEvent());
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
                  return Align(
                    alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                    child: Container(
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      decoration: BoxDecoration(
                          // usuario = celeste visible, bot = blanco sucio
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
                          Text(
                            message['text'] as String,
                            style: TextStyle(fontSize: 16, color: isMe ? Colors.black : Colors.black87),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _formatTime((message['timestamp'] ?? message['created_at'] ?? '').toString()),
                            style: TextStyle(fontSize: 10, color: Colors.grey[600]),
                          ),
                          const SizedBox(height: 2),
                          // debug: show source of message (initial/db/session/local/server)
                          Text(
                            (message['source'] ?? '').toString(),
                            style: TextStyle(fontSize: 9, color: Colors.grey[500]),
                          ),
                        ],
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