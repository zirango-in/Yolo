import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../core/theme.dart';
import '../../data/demo_content.dart';
import '../../data/family_providers.dart';
import '../../data/models.dart';
import '../../data/providers.dart';
import '../../data/repository.dart';
import '../../widgets/common.dart';
import '../../widgets/page_kit.dart';
import '../room/room_sheets.dart';

class FamilyBadge extends StatelessWidget {
  const FamilyBadge(this.f, {super.key, this.size = 52});
  final FamilyInfo f;
  final double size;

  @override
  Widget build(BuildContext context) => Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(size * 0.3),
          gradient: LinearGradient(colors: f.colors),
          border: Border.all(color: YoloColors.gold.withValues(alpha: 0.6), width: 1.5),
        ),
        alignment: Alignment.center,
        child: Text(f.name[0], style: TextStyle(fontSize: size * 0.4, fontWeight: FontWeight.w800)),
      );
}

Room familyRoom(FamilyInfo f) => Room(
      id: 700000 + f.id % 100000,
      name: '${f.name} Family Room',
      tag: 'Family',
      owner: DemoUsers.omar,
      online: 12,
      cover: f.colors,
      isFamily: true,
      announcement: 'Family members only. Daily sign-in at 9pm!',
    );

/// Family page: my family (if joined) or discover / create / search families.
class FamilyScreen extends ConsumerWidget {
  const FamilyScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(familyProvider);
    final family = ref.read(familyProvider.notifier).current;
    return YoloPage(
      title: 'Family',
      actions: [IconButton(tooltip: 'Family ranking', icon: const Icon(Icons.leaderboard_rounded, color: YoloColors.gold), onPressed: () => context.push('/family/ranking'))],
      body: family == null ? const _FamilyDiscover() : _MyFamily(family: family),
    );
  }
}

class _FamilyDiscover extends ConsumerStatefulWidget {
  const _FamilyDiscover();

  @override
  ConsumerState<_FamilyDiscover> createState() => _FamilyDiscoverState();
}

class _FamilyDiscoverState extends ConsumerState<_FamilyDiscover> {
  String _q = '';

  @override
  Widget build(BuildContext context) {
    final all = ref.read(familyProvider.notifier).allFamilies;
    final q = _q.trim().toLowerCase();
    final list = all.where((f) => q.isEmpty || f.name.toLowerCase().contains(q) || '${f.id}' == q).toList();
    return ListView(padding: const EdgeInsets.only(bottom: 40), children: [
      GlassCard(
        margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
        gradient: const LinearGradient(colors: [Color(0xFF4C1D95), Color(0xFF9D174D)]),
        child: Row(children: [
          const Icon(Icons.groups_rounded, size: 40, color: YoloColors.gold),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Create your family', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
              Text('Lead your own crew. Costs 5,000 coins.', style: TextStyle(fontSize: 12, color: YoloColors.textSoft)),
            ]),
          ),
          SizedBox(width: 92, child: GoldButton(label: 'Create', height: 38, onPressed: () => context.push('/family/create'))),
        ]),
      ),
      Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
        child: TextField(
          onChanged: (v) => setState(() => _q = v),
          decoration: InputDecoration(
            hintText: 'Search family name or ID',
            prefixIcon: const Icon(Icons.search_rounded),
            filled: true,
            fillColor: Colors.white.withValues(alpha: 0.07),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(24), borderSide: BorderSide.none),
          ),
        ),
      ),
      SectionTitle(q.isEmpty ? 'Recommended families' : 'Results'),
      if (list.isEmpty) const Padding(padding: EdgeInsets.all(20), child: Text('No family found', style: TextStyle(color: YoloColors.textMuted))),
      for (final (i, f) in list.indexed)
        GlassCard(
          margin: const EdgeInsets.fromLTRB(16, 0, 16, 10),
          padding: const EdgeInsets.all(12),
          onTap: () => context.push('/family/profile', extra: f),
          child: Row(children: [
            FamilyBadge(f),
            const SizedBox(width: 12),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  Flexible(child: Text(f.name, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w800))),
                  const SizedBox(width: 6),
                  Badge2('Lv ${f.level}'),
                ]),
                Text(f.slogan, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12, color: YoloColors.textMuted)),
                Text('${f.members}/${f.maxMembers} members · ID ${f.id}', style: const TextStyle(fontSize: 11, color: YoloColors.textSoft)),
              ]),
            ),
            const Icon(Icons.chevron_right_rounded, color: YoloColors.textMuted),
          ]),
        ).entrance(i),
    ]);
  }
}

