import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../core/theme.dart';
import '../../data/family_providers.dart';
import '../../data/providers.dart';
import '../../data/wallet_providers.dart';
import '../../widgets/common.dart';
import '../../widgets/page_kit.dart';
import '../room/room_sheets.dart';

/// Wallet: balance, diamonds exchange, recharge packages, links.
class WalletScreen extends ConsumerWidget {
  const WalletScreen({super.key});

  void _buy(BuildContext context, WidgetRef ref, RechargePackage p) {
    final first = ref.read(walletProvider).firstRecharge;
    showRoomSheet<void>(
      context,
      (c) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 22, 20, 16),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const CoinIcon(size: 48),
          const SizedBox(height: 10),
          Text('${formatCoins(p.coins + p.bonus + (first ? p.coins : 0))} coins', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: YoloColors.gold)),
          if (first) const Text('First recharge: double coins!', style: TextStyle(color: Color(0xFF86EFAC), fontWeight: FontWeight.w700)),
          const SizedBox(height: 6),
          Text('Pay ${p.price} with Google Play', style: const TextStyle(color: YoloColors.textSoft)),
          const SizedBox(height: 8),
          const Text('Demo mode: no real payment is taken.', style: TextStyle(fontSize: 11, color: YoloColors.textMuted)),
          const SizedBox(height: 16),
          GoldButton(
            label: 'Pay ${p.price}',
            onPressed: () {
              Navigator.pop(c);
              final order = ref.read(walletProvider.notifier).recharge(p);
              showYoloToast(context, 'Payment successful · order ${order.orderId}');
            },
          ),
        ]),
      ),
    );
  }

  void _exchange(BuildContext context, WidgetRef ref) {
    final diamonds = ref.read(walletProvider).diamonds;
    showRoomSheet<void>(
      context,
      (c) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Exchange diamonds', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
          Text('You have ${formatCoins(diamonds)} diamonds · $diamondsPerCoin diamonds = 1 coin', style: const TextStyle(color: YoloColors.textMuted)),
          const SizedBox(height: 14),
          for (final d in [1000, 5000, diamonds])
            if (d > 0 && d <= diamonds)
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.diamond_rounded, color: Color(0xFF7DD3FC)),
                title: Text(d == diamonds ? 'All (${formatCoins(d)})' : formatCoins(d)),
                trailing: Text('→ ${formatCoins(d ~/ diamondsPerCoin)} coins', style: const TextStyle(color: YoloColors.gold, fontWeight: FontWeight.w800)),
                onTap: () {
                  Navigator.pop(c);
                  final got = ref.read(walletProvider.notifier).exchange(d);
                  showYoloToast(context, '+$got coins');
                },
              ),
        ]),
      ),
    );
  }

  void _giftCard(BuildContext context, WidgetRef ref) {
    final ctrl = TextEditingController();
    showDialog<void>(
      context: context,
      builder: (c) => AlertDialog(
        backgroundColor: YoloColors.sheet,
        title: const Text('Redeem gift card'),
        content: TextField(key: const Key('gift-card'), controller: ctrl, textCapitalization: TextCapitalization.characters, decoration: const InputDecoration(hintText: 'Enter code')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c), child: const Text('Cancel')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: YoloColors.gold, foregroundColor: YoloColors.onGold),
            onPressed: () {
              Navigator.pop(c);
              showYoloToast(context, ref.read(walletProvider.notifier).redeem(ctrl.text));
            },
            child: const Text('Redeem'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final coins = ref.watch(sessionProvider)?.coins ?? 0;
    final w = ref.watch(walletProvider);
    final fam = ref.watch(familyProvider);

    Widget link(IconData icon, String label, Color color, VoidCallback onTap, {String value = ''}) => ListTile(
          leading: TintIcon(icon, color: color, size: 36),
          title: Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
          trailing: Row(mainAxisSize: MainAxisSize.min, children: [
            if (value.isNotEmpty) Text(value, style: const TextStyle(color: YoloColors.gold, fontWeight: FontWeight.w700)),
            const Icon(Icons.chevron_right_rounded, color: YoloColors.textMuted),
          ]),
          onTap: onTap,
        );

    return YoloPage(
      title: 'Wallet',
      body: ListView(padding: const EdgeInsets.fromLTRB(16, 4, 16, 40), children: [
        GlassCard(
          padding: const EdgeInsets.all(20),
          gradient: const LinearGradient(colors: [Color(0xFF4A3410), Color(0xFF2A1A05)], begin: Alignment.topLeft, end: Alignment.bottomRight),
          border: YoloColors.gold.withValues(alpha: 0.5),
          child: Row(children: [
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('Coins', style: TextStyle(color: Color(0xFFE9D8A6))),
                const SizedBox(height: 4),
                Row(children: [
                  const CoinIcon(size: 26),
                  const SizedBox(width: 8),
                  Flexible(
                    child: TweenAnimationBuilder<int>(
                      tween: IntTween(begin: 0, end: coins),
                      duration: 700.ms,
                      builder: (_, v, _) => Text(formatCoins(v), style: const TextStyle(fontSize: 30, fontWeight: FontWeight.w900, color: YoloColors.gold)),
                    ),
                  ),
                ]),
              ]),
            ),
            Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
              const Text('Diamonds', style: TextStyle(color: Color(0xFFE9D8A6))),
              Row(children: [
                const Icon(Icons.diamond_rounded, color: Color(0xFF7DD3FC), size: 18),
                Text(' ${formatCoins(w.diamonds)}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
              ]),
              TextButton(onPressed: () => _exchange(context, ref), child: const Text('Exchange', style: TextStyle(color: YoloColors.gold))),
            ]),
          ]),
        ),
        if (w.firstRecharge)
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: GlassCard(
              padding: const EdgeInsets.all(12),
              gradient: const LinearGradient(colors: [Color(0xFF14532D), Color(0xFF065F46)]),
              child: const Row(children: [
                Icon(Icons.celebration_rounded, color: Color(0xFF86EFAC)),
                SizedBox(width: 10),
                Expanded(child: Text('First recharge bonus: get DOUBLE coins on any package!', style: TextStyle(fontWeight: FontWeight.w700))),
              ]),
            ).animate(onPlay: (c) => c.repeat()).shimmer(delay: 2.seconds, duration: 1200.ms),
          ),
        const SectionTitle('Recharge'),
        GridView.count(
          crossAxisCount: 3,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 10,
          crossAxisSpacing: 10,
          childAspectRatio: 0.85,
          children: [
            for (final p in rechargePackages)
              GlassCard(
                padding: const EdgeInsets.all(8),
                border: p.popular ? YoloColors.gold : null,
                onTap: () => _buy(context, ref, p),
                child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                  if (p.popular) const Badge2('HOT', bg: Color(0xFFEF4444), fg: Colors.white),
                  const SizedBox(height: 4),
                  const CoinIcon(size: 26),
                  const SizedBox(height: 4),
                  Text(formatCoins(p.coins), style: const TextStyle(fontWeight: FontWeight.w900, color: YoloColors.gold)),
                  if (p.bonus > 0) Text('+${formatCoins(p.bonus)}', style: const TextStyle(fontSize: 11, color: Color(0xFF86EFAC))),
                  const SizedBox(height: 4),
                  Text(p.price, style: const TextStyle(fontWeight: FontWeight.w700)),
                ]),
              ),
          ],
        ),
        const SectionTitle('More'),
        GlassCard(
          padding: EdgeInsets.zero,
          child: Column(children: [
            link(Icons.card_giftcard_rounded, 'Rewards center', const Color(0xFFF9A8D4), () => context.push('/rewards')),
            link(Icons.calendar_month_rounded, 'Monthly pack', const Color(0xFF86EFAC), () => context.push('/rewards'),
                value: w.monthlyDaysLeft > 0 ? '${w.monthlyDaysLeft} days left' : ''),
            link(Icons.receipt_long_rounded, 'Transactions', const Color(0xFF7DD3FC), () => context.push('/wallet/transactions')),
            link(Icons.shopping_bag_rounded, 'Purchase history', const Color(0xFFC4B5FD), () => context.push('/wallet/purchases')),
            link(Icons.redeem_rounded, 'Redeem gift card', const Color(0xFFFDBA74), () => _giftCard(context, ref)),
            link(Icons.storefront_rounded, 'Shop', const Color(0xFFF5C451), () => context.push('/shop')),
            link(Icons.workspace_premium_rounded, 'VIP membership', const Color(0xFFFDE68A), () => showYoloToast(context, 'VIP Center arrives in Step 10')),
            link(Icons.groups_rounded, 'Family coins', const Color(0xFFA78BFA), () => context.push('/family'),
                value: fam.familyId != null ? '${fam.familyCoins} FC' : ''),
          ]),
        ),
      ]),
    );
  }
}

