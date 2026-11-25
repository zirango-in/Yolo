import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../core/theme.dart';
import '../../data/family_providers.dart';
import '../../data/providers.dart';
import '../../data/social_providers.dart';
import '../../widgets/common.dart';
import '../../widgets/page_kit.dart';
import '../room/room_sheets.dart';
import 'family_screen.dart';

/// Daily quests + activeness chests.
class FamilyQuestsScreen extends ConsumerWidget {
  const FamilyQuestsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(familyProvider);
    final ctrl = ref.read(familyProvider.notifier);
    return YoloPage(
      title: 'Quests & chests',
      body: ListView(padding: const EdgeInsets.fromLTRB(16, 4, 16, 40), children: [
        GlassCard(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Weekly activeness: ${s.activeness}', style: const TextStyle(fontWeight: FontWeight.w800)),
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(
                value: (s.activeness / chestMilestones.last.$1).clamp(0.0, 1.0),
                minHeight: 10,
                color: const Color(0xFF86EFAC),
                backgroundColor: const Color(0x22FFFFFF),
              ),
            ),
            const SizedBox(height: 14),
            Row(children: [
              for (final (i, (need, reward)) in chestMilestones.indexed)
                Expanded(
                  child: Column(children: [
                    Icon(
                      s.claimedChests.contains(i) ? Icons.inventory_2_rounded : Icons.redeem_rounded,
                      size: 40,
                      color: s.activeness >= need ? YoloColors.gold : YoloColors.textMuted,
                    )
                        .animate(target: s.activeness >= need && !s.claimedChests.contains(i) ? 1 : 0, onPlay: (c) => c.repeat(reverse: true))
                        .scaleXY(end: 1.12, duration: 600.ms),
                    Text('$need', style: const TextStyle(fontSize: 12, color: YoloColors.textMuted)),
                    const SizedBox(height: 4),
                    if (s.claimedChests.contains(i))
                      const Text('Opened', style: TextStyle(fontSize: 12, color: YoloColors.online))
                    else
                      TextButton(
                        onPressed: s.activeness >= need
                            ? () {
                                ctrl.claimChest(i);
                                showYoloToast(context, 'Chest opened: +$reward coins');
                              }
                            : null,
                        child: Text('Open', style: TextStyle(color: s.activeness >= need ? YoloColors.gold : YoloColors.textMuted)),
                      ),
                  ]),
                ),
            ]),
          ]),
        ),
        const SectionTitle('Daily quests'),
        for (final (i, q) in familyQuests.indexed)
          GlassCard(
            margin: const EdgeInsets.only(bottom: 10),
            child: Row(children: [
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(q.name, style: const TextStyle(fontWeight: FontWeight.w700)),
                  Text('+${q.activeness} activeness · +${q.coins} family coins', style: const TextStyle(fontSize: 12, color: YoloColors.textMuted)),
                  const SizedBox(height: 6),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(value: q.progress / q.target, minHeight: 6, color: YoloColors.gold, backgroundColor: const Color(0x22FFFFFF)),
                  ),
                ]),
              ),
              const SizedBox(width: 12),
              if (s.claimedQuests.contains(i))
                const Text('Claimed', style: TextStyle(color: YoloColors.online, fontWeight: FontWeight.w700))
              else if (q.done)
                SizedBox(width: 84, child: GoldButton(label: 'Claim', height: 36, onPressed: () => ctrl.claimQuest(i)))
              else
                Text('${q.progress}/${q.target}', style: const TextStyle(color: YoloColors.textMuted)),
            ]),
          ).entrance(i),
      ]),
    );
  }
}

/// Lucky roll (family gacha): one free roll per day, then 30 family coins.
class FamilyGachaScreen extends ConsumerStatefulWidget {
  const FamilyGachaScreen({super.key});

  @override
  ConsumerState<FamilyGachaScreen> createState() => _FamilyGachaScreenState();
}

class _FamilyGachaScreenState extends ConsumerState<FamilyGachaScreen> {
  int? _highlight;
  int? _won;
  bool _spinning = false;

