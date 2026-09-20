import 'package:flutter/material.dart';

import '../../core/models.dart';
import '../../core/session.dart';
import '../../design/status.dart';
import '../../design/theme.dart';

/// Progressive compatibility questionnaire. Renders every feature in the
/// catalogue grouped by dimension; the user picks their value, how important
/// it is to them, and whether it is a dealbreaker.
class QuestionnairePage extends StatefulWidget {
  const QuestionnairePage({super.key});

  @override
  State<QuestionnairePage> createState() => _QuestionnairePageState();
}

class _QuestionnairePageState extends State<QuestionnairePage> {
  List<DimensionGroup> _catalog = const [];
  Map<String, _FeatCtrl> _values = {};
  List<String> _interests = const [];
  String? _error;
  bool _busy = true;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final api = AppState.read(context).api;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final catalog = await api.get('/compat/catalog');
      final mine = await api.get('/compat/features');
      final interests = await api.get('/compat/interests');
      if (!mounted) return;
      final groups = catalog is List
          ? catalog
              .whereType<Map<String, Object?>>()
              .map(DimensionGroup.fromJson)
              .toList()
          : <DimensionGroup>[];
      final existing = mine is List
          ? {
              for (final f in mine.whereType<Map<String, Object?>>())
                _str(f['key']): f,
            }
          : <String, Map<String, Object?>>{};
      final ctrls = <String, _FeatCtrl>{};
      for (final g in groups) {
        for (final f in g.features) {
          final mineJson = existing[f.key];
          final value = mineJson == null
              ? (f.options.isEmpty ? '' : f.options.first)
              : _str(mineJson['value']);
          final importance = mineJson == null
              ? 3
              : (mineJson['importance'] is num
                  ? (mineJson['importance'] as num).toInt()
                  : 3);
          final dealbreaker =
              mineJson != null && _str(mineJson['classification']) == 'dealbreaker';
          ctrls[f.key] = _FeatCtrl(f, value, importance, dealbreaker);
        }
      }
      setState(() {
        _catalog = groups;
        _values = ctrls;
        _interests = interests is Map && interests['interests'] is List
            ? (interests['interests'] as List).map(_str).toList()
            : const [];
      });
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      await AppState.read(context).api.post('/compat/features', {
        'features': [
          for (final f in _values.values)
            f.toPayload(),
        ],
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(const SnackBar(content: Text('Saved.')));
      Navigator.of(context).pop();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(SnackBar(content: Text(e.toString())));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _addInterest() async {
    final api = AppState.read(context).api;
    final text = await showDialog<String>(
      context: context,
      builder: (context) => const _InterestDialog(),
    );
    if (text == null || text.trim().isEmpty) return;
    try {
      await api.post('/compat/interests', {
        'interests': [text.trim()],
      });
      if (!mounted) return;
      await _load();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(SnackBar(content: Text(e.toString())));
      }
    }
  }

  static String _str(Object? v) => v is String ? v : '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Your compatibility'),
        actions: [
          IconButton(tooltip: 'Save', onPressed: _saving ? null : _save, icon: const Icon(Icons.check)),
        ],
      ),
      body: _busy && _catalog.isEmpty
          ? const LoadingView(label: 'Loading the questionnaire…')
          : _error != null && _catalog.isEmpty
              ? ErrorView(message: _error!, onRetry: _load)
              : ListView(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  children: [
                    const Padding(
                      padding: EdgeInsets.fromLTRB(16, 8, 16, 8),
                      child: Text(
                        'Mark what helps you match honestly. These power the '
                        'reasons other people see — "dealbreaker" is shown '
                        'only as a conflict, never as raw data.',
                        style: TextStyle(height: 1.35),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: _buildInterests(),
                    ),
                    for (final g in _catalog) _buildGroup(g),
                    Padding(
                      padding: const EdgeInsets.all(24),
                      child: FilledButton(
                        onPressed: _saving ? null : _save,
                        child: _saving
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Text('Save answers'),
                      ),
                    ),
                  ],
                ),
    );
  }

  Widget _buildInterests() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Interests',
              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
            ),
            const SizedBox(height: 4),
            Text(
              'Shared interests appear in today\'s reason.',
              style: TextStyle(color: ParallelColors.inkMuted, fontSize: 13),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final t in _interests)
                  InputChip(
                    label: Text(t),
                    onDeleted: () async {
                      // removing an interest is not exposed by the backend;
                      // keep the chip but add-to-list is the primary path.
                    },
                  ),
                ActionChip(
                  avatar: const Icon(Icons.add, size: 16),
                  label: const Text('Add'),
                  onPressed: _addInterest,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGroup(DimensionGroup g) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              g.dimension,
              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
            ),
            const SizedBox(height: 4),
            Text(
              'Answers marked "dealbreaker" gate matches — a conflict on one '
              'is a hard pass.',
              style: TextStyle(color: ParallelColors.inkMuted, fontSize: 12),
            ),
            const SizedBox(height: 8),
            for (final f in g.features) _FeatTile(ctrl: _values[f.key]!),
          ],
        ),
      ),
    );
  }
}

