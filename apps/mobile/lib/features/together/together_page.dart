import 'package:flutter/material.dart';

import '../../core/models.dart';
import '../../core/session.dart';
import '../../design/status.dart';
import '../../design/theme.dart';

const List<String> _togetherSignals = [
  'quiet',
  'overwhelmed',
  'enjoying',
  'need_exit',
  'low_energy',
  'laugh',
  'breather',
  'present',
];

/// Together Mode: a session with a pairing code, a permission scope that the
/// app must honour, a visible exit button and non-verbal signals.
class TogetherPage extends StatefulWidget {
  const TogetherPage({super.key});

  @override
  State<TogetherPage> createState() => _TogetherPageState();
}

class _TogetherPageState extends State<TogetherPage> {
  List<TogetherSession> _sessions = const [];
  List<ConnectionEntry> _connections = const [];
  String? _error;
  bool _busy = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final state = AppState.read(context);
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final sessions = await state.api.get('/together/sessions');
      final conns = await state.api.get('/discover/connections');
      if (!mounted) return;
      setState(() {
        _sessions = sessions is Map && sessions['sessions'] is List
            ? (sessions['sessions'] as List)
                .whereType<Map<String, Object?>>()
                .map(TogetherSession.fromJson)
                .toList()
            : [];
        _connections = conns is List
            ? conns
                .whereType<Map<String, Object?>>()
                .map(ConnectionEntry.fromJson)
                .toList()
            : [];
      });
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _create() async {
    final api = AppState.read(context).api;
    final pick = await showModalBottomSheet<int>(
      context: context,
      showDragHandle: true,
      builder: (context) => _connections.isEmpty
          ? const Padding(
              padding: EdgeInsets.all(32),
              child: Text(
                'You need a connection first (a mutual introduction).',
                textAlign: TextAlign.center,
              ),
            )
          : ListView.builder(
              shrinkWrap: true,
              itemCount: _connections.length,
              itemBuilder: (context, i) {
                final c = _connections[i];
                return ListTile(
                  leading: const Icon(Icons.people_outline),
                  title: Text(c.user.displayName),
                  onTap: () => Navigator.of(context).pop(c.userId),
                );
              },
            ),
    );
    if (pick == null) return;
    try {
      await api.post('/together/sessions', {
        'partner_id': pick,
      });
      if (mounted) _load();
    } catch (e) {
      _toast(e.toString());
    }
  }

  Future<void> _join() async {
    final api = AppState.read(context).api;
    final code = await showDialog<String>(
      context: context,
      builder: (context) => const _JoinDialog(),
    );
    if (code == null || code.isEmpty) return;
    try {
      await api.post('/together/join', {
        'pairing_code': code.trim().toUpperCase(),
      });
      if (mounted) _load();
    } catch (e) {
      _toast(e.toString());
    }
  }

  Future<void> _signal(TogetherSession s, String signal) async {
    try {
      await AppState.read(context).api.post('/together/sessions/${s.id}/signal', {
        'signal': signal,
      });
      _toast('Sent: $signal');
    } catch (e) {
      _toast(e.toString());
    }
  }

  Future<void> _end(TogetherSession s) async {
    try {
      await AppState.read(context).api.post('/together/sessions/${s.id}/end');
      if (mounted) _load();
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
        title: const Text('Together'),
        actions: [
          IconButton(
            tooltip: 'New session',
            onPressed: _create,
            icon: const Icon(Icons.add_link),
          ),
          IconButton(
            tooltip: 'Join with pairing code',
            onPressed: _join,
            icon: const Icon(Icons.qr_code_2),
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
    if (_busy && _sessions.isEmpty) {
      return const LoadingView(label: 'Loading together sessions…');
    }
    if (_error != null) return ErrorView(message: _error!, onRetry: _load);
    if (_sessions.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: const [
          Padding(
            padding: EdgeInsets.all(32),
            child: Text(
              'No sessions. Start one to hang out with an exit button — a '
              'pairing code, a permission scope, and signals instead of '
              'words when words are too much.',
              textAlign: TextAlign.center,
            ),
          ),
        ],
      );
    }
    return ListView.builder(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: _sessions.length,
      itemBuilder: (_, i) {
        final s = _sessions[i];
        final active = s.state == 'active' || s.state == 'waiting';
        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        '${s.otherUser.displayName} · session ${s.id}',
                        style: const TextStyle(
                            fontWeight: FontWeight.w700, fontSize: 16),
                      ),
                    ),
                    Chip(
                      backgroundColor:
                          active ? ParallelColors.ink : ParallelColors.ramp[4],
                      label: Text(
                        s.state,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: active
                              ? ParallelColors.paper
                              : ParallelColors.ink,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'Pairing code: ${s.pairingCode}',
                  style: const TextStyle(
                      fontSize: 15, fontWeight: FontWeight.w700, letterSpacing: 1),
                ),
                if ((s.permissionScope['no_data_saved'] == true)) ...[
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(Icons.shield_outlined, size: 14),
                      const SizedBox(width: 6),
                      Text(
                        'No data is saved from this session.',
                        style: TextStyle(
                            color: ParallelColors.inkMuted, fontSize: 12),
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _togetherSignals
                      .map((sg) => ActionChip(
                            label: Text(sg),
                            onPressed: active ? () => _signal(s, sg) : null,
                          ))
                      .toList(),
                ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: active ? () => _end(s) : null,
                  icon: const Icon(Icons.logout, size: 18),
                  label: const Text('End session'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _JoinDialog extends StatefulWidget {
  const _JoinDialog();

  @override
  State<_JoinDialog> createState() => _JoinDialogState();
}

class _JoinDialogState extends State<_JoinDialog> {
  final _code = TextEditingController();

  @override
  void dispose() {
    _code.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Join a session'),
      content: TextField(
        controller: _code,
        textCapitalization: TextCapitalization.characters,
        decoration: const InputDecoration(labelText: 'Pairing code'),
        onSubmitted: (v) => Navigator.of(context).pop(v),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(_code.text),
          child: const Text('Join'),
        ),
      ],
    );
  }
}