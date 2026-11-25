import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../core/theme.dart';
import '../../data/models.dart';
import '../../data/providers.dart';
import '../../widgets/common.dart';

class GiftSheet extends ConsumerStatefulWidget {
  const GiftSheet({super.key, required this.room, this.initialTarget});
  final Room room;
  final YoloUser? initialTarget;

  @override
  ConsumerState<GiftSheet> createState() => _GiftSheetState();
}

class _GiftSheetState extends ConsumerState<GiftSheet> {
  static const _quantities = [1, 10, 66, 99, 520];
  static const _tabs = ['Gifts', 'Lucky', 'VIP', 'Backpack'];
  int _tab = 0;
  int? _giftId;
  int _qty = 1;
  YoloUser? _target;

  @override
  void initState() {
    super.initState();
    _target = widget.initialTarget ?? widget.room.owner;
  }

  void _send(List<Gift> gifts) {
    final gift = gifts.firstWhere((g) => g.id == _giftId, orElse: () => gifts.first);
    final ok = ref.read(roomProvider(widget.room).notifier).sendGift(gift, _target!, _qty);
    if (ok) {
      Navigator.of(context).pop();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Not enough coins. Recharge to send this gift.'),
        behavior: SnackBarBehavior.floating,
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    final me = ref.watch(sessionProvider);
    final roomState = ref.watch(roomProvider(widget.room));
    final gifts = ref.watch(giftsProvider);
    final targets = <YoloUser>[
      widget.room.owner,
      for (final s in roomState.seats)
        if (s.user != null && s.user!.id != me?.id && s.user!.id != widget.room.owner.id) s.user!,
    ];

    return Container(
      padding: EdgeInsets.fromLTRB(16, 16, 16, MediaQuery.paddingOf(context).bottom + 16),
      decoration: BoxDecoration(
        color: YoloColors.sheet,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        border: Border(top: BorderSide(color: YoloColors.gold.withValues(alpha: 0.25))),
      ),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        // Recipients
        SizedBox(
          height: 44,
          child: Row(children: [
            const Text('Send to', style: TextStyle(fontSize: 12, color: YoloColors.textMuted, fontWeight: FontWeight.w600)),
            const SizedBox(width: 8),
            Expanded(
              child: ListView(scrollDirection: Axis.horizontal, children: [
                for (final u in targets)
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: GestureDetector(
                      onTap: () => setState(() => _target = u),
                      child: AnimatedContainer(
                        duration: 200.ms,
                        padding: const EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: _target?.id == u.id ? YoloColors.gold : Colors.transparent, width: 2),
                        ),
                        child: YoloAvatar(user: u, size: 34),
                      ),
                    ),
                  ),
              ]),
            ),
          ]),
        ),
        const SizedBox(height: 10),
        // Tabs
        SingleChildScrollView(scrollDirection: Axis.horizontal, child: Row(children: [
          for (var i = 0; i < _tabs.length; i++)
            Padding(
              padding: const EdgeInsets.only(right: 20),
              child: GestureDetector(
                onTap: () => setState(() => _tab = i),
                child: Column(children: [
                  Text(_tabs[i],
                      style: TextStyle(
                          fontSize: i == _tab ? 15 : 14,
                          fontWeight: i == _tab ? FontWeight.w800 : FontWeight.w600,
                          color: i == _tab ? YoloColors.text : YoloColors.textMuted)),
                  const SizedBox(height: 6),
                  AnimatedContainer(duration: 200.ms, height: 3, width: i == _tab ? 24 : 0, color: YoloColors.gold),
                ]),
              ),
            ),
        ])),
        const SizedBox(height: 12),
        // Gift grid
        gifts.when(
          loading: () => const SizedBox(height: 220, child: Center(child: CircularProgressIndicator(color: YoloColors.gold))),
          error: (e, _) => SizedBox(height: 220, child: Center(child: Text('$e'))),
          data: (list) {
            final shown = _tab == 0 ? list : const <Gift>[];
            if (shown.isEmpty) {
              return SizedBox(
                height: 220,
                child: Center(
                  child: Text('${_tabs[_tab]} gifts arrive in a later phase',
                      style: const TextStyle(color: YoloColors.textMuted)),
                ),
              );
            }
            final selected = _giftId ?? shown.first.id;
            return Column(children: [
              GridView.count(
                crossAxisCount: 4,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: 10,
                crossAxisSpacing: 10,
                childAspectRatio: 0.82,
                children: [
                  for (final g in shown)
                    _GiftTile(gift: g, selected: g.id == selected, onTap: () => setState(() => _giftId = g.id)),
                ],
              ),
              const SizedBox(height: 14),
              Row(children: [
                const CoinIcon(size: 18),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(formatCoins(me?.coins ?? 0),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: YoloColors.gold, fontWeight: FontWeight.w800, fontSize: 14)),
                ),
                Container(
                  height: 44,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(color: YoloColors.gold.withValues(alpha: 0.4)),
                  ),
                  child: Row(children: [
                    PopupMenuButton<int>(
                      tooltip: 'Quantity',
                      initialValue: _qty,
                      onSelected: (q) => setState(() => _qty = q),
                      itemBuilder: (_) => [for (final q in _quantities) PopupMenuItem(value: q, child: Text('×$q'))],
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 14),
                        child: Text('×$_qty', style: const TextStyle(fontWeight: FontWeight.w700)),
                      ),
                    ),
                    GestureDetector(
                      onTap: () => _send(shown),
                      child: Container(
                        height: 44,
                        padding: const EdgeInsets.symmetric(horizontal: 22),
                        alignment: Alignment.center,
                        decoration: const BoxDecoration(
                          gradient: YoloColors.goldGradient,
                          borderRadius: BorderRadius.horizontal(right: Radius.circular(22)),
                        ),
                        child: const Text('Send', style: TextStyle(color: YoloColors.onGold, fontWeight: FontWeight.w800, fontSize: 15)),
                      ),
                    ),
                  ]),
                ),
              ]),
            ]);
          },
        ),
      ]),
    ).animate().slideY(begin: 0.1, end: 0, duration: 250.ms, curve: Curves.easeOut);
  }
}

class _GiftTile extends StatelessWidget {
  const _GiftTile({required this.gift, required this.selected, required this.onTap});
  final Gift gift;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      label: '${gift.name}, ${gift.price} coins',
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: 200.ms,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            color: selected ? YoloColors.gold.withValues(alpha: 0.10) : Colors.white.withValues(alpha: 0.04),
            border: Border.all(color: selected ? YoloColors.gold : Colors.white.withValues(alpha: 0.06), width: 1.5),
          ),
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            AnimatedScale(
              scale: selected ? 1.15 : 1,
              duration: 250.ms,
              curve: Curves.easeOutBack,
              child: Icon(gift.icon, size: 34, color: gift.tint),
            ),
            const SizedBox(height: 4),
            Text(gift.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
            Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              const CoinIcon(size: 10),
              const SizedBox(width: 3),
              Flexible(
                child: Text(formatCoins(gift.price),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 11, color: YoloColors.gold, fontWeight: FontWeight.w700)),
              ),
            ]),
          ]),
        ),
      ),
    );
  }
}