  Future<void> _roll() async {
    final result = ref.read(familyProvider.notifier).roll();
    if (result < 0) {
      showYoloToast(context, 'Not enough family coins (30 needed)');
      return;
    }
    setState(() {
      _spinning = true;
      _won = null;
    });
    // Light runs around the board, then stops on the prize.
    for (var step = 0; step < 12 + result; step++) {
      await Future<void>.delayed(Duration(milliseconds: 60 + step * 12));
      if (!mounted) return;
      setState(() => _highlight = step % gachaPrizes.length);
    }
    setState(() {
      _highlight = result;
      _won = result;
      _spinning = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(familyProvider);
    return YoloPage(
      title: 'Lucky roll',
      body: ListView(padding: const EdgeInsets.all(20), children: [
        Text('Family coins: ${s.familyCoins}', textAlign: TextAlign.center, style: const TextStyle(color: Color(0xFFC4B5FD), fontWeight: FontWeight.w700)),
        const SizedBox(height: 16),
        GridView.count(
          crossAxisCount: 3,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 10,
          crossAxisSpacing: 10,
          children: [
            for (final (i, (name, _, _)) in gachaPrizes.indexed)
              AnimatedContainer(
                duration: 80.ms,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  color: _highlight == i ? YoloColors.gold.withValues(alpha: 0.25) : YoloColors.surface,
                  border: Border.all(color: _highlight == i ? YoloColors.gold : Colors.white10, width: 2),
                ),
                padding: const EdgeInsets.all(8),
                child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                  Icon(i == 5 ? Icons.diamond_rounded : Icons.toll_rounded, color: i == 5 ? const Color(0xFF7DD3FC) : YoloColors.gold, size: 30),
                  const SizedBox(height: 6),
                  Text(name, textAlign: TextAlign.center, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700)),
                ]),
              ),
          ],
        ),
        const SizedBox(height: 20),
        if (_won != null)
          Text('You won ${gachaPrizes[_won!].$1}!', textAlign: TextAlign.center, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: YoloColors.gold))
              .animate()
              .scale(curve: Curves.elasticOut, duration: 600.ms),
        const SizedBox(height: 16),
        Opacity(
          opacity: _spinning ? 0.5 : 1,
          child: GoldButton(label: s.freeRollUsed ? 'Roll (30 family coins)' : 'Free roll today', icon: Icons.casino_rounded, onPressed: _spinning ? null : _roll),
        ),
        const SizedBox(height: 10),
        const Text('Earn family coins from quests, donations and daily sign-in.', textAlign: TextAlign.center, style: TextStyle(fontSize: 12, color: YoloColors.textMuted)),
      ]),
    );
  }
}

/// Family shop: titles and avatar frames bought with family coins.
class FamilyShopScreen extends ConsumerWidget {
  const FamilyShopScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(familyProvider);
    return YoloPage(
      title: 'Family shop',
      actions: [Padding(padding: const EdgeInsets.only(right: 12), child: Center(child: Text('${s.familyCoins} FC', style: const TextStyle(color: Color(0xFFC4B5FD), fontWeight: FontWeight.w800))))],
      body: GridView.builder(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 40),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, mainAxisSpacing: 12, crossAxisSpacing: 12, childAspectRatio: 0.95),
        itemCount: familyShop.length,
        itemBuilder: (_, i) {
          final it = familyShop[i];
          final owned = s.ownedItems.contains(it.id);
          final equipped = s.title == it.name || s.frame == it.name;
          return GlassCard(
            border: equipped ? YoloColors.gold : null,
            onTap: () => showYoloToast(context, ref.read(familyProvider.notifier).shop(it)),
            child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              Icon(it.icon, size: 44, color: it.color),
              const SizedBox(height: 8),
              Text(it.name, style: const TextStyle(fontWeight: FontWeight.w800)),
              Text(it.kind == 'title' ? 'Family title' : 'Family frame', style: const TextStyle(fontSize: 11, color: YoloColors.textMuted)),
              const SizedBox(height: 8),
              Text(equipped ? 'Equipped' : (owned ? 'Equip' : '${it.price} FC'),
                  style: TextStyle(fontWeight: FontWeight.w800, color: equipped ? YoloColors.online : YoloColors.gold)),
            ]),
          ).entrance(i);
        },
      ),
    );
  }
}

