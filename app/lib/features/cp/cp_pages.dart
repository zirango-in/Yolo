import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../core/theme.dart';
import '../../data/cp_providers.dart';
import '../../data/gift_providers.dart';
import '../../data/models.dart';
import '../../data/providers.dart';
import '../../data/social_providers.dart';
import '../../widgets/common.dart';
import '../../widgets/page_kit.dart';
import '../gifts/gift_pages.dart';
import '../room/room_sheets.dart';

/// Two avatars joined by a beating heart.
class PairAvatars extends StatelessWidget {
  const PairAvatars({super.key, required this.a, required this.b, required this.type, this.size = 64});
  final YoloUser a;
  final YoloUser b;
  final RelationType type;
  final double size;

  @override
  Widget build(BuildContext context) => Row(mainAxisSize: MainAxisSize.min, children: [
        YoloAvatar(user: a, size: size, goldFrame: true),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Icon(type.icon, color: type.colors.first, size: size * 0.45)
              .animate(onPlay: (c) => c.repeat(reverse: true))
              .scaleXY(begin: 0.85, end: 1.15, duration: 700.ms, curve: Curves.easeInOut),
        ),
        YoloAvatar(user: b, size: size, goldFrame: true),
      ]);
}

/// Pick a relationship type, then a friend, then send with the gift.
void showSendRelationSheet(BuildContext context, WidgetRef ref, {YoloUser? to}) {
  var type = relationTypes.first;
  YoloUser? target = to;
  showRoomSheet<void>(
    context,
    (c) => StatefulBuilder(builder: (c, setState) {
      final s = ref.read(cpProvider);
      final friends = ref.read(friendsProvider).where((u) => !s.hasRelationWith(u.id)).toList();
      final gift = giftById(type.giftId);
      final full = s.used(type.id) >= type.slots;
      return SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Send a relationship request', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
          const SizedBox(height: 12),
          Wrap(spacing: 8, runSpacing: 8, children: [
            for (final t in relationTypes)
              ChoiceChip(
                avatar: Icon(t.icon, size: 18, color: type.id == t.id ? YoloColors.onGold : t.colors.first),
                label: Text('${t.name} ${s.used(t.id)}/${t.slots}'),
                selected: type.id == t.id,
                onSelected: (_) => setState(() => type = t),
                selectedColor: YoloColors.gold,
                showCheckmark: false,
                labelStyle: TextStyle(color: type.id == t.id ? YoloColors.onGold : YoloColors.text, fontWeight: FontWeight.w700),
              ),
          ]),
          const SizedBox(height: 14),
          if (to == null) ...[
            const Text('Choose a friend', style: TextStyle(fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            if (friends.isEmpty) const Text('Add friends first (mutual follows).', style: TextStyle(color: YoloColors.textMuted)),
            SizedBox(
              height: 92,
              child: ListView(scrollDirection: Axis.horizontal, children: [
                for (final u in friends)
                  GestureDetector(
                    onTap: () => setState(() => target = u),
                    child: Padding(
                      padding: const EdgeInsets.only(right: 12),
                      child: Column(children: [
                        Container(
                          padding: const EdgeInsets.all(2),
                          decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: target?.id == u.id ? YoloColors.gold : Colors.transparent, width: 2)),
                          child: YoloAvatar(user: u, size: 52),
                        ),
                        const SizedBox(height: 4),
                        Text(u.name, style: const TextStyle(fontSize: 12)),
                      ]),
                    ),
                  ),
              ]),
            ),
          ] else
            ListTile(contentPadding: EdgeInsets.zero, leading: YoloAvatar(user: to, size: 44), title: Text('To ${to.name}', style: const TextStyle(fontWeight: FontWeight.w700))),
          const SizedBox(height: 8),
          GlassCard(
            padding: const EdgeInsets.all(12),
            child: Row(children: [
              Icon(gift.icon, color: gift.tint, size: 32),
              const SizedBox(width: 10),
              Expanded(child: Text('Sent with a ${gift.name} gift', style: const TextStyle(fontWeight: FontWeight.w600))),
              const CoinIcon(size: 14),
              Text(' ${formatCoins(gift.price)}', style: const TextStyle(color: YoloColors.gold, fontWeight: FontWeight.w800)),
            ]),
          ),
          const SizedBox(height: 14),
          Opacity(
            opacity: target != null && !full ? 1 : 0.5,
            child: GoldButton(
              label: full ? '${type.name} slots full' : 'Send request',
              icon: type.icon,
              onPressed: target == null || full
                  ? null
                  : () {
                      final err = ref.read(cpProvider.notifier).sendRequest(type.id, target!);
                      Navigator.pop(c);
                      showYoloToast(context, err.isEmpty ? 'Request sent to ${target!.name}' : err);
                    },
            ),
          ),
        ]),
      );
    }),
    scroll: true,
  );
}

