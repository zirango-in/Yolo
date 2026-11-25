import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../core/theme.dart';
import '../../data/cp_providers.dart';
import '../../data/moments_providers.dart';
import '../../data/profile_providers.dart';
import '../../data/providers.dart';
import '../../data/social_providers.dart';
import '../../widgets/avatar_figure.dart';
import '../../widgets/common.dart';
import '../../widgets/page_kit.dart';

/// My profile (the "Me" tab).
class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final me = ref.watch(sessionProvider);
    final x = ref.watch(profileExtrasProvider);
    final following = ref.watch(followingProvider);
    if (me == null) return const SizedBox.shrink();

    Widget stat(String value, String label) => Expanded(
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () => context.push('/friends'),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Column(children: [
                Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
                const SizedBox(height: 2),
                Text(label, style: const TextStyle(fontSize: 12, color: YoloColors.textMuted)),
              ]),
            ),
          ),
        );

    final menu = [
      (Icons.account_balance_wallet_rounded, 'Wallet', formatCoins(me.coins), const Color(0xFFF5C451), '/wallet'),
      (Icons.redeem_rounded, 'Rewards & check-in', '', const Color(0xFFF9A8D4), '/rewards'),
      (Icons.storefront_rounded, 'Shop', '', const Color(0xFFF9A8D4), '/shop'),
      (Icons.card_giftcard_rounded, 'Gift store', '', const Color(0xFFFDBA74), '/gifts'),
      (Icons.backpack_rounded, 'My items', '', const Color(0xFF86EFAC), '/backpack'),
      (Icons.history_rounded, 'Gift history', '', const Color(0xFF7DD3FC), '/gifts/history'),
      (Icons.groups_rounded, 'My Family', '', const Color(0xFFC4B5FD), '/family'),
      (Icons.celebration_rounded, 'Events', '', const Color(0xFFFDA4AF), '/events'),
      (Icons.manage_accounts_rounded, 'Account', '', const Color(0xFF7DD3FC), '/account'),
      (Icons.settings_rounded, 'Settings', '', YoloColors.textSoft, '/settings'),
    ];
    final myMoments = ref.watch(momentsProvider).where((m) => m.author.id == me.id).take(3).toList();

    return ListView(
      padding: EdgeInsets.only(bottom: 120 + MediaQuery.paddingOf(context).bottom),
      physics: const BouncingScrollPhysics(),
      children: [
        Stack(clipBehavior: Clip.none, alignment: Alignment.topCenter, children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 400),
            height: 210,
            decoration: BoxDecoration(gradient: LinearGradient(colors: ProfileExtras.covers[x.cover], begin: Alignment.topLeft, end: Alignment.bottomRight)),
          ),
          Positioned(
            top: MediaQuery.paddingOf(context).top + 6,
            right: 12,
            child: Row(children: [
              GlassIconButton(icon: Icons.edit_rounded, label: 'Edit profile', onTap: () => context.push('/profile/edit')),
              const SizedBox(width: 8),
              GlassIconButton(icon: Icons.settings_rounded, label: 'Settings', onTap: () => context.push('/settings')),
            ]),
          ),
          Positioned(
            top: 140,
            child: GestureDetector(
              onTap: () => context.push('/profile/edit'),
              child: const MyAvatar(size: 116).animate().scale(begin: const Offset(0.8, 0.8), duration: 500.ms, curve: Curves.easeOutBack),
            ),
          ),
        ]),
        const SizedBox(height: 56),
        Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          Flexible(child: Text(me.name, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800))),
          const SizedBox(width: 8),
          if (me.vipLevel > 0) Badge2('VIP ${me.vipLevel}', bg: YoloColors.gold, fg: YoloColors.onGold),
        ]),
        const SizedBox(height: 6),
        Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          InkWell(
            onTap: () {
              Clipboard.setData(ClipboardData(text: '${me.id}'));
              showYoloToast(context, 'Yolo ID copied');
            },
            child: Row(children: [
              Text('ID ${me.id}', style: const TextStyle(fontSize: 12, color: YoloColors.textMuted)),
              const SizedBox(width: 4),
              const Icon(Icons.copy_rounded, size: 13, color: YoloColors.textMuted),
            ]),
          ),
          const SizedBox(width: 8),
          Badge2('${me.gender == 'female' ? '♀' : '♂'} ${me.age}', bg: const Color(0x2EEC4899), fg: const Color(0xFFF9A8D4)),
          const SizedBox(width: 8),
          GestureDetector(onTap: () => context.push('/profile/levels'), child: Badge2('Lv ${me.level}', bg: const Color(0x338B5CF6), fg: const Color(0xFFC4B5FD))),
        ]),
        const SizedBox(height: 8),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Text(x.bio, textAlign: TextAlign.center, style: const TextStyle(fontSize: 13, color: YoloColors.textSoft)),
        ),
        GlassCard(
          margin: const EdgeInsets.fromLTRB(20, 18, 20, 0),
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Row(children: [
            stat('${following.length}', 'Following'),
            stat(compactCount(me.followers), 'Followers'),
            stat('${me.friends}', 'Friends'),
            stat('${demoAchievements.where((a) => a.done).length}', 'Trophies'),
          ]),
        ),
        // Avatar studio + levels shortcuts
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
          child: Row(children: [
            Expanded(
              child: GlassCard(
                padding: const EdgeInsets.all(12),
                onTap: () => context.push('/profile/avatar'),
                child: Row(children: [
                  AvatarFigure(config: x.avatar, size: 40),
                  const SizedBox(width: 10),
                  const Expanded(child: Text('Avatar studio', style: TextStyle(fontWeight: FontWeight.w700))),
                ]),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: GlassCard(
                padding: const EdgeInsets.all(12),
                onTap: () => context.push('/profile/levels'),
                child: const Row(children: [
                  TintIcon(Icons.trending_up_rounded, color: Color(0xFFC4B5FD)),
                  SizedBox(width: 10),
                  Expanded(child: Text('My levels', style: TextStyle(fontWeight: FontWeight.w700))),
                ]),
              ),
            ),
          ]),
        ),
        GlassCard(
          margin: const EdgeInsets.fromLTRB(20, 12, 20, 0),
          padding: const EdgeInsets.all(16),
          gradient: const LinearGradient(colors: [Color(0xFF2A1A05), Color(0xFF4A3410)]),
          border: YoloColors.gold.withValues(alpha: 0.45),
          onTap: () => context.push('/vip'),
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
        SectionTitle('CP & relationships', action: 'All', onAction: () => context.push('/cp')),
        Builder(builder: (_) {
          final cp = ref.watch(cpProvider);
          final couple = cp.couple;
          return GlassCard(
            margin: const EdgeInsets.symmetric(horizontal: 20),
            padding: const EdgeInsets.all(14),
            gradient: const LinearGradient(colors: [Color(0xFF9D174D), Color(0xFF4C1D95)]),
            onTap: () => couple == null ? context.push('/cp') : context.push('/cp/space', extra: couple),
            child: Row(children: [
              if (couple != null) ...[
                YoloAvatar(user: couple.partner, size: 44, goldFrame: true),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('CP · ${couple.partner.name}', style: const TextStyle(fontWeight: FontWeight.w800)),
                    Text('${couple.days} days · Lv${cpLevel(couple.intimacy)}', style: const TextStyle(fontSize: 12, color: Color(0xFFFCE7F3))),
                  ]),
                ),
              ] else
                const Expanded(
                  child: Row(children: [
                    Icon(Icons.favorite_border_rounded, color: Color(0xFFFBCFE8), size: 32),
                    SizedBox(width: 12),
                    Expanded(child: Text('Find your CP', style: TextStyle(fontWeight: FontWeight.w800))),
                  ]),
                ),
              Text('${cp.relations.length} relationships', style: const TextStyle(fontSize: 12, color: Color(0xFFFCE7F3))),
              const Icon(Icons.chevron_right_rounded),
            ]),
          );
        }),
        SectionTitle('Badges', action: 'All', onAction: () => context.push('/profile/badges')),
        SizedBox(
          height: 64,
          child: ListView(scrollDirection: Axis.horizontal, padding: const EdgeInsets.symmetric(horizontal: 20), children: [
            for (final b in demoBadges.where((b) => b.owned))
              Padding(
                padding: const EdgeInsets.only(right: 10),
                child: Tooltip(
                  message: b.name,
                  child: Container(
                    width: 56,
                    decoration: BoxDecoration(shape: BoxShape.circle, color: b.color.withValues(alpha: 0.18)),
                    child: Icon(b.icon, color: b.color),
                  ),
                ),
              ),
          ]),
        ),
        SectionTitle('Achievements', action: 'All', onAction: () => context.push('/profile/achievements')),
        GlassCard(
          margin: const EdgeInsets.symmetric(horizontal: 20),
          padding: const EdgeInsets.all(14),
          onTap: () => context.push('/profile/achievements'),
          child: Row(children: [
            const Icon(Icons.emoji_events_rounded, color: YoloColors.gold, size: 30),
            const SizedBox(width: 12),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('${demoAchievements.where((a) => a.done).length} of ${demoAchievements.length} completed', style: const TextStyle(fontWeight: FontWeight.w700)),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: demoAchievements.where((a) => a.done).length / demoAchievements.length,
                    minHeight: 6,
                    color: YoloColors.gold,
                    backgroundColor: const Color(0x22FFFFFF),
                  ),
                ),
              ]),
            ),
          ]),
        ),
        SectionTitle('My moments', action: 'New post', onAction: () => context.push('/moments/new')),
        if (myMoments.isEmpty)
          const Padding(padding: EdgeInsets.fromLTRB(20, 0, 20, 8), child: Text('You have not posted yet', style: TextStyle(color: YoloColors.textMuted))),
        for (final m in myMoments)
          GlassCard(
            margin: const EdgeInsets.fromLTRB(20, 0, 20, 10),
            padding: const EdgeInsets.all(12),
            onTap: () => context.push('/moments/post', extra: m),
            child: Row(children: [
              if (m.photo != null) ...[
                Container(width: 54, height: 54, decoration: BoxDecoration(borderRadius: BorderRadius.circular(12), gradient: LinearGradient(colors: m.photo!))),
                const SizedBox(width: 12),
              ],
              Expanded(child: Text(m.text, maxLines: 2, overflow: TextOverflow.ellipsis)),
              const SizedBox(width: 8),
              const Icon(Icons.favorite_rounded, size: 16, color: Color(0xFFF43F5E)),
              Text(' ${m.likes}', style: const TextStyle(fontSize: 12)),
            ]),
          ),
        GlassCard(
          margin: const EdgeInsets.fromLTRB(20, 6, 20, 0),
          padding: EdgeInsets.zero,
          child: Column(children: [
            for (final (icon, label, value, color, route) in menu)
              ListTile(
                leading: TintIcon(icon, color: color, size: 34),
                title: Text(label, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                  if (value.isNotEmpty) Text(value, style: const TextStyle(color: YoloColors.gold, fontWeight: FontWeight.w700)),
                  const Icon(Icons.chevron_right_rounded, color: YoloColors.textMuted),
                ]),
                onTap: () => context.push(route),
              ),
          ]),
        ),
      ],
    );
  }
}
