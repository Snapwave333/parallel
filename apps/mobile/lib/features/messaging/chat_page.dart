import 'package:flutter/material.dart';

import '../../core/api_client.dart';
import '../../core/config.dart';
import '../../core/models.dart';
import '../../core/session.dart';
import '../../design/status.dart';
import '../../design/theme.dart';

class ChatPage extends StatefulWidget {
  const ChatPage({
    super.key,
    required this.state,
    required this.conversationId,
    required this.peer,
  });

  final AppState state;
  final int conversationId;
  final PublicUser peer;

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final _input = TextEditingController();
  List<ChatMessage> _messages = const [];
  List<ContractRule> _contract = const [];
  IntentInfo? _intent;
  SocialStatus? _status;
  String? _error;
  bool _busy = true;
  bool _sending = false;

  int get _me => widget.state.me?.id ?? 0;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _input.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final api = widget.state.api;
      final msgs = await api.get('/messaging/conversations/${widget.conversationId}/messages');
      final rules =
          await api.get('/messaging/conversations/${widget.conversationId}/contract');
      final intent = await api.get('/messaging/intent/${widget.peer.id}');
      final status = await api.get('/messaging/status/me');
      if (!mounted) return;
      setState(() {
        _messages = msgs is Map && msgs['messages'] is List
            ? (msgs['messages'] as List)
                .whereType<Map<String, Object?>>()
                .map(ChatMessage.fromJson)
                .toList()
            : [];
        _contract = rules is Map && rules['rules'] is List
            ? (rules['rules'] as List)
                .whereType<Map<String, Object?>>()
                .map(ContractRule.fromJson)
                .toList()
            : [];
        _intent = intent is Map<String, Object?>
            ? IntentInfo.fromJson(intent)
            : null;
        _status = status is Map<String, Object?>
            ? SocialStatus.fromJson(status)
            : null;
      });
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _send() async {
    final body = _input.text.trim();
    if (body.isEmpty || _sending) return;
    setState(() => _sending = true);
    _input.clear();
    try {
      final json = await widget.state.api.post(
        '/messaging/conversations/${widget.conversationId}/messages',
        {'body': body},
      );
      if (json is Map && json['message'] is Map) {
        setState(() {
          _messages = [
            ..._messages,
            ChatMessage.fromJson(json['message'] as Map<String, Object?>),
          ];
        });
      }
    } catch (e) {
      _input.text = body;
      _toast(e.toString());
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  Future<void> _editContract() async {
    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) => _ContractSheet(
        rules: _contract,
        api: widget.state.api,
        conversationId: widget.conversationId,
      ),
    );
    if (result == true) _load();
  }

  Future<void> _setIntent(String signal) async {
    try {
      await widget.state.api.post('/messaging/intent/${widget.peer.id}', {
        'signal': signal,
      });
      await _load();
    } catch (e) {
      _toast(e.toString());
    }
  }