/// Relationships home: couple card, slots, requests, ranking.
class RelationshipsScreen extends ConsumerWidget {
  const RelationshipsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(cpProvider);
    final me = ref.watch(sessionProvider)!;
    final ctrl = ref.read(cpProvider.notifier);
    final couple = s.couple;
    final coupleType = relationType('couple');

    return YoloPage(
      title: 'CP & relationships',
      actions: [IconButton(tooltip: 'CP ranking', icon: const Icon(Icons.leaderboard_rounded, color: YoloColors.gold), onPressed: () => context.push('/cp/ranking'))],
      body: ListView(padding: const EdgeInsets.fromLTRB(16, 4, 16, 40), children: [
        GlassCard(
          padding: const EdgeInsets.all(20),
          gradient: LinearGradient(colors: [coupleType.colors.last.withValues(alpha: 0.7), const Color(0xFF4C1D95)]),
          onTap: couple == null ? null : () => context.push('/cp/space', extra: couple),
          child: couple == null
              ? Column(children: [
                  const Icon(Icons.favorite_border_rounded, size: 48, color: Color(0xFFFBCFE8)),
                  const SizedBox(height: 8),
                  const Text('Find your CP', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900)),
                  const Text('Send a Couple request with a Ring to someone special.', textAlign: TextAlign.center, style: TextStyle(color: Color(0xFFFCE7F3))),
                  const SizedBox(height: 12),
                  GoldButton(label: 'Send CP request', icon: Icons.favorite_rounded, height: 44, onPressed: () => showSendRelationSheet(context, ref)),
                ])
              : Column(children: [
                  PairAvatars(a: me, b: couple.partner, type: coupleType, size: 70),
                  const SizedBox(height: 10),
                  Text('${me.name} & ${couple.partner.name}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
                  Text('Together ${couple.days} days · CP Lv${cpLevel(couple.intimacy)}', style: const TextStyle(color: Color(0xFFFCE7F3))),
                  const SizedBox(height: 10),
                  _IntimacyBar(intimacy: couple.intimacy),
                ]),
        ),
        for (final t in relationTypes.where((t) => t.id != 'couple')) ...[
          SectionTitle('${t.name}  ${s.used(t.id)}/${t.slots}'),
          Row(children: [
            for (var i = 0; i < t.slots; i++)
              Expanded(
                child: Padding(
                  padding: EdgeInsets.only(right: i == 0 ? 6 : 0, left: i == 1 ? 6 : 0),
                  child: Builder(builder: (_) {
                    final rels = s.relations.where((r) => r.type == t.id).toList();
                    if (i < rels.length) {
                      final r = rels[i];
                      return GlassCard(
                        padding: const EdgeInsets.all(12),
                        gradient: LinearGradient(colors: [t.colors.last.withValues(alpha: 0.45), YoloColors.surface]),
                        onTap: () => context.push('/cp/space', extra: r),
                        child: Column(children: [
                          YoloAvatar(user: r.partner, size: 52),
                          const SizedBox(height: 6),
                          Text(r.partner.name, style: const TextStyle(fontWeight: FontWeight.w800)),
                          Text('${r.days} days · Lv${cpLevel(r.intimacy)}', style: const TextStyle(fontSize: 11, color: YoloColors.textSoft)),
                        ]),
                      );
                    }
                    return GlassCard(
                      padding: const EdgeInsets.all(12),
                      onTap: () => showSendRelationSheet(context, ref),
                      child: Column(children: [
                        Container(
                          width: 52,
                          height: 52,
                          decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: t.colors.first.withValues(alpha: 0.6), width: 1.5)),
                          child: Icon(Icons.add_rounded, color: t.colors.first),
                        ),
                        const SizedBox(height: 6),
                        Text('Invite', style: TextStyle(color: t.colors.first, fontWeight: FontWeight.w700)),
                        const Text(' ', style: TextStyle(fontSize: 11)),
                      ]),
                    );
                  }),
                ),
              ),
          ]),
        ],
        if (s.requests.isNotEmpty) ...[
          const SectionTitle('Requests'),
          for (final r in s.requests)
            GlassCard(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(12),
              child: Row(children: [
                YoloAvatar(user: r.user, size: 44),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(r.user.name, style: const TextStyle(fontWeight: FontWeight.w800)),
                    Text(r.incoming ? 'Wants to be your ${relationType(r.type).name}' : 'Waiting for reply · ${relationType(r.type).name}',
                        style: const TextStyle(fontSize: 12, color: YoloColors.textMuted)),
                  ]),
                ),
                if (r.incoming) ...[
                  IconButton(tooltip: 'Decline ${r.user.name}', icon: const Icon(Icons.close_rounded, color: YoloColors.textMuted), onPressed: () => ctrl.decline(r.id)),
                  SizedBox(
                    width: 88,
                    child: GoldButton(label: 'Accept', height: 36, onPressed: () {
                      final err = ctrl.accept(r.id);
                      showYoloToast(context, err.isEmpty ? 'You and ${r.user.name} are now ${relationType(r.type).name}!' : err);
                    }),
                  ),
                ] else
                  TextButton(onPressed: () => ctrl.decline(r.id), child: const Text('Cancel')),
              ]),
            ),
        ],
        const SizedBox(height: 16),
        OutlinedButton.icon(
          onPressed: () => showSendRelationSheet(context, ref),
          style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(50), shape: const StadiumBorder(), foregroundColor: YoloColors.gold),
          icon: const Icon(Icons.add_reaction_rounded),
          label: const Text('New relationship'),
        ),
      ]),
    );
  }
}