class _MyFamily extends ConsumerWidget {
  const _MyFamily({required this.family});
  final FamilyInfo family;

  static const _roleNames = {'leader': 'Leader', 'deputy': 'Deputy leader', 'admin': 'Admin', 'member': 'Member'};

  void _donate(BuildContext context, WidgetRef ref) {
    showRoomSheet<void>(
      context,
      (c) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Donate to family funds', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
          const SizedBox(height: 4),
          const Text('Funds level up the family. You earn activeness and family coins.', style: TextStyle(color: YoloColors.textMuted)),
          const SizedBox(height: 16),
          Row(children: [
            for (final amount in [100, 500, 1000])
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: GlassCard(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    border: YoloColors.gold.withValues(alpha: 0.4),
                    onTap: () {
                      Navigator.pop(c);
                      final ok = ref.read(familyProvider.notifier).donate(amount);
                      showYoloToast(context, ok ? 'Donated $amount coins. Thank you!' : 'Not enough coins');
                    },
                    child: Column(children: [
                      const CoinIcon(size: 22),
                      const SizedBox(height: 6),
                      Text(formatCoins(amount), style: const TextStyle(fontWeight: FontWeight.w800, color: YoloColors.gold)),
                    ]),
                  ),
                ),
              ),
          ]),
        ]),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(familyProvider);
    final ctrl = ref.read(familyProvider.notifier);
    final progress = (s.funds / s.upgradeCost).clamp(0.0, 1.0);

    Widget feature(IconData icon, String label, Color color, VoidCallback onTap) => InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              TintIcon(icon, color: color, size: 46),
              const SizedBox(height: 6),
              Text(label, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12)),
            ]),
          ),
        );

    return ListView(padding: const EdgeInsets.only(bottom: 40), children: [
      Column(children: [
        const SizedBox(height: 8),
        FamilyBadge(family, size: 88).animate().scale(begin: const Offset(0.8, 0.8), curve: Curves.easeOutBack),
        const SizedBox(height: 10),
        Text(family.name, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
        Text(family.slogan, style: const TextStyle(color: YoloColors.textMuted)),
        const SizedBox(height: 8),
        Wrap(alignment: WrapAlignment.center, spacing: 8, runSpacing: 6, children: [
          Badge2('Lv ${s.level}'),
          Badge2(_roleNames[s.role]!, bg: const Color(0x338B5CF6), fg: const Color(0xFFC4B5FD)),
          if (s.title != null) Badge2(s.title!, bg: const Color(0x337DD3FC), fg: const Color(0xFF7DD3FC)),
        ]),
      ]),
      Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
        child: Row(children: [
          Expanded(
            child: GlassCard(
              padding: const EdgeInsets.all(12),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('Family funds', style: TextStyle(fontSize: 12, color: YoloColors.textMuted)),
                Text(formatCoins(s.funds), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: YoloColors.gold)),
              ]),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: GlassCard(
              padding: const EdgeInsets.all(12),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('My family coins', style: TextStyle(fontSize: 12, color: YoloColors.textMuted)),
                Text('${s.familyCoins}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Color(0xFFC4B5FD))),
              ]),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: GlassCard(
              padding: const EdgeInsets.all(12),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('Activeness', style: TextStyle(fontSize: 12, color: YoloColors.textMuted)),
                Text('${s.activeness}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Color(0xFF86EFAC))),
              ]),
            ),
          ),
        ]),
      ),
      Padding(
        padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Level ${s.level} → ${s.level + 1}: ${formatCoins(s.funds)} / ${formatCoins(s.upgradeCost)} funds',
              style: const TextStyle(fontSize: 12, color: YoloColors.textMuted)),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(value: progress, minHeight: 8, color: YoloColors.gold, backgroundColor: const Color(0x22FFFFFF)),
          ),
        ]),
      ),
      Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
        child: Row(children: [
          Expanded(
            child: s.signedIn
                ? OutlinedButton.icon(
                    onPressed: null,
                    style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(46), shape: const StadiumBorder()),
                    icon: const Icon(Icons.check_rounded),
                    label: const Text('Signed in'),
                  )
                : GoldButton(label: 'Sign in', icon: Icons.event_available_rounded, height: 46, onPressed: () {
                    ctrl.signIn();
                    showYoloToast(context, '+10 activeness, +20 family coins');
                  }),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: OutlinedButton.icon(
              onPressed: () => _donate(context, ref),
              style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(46), shape: const StadiumBorder(), foregroundColor: YoloColors.gold),
              icon: const Icon(Icons.volunteer_activism_rounded),
              label: const Text('Donate'),
            ),
          ),
          if (s.canManage) ...[
            const SizedBox(width: 10),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () {
                  final err = ctrl.upgrade();
                  showYoloToast(context, err.isEmpty ? 'Family upgraded to level ${ref.read(familyProvider).level}!' : err);
                },
                style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(46), shape: const StadiumBorder(), foregroundColor: const Color(0xFF86EFAC)),
                icon: const Icon(Icons.upgrade_rounded),
                label: const Text('Upgrade'),
              ),
            ),
          ],
        ]),
      ),
      Padding(
        padding: const EdgeInsets.fromLTRB(12, 14, 12, 0),
        child: GridView.count(
          crossAxisCount: 4,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          childAspectRatio: 0.82,
          children: [
            feature(Icons.mic_rounded, 'Voice room', const Color(0xFFF5C451), () => context.push('/room', extra: familyRoom(family))),
            feature(Icons.task_alt_rounded, 'Quests', const Color(0xFF86EFAC), () => context.push('/family/quests')),
            feature(Icons.redeem_rounded, 'Chests', const Color(0xFFF9A8D4), () => context.push('/family/quests')),
            feature(Icons.casino_rounded, 'Lucky roll', const Color(0xFFFDBA74), () => context.push('/family/gacha')),
            feature(Icons.storefront_rounded, 'Family shop', const Color(0xFF7DD3FC), () => context.push('/family/shop')),
            feature(Icons.people_alt_rounded, 'Members', const Color(0xFFC4B5FD), () => context.push('/family/members')),
            feature(Icons.leaderboard_rounded, 'Ranking', const Color(0xFFFDE68A), () => context.push('/family/ranking')),
            feature(Icons.logout_rounded, 'Leave', const Color(0xFFF87171), () => _leave(context, ref)),
          ],
        ),
      ),
    ]);
  }

  void _leave(BuildContext context, WidgetRef ref) {
    final leader = ref.read(familyProvider).role == 'leader';
    showDialog<void>(
      context: context,
      builder: (c) => AlertDialog(
        backgroundColor: YoloColors.sheet,
        title: Text(leader ? 'Disband family?' : 'Leave family?'),
        content: Text(leader
            ? 'You are the leader. Leaving will disband the family for everyone.'
            : 'You will lose your activeness and family title. You can join another family any time.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c), child: const Text('Cancel')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: const Color(0xFFDC2626)),
            onPressed: () {
              Navigator.pop(c);
              ref.read(familyProvider.notifier).leave();
            },
            child: Text(leader ? 'Disband' : 'Leave'),
          ),
        ],
      ),
    );
  }
}

