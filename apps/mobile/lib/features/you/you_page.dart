import 'package:flutter/material.dart';

import '../../core/config.dart';
import '../../core/models.dart';
import '../../core/session.dart';
import '../../design/status.dart';
import '../../design/theme.dart';
import '../compat/questionnaire_page.dart';
import '../safety/safety_page.dart';

/// The "You" tab: profile editing, capacity status, the compatibility
/// questionnaire, and safety tools.
class YouPage extends StatefulWidget {
  const YouPage({super.key});

  @override
  State<YouPage> createState() => _YouPageState();
}

class _YouPageState extends State<YouPage> {
  SocialStatus? _status;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadStatus();
  }

  Future<void> _loadStatus() async {
    try {
      final json =
          await AppState.read(context).api.get('/messaging/status/me');
      if (mounted && json is Map<String, Object?>) {
        setState(() => _status = SocialStatus.fromJson(json));
      }
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    }
  }

  Future<void> _saveStatus({int? battery, String? temperature}) async {
    final api = AppState.read(context).api;
    try {
      await api.put('/messaging/status/me', {
        'battery': ?battery,
        'temperature': ?temperature,
      });
      await _loadStatus();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(SnackBar(content: Text(e.toString())));
      }
    }
  }

  Future<void> _logout() async {
    await AppState.read(context).logout();
  }

  void _push(Widget page) {
    Navigator.of(context)
        .push(MaterialPageRoute<void>(builder: (_) => page));
  }

  @override
  Widget build(BuildContext context) {
    final state = AppState.read(context);
    final me = state.me;
    return Scaffold(
      appBar: AppBar(
        title: Text(me?.displayName ?? 'You'),
        actions: [
          IconButton(
            tooltip: 'Log out',
            onPressed: _logout,
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 8),
        children: [
          _ProfileCard(user: me),
          _CapacityCard(status: _status, onSave: _saveStatus),
          _LinkCard(
            icon: Icons.tune,
            title: 'Compatibility questionnaire',
            subtitle: 'What matters, what you can flex on, what is a dealbreaker.',
            onTap: () => _push(const QuestionnairePage()),
          ),
          _LinkCard(
            icon: Icons.fact_check_outlined,
            title: 'Safety',
            subtitle: 'Block someone or file a report.',
            onTap: () => _push(const SafetyPage()),
          ),
          if (_error != null)
            Padding(
              padding: const EdgeInsets.all(16),
              child: ErrorView(message: _error!, onRetry: _loadStatus),
            ),
        ],
      ),
    );
  }
}

class _ProfileCard extends StatelessWidget {
  const _ProfileCard({required this.user});

  final PublicUser? user;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Profile',
              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
            ),
            const SizedBox(height: 4),
            Text(
              user == null ? 'Not loaded.' : 'This is what others see.',
              style: TextStyle(color: ParallelColors.inkMuted, fontSize: 13),
            ),
            const SizedBox(height: 12),
            if (user != null)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _kv('Name', user!.displayName),
                  if (user!.age != null) _kv('Age', '${user!.age}'),
                  if (user!.city != null) _kv('City', user!.city!),
                  if (user!.gender != null) _kv('Gender', user!.gender!),
                  if (user!.about != null && user!.about!.isNotEmpty)
                    _kv('About', user!.about!),
                  if (user!.datingIntents.isNotEmpty)
                    _kv('Looking for', user!.datingIntents.join(', ')),
                  if (user!.relationshipGoals.isNotEmpty)
                    _kv('Goals', user!.relationshipGoals.join(', ')),
                  Row(
                    children: [
                      _verified(user!.ageVerified, 'Age verified'),
                      const SizedBox(width: 16),
                      _verified(user!.identityVerified, 'Identity verified'),
                    ],
                  ),
                ],
              ),
            const SizedBox(height: 12),
            OutlinedButton(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute<void>(builder: (_) => const _ProfileEditSheet()),
              ),
              child: const Text('Edit profile'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _kv(String k, String v) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 3),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 90,
              child: Text(k,
                  style: TextStyle(
                      color: ParallelColors.inkMuted, fontSize: 13)),
            ),
            Expanded(
              child: Text(v, style: const TextStyle(fontSize: 14)),
            ),
          ],
        ),
      );

  Widget _verified(bool ok, String label) => Row(
        children: [
          Icon(ok ? Icons.verified : Icons.circle_outlined,
              size: 15, color: ParallelColors.inkMuted),
          const SizedBox(width: 4),
          Text('$label ${ok ? 'yes' : 'no'}',
              style: TextStyle(color: ParallelColors.inkMuted, fontSize: 12)),
        ],
      );
}

