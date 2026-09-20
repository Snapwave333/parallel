import 'package:flutter/material.dart';

import '../../core/models.dart';
import '../../core/session.dart';
import '../../design/status.dart';
import '../../design/theme.dart';

/// Safety: who you have blocked (and unblock), plus reporting. Reports remove
/// you from the other person's discovery pool and are looked at by the team.
class SafetyPage extends StatefulWidget {
  const SafetyPage({super.key});

  @override
  State<SafetyPage> createState() => _SafetyPageState();
}

class _SafetyPageState extends State<SafetyPage> {
  List<Block> _blocks = const [];
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
      final json = await AppState.read(context).api.get('/safety/blocks');
      if (!mounted) return;
      setState(() {
        _blocks = json is List
            ? json.whereType<Map<String, Object?>>().map(Block.fromJson).toList()
            : const [];
      });
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _block(int userId) async {
    final api = AppState.read(context).api;
    try {
      await api.post('/safety/blocks', {'user_id': userId});
      if (!mounted) return;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(const SnackBar(
            content: Text('Blocked. You will not be shown to them again.')));
      await _load();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(SnackBar(content: Text(e.toString())));
      }
    }
  }

  Future<void> _blockById() async {
    final text = await showDialog<String>(
      context: context,
      builder: (context) => const _BlockDialog(),
    );
    final id = text == null ? null : int.tryParse(text.trim());
    if (id == null) return;
    await _block(id);
  }

  Future<void> _unblock(int userId) async {
    try {
      await AppState.read(context).api.delete('/safety/blocks/$userId');
      if (mounted) _load();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(SnackBar(content: Text(e.toString())));
      }
    }
  }

  Future<void> _report() async {
    final api = AppState.read(context).api;
    final input = await showDialog<_ReportInput>(
      context: context,
      builder: (context) => const _ReportDialog(),
    );
    if (input == null) return;
    try {
      final json = await api.post('/safety/reports', {
        'user_id': input.userId,
        if (input.category.isNotEmpty) 'category': input.category,
        if (input.reason.isNotEmpty) 'reason': input.reason,
      });
      final msg = json is Map && json['message'] is String
          ? json['message'] as String
          : 'Report submitted.';
      if (!mounted) return;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(msg)));
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
        title: const Text('Safety'),
        actions: [
          IconButton(tooltip: 'Refresh', onPressed: _load, icon: const Icon(Icons.refresh)),
          IconButton(tooltip: 'Block by user id', onPressed: _blockById, icon: const Icon(Icons.person_off_outlined)),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 8),
        children: [
          Card(
            child: ListTile(
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              leading: const Icon(Icons.flag_outlined),
              title: const Text('Report someone',
                  style: TextStyle(fontWeight: FontWeight.w700)),
              subtitle: Text('Blocking is forever; reporting removes you from '
                  'their pool immediately.',
                  style: TextStyle(
                      color: ParallelColors.inkMuted, fontSize: 13)),
              trailing: const Icon(Icons.chevron_right, size: 20),
              onTap: _report,
            ),
          ),
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 16, 16, 6),
            child: Text('Blocked people',
                style: TextStyle(
                    fontWeight: FontWeight.w700, fontSize: 14)),
          ),
          if (_busy && _blocks.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: LoadingView(),
            ),
          if (_error != null && _blocks.isEmpty)
            ErrorView(message: _error!, onRetry: _load),
          if (!_busy && _blocks.isEmpty && _error == null)
            const Padding(
              padding: EdgeInsets.all(24),
              child: Text('Nobody is blocked right now.',
                  textAlign: TextAlign.center),
            ),
          for (final b in _blocks)
            Card(
              child: ListTile(
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                leading: const Icon(Icons.block, size: 20),
                title: Text(b.user.displayName),
                subtitle: Text('User ${b.blockedId}',
                    style: const TextStyle(fontSize: 12)),
                trailing: TextButton(
                  onPressed: () => _unblock(b.blockedId),
                  child: const Text('Unblock'),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _BlockDialog extends StatelessWidget {
  const _BlockDialog();

  @override
  Widget build(BuildContext context) {
    final text = TextEditingController();
    return AlertDialog(
      title: const Text('Block a user'),
      content: TextField(
        controller: text,
        autofocus: true,
        keyboardType: TextInputType.number,
        decoration: const InputDecoration(
            labelText: 'User id (shown on their profile)'),
        onSubmitted: (v) => Navigator.of(context).pop(v),
      ),
      actions: [
        TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel')),
        FilledButton(
            onPressed: () => Navigator.of(context).pop(text.text),
            child: const Text('Block')),
      ],
    );
  }
}

class _ReportInput {
  _ReportInput({required this.userId, required this.category, required this.reason});

  final int userId;
  final String category;
  final String reason;
}

class _ReportDialog extends StatefulWidget {
  const _ReportDialog();

  @override
  State<_ReportDialog> createState() => _ReportDialogState();
}

class _ReportDialogState extends State<_ReportDialog> {
  final _userId = TextEditingController();
  final _category = TextEditingController();
  final _reason = TextEditingController();
  String? _error;

  @override
  void dispose() {
    _userId.dispose();
    _category.dispose();
    _reason.dispose();
    super.dispose();
  }

  void _submit() {
    final id = int.tryParse(_userId.text.trim());
    if (id == null) {
      setState(() => _error = 'Enter the user\'s id (shown on their profile).');
      return;
    }
    Navigator.of(context).pop(_ReportInput(
      userId: id,
      category: _category.text.trim(),
      reason: _reason.text.trim(),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Report someone'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _userId,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'User id'),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _category,
              decoration: const InputDecoration(labelText: 'Category (optional)'),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _reason,
              maxLines: 3,
              decoration: const InputDecoration(labelText: 'What happened?'),
            ),
            if (_error != null)
              Padding(
                padding: const EdgeInsets.only(top: 10),
                child: Text(
                  _error!,
                  style: TextStyle(
                      color: Theme.of(context).colorScheme.error, fontSize: 13),
                ),
              ),
          ],
        ),
      ),
      actions: [
        TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel')),
        FilledButton(onPressed: _submit, child: const Text('Submit report')),
      ],
    );
  }
}