/// Another family's profile with a Join button.
class FamilyProfileScreen extends ConsumerWidget {
  const FamilyProfileScreen({super.key, required this.family});
  final FamilyInfo family;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(familyProvider);
    final isMine = s.familyId == family.id;
    final full = family.members >= family.maxMembers;
    return YoloPage(
      title: family.name,
      body: ListView(padding: const EdgeInsets.fromLTRB(20, 8, 20, 40), children: [
        Center(child: FamilyBadge(family, size: 96)),
        const SizedBox(height: 12),
        Center(child: Text(family.name, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800))),
        Center(child: Text(family.slogan, style: const TextStyle(color: YoloColors.textMuted))),
        const SizedBox(height: 10),
        Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          Badge2('Lv ${family.level}'),
          const SizedBox(width: 8),
          Badge2('${family.members}/${family.maxMembers} members', bg: const Color(0x338B5CF6), fg: const Color(0xFFC4B5FD)),
          const SizedBox(width: 8),
          Badge2('ID ${family.id}', bg: const Color(0x22FFFFFF), fg: YoloColors.textSoft),
        ]),
        const SectionTitle('Leaders'),
        for (final (u, role) in [(DemoUsers.omar, 'Leader'), (DemoUsers.zara, 'Deputy leader')])
          ListTile(contentPadding: EdgeInsets.zero, leading: YoloAvatar(user: u, size: 42), title: Text(u.name), trailing: Badge2(role)),
        const SizedBox(height: 20),
        if (isMine)
          const Center(child: Text('This is your family', style: TextStyle(color: YoloColors.online, fontWeight: FontWeight.w700)))
        else
          Opacity(
            opacity: full || s.familyId != null ? 0.5 : 1,
            child: GoldButton(
              label: full ? 'Family is full' : (s.familyId != null ? 'Leave your family first' : 'Join family'),
              onPressed: full || s.familyId != null
                  ? null
                  : () {
                      ref.read(familyProvider.notifier).join(family);
                      showYoloToast(context, 'Welcome to ${family.name}!');
                      context.pop();
                    },
            ),
          ),
      ]),
    );
  }
}

