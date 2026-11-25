import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../core/theme.dart';
import '../../data/demo_content.dart';
import '../../data/gift_providers.dart';
import '../../data/models.dart';
import '../../data/providers.dart';
import '../../data/repository.dart';
import '../../data/social_providers.dart';
import '../../widgets/common.dart';
import '../../widgets/page_kit.dart';
import '../room/room_sheets.dart';

const _cats = ['popular', 'lucky', 'vip', 'special'];
const _catNames = ['Popular', 'Lucky', 'VIP', 'Special'];

Widget _price(Gift g) => g.vipLevel > 0
    ? Text('VIP ${g.vipLevel} · ${formatCoins(g.price)}', style: const TextStyle(fontSize: 11, color: YoloColors.gold, fontWeight: FontWeight.w700))
    : Row(mainAxisSize: MainAxisSize.min, children: [
        const CoinIcon(size: 11),
        const SizedBox(width: 3),
        Text(formatCoins(g.price), style: const TextStyle(fontSize: 11, color: YoloColors.gold, fontWeight: FontWeight.w700)),
      ]);

/// Animated gift preview (used in store and sheets).
class GiftPreview extends StatelessWidget {
  const GiftPreview({super.key, required this.gift, this.size = 120});
  final Gift gift;
  final double size;

  @override
  Widget build(BuildContext context) => Stack(alignment: Alignment.center, children: [
        Container(
          width: size * 1.6,
          height: size * 1.6,
          decoration: BoxDecoration(shape: BoxShape.circle, gradient: RadialGradient(colors: [gift.tint.withValues(alpha: 0.5), gift.tint.withValues(alpha: 0)])),
        ).animate(onPlay: (c) => c.repeat(reverse: true)).scaleXY(begin: 0.85, end: 1.05, duration: 1200.ms),
        Icon(gift.icon, size: size, color: gift.tint)
            .animate(onPlay: (c) => c.repeat())
            .scale(begin: const Offset(0.6, 0.6), end: const Offset(1, 1), duration: 700.ms, curve: Curves.elasticOut)
            .then(delay: 900.ms)
            .shake(hz: 3, rotation: 0.05, duration: 500.ms),
      ]);
}

/// Sheet to send a gift to a user outside a room (profile, chat).
void showSendGiftSheet(BuildContext context, WidgetRef ref, YoloUser to) {
  var selected = demoGiftCatalog.first;
  var qty = 1;
  showRoomSheet<void>(
    context,
    (c) => StatefulBuilder(
      builder: (c, setState) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 18, 16, 16),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Row(children: [
            YoloAvatar(user: to, size: 36),
            const SizedBox(width: 10),
            Expanded(child: Text('Send a gift to ${to.name}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800))),
          ]),
          const SizedBox(height: 12),
          SizedBox(
            height: 230,
            child: GridView.count(
              crossAxisCount: 4,
              mainAxisSpacing: 8,
              crossAxisSpacing: 8,
              childAspectRatio: 0.8,
              children: [
                for (final g in demoGiftCatalog.where((g) => g.category != 'vip'))
                  GestureDetector(
                    onTap: () => setState(() => selected = g),
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(14),
                        color: selected.id == g.id ? YoloColors.gold.withValues(alpha: 0.12) : Colors.white.withValues(alpha: 0.04),
                        border: Border.all(color: selected.id == g.id ? YoloColors.gold : Colors.white10, width: 1.5),
                      ),
                      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                        Icon(g.icon, color: g.tint, size: 30),
                        Text(g.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700)),
                        _price(g),
                      ]),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Row(children: [
            for (final q in [1, 10, 99])
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: ChoiceChip(
                  label: Text('×$q'),
                  selected: qty == q,
                  onSelected: (_) => setState(() => qty = q),
                  selectedColor: YoloColors.gold,
                  showCheckmark: false,
                  labelStyle: TextStyle(color: qty == q ? YoloColors.onGold : YoloColors.text, fontWeight: FontWeight.w700),
                ),
              ),
            const Spacer(),
            SizedBox(
              width: 110,
              child: GoldButton(
                label: 'Send',
                height: 44,
                onPressed: () {
                  final res = ref.read(giftCenterProvider.notifier).send(selected, to, qty);
                  Navigator.pop(c);
                  if (res.ok) ref.read(chatProvider('u:${to.id}').notifier).send('Sent you a gift: ${selected.name} ×$qty');
                  showYoloToast(context, res.message);
                },
              ),
            ),
          ]),
        ]),
      ),
    ),
    scroll: true,
  );
}