class _IntimacyBar extends StatelessWidget {
  const _IntimacyBar({required this.intimacy});
  final int intimacy;

  @override
  Widget build(BuildContext context) {
    final lvl = cpLevel(intimacy);
    final from = cpLevels[lvl - 1].$2;
    final to = nextCpLevelAt(intimacy);
    return Column(children: [
      ClipRRect(
        borderRadius: BorderRadius.circular(6),
        child: LinearProgressIndicator(
          value: to == null ? 1 : ((intimacy - from) / (to - from)).clamp(0.0, 1.0),
          minHeight: 8,
          color: const Color(0xFFF472B6),
          backgroundColor: const Color(0x33FFFFFF),
        ),
      ),
      const SizedBox(height: 4),
      Text(to == null ? 'Intimacy ${formatCoins(intimacy)} · max level' : 'Intimacy ${formatCoins(intimacy)} / ${formatCoins(to)}',
          style: const TextStyle(fontSize: 12, color: Color(0xFFFCE7F3))),
    ]);
  }
}

/// CP space for one relationship: days, level, intimacy, rewards, gift, break up.
class CpSpaceScreen extends ConsumerWidget {
  const CpSpaceScreen({super.key, required this.relationId});
  final int relationId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(cpProvider);
    final me = ref.watch(sessionProvider)!;
    final r = s.relations.where((x) => x.id == relationId).firstOrNull;
    if (r == null) return const YoloPage(title: 'Relationship', body: EmptyState(icon: Icons.heart_broken_rounded, title: 'This relationship has ended'));
    final t = relationType(r.type);
    final lvl = cpLevel(r.intimacy);
    final gifts = ref.watch(giftCenterProvider).records.where((g) => (g.from.id == me.id && g.to.id == r.partner.id) || (g.to.id == me.id && g.from.id == r.partner.id)).toList();