class _FeatTile extends StatelessWidget {
  const _FeatTile({required this.ctrl});

  final _FeatCtrl ctrl;

  @override
  Widget build(BuildContext context) {
    final feat = ctrl.feature;
    return StatefulBuilder(
      builder: (context, setState) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    feat.label,
                    style: const TextStyle(
                        fontWeight: FontWeight.w600, fontSize: 14),
                  ),
                ),
                Switch(
                  value: ctrl.dealbreaker,
                  onChanged: (v) => setState(() => ctrl.dealbreaker = v),
                ),
                Text(
                  ctrl.dealbreaker ? 'dealbreaker' : 'preference',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: ctrl.dealbreaker
                        ? ParallelColors.ink
                        : ParallelColors.inkMuted,
                  ),
                ),
              ],
            ),
            if (feat.options.isNotEmpty)
              InputDecorator(
                decoration: const InputDecoration(
                    contentPadding:
                        EdgeInsets.symmetric(horizontal: 12, vertical: 6)),
                child: DropdownButton<String>(
                  value: feat.options.contains(ctrl.value)
                      ? ctrl.value
                      : feat.options.first,
                  isExpanded: true,
                  isDense: true,
                  underline: const SizedBox.shrink(),
                  items: [
                    for (final o in feat.options)
                      DropdownMenuItem(value: o, child: Text(o)),
                  ],
                  onChanged: (v) =>
                      setState(() => ctrl.value = v ?? feat.options.first),
                ),
              ),
            if (feat.ordinal) ...[
              const SizedBox(height: 4),
              Row(
                children: [
                  Icon(
                    ctrl.importance == 0
                        ? Icons.not_interested
                        : Icons.stars_outlined,
                    size: 15,
                    color: ParallelColors.inkMuted,
                  ),
                  Expanded(
                    child: Slider(
                      value: ctrl.importance.toDouble().clamp(0, 5),
                      min: 0,
                      max: 5,
                      divisions: 5,
                      label: 'Importance ${ctrl.importance}',
                      onChanged: (v) =>
                          setState(() => ctrl.importance = v.round()),
                    ),
                  ),
                  SizedBox(
                    width: 56,
                    child: Text(
                      ctrl.importance == 0
                          ? 'not important'
                          : '${ctrl.importance}',
                      textAlign: TextAlign.right,
                      style: TextStyle(
                          fontSize: 12, color: ParallelColors.inkMuted),
                    ),
                  ),
                ],
              ),
            ],
            const Divider(height: 16),
          ],
        );
      },
    );
  }
}

class _FeatCtrl {
  _FeatCtrl(this.feature, this.value, this.importance, this.dealbreaker);

  final CatalogFeature feature;
  String value;
  int importance;
  bool dealbreaker;

  Map<String, Object?> toPayload() => {
        'key': feature.key,
        'value': value,
        'importance': importance,
        'classification': dealbreaker ? 'dealbreaker' : 'preference',
        'visibility': 'public',
      };
}

class _InterestDialog extends StatefulWidget {
  const _InterestDialog();

  @override
  State<_InterestDialog> createState() => _InterestDialogState();
}

class _InterestDialogState extends State<_InterestDialog> {
  final _text = TextEditingController();

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add an interest'),
      content: TextField(
        controller: _text,
        autofocus: true,
        decoration: const InputDecoration(labelText: 'e.g. board games, hiking'),
        onSubmitted: (v) => Navigator.of(context).pop(v),
      ),
      actions: [
        TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel')),
        FilledButton(
            onPressed: () => Navigator.of(context).pop(_text.text),
            child: const Text('Add')),
      ],
    );
  }
}