class _ProfileEditSheet extends StatefulWidget {
  const _ProfileEditSheet();

  @override
  State<_ProfileEditSheet> createState() => _ProfileEditSheetState();
}

class _ProfileEditSheetState extends State<_ProfileEditSheet> {
  late final TextEditingController _name;
  late final TextEditingController _age;
  late final TextEditingController _city;
  late final TextEditingController _gender;
  late final TextEditingController _about;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    final me = AppState.read(context).me;
    _name = TextEditingController(text: me?.name ?? '');
    _age = TextEditingController(
        text: me?.age == null ? '' : '${me!.age}');
    _city = TextEditingController(text: me?.city ?? '');
    _gender = TextEditingController(text: me?.gender ?? '');
    _about = TextEditingController(text: me?.about ?? '');
  }

  @override
  void dispose() {
    _name.dispose();
    _age.dispose();
    _city.dispose();
    _gender.dispose();
    _about.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      final app = AppState.read(context);
      final api = app.api;
      final age = int.tryParse(_age.text.trim());
      await api.patch('/auth/me', {
        'name': _name.text.trim().isEmpty ? null : _name.text.trim(),
        'age': age,
        'city': _city.text.trim().isEmpty ? null : _city.text.trim(),
        'gender': _gender.text.trim().isEmpty ? null : _gender.text.trim(),
        'about': _about.text.trim().isEmpty ? null : _about.text.trim(),
      });
      await app.refreshProfile();
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Edit profile')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextField(
              controller: _name,
              decoration: const InputDecoration(labelText: 'Name'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _age,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Age'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _city,
              decoration: const InputDecoration(labelText: 'City'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _gender,
              decoration: const InputDecoration(labelText: 'Gender'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _about,
              maxLines: 4,
              decoration: const InputDecoration(labelText: 'About'),
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
              onPressed: _saving ? null : _save,
              child: _saving
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }
}

class _CapacityCard extends StatelessWidget {
  const _CapacityCard({required this.status, required this.onSave});

  final SocialStatus? status;
  final void Function({int? battery, String? temperature}) onSave;

  @override
  Widget build(BuildContext context) {
    final s = status;
    if (s == null) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Text('Capacity status not loaded.'),
        ),
      );
    }
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Your social capacity',
              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
            ),
            const SizedBox(height: 4),
            Text(
              'Shown to people you match with, so they know how much to '
              'expect from you today.',
              style: TextStyle(color: ParallelColors.inkMuted, fontSize: 13),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Text('Battery', style: TextStyle(color: ParallelColors.inkMuted)),
                const SizedBox(width: 16),
                SegmentedButton<int>(
                  segments: [
                    for (var b = 0; b <= 4; b++)
                      ButtonSegment(value: b, label: Text('$b')),
                  ],
                  selected: {s.battery},
                  onSelectionChanged: (sel) => onSave(battery: sel.first),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: temperatures
                  .map((t) => ChoiceChip(
                        label: Text(t),
                        selected: s.temperature == t,
                        onSelected: (_) => onSave(temperature: t),
                      ))
                  .toList(),
            ),
          ],
        ),
      ),
    );
  }
}

class _LinkCard extends StatelessWidget {
  const _LinkCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Icon(icon, color: ParallelColors.ink),
        title: Text(title,
            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
        subtitle: Text(subtitle,
            style:
                TextStyle(color: ParallelColors.inkMuted, fontSize: 13)),
        trailing: const Icon(Icons.chevron_right, size: 20),
        onTap: onTap,
      ),
    );
  }
}