/// All coin transactions (income / spent).
class TransactionsScreen extends ConsumerStatefulWidget {
  const TransactionsScreen({super.key});

  @override
  ConsumerState<TransactionsScreen> createState() => _TransactionsScreenState();
}

class _TransactionsScreenState extends ConsumerState<TransactionsScreen> {
  int _tab = 0;

  @override
  Widget build(BuildContext context) {
    final all = ref.watch(ledgerProvider);
    final list = switch (_tab) {
      1 => all.where((t) => t.amount > 0).toList(),
      2 => all.where((t) => t.amount < 0).toList(),
      _ => all,
    };
    return YoloPage(
      title: 'Transactions',
      bottom: YoloTabs(tabs: const ['All', 'Income', 'Spent'], index: _tab, onChanged: (i) => setState(() => _tab = i)),
      body: list.isEmpty
          ? const EmptyState(icon: Icons.receipt_long_rounded, title: 'No transactions')
          : ListView.separated(
              itemCount: list.length,
              separatorBuilder: (_, _) => const Divider(height: 1, indent: 72, color: Color(0x11FFFFFF)),
              itemBuilder: (_, i) {
                final t = list[i];
                final plus = t.amount > 0;
                return ListTile(
                  leading: TintIcon(plus ? Icons.south_west_rounded : Icons.north_east_rounded, color: plus ? const Color(0xFF86EFAC) : const Color(0xFFFCA5A5), size: 40),
                  title: Text(t.note, style: const TextStyle(fontWeight: FontWeight.w600)),
                  subtitle: Text(t.time, style: const TextStyle(fontSize: 12, color: YoloColors.textMuted)),
                  trailing: Text('${plus ? '+' : ''}${formatCoins(t.amount)}',
                      style: TextStyle(fontWeight: FontWeight.w800, color: plus ? const Color(0xFF86EFAC) : const Color(0xFFFCA5A5))),
                );
              },
            ),
    );
  }
}