    return YoloPage(
      title: t.name,
      body: ListView(padding: const EdgeInsets.fromLTRB(16, 4, 16, 40), children: [
        GlassCard(
          padding: const EdgeInsets.all(20),
          gradient: LinearGradient(colors: [t.colors.last.withValues(alpha: 0.7), const Color(0xFF312E81)]),
          child: Column(children: [
            PairAvatars(a: me, b: r.partner, type: t, size: 78),
            const SizedBox(height: 12),
            Text('${me.name} & ${r.partner.name}', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900)),
            const SizedBox(height: 4),
            Text('${t.name} for ${r.days} days', style: const TextStyle(color: Color(0xFFF1F5F9))),
            const SizedBox(height: 12),
            Badge2('Lv$lvl', bg: YoloColors.gold, fg: YoloColors.onGold),
            const SizedBox(height: 10),
            _IntimacyBar(intimacy: r.intimacy),
          ]),
        ),
        const SizedBox(height: 12),
        GoldButton(label: 'Send a gift to grow intimacy', icon: Icons.card_giftcard_rounded, onPressed: () => showSendGiftSheet(context, ref, r.partner)),
        const Padding(
          padding: EdgeInsets.only(top: 6),
          child: Text('Every 10 coins of gifts between you = 1 intimacy point.', textAlign: TextAlign.center, style: TextStyle(fontSize: 12, color: YoloColors.textMuted)),
        ),
        const SectionTitle('Level rewards'),
        for (final (l, need, reward) in cpLevels)
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Badge2('Lv$l', bg: lvl >= l ? YoloColors.gold : const Color(0x22FFFFFF), fg: lvl >= l ? YoloColors.onGold : YoloColors.textSoft),
            title: Text(reward),
            subtitle: Text('${formatCoins(need)} intimacy', style: const TextStyle(fontSize: 12, color: YoloColors.textMuted)),
            trailing: Icon(lvl >= l ? Icons.check_circle_rounded : Icons.lock_rounded, color: lvl >= l ? YoloColors.online : YoloColors.textMuted),
          ),
        SectionTitle('Gifts between you (${gifts.length})'),
        if (gifts.isEmpty) const Text('No gifts yet', style: TextStyle(color: YoloColors.textMuted)),
        for (final g in gifts.take(6))
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Icon(g.gift.icon, color: g.gift.tint),
            title: Text('${g.from.name} → ${g.to.name}'),
            trailing: Text('${g.gift.name} ×${g.qty}', style: const TextStyle(fontWeight: FontWeight.w700)),
          ),
        const SizedBox(height: 20),
        TextButton.icon(
          onPressed: () => showDialog<void>(
            context: context,
            builder: (c) => AlertDialog(
              backgroundColor: YoloColors.sheet,
              title: Text('End ${t.name} with ${r.partner.name}?'),
              content: const Text('Your days together and intimacy will be lost. This cannot be undone.'),
              actions: [
                TextButton(onPressed: () => Navigator.pop(c), child: const Text('Keep')),
                FilledButton(
                  style: FilledButton.styleFrom(backgroundColor: const Color(0xFFDC2626)),
                  onPressed: () {
                    Navigator.pop(c);
                    ref.read(cpProvider.notifier).breakUp(r.id);
                    context.pop();
                    showYoloToast(context, 'Relationship ended');
                  },
                  child: const Text('End'),
                ),
              ],
            ),
          ),
          icon: const Icon(Icons.heart_broken_rounded, color: Color(0xFFF87171)),
          label: Text('End ${t.name.toLowerCase()}', style: const TextStyle(color: Color(0xFFF87171))),
        ),
      ]),
    );
  }
}

/// Top pairs by intimacy.
class CpRankingScreen extends ConsumerWidget {
  const CpRankingScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final rows = cpRanking(ref.watch(cpProvider), ref.watch(sessionProvider)!);
    const medal = [Color(0xFFF5C451), Color(0xFFD1D5DB), Color(0xFFD97706)];
    return YoloPage(
      title: 'CP ranking',
      body: ListView(padding: const EdgeInsets.fromLTRB(16, 4, 16, 40), children: [
        for (final (i, (a, b, score)) in rows.indexed)
          GlassCard(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(12),
            border: i < 3 ? medal[i].withValues(alpha: 0.6) : null,
            child: Row(children: [
              SizedBox(width: 30, child: Text('${i + 1}', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: i < 3 ? medal[i] : YoloColors.textMuted))),
              PairAvatars(a: a, b: b, type: relationType('couple'), size: 40),
              const SizedBox(width: 10),
              Expanded(child: Text('${a.name} & ${b.name}', maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w800))),
              Text(formatCoins(score), style: const TextStyle(color: Color(0xFFF472B6), fontWeight: FontWeight.w900)),
            ]),
          ).entrance(i),
      ]),
    );
  }
}
