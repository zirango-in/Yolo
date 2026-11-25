import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../core/theme.dart';
import '../../data/providers.dart';
import '../../data/repository.dart';
import '../../data/vip_providers.dart';
import '../../widgets/common.dart';
import '../../widgets/page_kit.dart';

/// VIP Center: my status, tier browser with privileges, VIP gifts, ring, buy / renew / upgrade.
class VipCenterScreen extends ConsumerStatefulWidget {
  const VipCenterScreen({super.key});

  @override
  ConsumerState<VipCenterScreen> createState() => _VipCenterScreenState();
}

class _VipCenterScreenState extends ConsumerState<VipCenterScreen> {
  late int _view = (ref.read(sessionProvider)?.vipLevel ?? 0).clamp(1, 7);

  void _confirm(VipTier t, int current, VipState v) {
    final isUpgrade = current > 0 && t.level > current && v.daysLeft > 0;
    final credit = isUpgrade ? (tierOf(current).monthlyCoins * v.daysLeft / 30).round() : 0;
    showDialog<void>(
      context: context,
      builder: (c) => AlertDialog(
        backgroundColor: YoloColors.sheet,
        title: Text('${t.level == current ? 'Renew' : (isUpgrade ? 'Upgrade to' : 'Buy')} VIP ${t.level} ${t.name}'),
        content: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('30 days · ${formatCoins(t.monthlyCoins)} coins'),
          if (credit > 0) Text('Credit for unused days: -${formatCoins(credit)}', style: const TextStyle(color: Color(0xFF86EFAC))),
          const SizedBox(height: 6),
          Text('You pay ${formatCoins(t.monthlyCoins - credit)} coins', style: const TextStyle(fontWeight: FontWeight.w800, color: YoloColors.gold)),
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c), child: const Text('Cancel')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: YoloColors.gold, foregroundColor: YoloColors.onGold),
            onPressed: () {
              Navigator.pop(c);
              showYoloToast(context, ref.read(vipProvider.notifier).purchase(t.level));
            },
            child: const Text('Confirm'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final me = ref.watch(sessionProvider)!;
    final v = ref.watch(vipProvider);
    final current = v.daysLeft > 0 ? me.vipLevel : 0;
    final t = tierOf(_view);
    final vipGifts = demoGiftCatalog.where((g) => g.category == 'vip').toList();

    return YoloPage(
      title: 'VIP Center',
      actions: [
        IconButton(tooltip: 'Manage subscription', icon: const Icon(Icons.manage_accounts_rounded), onPressed: () => context.push('/vip/manage')),
        IconButton(tooltip: 'VIP history', icon: const Icon(Icons.history_rounded), onPressed: () => context.push('/vip/history')),
      ],
      body: ListView(padding: const EdgeInsets.fromLTRB(16, 4, 16, 40), children: [
        // My status
        GlassCard(
          gradient: LinearGradient(colors: current > 0 ? tierOf(current).colors : const [Color(0xFF1F2937), Color(0xFF374151)]),
          child: Row(children: [
            Icon(current > 0 ? tierOf(current).icon : Icons.lock_rounded, size: 42, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(current > 0 ? 'VIP $current · ${tierOf(current).name}' : 'Not a VIP yet', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
                Text(current > 0 ? '${v.daysLeft} days left · auto-renew ${v.autoRenew ? 'on' : 'off'}' : 'Unlock exclusive privileges',
                    style: const TextStyle(fontSize: 12, color: Color(0xFFF1F5F9))),
              ]),
            ),
            if (current > 0)
              SizedBox(
                width: 100,
                child: Opacity(
                  opacity: v.dailyClaimed ? 0.5 : 1,
                  child: GoldButton(
                    label: v.dailyClaimed ? 'Claimed' : '+${formatCoins(tierOf(current).dailyCoins)}',
                    height: 38,
                    onPressed: v.dailyClaimed
                        ? null
                        : () {
                            final got = ref.read(vipProvider.notifier).claimDaily();
                            showYoloToast(context, '+$got VIP daily coins');
                          },
                  ),
                ),
              ),
          ]),
        ),
        const SizedBox(height: 14),
        // Tier selector
        SizedBox(
          height: 86,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: vipTiers.length,
            separatorBuilder: (_, _) => const SizedBox(width: 10),
            itemBuilder: (_, i) {
              final tier = vipTiers[i];
              final sel = tier.level == _view;
              return Semantics(
                button: true,
                selected: sel,
                label: 'VIP ${tier.level}',
                excludeSemantics: true,
                child: GestureDetector(
                  onTap: () => setState(() => _view = tier.level),
                  child: AnimatedContainer(
                    duration: 200.ms,
                    width: 74,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      gradient: LinearGradient(colors: tier.colors, begin: Alignment.topLeft, end: Alignment.bottomRight),
                      border: Border.all(color: sel ? Colors.white : Colors.transparent, width: 2.5),
                      boxShadow: sel ? [BoxShadow(color: tier.colors.last.withValues(alpha: 0.6), blurRadius: 16)] : null,
                    ),
                    child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                      Icon(tier.icon, color: Colors.white),
                      Text('VIP ${tier.level}', style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 13)),
                      Text(tier.name, style: const TextStyle(fontSize: 10)),
                    ]),
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 14),
        // Selected tier card
        GlassCard(
          border: t.colors.last.withValues(alpha: 0.6),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Icon(t.icon, color: t.colors.last, size: 30),
              const SizedBox(width: 8),
              Expanded(child: Text('VIP ${t.level} · ${t.name}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900))),
              Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                Row(children: [const CoinIcon(size: 14), Text(' ${formatCoins(t.monthlyCoins)}', style: const TextStyle(fontWeight: FontWeight.w800, color: YoloColors.gold))]),
                const Text('per 30 days', style: TextStyle(fontSize: 11, color: YoloColors.textMuted)),
              ]),
            ]),
            const SizedBox(height: 4),
            Text('${formatCoins(t.dailyCoins)} free coins every day', style: const TextStyle(color: Color(0xFF86EFAC), fontSize: 12)),
            const SizedBox(height: 14),
            const Text('Privileges', style: TextStyle(fontWeight: FontWeight.w800)),
            const SizedBox(height: 10),
            GridView.count(
              crossAxisCount: 3,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 10,
              childAspectRatio: 1.05,
              children: [
                for (final (name, icon, min) in vipPrivileges)
                  Opacity(
                    opacity: t.level >= min ? 1 : 0.35,
                    child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(shape: BoxShape.circle, color: t.colors.last.withValues(alpha: 0.2)),
                        child: Icon(t.level >= min ? icon : Icons.lock_rounded, color: t.colors.last, size: 22),
                      ),
                      const SizedBox(height: 4),
                      Text(name, textAlign: TextAlign.center, maxLines: 2, style: const TextStyle(fontSize: 11)),
                    ]),
                  ),
              ],
            ),
          ]),
        ).animate(key: ValueKey(_view)).fadeIn(duration: 250.ms).slideX(begin: 0.05, end: 0),
        const SectionTitle('VIP gifts'),
        SizedBox(
          height: 92,
          child: ListView(scrollDirection: Axis.horizontal, children: [
            for (final g in vipGifts)
              Container(
                width: 96,
                margin: const EdgeInsets.only(right: 10),
                decoration: BoxDecoration(color: YoloColors.surface, borderRadius: BorderRadius.circular(16)),
                child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                  Icon(g.icon, color: g.tint, size: 32),
                  Text(g.name, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700)),
                  Text('VIP ${g.vipLevel}+', style: const TextStyle(fontSize: 10, color: YoloColors.gold)),
                ]),
              ),
          ]),
        ),
        const SectionTitle('VIP ring'),
        GlassCard(
          onTap: () => showYoloToast(context, ref.read(vipProvider.notifier).toggleRing()),
          child: Row(children: [
            Container(
              width: 48,
              height: 48,
              decoration: const BoxDecoration(shape: BoxShape.circle, gradient: SweepGradient(colors: [YoloColors.gold, Colors.white, YoloColors.goldDeep, YoloColors.gold])),
              child: const Icon(Icons.radio_button_checked_rounded, color: YoloColors.onGold),
            ).animate(onPlay: (c) => c.repeat()).rotate(duration: 6.seconds),
            const SizedBox(width: 12),
            const Expanded(child: Text('Show a shining VIP ring on your profile (VIP 4+)', style: TextStyle(fontSize: 13))),
            Text(v.ringEquipped ? 'Equipped' : 'Equip', style: TextStyle(color: v.ringEquipped ? YoloColors.online : YoloColors.gold, fontWeight: FontWeight.w800)),
          ]),
        ),
        const SizedBox(height: 20),
        GoldButton(
          label: t.level == current ? 'Renew VIP ${t.level}' : (t.level > current && current > 0 ? 'Upgrade to VIP ${t.level}' : 'Get VIP ${t.level}'),
          icon: Icons.workspace_premium_rounded,
          onPressed: t.level < current ? null : () => _confirm(t, current, v),
        ),
        if (t.level < current)
          const Padding(padding: EdgeInsets.only(top: 8), child: Text('You already have a higher level.', textAlign: TextAlign.center, style: TextStyle(color: YoloColors.textMuted))),
      ]),
    );
  }
}

