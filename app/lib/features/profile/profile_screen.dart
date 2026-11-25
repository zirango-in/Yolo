import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../core/theme.dart';
import '../../data/providers.dart';
import '../../widgets/common.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final me = ref.watch(sessionProvider);
    if (me == null) return const SizedBox.shrink();

    Widget stat(String value, String label) => Expanded(
          child: Column(children: [
            Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
            const SizedBox(height: 2),
            Text(label, style: const TextStyle(fontSize: 12, color: YoloColors.textMuted)),
          ]),
        );

    final menu = [
      (Icons.account_balance_wallet_rounded, 'Wallet', formatCoins(me.coins), const Color(0xFFF5C451), '/shop'),
      (Icons.storefront_rounded, 'Shop', '', const Color(0xFFF9A8D4), '/shop'),
      (Icons.people_alt_rounded, 'Friends', '', const Color(0xFF7DD3FC), '/friends'),
      (Icons.groups_rounded, 'My Family', '', const Color(0xFFC4B5FD), '/family'),
      (Icons.photo_library_rounded, 'Moments', '', const Color(0xFF86EFAC), '/moments'),
      (Icons.celebration_rounded, 'Events', '', const Color(0xFFFDA4AF), '/events'),
      (Icons.settings_rounded, 'Settings', '', YoloColors.textSoft, '/settings'),
    ];

    return ListView(
      padding: EdgeInsets.only(bottom: 120 + MediaQuery.paddingOf(context).bottom),
      physics: const BouncingScrollPhysics(),
      children: [
        Stack(clipBehavior: Clip.none, alignment: Alignment.topCenter, children: [
          Container(
            height: 210,
            decoration: const BoxDecoration(
              gradient: LinearGradient(colors: [Color(0xFF5B21B6), Color(0xFF9D174D)], begin: Alignment.topLeft, end: Alignment.bottomRight),
            ),
          ),
          Positioned(
            top: 140,
            child: YoloAvatar(user: me, size: 116, goldFrame: true)
                .animate()
                .scale(begin: const Offset(0.8, 0.8), duration: 500.ms, curve: Curves.easeOutBack),
          ),
        ]),
        const SizedBox(height: 56),
        Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          Text(me.name, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
          const SizedBox(width: 8),
          if (me.vipLevel > 0) Badge2('VIP ${me.vipLevel}', bg: YoloColors.gold, fg: YoloColors.onGold),
        ]),
        const SizedBox(height: 6),
        Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          Text('ID ${me.id}', style: const TextStyle(fontSize: 12, color: YoloColors.textMuted)),
          const SizedBox(width: 8),
          Badge2('${me.gender == 'female' ? '♀' : '♂'} ${me.age}', bg: const Color(0x2EEC4899), fg: const Color(0xFFF9A8D4)),
          const SizedBox(width: 8),
          Badge2('Lv ${me.level}', bg: const Color(0x338B5CF6), fg: const Color(0xFFC4B5FD)),
        ]),
        const SizedBox(height: 8),
        Text(me.bio, textAlign: TextAlign.center, style: const TextStyle(fontSize: 13, color: YoloColors.textSoft)),
        Container(
          margin: const EdgeInsets.fromLTRB(20, 18, 20, 0),
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(color: YoloColors.surface, borderRadius: BorderRadius.circular(18)),
          child: Row(children: [
            stat('${me.following}', 'Following'),
            stat(compactCount(me.followers), 'Followers'),
            stat('${me.friends}', 'Friends'),
          ]),
        ),
        Container(
          margin: const EdgeInsets.fromLTRB(20, 14, 20, 0),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            gradient: const LinearGradient(colors: [Color(0xFF2A1A05), Color(0xFF4A3410)]),
            border: Border.all(color: YoloColors.gold.withValues(alpha: 0.45)),
          ),
          child: const Row(children: [
            Icon(Icons.workspace_premium_rounded, color: YoloColors.gold, size: 34),
            SizedBox(width: 12),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('VIP Center', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: Color(0xFFFDE7A8))),
                Text('Frames, entry effects and exclusive gifts', style: TextStyle(fontSize: 12, color: Color(0xFFE9D8A6))),
              ]),
            ),
            Icon(Icons.chevron_right_rounded, color: YoloColors.gold),
          ]),
        ).animate(onPlay: (c) => c.repeat()).shimmer(delay: 2.seconds, duration: 1500.ms, color: const Color(0x33FFE9A8)),
        Container(
          margin: const EdgeInsets.fromLTRB(20, 14, 20, 0),
          decoration: BoxDecoration(color: YoloColors.surface, borderRadius: BorderRadius.circular(18)),
          clipBehavior: Clip.antiAlias,
          child: Column(children: [
            for (final (icon, label, value, color, route) in menu)
              ListTile(
                leading: Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(color: color.withValues(alpha: 0.18), borderRadius: BorderRadius.circular(11)),
                  child: Icon(icon, size: 18, color: color),
                ),
                title: Text(label, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                  if (value.isNotEmpty) Text(value, style: const TextStyle(color: YoloColors.gold, fontWeight: FontWeight.w700)),
                  const Icon(Icons.chevron_right_rounded, color: YoloColors.textMuted),
                ]),
                onTap: () => context.push(route),
              ),
          ]),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
          child: TextButton(
            onPressed: () {
              ref.read(sessionProvider.notifier).logout();
              context.go('/login');
            },
            child: const Text('Log out', style: TextStyle(color: YoloColors.textMuted)),
          ),
        ),
      ],
    );
  }
}
