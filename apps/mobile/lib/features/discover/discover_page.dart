import 'package:flutter/material.dart';

import '../../core/models.dart';
import '../../core/session.dart';
import '../../design/status.dart';
import '../../design/theme.dart';
import '../compat/explain_page.dart';

/// Today's introductions, plus inbound introduction requests.
class DiscoverPage extends StatefulWidget {
  const DiscoverPage({super.key, required this.state});

  final AppState state;

  @override
  State<DiscoverPage> createState() => _DiscoverPageState();
}

class _DiscoverPageState extends State<DiscoverPage> {
  DiscoverToday? _today;
  List<RequestItem> _incoming = [];
  String? _error;
  bool _busy = false;

  AppState get state => widget.state;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _error = null;
      _busy = true;
    });
    try {
      final today = await state.api.get('/discover/today');
      final incoming = await state.api.get('/discover/requests/incoming');
      if (!mounted) return;
      setState(() {
        _today = today is Map<String, Object?>
            ? DiscoverToday.fromJson(today)
            : null;
        _incoming = incoming is List
            ? incoming
                .whereType<Map<String, Object?>>()
                .map(RequestItem.fromJson)
                .toList()
            : [];
      });
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _introduce(TodayIntro intro) async {
    setState(() => _busy = true);
    try {
      final result = await state.api.post('/discover/introduce', {
        'to_user': intro.userId,
        'reason': 'Connected via today\'s introduction.',
      });
      if (!mounted) return;
      if (result is Map && result['matched'] == true) {
        _toast(context, 'It\'s a match — go say hi.');
      } else {
        _toast(context, 'Introduction sent to ${intro.user.displayName}.');
      }
      await _load();
    } catch (e) {
      if (mounted) _toast(context, e.toString());
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _respond(RequestItem req, bool accept) async {
    try {
      await state.api.post('/discover/requests/${req.id}/${accept ? 'accept' : 'decline'}');
      if (!mounted) return;
      _toast(context,
          accept ? 'You matched. Check your messages.' : 'Request declined.');
      await _load();
    } catch (e) {
      if (mounted) _toast(context, e.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.only(bottom: 24),
        children: [
          const _PageHeader(),
          if (_busy && _today == null)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 48),
              child: LoadingView(label: "Finding today's introductions…"),
            ),
          if (_error != null)
            ErrorView(message: _error!, onRetry: _load),
          if (_incoming.isNotEmpty) ...[
            _sectionTitle('Incoming requests'),
            ..._incoming.map((r) => _IncomingCard(
                  request: r,
                  enabled: !_busy,
                  onAccept: () => _respond(r, true),
                  onDecline: () => _respond(r, false),
                )),
          ],
          _sectionTitle('Today for you'),
          if (_today != null && _today!.introductions.isEmpty)
            const Padding(
              padding: EdgeInsets.all(32),
              child: Text(
                'No introductions today.\n\nPlease check back tomorrow — '
                'matching is deliberately slow on purpose.',
                textAlign: TextAlign.center,
              ),
            ),
          ...(_today?.introductions
                  .map((i) => _IntroCard(
                        intro: i,
                        busy: _busy,
                        onIntroduce: () => _introduce(i),
                        onExplain: () => Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) =>
                                ExplainPage(state: state, otherId: i.userId),
                          ),
                        ),
                      ))
                  .toList() ??
              const []),
        ],
      ),
    );
  }

  Widget _sectionTitle(String t) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
        child: Text(
          t,
          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
        ),
      );

  static void _toast(BuildContext context, String msg) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(msg)));
  }
}

class _PageHeader extends StatelessWidget {
  const _PageHeader();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Parallel', style: Theme.of(context).textTheme.headlineSmall),
          Text(
            'Low-pressure, one reason at a time.',
            style: TextStyle(color: ParallelColors.inkMuted, fontSize: 13),
          ),
        ],
      ),
    );
  }
}

class _IncomingCard extends StatelessWidget {
  const _IncomingCard({
    required this.request,
    required this.onAccept,
    required this.onDecline,
    required this.enabled,
  });

  final RequestItem request;
  final VoidCallback onAccept;
  final VoidCallback onDecline;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${request.otherUser.displayName} wants to connect',
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
            if (request.reason != null && request.reason!.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(request.reason!, style: const TextStyle(fontSize: 13)),
            ],
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: FilledButton(
                    onPressed: enabled ? onAccept : null,
                    child: const Text('Say yes'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton(
                    onPressed: enabled ? onDecline : null,
                    child: const Text('Pass'),
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

class _IntroCard extends StatelessWidget {
  const _IntroCard({
    required this.intro,
    required this.onIntroduce,
    required this.onExplain,
    required this.busy,
  });

  final TodayIntro intro;
  final VoidCallback onIntroduce;
  final VoidCallback onExplain;
  final bool busy;

  @override
  Widget build(BuildContext context) {
    final u = intro.user;
    final meta = [
      if (u.age != null) '${u.age}',
      if (u.city != null) u.city!,
      if (u.gender != null) u.gender!,
    ].join(' · ');
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 22,
                  backgroundColor: ParallelColors.ramp[3],
                  foregroundColor: ParallelColors.paper,
                  child: Text(
                    u.displayName.characters.first.toUpperCase(),
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        u.displayName,
                        style: const TextStyle(
                            fontWeight: FontWeight.w700, fontSize: 16),
                      ),
                      if (meta.isNotEmpty)
                        Text(
                          meta,
                          style: TextStyle(
                              color: ParallelColors.inkMuted, fontSize: 13),
                        ),
                    ],
                  ),
                ),
                Chip(
                  backgroundColor: ParallelColors.ramp[4],
                  label: Text(
                    '${intro.reason.overall.round()}%',
                    style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                        color: ParallelColors.ink),
                  ),
                ),
              ],
            ),
            if (u.about != null && u.about!.isNotEmpty) ...[
              const SizedBox(height: 10),
              Text(u.about!, style: const TextStyle(height: 1.35)),
            ],
            if (u.datingIntents.isNotEmpty) ...[
              const SizedBox(height: 8),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: u.datingIntents
                    .map((t) => _tag(t.toLowerCase()))
                    .toList(),
              ),
            ],
            const SizedBox(height: 12),
            _ReasonBlock(intro: intro),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: FilledButton.icon(
                    onPressed: busy ? null : onIntroduce,
                    icon: const Icon(Icons.waving_hand_outlined, size: 18),
                    label: const Text('Introduce'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton(
                    onPressed: onExplain,
                    child: const Text('Why?'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _tag(String t) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: ParallelColors.lineSoft,
          borderRadius: BorderRadius.circular(999),
        ),
        child: Text(t, style: const TextStyle(fontSize: 12)),
      );
}

class _ReasonBlock extends StatelessWidget {
  const _ReasonBlock({required this.intro});

  final TodayIntro intro;

  @override
  Widget build(BuildContext context) {
    final reason = intro.reason;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: ParallelColors.canvas,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: ParallelColors.lineSoft),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (reason.sharedInterests > 0)
            Text(
              '${reason.sharedInterests} shared '
              '${reason.sharedInterests == 1 ? 'interest' : 'interests'}',
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
            ),
          if (reason.explain.isNotEmpty) ...[
            const SizedBox(height: 6),
            ...reason.explain.take(3).map(
                  (e) => Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Text(
                      '•  ${e.text}',
                      style: TextStyle(
                        fontSize: 13,
                        height: 1.3,
                        color: ParallelColors.inkMuted,
                      ),
                    ),
                  ),
                ),
          ],
        ],
      ),
    );
  }
}