/// Manage subscription: plan, expiry, auto-renew, cancel.
class VipManageScreen extends ConsumerWidget {
  const VipManageScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final me = ref.watch(sessionProvider)!;
    final v = ref.watch(vipProvider);
    final active = v.daysLeft > 0 && me.vipLevel > 0;
    return YoloPage(
      title: 'Subscription',
      body: ListView(padding: const EdgeInsets.all(16), children: [
        GlassCard(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(active ? 'VIP ${me.vipLevel} · ${tierOf(me.vipLevel).name}' : 'No active VIP', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
            const SizedBox(height: 6),
            Text(active ? 'Expires in ${v.daysLeft} days' : 'Join VIP to unlock privileges', style: const TextStyle(color: YoloColors.textMuted)),
            if (active) Text('Renews for ${formatCoins(tierOf(me.vipLevel).monthlyCoins)} coins', style: const TextStyle(color: YoloColors.textMuted)),
          ]),
        ),
        const SizedBox(height: 12),
        if (active) ...[
          GlassCard(
            padding: EdgeInsets.zero,
            child: SwitchListTile(
              title: const Text('Auto-renew'),
              subtitle: const Text('Renew with coins when it expires', style: TextStyle(fontSize: 12)),
              value: v.autoRenew,
              activeThumbColor: YoloColors.gold,
              onChanged: (x) => ref.read(vipProvider.notifier).setAutoRenew(x),
            ),
          ),
          const SizedBox(height: 12),
          OutlinedButton(
            style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(50), shape: const StadiumBorder(), foregroundColor: const Color(0xFFF87171)),
            onPressed: v.autoRenew
                ? () {
                    ref.read(vipProvider.notifier).cancel();
                    showYoloToast(context, 'Subscription cancelled. VIP stays active for ${v.daysLeft} days.');
                  }
                : null,
            child: Text(v.autoRenew ? 'Cancel subscription' : 'Cancelled — active until expiry'),
          ),
        ],
        const SizedBox(height: 12),
        GoldButton(label: active ? 'Upgrade or renew' : 'Join VIP', onPressed: () => context.push('/vip')),
      ]),
    );
  }
}

class VipHistoryScreen extends ConsumerWidget {
  const VipHistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final h = ref.watch(vipProvider).history;
    return YoloPage(
      title: 'VIP purchase history',
      body: h.isEmpty
          ? const EmptyState(icon: Icons.workspace_premium_rounded, title: 'No VIP purchases yet')
          : ListView(children: [
              for (final p in h)
                ListTile(
                  leading: const TintIcon(Icons.workspace_premium_rounded, color: YoloColors.gold, size: 40),
                  title: Text(p.what, style: const TextStyle(fontWeight: FontWeight.w700)),
                  subtitle: Text(p.time, style: const TextStyle(fontSize: 12, color: YoloColors.textMuted)),
                  trailing: Text('-${formatCoins(p.coins)}', style: const TextStyle(color: Color(0xFFFCA5A5), fontWeight: FontWeight.w800)),
                ),
            ]),
    );
  }
}