/// Gift store: browse every gift by category, preview, buy into backpack.
class GiftStoreScreen extends ConsumerStatefulWidget {
  const GiftStoreScreen({super.key});

  @override
  ConsumerState<GiftStoreScreen> createState() => _GiftStoreScreenState();
}

class _GiftStoreScreenState extends ConsumerState<GiftStoreScreen> {
  int _tab = 0;

  void _preview(Gift g) {
    showRoomSheet<void>(
      context,
      (c) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 16),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          SizedBox(height: 190, child: Center(child: GiftPreview(gift: g))),
          Text(g.name, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
          const SizedBox(height: 4),
          _price(g),
          const SizedBox(height: 6),
          Text(
            switch (g.category) {
              'lucky' => 'Lucky gift: 30% chance to win 2×, 5× or 10× coins back.',
              'vip' => 'Only VIP ${g.vipLevel}+ members can send this gift.',
              'special' => 'Special gift with a full-screen animation and a global banner.',
              _ => g.fullScreen ? 'Plays a full-screen animation in the room.' : 'A sweet gift for anyone.',
            },
            textAlign: TextAlign.center,
            style: const TextStyle(color: YoloColors.textSoft),
          ),
          const SizedBox(height: 16),
          Row(children: [
            Expanded(
              child: OutlinedButton(
                style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(48), shape: const StadiumBorder(), foregroundColor: YoloColors.gold),
                onPressed: () {
                  final ok = ref.read(giftCenterProvider.notifier).buyToBackpack(g, 1);
                  Navigator.pop(c);
                  showYoloToast(context, ok ? '${g.name} added to your backpack' : 'Not enough coins');
                },
                child: const Text('Buy to backpack'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: GoldButton(
                label: 'Send to friend',
                height: 48,
                onPressed: () {
                  Navigator.pop(c);
                  final friends = ref.read(friendsProvider);
                  if (friends.isEmpty) {
                    showYoloToast(context, 'Add friends first');
                    return;
                  }
                  showRoomSheet<void>(
                    context,
                    (c2) => Column(mainAxisSize: MainAxisSize.min, children: [
                      const Padding(padding: EdgeInsets.all(16), child: Text('Choose a friend', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800))),
                      for (final u in friends)
                        ListTile(
                          leading: YoloAvatar(user: u, size: 40),
                          title: Text(u.name),
                          onTap: () {
                            Navigator.pop(c2);
                            showYoloToast(context, ref.read(giftCenterProvider.notifier).send(g, u, 1).message);
                          },
                        ),
                      const SizedBox(height: 8),
                    ]),
                  );
                },
              ),
            ),
          ]),
        ]),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final coins = ref.watch(sessionProvider)?.coins ?? 0;
    final gifts = demoGiftCatalog.where((g) => g.category == _cats[_tab]).toList();
    return YoloPage(
      title: 'Gift store',
      actions: [
        IconButton(tooltip: 'Gift history', icon: const Icon(Icons.history_rounded), onPressed: () => context.push('/gifts/history')),
        IconButton(tooltip: 'Gift ranking', icon: const Icon(Icons.leaderboard_rounded), onPressed: () => context.push('/gifts/ranking')),
      ],
      bottom: Column(children: [
        Padding(padding: const EdgeInsets.fromLTRB(20, 0, 20, 6), child: Row(children: [CoinPill(coins: coins), const Spacer(), TextButton.icon(onPressed: () => context.push('/backpack'), icon: const Icon(Icons.backpack_rounded, color: YoloColors.gold), label: const Text('My items', style: TextStyle(color: YoloColors.gold)))])),
        YoloTabs(tabs: _catNames, index: _tab, onChanged: (i) => setState(() => _tab = i)),
      ]),
      body: GridView.builder(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 40),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 3, mainAxisSpacing: 12, crossAxisSpacing: 12, childAspectRatio: 0.82),
        itemCount: gifts.length,
        itemBuilder: (_, i) {
          final g = gifts[i];
          return GlassCard(
            padding: const EdgeInsets.all(8),
            border: g.category == 'special' ? YoloColors.gold.withValues(alpha: 0.5) : null,
            onTap: () => _preview(g),
            child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              Icon(g.icon, size: 42, color: g.tint),
              const SizedBox(height: 6),
              Text(g.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
              const SizedBox(height: 2),
              _price(g),
            ]),
          ).entrance(i);
        },
      ),
    );
  }
}

