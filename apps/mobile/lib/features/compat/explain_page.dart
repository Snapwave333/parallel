import 'package:flutter/material.dart';

import '../../core/models.dart';
import '../../core/session.dart';
import '../../design/status.dart';
import '../../design/theme.dart';

/// Human-readable compatibility breakdown for one person, straight off
/// `/compat/explain/{id}`. The point is that nothing about the match is a
/// silent black box.
class ExplainPage extends StatefulWidget {
  const ExplainPage({super.key, required this.state, required this.otherId});

  final AppState state;
  final int otherId;

  @override
  State<ExplainPage> createState() => _ExplainPageState();
}

class _ExplainPageState extends State<ExplainPage> {
  ExplainResponse? _explain;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final json =
          await widget.state.api.get('/compat/explain/${widget.otherId}');
      if (mounted && json is Map<String, Object?>) {
        setState(() => _explain = ExplainResponse.fromJson(json));
      }
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Why we match')),
      body: _explain == null
          ? (_error != null
              ? ErrorView(message: _error!, onRetry: _load)
              : const LoadingView(label: 'Loading the reason…'))
          : _build(),
    );
  }

  Widget _build() {
    final e = _explain!;
    return ListView(
      padding: const EdgeInsets.symmetric(vertical: 8),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (e.dealbreakerConflicts.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Text(
                      '${e.dealbreakerConflicts.length} dealbreaker '
                      '${e.dealbreakerConflicts.length == 1 ? 'conflict' : 'conflicts'} '
                      'block this match.',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                for (final line in e.explain)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Padding(
                          padding: EdgeInsets.only(top: 4),
                          child: Icon(Icons.circle, size: 8),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(line.text,
                              style: const TextStyle(height: 1.35)),
                        ),
                      ],
                    ),
                  ),
                if (e.sharedInterests > 0)
                  Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(
                      '${e.sharedInterests} shared '
                      '${e.sharedInterests == 1 ? 'interest' : 'interests'}',
                      style: TextStyle(
                          color: ParallelColors.inkMuted, fontSize: 13),
                    ),
                  ),
              ],
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 6),
          child: Text(
            'Dimension by dimension',
            style: TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 14,
                color: ParallelColors.ink),
          ),
        ),
        for (final d in e.dimensions) _dimensionCard(d),
      ],
    );
  }

  Widget _dimensionCard(ExplainDimension d) {
    final color = switch (d.alignment) {
      'Aligned' => ParallelColors.ramp[0],
      'Complementary' => ParallelColors.ramp[2],
      'PotentialFriction' => ParallelColors.ramp[4],
      _ => ParallelColors.line,
    };
    final left = d.aValue;
    final right = d.bValue;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 34,
              height: 34,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
              ),
              child: Text(
                d.compat == null ? '?' : '${(d.compat! * 100).round()}',
                style: TextStyle(
                  color: d.alignment == 'PotentialFriction'
                      ? ParallelColors.ink
                      : ParallelColors.paper,
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    d.label,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  Text(
                    d.alignment,
                    style: TextStyle(
                      color: ParallelColors.inkMuted,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (left != null || right != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      'you: ${left ?? '—'}',
                      style: const TextStyle(fontSize: 13, height: 1.3),
                    ),
                    Text(
                      'them: ${right ?? '—'}',
                      style: TextStyle(
                          fontSize: 13, height: 1.3, color: ParallelColors.inkMuted),
                    ),
                  ],
                  if ((d.aImportance > 0 || d.bImportance > 0) &&
                      d.aImportance != d.bImportance)
                    Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Text(
                        'mine ${d.aImportance}/5 · theirs ${d.bImportance}/5',
                        style: TextStyle(
                            fontSize: 12, color: ParallelColors.inkMuted),
                      ),
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