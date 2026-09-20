import 'package:flutter/material.dart';

import '../../core/models.dart';
import '../../core/session.dart';
import '../../design/status.dart';
import '../../design/theme.dart';
import 'chat_page.dart';

class ConversationsPage extends StatefulWidget {
  const ConversationsPage({super.key, required this.state});

  final AppState state;

  @override
  State<ConversationsPage> createState() => _ConversationsPageState();
}

class _ConversationsPageState extends State<ConversationsPage> {
  List<Conversation> _conversations = const [];
  List<ConnectionEntry> _connections = const [];
  String? _error;
  bool _busy = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final convs = await widget.state.api.get('/messaging/conversations');
      final conns = await widget.state.api.get('/discover/connections');
      if (!mounted) return;
      setState(() {
        _conversations = convs is List
            ? convs.whereType<Map<String, Object?>>().map(Conversation.fromJson).toList()
            : [];
        _connections = conns is List
            ? conns.whereType<Map<String, Object?>>().map(ConnectionEntry.fromJson).toList()
            : [];
      });
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _open(Conversation c) async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => ChatPage(
          state: widget.state,
          conversationId: c.id,
          peer: c.otherUser,
        ),
      ),
    );
    _load();
  }

  Future<void> _newConversation() async {
    final pick = await showModalBottomSheet<int>(
      context: context,
      showDragHandle: true,
      builder: (context) => _NewConversationSheet(connections: _connections),
    );
    if (pick == null) return;
    try {
      await widget.state.api.post('/messaging/conversations', {'other_user_id': pick});
      if (!mounted) return;
      _load();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(SnackBar(content: Text(e.toString())));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Messages'),
        actions: [
          IconButton(
            tooltip: 'New conversation',
            onPressed: _busy ? null : _newConversation,
            icon: const Icon(Icons.edit_outlined),
          ),
          IconButton(
            tooltip: 'Refresh',
            onPressed: _load,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        child: _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    if (_busy && _conversations.isEmpty) {
      return const LoadingView(label: 'Loading conversations…');
    }
    if (_error != null && _conversations.isEmpty) {
      return ErrorView(message: _error!, onRetry: _load);
    }
    if (_conversations.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: const [
          Padding(
            padding: EdgeInsets.all(32),
            child: Text(
              'No conversations yet.\n\nMatch with someone today and they will '
              'appear here.',
              textAlign: TextAlign.center,
            ),
          ),
        ],
      );
    }
    return ListView.separated(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: _conversations.length,
      separatorBuilder: (_, _) => const Divider(height: 1, indent: 72),
      itemBuilder: (_, i) {
        final c = _conversations[i];
        final last = c.lastMessage;
        return ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          leading: CircleAvatar(
            radius: 22,
            backgroundColor: ParallelColors.ramp[2],
            foregroundColor: ParallelColors.paper,
            child: Text(
              c.otherUser.displayName.characters.first.toUpperCase(),
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
          title: Text(
            c.otherUser.displayName,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          subtitle: Text(
            last?.body ?? 'Say hi',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: last == null ? ParallelColors.inkMuted : ParallelColors.ink,
            ),
          ),
          trailing: const Icon(Icons.chevron_right, size: 20),
          onTap: () => _open(c),
        );
      },
    );
  }
}

class _NewConversationSheet extends StatelessWidget {
  const _NewConversationSheet({required this.connections});

  final List<ConnectionEntry> connections;

  @override
  Widget build(BuildContext context) {
    if (connections.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(32),
        child: Text(
          'No connections yet. A connection forms when an introduction is '
          'mutual — until then you can still message from a match.',
          textAlign: TextAlign.center,
        ),
      );
    }
    return SafeArea(
      child: ListView.builder(
        shrinkWrap: true,
        itemCount: connections.length,
        itemBuilder: (context, i) {
          final c = connections[i];
          return ListTile(
            leading: const Icon(Icons.person_outline),
            title: Text(c.user.displayName),
            subtitle: Text(c.user.city ?? 'Connection'),
            onTap: () => Navigator.of(context).pop(c.userId),
          );
        },
      ),
    );
  }
}