/// Sent / received gift history.
class GiftHistoryScreen extends ConsumerStatefulWidget {
  const GiftHistoryScreen({super.key});

  @override
  ConsumerState<GiftHistoryScreen> createState() => _GiftHistoryScreenState();
}

class _GiftHistoryScreenState extends ConsumerState<GiftHistoryScreen> {
  int _tab = 1;

  @override
  Widget build(BuildContext context) {
    final meId = ref.watch(sessionProvider)?.id;
    final records = ref.watch(giftCenterProvider).records;
    final sent = records.where((r) => r.from.id == meId).toList();
    final received = records.where((r) => r.to.id == meId).toList();
    final list = _tab == 0 ? sent : received;
    final total = list.fold<int>(0, (a, r) => a + r.total);
    return YoloPage(
      title: 'Gift history',
      bottom: Column(children: [
        YoloTabs(tabs: ['Sent ${sent.length}', 'Received ${received.length}'], index: _tab, onChanged: (i) => setState(() => _tab = i)),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
          child: Row(children: [
            Text(_tab == 0 ? 'Total sent ' : 'Total received ', style: const TextStyle(color: YoloColors.textMuted)),
            const CoinIcon(size: 14),
            Text(' ${formatCoins(total)}', style: const TextStyle(color: YoloColors.gold, fontWeight: FontWeight.w800)),
          ]),
        ),
      ]),
      body: list.isEmpty
          ? EmptyState(icon: Icons.card_giftcard_rounded, title: _tab == 0 ? 'No gifts sent yet' : 'No gifts received yet')
          : ListView.builder(
              itemCount: list.length,
              itemBuilder: (_, i) {
                final r = list[i];
                final other = _tab == 0 ? r.to : r.from;
                return ListTile(
                  leading: YoloAvatar(user: other, size: 44),
                  title: Text(_tab == 0 ? 'To ${other.name}' : 'From ${other.name}', style: const TextStyle(fontWeight: FontWeight.w700)),
                  subtitle: Text(r.time, style: const TextStyle(fontSize: 12, color: YoloColors.textMuted)),
                  trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                    Icon(r.gift.icon, color: r.gift.tint),
                    const SizedBox(width: 6),
                    Text('${r.gift.name} ×${r.qty}', style: const TextStyle(fontWeight: FontWeight.w700)),
                  ]),
                ).entrance(i);
              },
            ),
    );
  }
}

/// Top senders / receivers.
class GiftRankingScreen extends ConsumerStatefulWidget {
  const GiftRankingScreen({super.key});

  @override
  ConsumerState<GiftRankingScreen> createState() => _GiftRankingScreenState();
}

class _GiftRankingScreenState extends ConsumerState<GiftRankingScreen> {
  int _tab = 0;

  @override
  Widget build(BuildContext context) {
    final rows = giftRanking(ref.watch(giftCenterProvider).records, senders: _tab == 0);
    final meId = ref.watch(sessionProvider)?.id;
    const medal = [Color(0xFFF5C451), Color(0xFFD1D5DB), Color(0xFFD97706)];
    return YoloPage(
      title: 'Gift ranking',
      bottom: YoloTabs(tabs: const ['Top senders', 'Top receivers'], index: _tab, onChanged: (i) => setState(() => _tab = i)),
      body: ListView.builder(
        itemCount: rows.length,
        itemBuilder: (_, i) {
          final (u, total) = rows[i];
          return ListTile(
            tileColor: u.id == meId ? YoloColors.gold.withValues(alpha: 0.06) : null,
            leading: SizedBox(
              width: 88,
              child: Row(children: [
                SizedBox(width: 30, child: Text('${i + 1}', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: i < 3 ? medal[i] : YoloColors.textMuted))),
                YoloAvatar(user: u, size: 44, goldFrame: i == 0),
              ]),
            ),
            title: Text(u.id == meId ? '${u.name} (you)' : u.name, style: const TextStyle(fontWeight: FontWeight.w700)),
            trailing: Row(mainAxisSize: MainAxisSize.min, children: [
              const CoinIcon(size: 14),
              Text(' ${formatCoins(total)}', style: const TextStyle(color: YoloColors.gold, fontWeight: FontWeight.w800)),
            ]),
          ).entrance(i);
        },
      ),
    );
  }
}

