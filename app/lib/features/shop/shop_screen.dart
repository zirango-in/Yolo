import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../core/theme.dart';
import '../../data/demo_content.dart';
import '../../data/providers.dart';
import '../../data/social_providers.dart';
import '../../widgets/common.dart';
import '../../widgets/page_kit.dart';

class ShopScreen extends ConsumerStatefulWidget {
  const ShopScreen({super.key});

  @override
  ConsumerState<ShopScreen> createState() => _ShopScreenState();
}

class _ShopScreenState extends ConsumerState<ShopScreen> {
  static const _tabs = ['Frames', 'Entry effects', 'Special effects', 'Chat bubbles', 'Room themes', 'Decorations'];
  static const _cats = ['frame', 'entry', 'effect', 'bubble', 'theme', 'decoration'];
  int _tab = 0;

  void _buy(ShopItem item) {
    final owned = ref.read(ownedItemsProvider).contains(item.id);
    if (owned) {
      final equipped = ref.read(equippedItemsProvider.notifier);
      // Only one item per category can be equipped.
      for (final other in demoShopItems.where((s) => s.category == item.category)) {
        equipped.remove(other.id);
      }
      equipped.add(item.id);
      showYoloToast(context, '${item.name} equipped');
      return;
    }
    showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: YoloColors.sheet,
        title: Text('Buy ${item.name}?'),
        content: Row(children: [
          const CoinIcon(),
          const SizedBox(width: 6),
          Text('${formatCoins(item.price)} for ${item.duration}'),
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: YoloColors.gold, foregroundColor: YoloColors.onGold),
            onPressed: () {
              Navigator.pop(context);
              if (ref.read(sessionProvider.notifier).spend(item.price)) {
                ref.read(ownedItemsProvider.notifier).add(item.id);
                showYoloToast(context, 'Purchased! Find it in your backpack.');
              } else {
                showYoloToast(context, 'Not enough coins');
              }
            },
            child: const Text('Buy'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final coins = ref.watch(sessionProvider)?.coins ?? 0;
    final owned = ref.watch(ownedItemsProvider);
    final equipped = ref.watch(equippedItemsProvider);
    final items = demoShopItems.where((s) => s.category == _cats[_tab]).toList();

    return YoloPage(
      title: 'Shop',
      actions: [
        IconButton(tooltip: 'My items', icon: const Icon(Icons.backpack_rounded, color: YoloColors.gold), onPressed: () => context.push('/backpack')),
        Padding(padding: const EdgeInsets.only(right: 4), child: CoinPill(coins: coins)),
      ],
      bottom: YoloTabs(tabs: _tabs, index: _tab, onChanged: (i) => setState(() => _tab = i)),
      body: GridView.builder(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 40),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, mainAxisSpacing: 12, crossAxisSpacing: 12, childAspectRatio: 0.78),
        itemCount: items.length,
        itemBuilder: (_, i) {
          final it = items[i];
          final isOwned = owned.contains(it.id);
          final isEquipped = equipped.contains(it.id);
          return GlassCard(
            padding: const EdgeInsets.all(12),
            border: isEquipped ? YoloColors.gold : null,
            onTap: () => _buy(it),
            child: Column(children: [
              Expanded(
                child: Center(
                  child: Container(
                    width: 84,
                    height: 84,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: SweepGradient(colors: [...it.colors, it.colors.first]),
                      boxShadow: [BoxShadow(color: it.colors.last.withValues(alpha: 0.45), blurRadius: 20)],
                    ),
                    child: Icon(it.icon, size: 38, color: Colors.white),
                  ),
                ),
              ),
              Text(it.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w700)),
              Text(it.duration, style: const TextStyle(fontSize: 11, color: YoloColors.textMuted)),
              const SizedBox(height: 8),
              Container(
                height: 32,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  gradient: isOwned ? null : YoloColors.goldGradient,
                  color: isOwned ? Colors.white.withValues(alpha: 0.08) : null,
                ),
                alignment: Alignment.center,
                child: isOwned
                    ? Text(isEquipped ? 'Equipped' : 'Equip',
                        style: TextStyle(fontWeight: FontWeight.w800, color: isEquipped ? YoloColors.gold : YoloColors.text))
                    : Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                        const CoinIcon(size: 12),
                        const SizedBox(width: 4),
                        Text(formatCoins(it.price), style: const TextStyle(color: YoloColors.onGold, fontWeight: FontWeight.w800)),
                      ]),
              ),
            ]),
          ).entrance(i);
        },
      ),
    );
  }
}