/// Create a new family (5,000 coins).
class CreateFamilyScreen extends ConsumerStatefulWidget {
  const CreateFamilyScreen({super.key});

  @override
  ConsumerState<CreateFamilyScreen> createState() => _CreateFamilyScreenState();
}

class _CreateFamilyScreenState extends ConsumerState<CreateFamilyScreen> {
  static const _colors = [
    [Color(0xFF6366F1), Color(0xFFA855F7)],
    [Color(0xFFF59E0B), Color(0xFFEA580C)],
    [Color(0xFF0EA5E9), Color(0xFF14B8A6)],
    [Color(0xFFEC4899), Color(0xFFF43F5E)],
    [Color(0xFF111827), Color(0xFFB45309)],
  ];
  final _name = TextEditingController();
  final _slogan = TextEditingController();
  int _color = 0;
  String? _error;

  @override
  void dispose() {
    _name.dispose();
    _slogan.dispose();
    super.dispose();
  }

  void _create() {
    final name = _name.text.trim();
    if (name.length < 2 || name.length > 16) {
      setState(() => _error = 'Family name must be 2–16 characters');
      return;
    }
    final err = ref.read(familyProvider.notifier).create(ref.read(sessionProvider)!, name, _slogan.text.trim().isEmpty ? 'A brand new family' : _slogan.text.trim(), _colors[_color]);
    if (err.isNotEmpty) {
      setState(() => _error = err);
      return;
    }
    showYoloToast(context, 'Family created! You are the leader.');
    context.pop();
  }

  @override
  Widget build(BuildContext context) {
    final preview = FamilyInfo(0, _name.text.isEmpty ? '?' : _name.text, '', 1, 1, 50, _colors[_color]);
    return YoloPage(
      title: 'Create family',
      body: ListView(padding: const EdgeInsets.fromLTRB(20, 8, 20, 40), children: [
        Center(child: FamilyBadge(preview, size: 96)),
        const SizedBox(height: 12),
        Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          for (var i = 0; i < _colors.length; i++)
            Semantics(
              button: true,
              selected: _color == i,
              label: 'Badge color ${i + 1}',
              child: GestureDetector(
                onTap: () => setState(() => _color = i),
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 6),
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(colors: _colors[i]),
                    border: Border.all(color: _color == i ? YoloColors.gold : Colors.white24, width: _color == i ? 3 : 1),
                  ),
                ),
              ),
            ),
        ]),
        const SizedBox(height: 16),
        TextField(controller: _name, maxLength: 16, onChanged: (_) => setState(() {}), decoration: const InputDecoration(labelText: 'Family name')),
        TextField(controller: _slogan, maxLength: 60, decoration: const InputDecoration(labelText: 'Slogan')),
        if (_error != null) Padding(padding: const EdgeInsets.only(top: 6), child: Text(_error!, style: const TextStyle(color: Color(0xFFF87171)))),
        const SizedBox(height: 18),
        GoldButton(label: 'Create for 5,000 coins', icon: Icons.groups_rounded, onPressed: _create),
      ]),
    );
  }
}
