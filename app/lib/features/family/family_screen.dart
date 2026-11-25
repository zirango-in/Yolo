import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../core/theme.dart';
import '../../data/demo_content.dart';
import '../../data/social_providers.dart';
import '../../widgets/common.dart';
import '../../widgets/page_kit.dart';

/// Family page: shows my family (if joined) or the list of families to join.
class FamilyScreen extends ConsumerWidget {
  const FamilyScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final joined = ref.watch(joinedFamilyProvider);
    final family = demoFamilies.where((f) => f.id == joined).firstOrNull;

    return YoloPage(
      title: 'Family',
      body: family == null ? _FamilyList(onJoin: (f) => ref.read(joinedFamilyProvider.notifier).join(f.id)) : _MyFamily(family: family),
    );
  }
}

class _FamilyBadge extends StatelessWidget {
  const _FamilyBadge(this.f, {this.size = 52});
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

class _FamilyList extends StatelessWidget {
  const _FamilyList({required this.onJoin});
  final ValueChanged<FamilyInfo> onJoin;

  @override
  Widget build(BuildContext context) => ListView(padding: const EdgeInsets.only(bottom: 40), children: [
        GlassCard(
          margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
          gradient: const LinearGradient(colors: [Color(0xFF4C1D95), Color(0xFF9D174D)]),
          child: Row(children: [
            const Icon(Icons.groups_rounded, size: 40, color: YoloColors.gold),
            const SizedBox(width: 12),
            const Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Create your family', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
                Text('Lead your own crew, chat and win rewards together', style: TextStyle(fontSize: 12, color: YoloColors.textSoft)),
              ]),
            ),
            GoldButton(label: 'Create', height: 38, onPressed: () => showYoloToast(context, 'Creating a family arrives in Step 7')),
          ]),
        ),
        const SectionTitle('Recommended families'),
        for (final (i, f) in demoFamilies.indexed)
          GlassCard(
            margin: const EdgeInsets.fromLTRB(16, 0, 16, 10),
            padding: const EdgeInsets.all(12),
            child: Row(children: [
              _FamilyBadge(f),
              const SizedBox(width: 12),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(children: [
                    Flexible(child: Text(f.name, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w800))),
                    const SizedBox(width: 6),
                    Badge2('Lv ${f.level}'),
                  ]),
                  Text(f.slogan, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12, color: YoloColors.textMuted)),
                  Text('${f.members}/${f.maxMembers} members', style: const TextStyle(fontSize: 11, color: YoloColors.textSoft)),
                ]),
              ),
              OutlinedButton(
                onPressed: () {
                  onJoin(f);
                  showYoloToast(context, 'You joined ${f.name}');
                },
                style: OutlinedButton.styleFrom(shape: const StadiumBorder(), foregroundColor: YoloColors.gold, side: const BorderSide(color: YoloColors.gold)),
                child: const Text('Join'),
              ),
            ]),
          ).entrance(i),
      ]);
}

class _MyFamily extends ConsumerWidget {
  const _MyFamily({required this.family});
  final FamilyInfo family;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    Widget feature(IconData icon, String label, Color color) => Expanded(
          child: InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: () => showYoloToast(context, '$label arrives in Step 7'),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Column(children: [TintIcon(icon, color: color, size: 46), const SizedBox(height: 6), Text(label, style: const TextStyle(fontSize: 12))]),
            ),
          ),
        );

    return ListView(padding: const EdgeInsets.only(bottom: 40), children: [
      Column(children: [
        const SizedBox(height: 8),
        _FamilyBadge(family, size: 88),
        const SizedBox(height: 10),
        Text(family.name, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
        Text(family.slogan, style: const TextStyle(color: YoloColors.textMuted)),
        const SizedBox(height: 8),
        Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          Badge2('Lv ${family.level}'),
          const SizedBox(width: 8),
          Badge2('${family.members}/${family.maxMembers} members', bg: const Color(0x338B5CF6), fg: const Color(0xFFC4B5FD)),
        ]),
      ]),
      Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Level progress', style: TextStyle(fontSize: 12, color: YoloColors.textMuted)),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: const LinearProgressIndicator(value: 0.62, minHeight: 8, color: YoloColors.gold, backgroundColor: Color(0x22FFFFFF)),
          ),
        ]),
      ),
      Padding(
        padding: const EdgeInsets.fromLTRB(12, 16, 12, 0),
        child: Row(children: [
          feature(Icons.mic_rounded, 'Voice room', const Color(0xFFF5C451)),
          feature(Icons.task_alt_rounded, 'Quests', const Color(0xFF86EFAC)),
          feature(Icons.redeem_rounded, 'Chests', const Color(0xFFF9A8D4)),
          feature(Icons.leaderboard_rounded, 'Ranking', const Color(0xFF7DD3FC)),
        ]),
      ),
      const SectionTitle('Members'),
      for (final (i, u) in demoAllUsers.indexed)
        ListTile(
          leading: YoloAvatar(user: u, size: 44),
          title: Text(u.name, style: const TextStyle(fontWeight: FontWeight.w700)),
          trailing: Badge2(i == 0 ? 'Leader' : (i == 1 ? 'Deputy' : 'Member'),
              bg: i == 0 ? YoloColors.gold : const Color(0x22FFFFFF), fg: i == 0 ? YoloColors.onGold : YoloColors.textSoft),
        ).entrance(i),
      Padding(
        padding: const EdgeInsets.all(20),
        child: TextButton(
          onPressed: () => ref.read(joinedFamilyProvider.notifier).leave(),
          child: const Text('Leave family', style: TextStyle(color: Color(0xFFF87171))),
        ),
      ),
    ]);
  }
}