/// My items (backpack): gifts and owned virtual items, with equip.
class BackpackScreen extends ConsumerStatefulWidget {
  const BackpackScreen({super.key});

  @override
  ConsumerState<BackpackScreen> createState() => _BackpackScreenState();
}

class _BackpackScreenState extends ConsumerState<BackpackScreen> {
  static const _tabs = ['Gifts', 'Frames', 'Entry effects', 'Special effects', 'Bubbles', 'Themes', 'Decorations'];
  static const _cats = ['', 'frame', 'entry', 'effect', 'bubble', 'theme', 'decoration'];
  int _tab = 0;

  @override
  Widget build(BuildContext context) {
    final backpack = ref.watch(giftCenterProvider).backpack;
    final owned = ref.watch(ownedItemsProvider);
    final equipped = ref.watch(equippedItemsProvider);

    Widget body;
    if (_tab == 0) {
      final gifts = backpack.entries.toList();
      body = gifts.isEmpty
          ? const EmptyState(icon: Icons.backpack_rounded, title: 'No gifts in your backpack', subtitle: 'Buy gifts in the gift store or win them in events.')
          : GridView.count(
              padding: const EdgeInsets.all(16),
              crossAxisCount: 3,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              children: [
                for (final e in gifts)
                  GlassCard(
                    padding: const EdgeInsets.all(8),
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Column(mainAxisSize: MainAxisSize.min, children: [
                        Icon(giftById(e.key).icon, color: giftById(e.key).tint, size: 36),
                        Text(giftById(e.key).name, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12)),
                        Text('×${e.value}', style: const TextStyle(color: Color(0xFF86EFAC), fontWeight: FontWeight.w800)),
                      ]),
                    ),
                  ),
              ],
            );
    } else {
      final items = demoShopItems.where((s) => s.category == _cats[_tab] && owned.contains(s.id)).toList();
      body = items.isEmpty
          ? EmptyState(icon: Icons.inventory_2_rounded, title: 'Nothing here yet', subtitle: 'Get ${_tabs[_tab].toLowerCase()} in the shop.')
          : ListView(children: [
              for (final it in items)
                ListTile(
                  leading: Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(shape: BoxShape.circle, gradient: SweepGradient(colors: [...it.colors, it.colors.first])),
                    child: Icon(it.icon, color: Colors.white),
                  ),
                  title: Text(it.name, style: const TextStyle(fontWeight: FontWeight.w700)),
                  subtitle: Text('Valid ${it.duration}', style: const TextStyle(fontSize: 12, color: YoloColors.textMuted)),
                  trailing: equipped.contains(it.id)
                      ? OutlinedButton(onPressed: () => ref.read(equippedItemsProvider.notifier).remove(it.id), child: const Text('Unequip'))
                      : SizedBox(
                          width: 96,
                          child: GoldButton(label: 'Equip', height: 36, onPressed: () {
                            final eq = ref.read(equippedItemsProvider.notifier);
                            for (final o in demoShopItems.where((s) => s.category == it.category)) {
                              eq.remove(o.id);
                            }
                            eq.add(it.id);
                          }),
                        ),
                ),
            ]);
    }

    return YoloPage(
      title: 'My items',
      actions: [TextButton(onPressed: () => context.push('/shop'), child: const Text('Shop', style: TextStyle(color: YoloColors.gold)))],
      bottom: YoloTabs(tabs: _tabs, index: _tab, onChanged: (i) => setState(() => _tab = i)),
      body: body,
    );
  }
}