/// Members with roles. Leader/deputy can promote, demote and remove.
class FamilyMembersScreen extends ConsumerWidget {
  const FamilyMembersScreen({super.key});

  static const _order = {'leader': 0, 'deputy': 1, 'admin': 2, 'member': 3};
  static const _names = {'leader': 'Leader', 'deputy': 'Deputy', 'admin': 'Admin', 'member': 'Member'};

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(familyProvider);
    final me = ref.watch(sessionProvider)!;
    final rows = [
      (me, s.role),
      for (final e in s.memberRoles.entries) (userById(e.key), e.value),
    ]..sort((a, b) => _order[a.$2]!.compareTo(_order[b.$2]!));

    return YoloPage(
      title: 'Members ${rows.length}/${s.maxMembers}',
      body: ListView(children: [
        for (final (u, role) in rows)
          ListTile(
            leading: YoloAvatar(user: u, size: 44),
            title: Text(u.id == me.id ? '${u.name} (you)' : u.name, style: const TextStyle(fontWeight: FontWeight.w700)),
            trailing: Badge2(_names[role]!, bg: role == 'leader' ? YoloColors.gold : const Color(0x22FFFFFF), fg: role == 'leader' ? YoloColors.onGold : YoloColors.textSoft),
            onTap: s.canManage && u.id != me.id && role != 'leader'
                ? () => showRoomSheet<void>(
                      context,
                      (c) => Column(mainAxisSize: MainAxisSize.min, children: [
                        ListTile(title: Text(u.name, style: const TextStyle(fontWeight: FontWeight.w800))),
                        for (final r in ['deputy', 'admin', 'member'])
                          if (r != role && !(r == 'deputy' && s.role != 'leader'))
                            ListTile(
                              leading: const Icon(Icons.swap_vert_rounded),
                              title: Text('Set as ${_names[r]}'),
                              onTap: () {
                                Navigator.pop(c);
                                ref.read(familyProvider.notifier).setRole(u.id, r);
                              },
                            ),
                        ListTile(
                          leading: const Icon(Icons.person_remove_rounded, color: Color(0xFFF87171)),
                          title: const Text('Remove from family', style: TextStyle(color: Color(0xFFF87171))),
                          onTap: () {
                            Navigator.pop(c);
                            ref.read(familyProvider.notifier).removeMember(u.id);
                          },
                        ),
                        const SizedBox(height: 8),
                      ]),
                    )
                : null,
          ),
      ]),
    );
  }
}

/// Weekly family ranking.
class FamilyRankingScreen extends ConsumerWidget {
  const FamilyRankingScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(familyProvider);
    final rows = familyRanking(s, ref.read(familyProvider.notifier).allFamilies);
    const medal = [Color(0xFFF5C451), Color(0xFFD1D5DB), Color(0xFFD97706)];
    return YoloPage(
      title: 'Family ranking',
      body: ListView(children: [
        const Padding(padding: EdgeInsets.fromLTRB(20, 0, 20, 8), child: Text('This week · by activeness', style: TextStyle(color: YoloColors.textMuted))),
        for (final (i, (f, score)) in rows.indexed)
          ListTile(
            tileColor: f.id == s.familyId ? YoloColors.gold.withValues(alpha: 0.06) : null,
            leading: SizedBox(
              width: 92,
              child: Row(children: [
                SizedBox(width: 30, child: Text('${i + 1}', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: i < 3 ? medal[i] : YoloColors.textMuted))),
                FamilyBadge(f, size: 44),
              ]),
            ),
            title: Text(f.name, style: const TextStyle(fontWeight: FontWeight.w700)),
            subtitle: Text('Lv ${f.id == s.familyId ? s.level : f.level}', style: const TextStyle(fontSize: 12, color: YoloColors.textMuted)),
            trailing: Text('$score', style: const TextStyle(color: YoloColors.gold, fontWeight: FontWeight.w800)),
          ).entrance(i),
      ]),
    );
  }
}