/// Recharge / pack orders.
class PurchaseHistoryScreen extends ConsumerWidget {
  const PurchaseHistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final orders = ref.watch(walletProvider).orders;
    return YoloPage(
      title: 'Purchase history',
      body: orders.isEmpty
          ? const EmptyState(icon: Icons.shopping_bag_rounded, title: 'No purchases yet', subtitle: 'Your recharges and packs will show here.')
          : ListView(children: [
              for (final o in orders)
                ListTile(
                  leading: const TintIcon(Icons.shopping_bag_rounded, color: Color(0xFFC4B5FD), size: 40),
                  title: Text(o.pack.id == 'monthly' ? 'Monthly pack' : '${formatCoins(o.pack.coins + o.pack.bonus)} coins${o.firstBonus ? ' ×2' : ''}',
                      style: const TextStyle(fontWeight: FontWeight.w700)),
                  subtitle: Text('Order ${o.orderId} · ${o.time}', style: const TextStyle(fontSize: 12, color: YoloColors.textMuted)),
                  trailing: Column(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.end, children: [
                    Text(o.pack.price, style: const TextStyle(fontWeight: FontWeight.w800)),
                    const Text('Paid', style: TextStyle(fontSize: 11, color: YoloColors.online)),
                  ]),
                ),
            ]),
    );
  }
}

