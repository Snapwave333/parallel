import 'package:flutter/material.dart';

import '../../core/models.dart';
import '../../core/session.dart';
import '../../design/status.dart';
import '../../design/theme.dart';

/// Date Builder: plans with a primary + fallback, so a first date can be
/// adjusted together instead of falling apart.
class DatesPage extends StatefulWidget {
  const DatesPage({super.key});

  @override
  State<DatesPage> createState() => _DatesPageState();
}

class _DatesPageState extends State<DatesPage> {
  List<DatePlan> _plans = const [];
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
      final plans = await state.api.get('/dates/plans');
      final conns = await state.api.get('/discover/connections');
      if (!mounted) return;
      setState(() {
        _plans = plans is Map && plans['plans'] is List
            ? (plans['plans'] as List)
                .map((e) => e is Map<String, Object?> && e['plan'] is Map
                    ? DatePlan.fromJson(e['plan'] as Map<String, Object?>)
                    : null)
                .whereType<DatePlan>()
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

  Future<void> _newPlan() async {
    final created = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) => _NewPlanSheet(connections: _connections),
    );
    if (created == true) _load();
  }

  Future<void> _respond(int id, String action) async {
    final state = AppState.read(context);
    try {
      await state.api.post('/dates/plans/$id/$action');
      if (mounted) _load();
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
        title: const Text('Dates'),
        actions: [
          IconButton(
            tooltip: 'New plan',
            onPressed: _newPlan,
            icon: const Icon(Icons.add),
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
    if (_busy && _plans.isEmpty) {
      return const LoadingView(label: 'Loading date plans…');
    }
    if (_error != null) return ErrorView(message: _error!, onRetry: _load);
    if (_plans.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: const [
          Padding(
            padding: EdgeInsets.all(32),
            child: Text(
              'No date plans yet. Propose a plan with a fallback — having '
              'a plan B is part of the point.',
              textAlign: TextAlign.center,
            ),
          ),
        ],
      );
    }
    return ListView.builder(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: _plans.length,
      itemBuilder: (_, i) => _PlanCard(
        plan: _plans[i],
        onAccept: () => _respond(_plans[i].id, 'accept'),
        onDecline: () => _respond(_plans[i].id, 'decline'),
        onDone: () => _respond(_plans[i].id, 'done'),
      ),
    );
  }
}

class _PlanCard extends StatelessWidget {
  const _PlanCard({
    required this.plan,
    required this.onAccept,
    required this.onDecline,
    required this.onDone,
  });

  final DatePlan plan;
  final VoidCallback onAccept;
  final VoidCallback onDecline;
  final VoidCallback onDone;

  @override
  Widget build(BuildContext context) {
    final pending = plan.state == 'pending';
    final isMine = plan.initiatorId == AppState.read(context).me?.id;
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
                    plan.title,
                    style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
                  ),
                ),
                Chip(
                  backgroundColor: pending
                      ? ParallelColors.ink
                      : ParallelColors.ramp[4],
                  label: Text(
                    plan.state,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: pending
                          ? ParallelColors.paper
                          : ParallelColors.ink,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              '${plan.dayLabel()} · with ${plan.otherUser.displayName}',
              style: TextStyle(color: ParallelColors.inkMuted, fontSize: 13),
            ),
            const SizedBox(height: 10),
            _option(context, 'Plan A', plan.planA, primary: true),
            if (plan.planB != null) _option(context, 'Fallback', plan.planB!),
            if (plan.planC != null) _option(context, 'Plan C', plan.planC!),
            if (plan.detail != null && plan.detail!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(plan.detail!, style: const TextStyle(fontSize: 13)),
            ],
            if (pending) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: FilledButton(
                      onPressed: isMine ? onDecline : onAccept,
                      child: Text(isMine ? 'Withdraw' : 'Accept'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: OutlinedButton(
                      onPressed: isMine ? onAccept : onDecline,
                      child: Text(isMine ? 'Confirm' : 'Pass'),
                    ),
                  ),
                ],
              ),
            ] else if (plan.state == 'accepted') ...[
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: onDone,
                icon: const Icon(Icons.check_circle_outline, size: 18),
                label: const Text('It went well'),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _option(BuildContext context, String label, String text,
      {bool primary = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: primary ? ParallelColors.ink : ParallelColors.inkMuted,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(text, style: const TextStyle(fontSize: 14, height: 1.25)),
          ),
        ],
      ),
    );
  }
}

class _NewPlanSheet extends StatefulWidget {
  const _NewPlanSheet({required this.connections});

  final List<ConnectionEntry> connections;

  @override
  State<_NewPlanSheet> createState() => _NewPlanSheetState();
}

class _NewPlanSheetState extends State<_NewPlanSheet> {
  final _title = TextEditingController();
  final _planA = TextEditingController();
  final _planB = TextEditingController();
  final _planC = TextEditingController();
  int? _partnerId;
  int _daysAhead = 3;
  bool _saving = false;
  String? _error;

  @override
  void dispose() {
    _title.dispose();
    _planA.dispose();
    _planB.dispose();
    _planC.dispose();
    super.dispose();
  }

  Future<void> _create() async {
    if (_partnerId == null) {
      setState(() => _error = 'Pick who this date is with.');
      return;
    }
    if (_title.text.trim().isEmpty || _planA.text.trim().isEmpty) {
      setState(() => _error = 'A title and a plan A are required.');
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      final day = DateTime.now().add(Duration(days: _daysAhead));
      final dayOrdinal = day.millisecondsSinceEpoch ~/ 86400000;
      await AppState.read(context).api.post('/dates/plans', {
        'partner_id': _partnerId,
        'title': _title.text.trim(),
        'plan_a': _planA.text.trim(),
        'plan_b': _planB.text.trim().isEmpty ? null : _planB.text.trim(),
        'plan_c': _planC.text.trim().isEmpty ? null : _planC.text.trim(),
        'day': dayOrdinal,
      });
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
          left: 20,
          right: 20,
          bottom: 20 + MediaQuery.of(context).viewInsets.bottom,
        ),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'New date plan',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 4),
              Text(
                'Plan A is the main idea; the fallback keeps the date kind '
                'if the first venue is overwhelming.',
                style: TextStyle(color: ParallelColors.inkMuted, fontSize: 13),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<int>(
                initialValue: _partnerId,
                decoration: const InputDecoration(labelText: 'With'),
                items: [
                  for (final c in widget.connections)
                    DropdownMenuItem(
                      value: c.userId,
                      child: Text(c.user.displayName),
                    ),
                ],
                onChanged: (v) => setState(() => _partnerId = v),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _title,
                decoration: const InputDecoration(labelText: 'What is it?'),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _planA,
                decoration: const InputDecoration(labelText: 'Plan A'),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _planB,
                decoration:
                    const InputDecoration(labelText: 'Fallback (optional)'),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _planC,
                decoration: const InputDecoration(labelText: 'Plan C (optional)'),
              ),
              const SizedBox(height: 12),
              SegmentedButton<int>(
                segments: const [
                  ButtonSegment(value: 1, label: Text('Tomorrow')),
                  ButtonSegment(value: 3, label: Text('In 3 days')),
                  ButtonSegment(value: 7, label: Text('A week')),
                ],
                selected: {_daysAhead},
                onSelectionChanged: (s) =>
                    setState(() => _daysAhead = s.first),
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
              const SizedBox(height: 16),
              FilledButton(
                onPressed: _saving ? null : _create,
                child: _saving
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Propose plan'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}