  void _toast(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.peer.displayName,
                style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
            if (_status != null)
              Text(
                'battery ${_status!.battery}/4 · ${_status!.temperature}',
                style: TextStyle(
                    fontSize: 12, color: ParallelColors.inkMuted),
              ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Conversation contract',
            onPressed: _editContract,
            icon: const Icon(Icons.rule_outlined),
          ),
          IconButton(
            tooltip: 'Refresh',
            onPressed: _load,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(child: _buildMessages()),
          _IntentBar(
            intent: _intent,
            onSelect: _setIntent,
          ),
          _buildComposer(),
        ],
      ),
    );
  }

  Widget _buildMessages() {
    if (_busy && _messages.isEmpty) {
      return const LoadingView(label: 'Loading messages…');
    }
    if (_error != null && _messages.isEmpty) {
      return ErrorView(message: _error!, onRetry: _load);
    }
    if (_messages.isEmpty) {
      return const Center(
        child: Text(
          'Nothing yet. No response needed unless you want to.',
          textAlign: TextAlign.center,
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      reverse: true,
      itemCount: _messages.length,
      itemBuilder: (_, i) {
        final m = _messages[_messages.length - 1 - i];
        final mine = m.senderId == _me;
        return Align(
          alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
          child: Container(
            margin: const EdgeInsets.symmetric(vertical: 3),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            constraints: const BoxConstraints(maxWidth: 300),
            decoration: BoxDecoration(
              color: mine ? ParallelColors.ink : ParallelColors.paper,
              borderRadius: BorderRadius.circular(16),
              border: mine
                  ? null
                  : Border.all(color: ParallelColors.lineSoft),
            ),
            child: Column(
              crossAxisAlignment: mine
                  ? CrossAxisAlignment.end
                  : CrossAxisAlignment.start,
              children: [
                Text(
                  m.body,
                  style: TextStyle(
                    color: mine ? ParallelColors.paper : ParallelColors.ink,
                    height: 1.3,
                  ),
                ),
                const SizedBox(height: 3),
                if (m.noResponseNeeded)
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.pause_circle_outline,
                          size: 11,
                          color: mine
                              ? ParallelColors.ramp[3]
                              : ParallelColors.inkMuted),
                      const SizedBox(width: 3),
                      Text(
                        'no reply expected',
                        style: TextStyle(
                          fontSize: 10,
                          color: mine
                              ? ParallelColors.ramp[3]
                              : ParallelColors.inkMuted,
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildComposer() {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 6, 12, 10),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _input,
                minLines: 1,
                maxLines: 4,
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => _send(),
                decoration: const InputDecoration(
                  hintText: 'Write …',
                  contentPadding:
                      EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                ),
              ),
            ),
            const SizedBox(width: 8),
            IconButton.filled(
              tooltip: 'Send',
              onPressed: _sending ? null : _send,
              icon: const Icon(Icons.arrow_upward),
            ),
          ],
        ),
      ),
    );
  }
}

class _IntentBar extends StatelessWidget {
  const _IntentBar({required this.intent, required this.onSelect});

  final IntentInfo? intent;
  final ValueChanged<String> onSelect;

  @override
  Widget build(BuildContext context) {
    final mine = intent?.mine;
    final mutual = intent?.mutual;
    if (mutual != null) {
      return Container(
        width: double.infinity,
        margin: const EdgeInsets.fromLTRB(12, 6, 12, 0),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: ParallelColors.ink,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          '🔥 You both chose "${_label(mutual)}" — it is mutual.',
          style: const TextStyle(color: ParallelColors.paper, fontSize: 13),
        ),
      );
    }
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: Row(
        children: intentSignals.map((s) {
          final selected = mine == s;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              label: Text(_label(s)),
              selected: selected,
              onSelected: (_) => onSelect(s),
              selectedColor: ParallelColors.ink,
              labelStyle: TextStyle(
                color: selected ? ParallelColors.paper : ParallelColors.ink,
                fontSize: 12,
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  static String _label(String s) {
    switch (s) {
      case 'romantic':
        return 'romantic';
      case 'more_time':
        return 'more time';
      case 'friendship':
        return 'friendship';
      case 'unsure':
        return 'unsure';
      case 'meet':
        return 'meet';
      case 'not_compatible':
        return 'not compatible';
      default:
        return s;
    }
  }
}

class _ContractSheet extends StatefulWidget {
  const _ContractSheet({
    required this.rules,
    required this.api,
    required this.conversationId,
  });

  final List<ContractRule> rules;
  final ApiClient api;
  final int conversationId;

  @override
  State<_ContractSheet> createState() => _ContractSheetState();
}

class _ContractSheetState extends State<_ContractSheet> {
  late List<ContractRule> _rules;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _rules = List.of(widget.rules);
  }

  Future<void> _save() async {
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await widget.api.put(
        '/messaging/conversations/${widget.conversationId}/contract',
        {'rules': _rules.map((r) => {'key': r.key, 'enabled': r.enabled}).toList()},
      );
      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          left: 16,
          right: 16,
          bottom: 16 + MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Conversation contract',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 4),
            Text(
              'Clear norms for how this chat works — both of you can see and '
              'change them.',
              style: TextStyle(color: ParallelColors.inkMuted, fontSize: 13),
            ),
            const SizedBox(height: 12),
            Flexible(
              child: ListView(
                shrinkWrap: true,
                children: [
                  for (final r in _rules)
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      value: r.enabled,
                      title: Text(r.label, style: const TextStyle(fontSize: 14)),
                      subtitle: r.askFirst
                          ? const Text('Ask first', style: TextStyle(fontSize: 11))
                          : null,
                      onChanged: (v) => setState(() {
                        _rules = [
                          for (final x in _rules)
                            if (x.key == r.key) x.copyWith(enabled: v) else x,
                        ];
                      }),
                    ),
                ],
              ),
            ),
            if (_error != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(
                  _error!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error, fontSize: 13),
                ),
              ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.of(context).pop(false),
                    child: const Text('Cancel'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: FilledButton(
                    onPressed: _saving ? null : _save,
                    child: _saving
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Save'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}