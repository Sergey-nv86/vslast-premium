import 'dart:async';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/chat_service.dart';
import '../theme/app_theme.dart';

class ChatUnreadBadge extends StatefulWidget {
  final Color color;
  final Color textColor;
  const ChatUnreadBadge({
    super.key,
    this.color = AppColors.brickRed,
    this.textColor = Colors.white,
  });

  @override
  State<ChatUnreadBadge> createState() => _ChatUnreadBadgeState();
}

class _ChatUnreadBadgeState extends State<ChatUnreadBadge> {
  int _count = 0;
  RealtimeChannel? _channel;

  @override
  void initState() {
    super.initState();
    _load();
    _channel = Supabase.instance.client
        .channel('chat-unread-badge-${DateTime.now().microsecondsSinceEpoch}')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'chat_messages',
          callback: (_) => _load(),
        )
        .subscribe();
  }

  Future<void> _load() async {
    try {
      final value = await ChatService.instance.unreadForCurrentUser();
      if (mounted) setState(() => _count = value);
    } catch (_) {}
  }

  @override
  void dispose() {
    final channel = _channel;
    if (channel != null) {
      Supabase.instance.client.removeChannel(channel);
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_count <= 0) return const SizedBox.shrink();
    return Container(
      constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
      decoration: BoxDecoration(
        color: widget.color,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        _count > 99 ? '99+' : '$_count',
        textAlign: TextAlign.center,
        style: TextStyle(
          color: widget.textColor,
          fontSize: 10,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class ClientChatScreen extends StatefulWidget {
  final String? targetMessageId;

  const ClientChatScreen({
    super.key,
    this.targetMessageId,
  });

  @override
  State<ClientChatScreen> createState() => _ClientChatScreenState();
}

class _ClientChatScreenState extends State<ClientChatScreen> {
  final _controller = TextEditingController();
  final _scrollController = ScrollController();

  String? _threadId;
  List<Map<String, dynamic>> _messages = [];
  RealtimeChannel? _channel;
  bool _loading = true;
  bool _sending = false;
  String? _pendingImagePath;
  final Map<String, GlobalKey> _messageKeys = {};

  @override
  void initState() {
    super.initState();
    _open();
  }

  Future<void> _open() async {
    try {
      final thread = await ChatService.instance.ensureMyThread();
      _threadId = thread['id'].toString();
      await _reload();
      _subscribe();
      await ChatService.instance.markIncomingRead(_threadId!);
      await _reload();
    } catch (e) {
      if (mounted) _showError(e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _subscribe() {
    final id = _threadId;
    if (id == null) return;
    _channel = Supabase.instance.client
        .channel('client-chat-$id')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'chat_messages',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'thread_id',
            value: id,
          ),
          callback: (_) async {
            await _reload();
            await ChatService.instance.markIncomingRead(id);
          },
        )
        .subscribe();
  }

  Future<void> _reload() async {
    final id = _threadId;
    if (id == null) return;
    try {
      final messages = await ChatService.instance.messages(id);
      if (!mounted) return;
      setState(() => _messages = messages);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (widget.targetMessageId != null) {
          _revealTargetMessage();
        } else if (_scrollController.hasClients) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 240),
            curve: Curves.easeOut,
          );
        }
      });
    } catch (_) {}
  }

  Future<void> _revealTargetMessage() async {
    final targetId = widget.targetMessageId?.trim();
    if (targetId == null || targetId.isEmpty) return;

    final index = _messages.indexWhere(
      (message) => message['id']?.toString() == targetId,
    );
    if (index < 0) return;

    if (!mounted) return;
    final key = _messageKeys.putIfAbsent(targetId, () => GlobalKey());

    for (var attempt = 0; attempt < 6; attempt++) {
      if (!_scrollController.hasClients) return;

      final targetContext = key.currentContext;
      if (targetContext != null) {
        return Scrollable.ensureVisible(
          targetContext,
          alignment: 0.35,
          duration: const Duration(milliseconds: 280),
          curve: Curves.easeOutCubic,
        );
      }

      if (!mounted) return;

      final max = _scrollController.position.maxScrollExtent;
      final estimated = max == 0
          ? 0.0
          : (index / _messages.length.clamp(1, 100000)) * max;
      _scrollController.jumpTo(
        estimated.clamp(0.0, max).toDouble(),
      );
      await Future<void>.delayed(const Duration(milliseconds: 60));
    }
  }

  Future<void> _send() async {
    final id = _threadId;
    if (id == null || _sending) return;
    final text = _controller.text.trim();
    if (text.isEmpty && _pendingImagePath == null) return;

    setState(() => _sending = true);
    try {
      await ChatService.instance.sendMessage(
        threadId: id,
        body: text.isEmpty ? null : text,
        imagePath: _pendingImagePath,
      );
      _controller.clear();
      _pendingImagePath = null;
      await _reload();
    } catch (e) {
      _showError(e.toString());
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  Future<void> _pickImage() async {
    final id = _threadId;
    if (id == null || _sending) return;
    try {
      setState(() => _sending = true);
      final path = await ChatService.instance.pickAndUploadImage(id);
      if (mounted && path != null) setState(() => _pendingImagePath = path);
    } catch (e) {
      _showError(e.toString());
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    final channel = _channel;
    if (channel != null) Supabase.instance.client.removeChannel(channel);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: Text('Чат с «Всласть»', style: AppTextStyles.screenTitleSmall),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Expanded(
                  child: _messages.isEmpty
                      ? Center(
                          child: Text(
                            'Напишите нам — мы ответим здесь.',
                            style: AppTextStyles.rowLabelMuted,
                          ),
                        )
                      : ListView.builder(
                          controller: _scrollController,
                          padding: const EdgeInsets.fromLTRB(16, 14, 16, 18),
                          itemCount: _messages.length,
                          itemBuilder: (_, index) {
                            final message = _messages[index];
                            final id = message['id']?.toString() ?? '';
                            final key = id.isEmpty
                                ? null
                                : _messageKeys.putIfAbsent(id, () => GlobalKey());
                            return KeyedSubtree(
                              key: key,
                              child: _MessageBubble(
                                message: message,
                                highlighted: id == widget.targetMessageId,
                              ),
                            );
                          },
                        ),
                ),
                if (_pendingImagePath != null)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                    child: Row(
                      children: [
                        const Icon(Icons.image_outlined, color: AppColors.caramel),
                        const SizedBox(width: 8),
                        const Expanded(child: Text('Изображение прикреплено')),
                        IconButton(
                          onPressed: () => setState(() => _pendingImagePath = null),
                          icon: const Icon(Icons.close_rounded),
                        ),
                      ],
                    ),
                  ),
                SafeArea(
                  top: false,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        IconButton(
                          onPressed: _sending ? null : _pickImage,
                          icon: const Icon(Icons.add_photo_alternate_outlined),
                          color: AppColors.primaryBrown,
                        ),
                        Expanded(
                          child: TextField(
                            controller: _controller,
                            minLines: 1,
                            maxLines: 4,
                            textCapitalization: TextCapitalization.sentences,
                            decoration: InputDecoration(
                              hintText: 'Сообщение',
                              filled: true,
                              fillColor: Colors.white,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(22),
                                borderSide: const BorderSide(color: AppColors.border),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(22),
                                borderSide: const BorderSide(color: AppColors.border),
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 11,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        IconButton(
                          onPressed: _sending ? null : _send,
                          icon: _sending
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                )
                              : const Icon(Icons.arrow_upward_rounded),
                          color: AppColors.primaryBrown,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  final Map<String, dynamic> message;
  final bool highlighted;

  const _MessageBubble({
    required this.message,
    this.highlighted = false,
  });

  @override
  Widget build(BuildContext context) {
    final mine = message['sender_role'] == 'customer';
    final imageUrl = message['image_url']?.toString();
    final body = message['body']?.toString() ?? '';
    final color = mine ? AppColors.primaryBrown : Colors.white;
    final textColor = mine ? Colors.white : AppColors.textPrimary;

    return Align(
      alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 320),
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(18),
          border: highlighted
              ? Border.all(color: AppColors.caramel, width: 2)
              : mine
                  ? null
                  : Border.all(color: AppColors.border),
          boxShadow: highlighted
              ? const [BoxShadow(blurRadius: 12, spreadRadius: 1, color: Color(0x335E4030))]
              : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (imageUrl != null && imageUrl.isNotEmpty)
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.network(
                  imageUrl,
                  width: 260,
                  fit: BoxFit.cover,
                ),
              ),
            if (body.isNotEmpty) ...[
              if (imageUrl != null && imageUrl.isNotEmpty) const SizedBox(height: 7),
              Text(body, style: TextStyle(color: textColor, fontSize: 14, height: 1.35)),
            ],
          ],
        ),
      ),
    );
  }
}

class AdminChatListScreen extends StatefulWidget {
  const AdminChatListScreen({super.key});

  @override
  State<AdminChatListScreen> createState() => _AdminChatListScreenState();
}

class _AdminChatListScreenState extends State<AdminChatListScreen> {
  List<Map<String, dynamic>> _threads = [];
  bool _loading = true;
  RealtimeChannel? _channel;

  @override
  void initState() {
    super.initState();
    _load();
    _channel = Supabase.instance.client
        .channel('admin-chat-list')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'chat_messages',
          callback: (_) => _load(),
        )
        .subscribe();
  }

  Future<void> _load() async {
    try {
      final threads = await ChatService.instance.adminThreads();
      if (mounted) setState(() { _threads = threads; _loading = false; });
    } catch (e) {
      if (mounted) {
        setState(() => _loading = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
      }
    }
  }

  Future<void> _showBroadcastDialog({String? level, String? title}) async {
    final controller = TextEditingController();
    var sending = false;
    final recipientLabel = level == 'gold'
        ? 'клиентам Голд'
        : level == 'premium'
            ? 'клиентам Премиум'
            : 'всем клиентам';

    try {
      await showDialog<void>(
        context: context,
        builder: (dialogContext) {
          return StatefulBuilder(
            builder: (context, setDialogState) {
              return AlertDialog(
                title: Text(title ?? 'Сообщение $recipientLabel'),
                content: TextField(
                  controller: controller,
                  autofocus: true,
                  maxLines: 6,
                  minLines: 3,
                  decoration: InputDecoration(
                    hintText: 'Введите сообщение для $recipientLabel',
                    border: const OutlineInputBorder(),
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: sending ? null : () => Navigator.of(dialogContext).pop(),
                    child: const Text('Отмена'),
                  ),
                  FilledButton(
                    onPressed: sending
                        ? null
                        : () async {
                            final text = controller.text.trim();
                            if (text.isEmpty) return;

                            final dialogNavigator = Navigator.of(dialogContext);
                            final messenger = ScaffoldMessenger.of(this.context);
                            setDialogState(() => sending = true);
                            try {
                              final count = await ChatService.instance
                                  .broadcastMessage(text, level: level);
                              if (!mounted) return;
                              dialogNavigator.pop();
                              messenger.showSnackBar(
                                SnackBar(
                                  content: Text('Сообщение отправлено $count клиентам'),
                                ),
                              );
                              await _load();
                            } catch (e) {
                              setDialogState(() => sending = false);
                              if (!mounted) return;
                              messenger.showSnackBar(
                                SnackBar(content: Text(e.toString())),
                              );
                            }
                          },
                    child: sending
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Отправить'),
                  ),
                ],
              );
            },
          );
        },
      );
    } finally {
      controller.dispose();
    }
  }

  Future<void> _showClientPicker() async {
    List<ChatClient> clients = [];
    var loading = true;
    var query = '';

    try {
      await showDialog<void>(
        context: context,
        builder: (dialogContext) {
          return StatefulBuilder(
            builder: (context, setDialogState) {
              if (loading) {
                ChatService.instance.adminChatClients().then((value) {
                  if (context.mounted) {
                    setDialogState(() {
                      clients = value;
                      loading = false;
                    });
                  }
                }).catchError((error) {
                  if (context.mounted) {
                    setDialogState(() => loading = false);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(error.toString())),
                    );
                  }
                });
              }

              final filtered = clients.where((client) {
                final q = query.trim().toLowerCase();
                if (q.isEmpty) return true;
                return client.clientId.toLowerCase().contains(q) ||
                    client.name.toLowerCase().contains(q) ||
                    client.phone.toLowerCase().contains(q);
              }).toList();

              return AlertDialog(
                title: const Text('Написать клиенту'),
                content: SizedBox(
                  width: 520,
                  height: 520,
                  child: loading
                      ? const Center(child: CircularProgressIndicator())
                      : Column(
                          children: [
                            TextField(
                              autofocus: true,
                              onChanged: (value) => setDialogState(() => query = value),
                              decoration: const InputDecoration(
                                hintText: 'Поиск: C-000000, имя или телефон',
                                prefixIcon: Icon(Icons.search_rounded),
                              ),
                            ),
                            const SizedBox(height: 12),
                            Expanded(
                              child: filtered.isEmpty
                                  ? const Center(child: Text('Клиенты не найдены'))
                                  : ListView.separated(
                                      itemCount: filtered.length,
                                      separatorBuilder: (_, _) => const Divider(height: 1),
                                      itemBuilder: (_, index) {
                                        final client = filtered[index];
                                        return ListTile(
                                          leading: const CircleAvatar(
                                            backgroundColor: Color(0xFFF1E8E0),
                                            child: Icon(Icons.person_outline, color: Color(0xFF8B5E3C)),
                                          ),
                                          title: Text(
                                            client.label,
                                            style: const TextStyle(fontWeight: FontWeight.w700),
                                          ),
                                          subtitle: Text(
                                            '${client.name} · ${client.levelLabel}',
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          onTap: () async {
                                            final navigator = Navigator.of(this.context);
                                            final messenger = ScaffoldMessenger.of(this.context);
                                            Navigator.of(dialogContext).pop();
                                            try {
                                              final threadId = await ChatService.instance
                                                  .ensureAdminThreadForClient(client.userId);
                                              if (!mounted) return;
                                              await navigator.push(
                                                MaterialPageRoute(
                                                  builder: (_) => AdminChatScreen(
                                                    threadId: threadId,
                                                    title: client.label,
                                                  ),
                                                ),
                                              );
                                              await _load();
                                            } catch (e) {
                                              if (!mounted) return;
                                              messenger.showSnackBar(
                                                SnackBar(content: Text(e.toString())),
                                              );
                                            }
                                          },
                                        );
                                      },
                                    ),
                            ),
                          ],
                        ),
                ),
              );
            },
          );
        },
      );
    } catch (_) {}
  }

  @override
  void dispose() {
    final channel = _channel;
    if (channel != null) Supabase.instance.client.removeChannel(channel);
    super.dispose();
  }

  String _name(Map<String, dynamic> thread) {
    final clientId = thread['client_id']?.toString().trim() ?? '';
    if (clientId.isNotEmpty) return 'Клиент $clientId';

    final p = thread['profile'] as Map<String, dynamic>?;
    if (p == null) return 'Клиент';

    final display = p['display_name']?.toString().trim() ?? '';
    if (display.isNotEmpty) return display;

    final full = [p['first_name'], p['last_name']]
        .map((e) => e?.toString().trim() ?? '')
        .where((e) => e.isNotEmpty)
        .join(' ');
    return full.isNotEmpty ? full : 'Клиент';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F4EE),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF8F4EE),
        elevation: 0,
        title: const Text(
          'Чаты',
          style: TextStyle(
            color: Color(0xFF3B281F),
            fontSize: 24,
            fontWeight: FontWeight.w700,
          ),
        ),
        actions: [
          PopupMenuButton<String>(
            tooltip: 'Новая рассылка',
            onSelected: (value) {
              if (value == 'client') {
                _showClientPicker();
              } else if (value == 'all') {
                _showBroadcastDialog();
              } else if (value == 'gold') {
                _showBroadcastDialog(level: 'gold', title: 'Сообщение группе Голд');
              } else if (value == 'premium') {
                _showBroadcastDialog(level: 'premium', title: 'Сообщение группе Премиум');
              }
            },
            icon: const Icon(
              Icons.edit_outlined,
              color: Color(0xFF8B5E3C),
            ),
            itemBuilder: (_) => const [
              PopupMenuItem(
                value: 'client',
                child: Text('Написать клиенту'),
              ),
              PopupMenuDivider(),
              PopupMenuItem(
                value: 'all',
                child: Text('Всем клиентам'),
              ),
              PopupMenuItem(
                value: 'gold',
                child: Text('Группа · Голд'),
              ),
              PopupMenuItem(
                value: 'premium',
                child: Text('Группа · Премиум'),
              ),
            ],
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : _threads.isEmpty
                ? ListView(children: const [
                    SizedBox(height: 180),
                    Center(child: Text('Пока нет обращений')),
                  ])
                : ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: _threads.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 10),
                    itemBuilder: (_, index) {
                      final thread = _threads[index];
                      final unread = (thread['unread_count'] as num?)?.toInt() ?? 0;
                      return ListTile(
                        tileColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18),
                          side: const BorderSide(color: Color(0xFFEADFD5)),
                        ),
                        leading: CircleAvatar(
                          backgroundColor: const Color(0xFFF1E8E0),
                          child: Text(
                            _name(thread).substring(0, 1).toUpperCase(),
                            style: const TextStyle(color: Color(0xFF8B5E3C)),
                          ),
                        ),
                        title: Text(
                          _name(thread),
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                        subtitle: Text(
                          thread['last_message_preview']?.toString() ?? 'Новый чат',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        trailing: unread > 0
                            ? CircleAvatar(
                                radius: 12,
                                backgroundColor: const Color(0xFFB5423F),
                                child: Text(
                                  unread > 99 ? '99+' : '$unread',
                                  style: const TextStyle(color: Colors.white, fontSize: 9),
                                ),
                              )
                            : const Icon(Icons.chevron_right_rounded),
                        onTap: () async {
                          await Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => AdminChatScreen(
                                threadId: thread['id'].toString(),
                                title: _name(thread),
                              ),
                            ),
                          );
                          _load();
                        },
                      );
                    },
                  ),
      ),
    );
  }
}

