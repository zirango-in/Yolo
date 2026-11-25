import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../core/theme.dart';
import '../../data/profile_providers.dart';
import '../../data/providers.dart';
import '../../widgets/common.dart';
import '../../widgets/page_kit.dart';

/// User level, wealth level and charm level with progress and perks.
class LevelScreen extends ConsumerWidget {
  const LevelScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final me = ref.watch(sessionProvider);
    final levels = [
      ('User level', me?.level ?? 1, 0.64, 'Earn XP by chatting, being on mic and daily tasks', Icons.trending_up_rounded, const Color(0xFFC4B5FD)),
      ('Wealth level', 18, 0.35, 'Grows when you send gifts', Icons.diamond_rounded, const Color(0xFFF5C451)),
      ('Charm level', 22, 0.8, 'Grows when you receive gifts', Icons.favorite_rounded, const Color(0xFFF9A8D4)),
    ];
    const perks = [
      (5, 'Colored nickname in rooms'),
      (10, 'Exclusive chat bubble'),
      (20, 'Animated entry banner'),
      (30, 'Special level badge'),
      (50, 'Legend avatar frame'),
    ];
    return YoloPage(
      title: 'Levels',
      body: ListView(padding: const EdgeInsets.fromLTRB(16, 4, 16, 40), children: [
        for (final (i, (name, lv, progress, how, icon, color)) in levels.indexed)
          GlassCard(
            margin: const EdgeInsets.only(bottom: 12),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                TintIcon(icon, color: color),
                const SizedBox(width: 12),
                Expanded(child: Text(name, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800))),
                Text('Lv $lv', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: color)),
              ]),
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0, end: progress),
                  duration: const Duration(milliseconds: 900),
                  curve: Curves.easeOutCubic,
                  builder: (_, v, _) => LinearProgressIndicator(value: v, minHeight: 10, color: color, backgroundColor: const Color(0x22FFFFFF)),
                ),
              ),
              const SizedBox(height: 6),
              Text('${(progress * 100).round()}% to Lv ${lv + 1} · $how', style: const TextStyle(fontSize: 12, color: YoloColors.textMuted)),
            ]),
          ).entrance(i),
        const SectionTitle('Level rewards'),
        for (final (lv, perk) in perks)
          ListTile(
            leading: Badge2('Lv $lv', bg: (me?.level ?? 0) >= lv ? YoloColors.gold : const Color(0x22FFFFFF), fg: (me?.level ?? 0) >= lv ? YoloColors.onGold : YoloColors.textSoft),
            title: Text(perk),
            trailing: Icon((me?.level ?? 0) >= lv ? Icons.check_circle_rounded : Icons.lock_rounded,
                color: (me?.level ?? 0) >= lv ? YoloColors.online : YoloColors.textMuted),
          ),
      ]),
    );
  }
}

/// Badges and achievements (two tabs).
class BadgesScreen extends ConsumerStatefulWidget {
  const BadgesScreen({super.key, this.initialTab = 0});
  final int initialTab;

  @override
  ConsumerState<BadgesScreen> createState() => _BadgesScreenState();
}

class _BadgesScreenState extends ConsumerState<BadgesScreen> {
  late int _tab = widget.initialTab;
  final _claimed = <int>{};

  @override
  Widget build(BuildContext context) {
    final owned = demoBadges.where((b) => b.owned).length;
    return YoloPage(
      title: _tab == 0 ? 'Badges' : 'Achievements',
      bottom: YoloTabs(tabs: ['Badges $owned/${demoBadges.length}', 'Achievements'], index: _tab, onChanged: (i) => setState(() => _tab = i)),
      body: _tab == 0
          ? GridView.builder(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 40),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 3, mainAxisSpacing: 12, crossAxisSpacing: 12, childAspectRatio: 0.8),
              itemCount: demoBadges.length,
              itemBuilder: (_, i) {
                final b = demoBadges[i];
                return GlassCard(
                  padding: const EdgeInsets.all(10),
                  onTap: () => showYoloToast(context, b.owned ? '${b.name}: ${b.how}' : 'Locked: ${b.how}'),
                  child: Opacity(
                    opacity: b.owned ? 1 : 0.4,
                    child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                      Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: b.color.withValues(alpha: 0.18),
                          boxShadow: b.owned ? [BoxShadow(color: b.color.withValues(alpha: 0.4), blurRadius: 16)] : null,
                        ),
                        child: Icon(b.owned ? b.icon : Icons.lock_rounded, color: b.color, size: 28),
                      ),
                      const SizedBox(height: 8),
                      Text(b.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                    ]),
                  ),
                ).entrance(i);
              },
            )
          : ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 40),
              itemCount: demoAchievements.length,
              itemBuilder: (_, i) {
                final a = demoAchievements[i];
                final claimed = _claimed.contains(i);
                return GlassCard(
                  margin: const EdgeInsets.only(bottom: 10),
                  child: Row(children: [
                    Expanded(
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(a.name, style: const TextStyle(fontWeight: FontWeight.w800)),
                        Text(a.goal, style: const TextStyle(fontSize: 12, color: YoloColors.textMuted)),
                        const SizedBox(height: 8),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(value: a.progress / a.target, minHeight: 6, color: YoloColors.gold, backgroundColor: const Color(0x22FFFFFF)),
                        ),
                        const SizedBox(height: 4),
                        Text('${a.progress}/${a.target}', style: const TextStyle(fontSize: 11, color: YoloColors.textSoft)),
                      ]),
                    ),
                    const SizedBox(width: 12),
                    a.done && !claimed
                        ? GoldButton(label: 'Claim ${a.reward}', height: 36, onPressed: () {
                            setState(() => _claimed.add(i));
                            ref.read(sessionProvider.notifier).earn(a.reward);
                            showYoloToast(context, '+${a.reward} coins');
                          })
                        : Text(claimed ? 'Claimed' : '+${a.reward}', style: TextStyle(color: claimed ? YoloColors.online : YoloColors.gold, fontWeight: FontWeight.w800)),
                  ]),
                ).entrance(i);
              },
            ),
    );
  }
}