/// Rewards center: daily check-in, monthly pack, daily tasks, invite, event rewards.
class RewardsScreen extends ConsumerWidget {
  const RewardsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final w = ref.watch(walletProvider);
    final ctrl = ref.read(walletProvider.notifier);
    final me = ref.watch(sessionProvider)!;

    return YoloPage(
      title: 'Rewards',
      body: ListView(padding: const EdgeInsets.fromLTRB(16, 4, 16, 40), children: [
        // Daily check-in
        GlassCard(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              const Expanded(child: Text('Daily check-in', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800))),
              Text('${w.checkInDays}/7 days', style: const TextStyle(color: YoloColors.textMuted)),
            ]),
            const SizedBox(height: 12),
            Row(children: [
              for (var d = 0; d < 7; d++)
                Expanded(
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 2),
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      color: d < w.checkInDays ? YoloColors.gold.withValues(alpha: 0.2) : Colors.white.withValues(alpha: 0.05),
                      border: Border.all(color: d == w.checkInDays && !w.checkedInToday ? YoloColors.gold : Colors.transparent),
                    ),
                    child: Column(children: [
                      Text('D${d + 1}', style: const TextStyle(fontSize: 10, color: YoloColors.textMuted)),
                      Icon(d < w.checkInDays ? Icons.check_circle_rounded : (d == 6 ? Icons.redeem_rounded : Icons.toll_rounded),
                          size: 18, color: d < w.checkInDays ? YoloColors.online : YoloColors.gold),
                      Text('${checkInRewards[d]}', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700)),
                    ]),
                  ),
                ),
            ]),
            const SizedBox(height: 12),
            Opacity(
              opacity: w.checkedInToday ? 0.5 : 1,
              child: GoldButton(
                label: w.checkedInToday ? 'Checked in today' : 'Check in',
                height: 46,
                onPressed: w.checkedInToday
                    ? null
                    : () {
                        final got = ctrl.checkIn();
                        showYoloToast(context, '+$got coins');
                      },
              ),
            ),
          ]),
        ),
        const SizedBox(height: 12),
        // Monthly pack
        GlassCard(
          gradient: const LinearGradient(colors: [Color(0xFF14532D), Color(0xFF0F766E)]),
          child: Row(children: [
            const Icon(Icons.calendar_month_rounded, color: Color(0xFF86EFAC), size: 36),
            const SizedBox(width: 12),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('Monthly pack', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
                Text(w.monthlyDaysLeft > 0 ? '$monthlyPackDaily coins every day · ${w.monthlyDaysLeft} days left' : '$monthlyPackDaily coins every day for 30 days',
                    style: const TextStyle(fontSize: 12, color: YoloColors.textSoft)),
              ]),
            ),
            SizedBox(
              width: 100,
              child: w.monthlyDaysLeft <= 0
                  ? GoldButton(label: monthlyPackPrice, height: 38, onPressed: () {
                      ctrl.buyMonthly();
                      showYoloToast(context, 'Monthly pack active! Claim your coins daily.');
                    })
                  : Opacity(
                      opacity: w.monthlyClaimedToday ? 0.5 : 1,
                      child: GoldButton(label: w.monthlyClaimedToday ? 'Claimed' : 'Claim', height: 38, onPressed: w.monthlyClaimedToday ? null : () {
                        ctrl.claimMonthly();
                        showYoloToast(context, '+$monthlyPackDaily coins');
                      }),
                    ),
            ),
          ]),
        ),
        const SectionTitle('Daily tasks'),
        for (final (i, t) in dailyTasks.indexed)
          GlassCard(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(14),
            child: Row(children: [
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(t.name, style: const TextStyle(fontWeight: FontWeight.w700)),
                  const SizedBox(height: 6),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(value: t.progress / t.target, minHeight: 6, color: YoloColors.gold, backgroundColor: const Color(0x22FFFFFF)),
                  ),
                ]),
              ),
              const SizedBox(width: 12),
              if (w.claimedTasks.contains(i))
                const Text('Claimed', style: TextStyle(color: YoloColors.online, fontWeight: FontWeight.w700))
              else if (t.done)
                SizedBox(width: 92, child: GoldButton(label: '+${t.reward}', height: 36, onPressed: () => ctrl.claimTask(i)))
              else
                Text('${t.progress}/${t.target}', style: const TextStyle(color: YoloColors.textMuted)),
            ]),
          ),
        const SectionTitle('Invite friends'),
        GlassCard(
          gradient: const LinearGradient(colors: [Color(0xFF4C1D95), Color(0xFF9D174D)]),
          onTap: () => context.push('/rewards/invite'),
          child: Row(children: [
            const Icon(Icons.group_add_rounded, color: YoloColors.gold, size: 34),
            const SizedBox(width: 12),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('Get 500 coins per friend', style: TextStyle(fontWeight: FontWeight.w800)),
                Text('Your code: ${inviteCodeFor(me.id)}', style: const TextStyle(fontSize: 12, color: YoloColors.textSoft)),
              ]),
            ),
            const Icon(Icons.chevron_right_rounded),
          ]),
        ),
        const SectionTitle('Event rewards'),
        for (final (i, (name, coins)) in eventRewards.indexed)
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const TintIcon(Icons.emoji_events_rounded, color: Color(0xFFFDE68A), size: 40),
            title: Text(name, style: const TextStyle(fontWeight: FontWeight.w600)),
            trailing: w.claimedEvents.contains(i)
                ? const Text('Claimed', style: TextStyle(color: YoloColors.online, fontWeight: FontWeight.w700))
                : SizedBox(width: 92, child: GoldButton(label: '+$coins', height: 36, onPressed: () => ctrl.claimEvent(i))),
          ),
      ]),
    );
  }
}