class AdminChatScreen extends StatefulWidget {
  final String threadId;
  final String title;
  final String? targetMessageId;

  const AdminChatScreen({
    super.key,
    required this.threadId,
    required this.title,
    this.targetMessageId,
  });

  @override
  State<AdminChatScreen> createState() => _AdminChatScreenState();
}

class _AdminChatScreenState extends State<AdminChatScreen> {
  final _controller = TextEditingController();
  final _scrollController = ScrollController();
  List<Map<String, dynamic>> _messages = [];
  RealtimeChannel? _channel;
  bool _loading = true;
  bool _sending = false;
  String? _pendingImagePath;
  final Map<String, GlobalKey> _messageKeys = {};

  @override
  void initState() {
    super.initState();
    _load();
    _channel = Supabase.instance.client
        .channel('admin-chat-${widget.threadId}')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'chat_messages',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'thread_id',
            value: widget.threadId,
          ),
          callback: (_) async {
            await _load();
            await ChatService.instance.markIncomingRead(widget.threadId);
          },
        )
        .subscribe();
    ChatService.instance.markIncomingRead(widget.threadId);
  }

  Future<void> _load() async {
    try {
      final messages = await ChatService.instance.messages(widget.threadId);
      if (!mounted) return;
      setState(() { _messages = messages; _loading = false; });
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (widget.targetMessageId != null) {
          _revealTargetMessage();
        } else if (_scrollController.hasClients) {
          _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
        }
      });
    } catch (e) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _revealTargetMessage() async {
    final targetId = widget.targetMessageId?.trim();
    if (targetId == null || targetId.isEmpty) return;

    final index = _messages.indexWhere(
      (message) => message['id']?.toString() == targetId,
    );
    if (index < 0) return;

    final key = _messageKeys.putIfAbsent(targetId, () => GlobalKey());

    for (var attempt = 0; attempt < 6; attempt++) {
      if (!_scrollController.hasClients) return;

      final targetContext = key.currentContext;
      if (targetContext != null) {
        return Scrollable.ensureVisible(
          targetContext,
          alignment: 0.35,
          duration: const Duration(milliseconds: 280),
          curve: Curves.easeOutCubic,
        );
      }

      if (!mounted) return;

      final max = _scrollController.position.maxScrollExtent;
      final estimated = max == 0
          ? 0.0
          : (index / _messages.length.clamp(1, 100000)) * max;
      _scrollController.jumpTo(
        estimated.clamp(0.0, max).toDouble(),
      );
      await Future<void>.delayed(const Duration(milliseconds: 60));
    }
  }

  Future<void> _send() async {
    final text = _controller.text.trim();
    if (text.isEmpty && _pendingImagePath == null || _sending) return;
    setState(() => _sending = true);
    try {
      await ChatService.instance.sendMessage(
        threadId: widget.threadId,
        body: text.isEmpty ? null : text,
        imagePath: _pendingImagePath,
      );
      _controller.clear();
      _pendingImagePath = null;
      await _load();
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  Future<void> _pickImage() async {
    if (_sending) return;
    try {
      setState(() => _sending = true);
      final path = await ChatService.instance.pickAndUploadImage(widget.threadId);
      if (mounted && path != null) setState(() => _pendingImagePath = path);
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    final channel = _channel;
    if (channel != null) Supabase.instance.client.removeChannel(channel);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F4EE),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF8F4EE),
        elevation: 0,
        title: Text(widget.title, style: const TextStyle(fontWeight: FontWeight.w700)),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Expanded(
                  child: ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(16),
                    itemCount: _messages.length,
                    itemBuilder: (_, i) {
                      final message = _messages[i];
                      final id = message['id']?.toString() ?? '';
                      final key = id.isEmpty
                          ? null
                          : _messageKeys.putIfAbsent(id, () => GlobalKey());
                      return KeyedSubtree(
                        key: key,
                        child: _MessageBubble(
                          message: message,
                          highlighted: id == widget.targetMessageId,
                        ),
                      );
                    },
                  ),
                ),
                if (_pendingImagePath != null)
                  const Padding(
                    padding: EdgeInsets.only(bottom: 6),
                    child: Text('Изображение прикреплено'),
                  ),
                SafeArea(
                  top: false,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
                    child: Row(
                      children: [
                        IconButton(
                          onPressed: _sending ? null : _pickImage,
                          icon: const Icon(Icons.add_photo_alternate_outlined),
                        ),
                        Expanded(
                          child: TextField(
                            controller: _controller,
                            maxLines: 4,
                            minLines: 1,
                            decoration: InputDecoration(
                              hintText: 'Ответ клиенту',
                              filled: true,
                              fillColor: Colors.white,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(22),
                              ),
                            ),
                          ),
                        ),
                        IconButton(
                          onPressed: _sending ? null : _send,
                          icon: _sending
                              ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                              : const Icon(Icons.arrow_upward_rounded),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}