/// Invite friends: code, share, invited list.
class InviteScreen extends ConsumerWidget {
  const InviteScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final me = ref.watch(sessionProvider)!;
    final w = ref.watch(walletProvider);
    final code = inviteCodeFor(me.id);
    return YoloPage(
      title: 'Invite friends',
      body: ListView(padding: const EdgeInsets.all(20), children: [
        const Icon(Icons.group_add_rounded, size: 72, color: YoloColors.gold).animate().scale(curve: Curves.easeOutBack),
        const SizedBox(height: 12),
        const Text('Invite friends, earn coins', textAlign: TextAlign.center, style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
        const SizedBox(height: 6),
        const Text('You get 500 coins and your friend gets 200 coins when they sign up with your code.',
            textAlign: TextAlign.center, style: TextStyle(color: YoloColors.textSoft)),
        const SizedBox(height: 20),
        GlassCard(
          border: YoloColors.gold.withValues(alpha: 0.5),
          child: Row(children: [
            Expanded(child: Text(code, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900, letterSpacing: 2, color: YoloColors.gold))),
            IconButton(
              tooltip: 'Copy code',
              icon: const Icon(Icons.copy_rounded),
              onPressed: () {
                Clipboard.setData(ClipboardData(text: code));
                showYoloToast(context, 'Invite code copied');
              },
            ),
          ]),
        ),
        const SizedBox(height: 12),
        GoldButton(
          label: 'Share invite link',
          icon: Icons.share_rounded,
          onPressed: () {
            Clipboard.setData(ClipboardData(text: 'Join me on Yolo! https://yolo.app/invite/$code'));
            showYoloToast(context, 'Invite link copied — paste it anywhere');
          },
        ),
        SectionTitle('Friends who joined (${w.invited.length})'),
        for (final name in w.invited)
          ListTile(
            leading: CircleAvatar(backgroundColor: YoloColors.surface, child: Text(name[0])),
            title: Text(name),
            trailing: const Text('+500', style: TextStyle(color: YoloColors.gold, fontWeight: FontWeight.w800)),
          ),
      ]),
    );
  }
}
