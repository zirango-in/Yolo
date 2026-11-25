import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../core/theme.dart';
import '../../data/demo_content.dart';
import '../../data/models.dart';
import '../../data/profile_providers.dart';
import '../../data/social_providers.dart';
import '../../widgets/common.dart';
import '../../widgets/page_kit.dart';
import '../gifts/gift_pages.dart';
import '../room/room_sheets.dart';

/// Another user's profile: cover, stats, follow/friend status, badges, gift wall, moments.
class UserProfileScreen extends ConsumerWidget {
  const UserProfileScreen({super.key, required this.user});
  final YoloUser user;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final following = ref.watch(followingProvider);
    final iFollow = following.contains(user.id);
    final theyFollow = ref.watch(followersProvider).contains(user.id);
    final isBlocked = ref.watch(blockedProvider).contains(user.id);
    final relation = iFollow && theyFollow ? 'Friends' : (theyFollow ? 'Follows you' : (iFollow ? 'You follow' : ''));
    final mutual = demoAllUsers.where((u) => u.id != user.id && following.contains(u.id)).take(3).toList();
    final moments = demoMoments.where((m) => m.author.id == user.id).toList();
    final cover = ProfileExtras.covers[user.id % ProfileExtras.covers.length];
    final badges = demoBadges.where((b) => b.owned).take(4 + user.id % 2).toList();
    const gifts = [(Icons.local_florist, 'Rose', 120, Color(0xFFFDA4AF)), (Icons.favorite, 'Heart', 48, Color(0xFFF9A8D4)), (Icons.workspace_premium, 'Crown', 6, Color(0xFFFDE7A8)), (Icons.diamond, 'Diamond', 3, Color(0xFF7DD3FC))];

    return Scaffold(
      body: ListView(padding: EdgeInsets.zero, children: [
        Stack(clipBehavior: Clip.none, alignment: Alignment.topCenter, children: [
          Container(height: 200, decoration: BoxDecoration(gradient: LinearGradient(colors: cover))),
          Positioned(
            top: MediaQuery.paddingOf(context).top + 4,
            left: 8,
            right: 8,
            child: Row(children: [
              GlassIconButton(icon: Icons.arrow_back_ios_new_rounded, label: 'Back', onTap: () => context.pop()),
              const Spacer(),
              PopupMenuButton<String>(
                tooltip: 'More',
                icon: const Icon(Icons.more_horiz_rounded),
                onSelected: (v) {
                  if (v == 'report') {
                    showReportSheet(context, 'user');
                  } else {
                    ref.read(blockedProvider.notifier).toggle(user.id);
                    showYoloToast(context, isBlocked ? '${user.name} unblocked' : '${user.name} blocked');
                  }
                },
                itemBuilder: (_) => [
                  const PopupMenuItem(value: 'report', child: Text('Report')),
                  PopupMenuItem(value: 'block', child: Text(isBlocked ? 'Unblock' : 'Block')),
                ],
              ),
            ]),
          ),
          Positioned(top: 140, child: YoloAvatar(user: user, size: 110, goldFrame: true)),
        ]),
        const SizedBox(height: 58),
        Center(child: Text(user.name, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800))),
        const SizedBox(height: 6),
        Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          Text('ID ${user.id}', style: const TextStyle(color: YoloColors.textMuted, fontSize: 12)),
          const SizedBox(width: 8),
          Badge2('${user.gender == 'female' ? '♀' : '♂'} ${user.age}', bg: const Color(0x2EEC4899), fg: const Color(0xFFF9A8D4)),
          const SizedBox(width: 8),
          Badge2('Lv ${user.level + 12}', bg: const Color(0x338B5CF6), fg: const Color(0xFFC4B5FD)),
          if (relation.isNotEmpty) ...[const SizedBox(width: 8), Badge2(relation, bg: const Color(0x334ADE80), fg: YoloColors.online)],
        ]),
        GlassCard(
          margin: const EdgeInsets.fromLTRB(20, 16, 20, 0),
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Row(children: [
            for (final (v, l) in [('${120 + user.id % 90}', 'Following'), ('${(user.id % 50) / 10 + 1}K', 'Followers'), ('${30 + user.id % 40}', 'Friends')])
              Expanded(
                child: Column(children: [
                  Text(v, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
                  Text(l, style: const TextStyle(fontSize: 12, color: YoloColors.textMuted)),
                ]),
              ),
          ]),
        ),
        if (mutual.isNotEmpty)
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
            child: Row(children: [
              for (final u in mutual) Padding(padding: const EdgeInsets.only(right: 4), child: YoloAvatar(user: u, size: 26)),
              const SizedBox(width: 6),
              Expanded(
                child: Text('Followed by ${mutual.map((u) => u.name).join(', ')}',
                    maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12, color: YoloColors.textSoft)),
              ),
            ]),
          ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
          child: Row(children: [
            Expanded(
              child: iFollow
                  ? OutlinedButton(
                      onPressed: () => ref.read(followingProvider.notifier).toggle(user.id),
                      style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(50), shape: const StadiumBorder()),
                      child: Text(theyFollow ? 'Friends' : 'Following'),
                    )
                  : GoldButton(label: theyFollow ? 'Follow back' : 'Follow', height: 50, onPressed: () => ref.read(followingProvider.notifier).toggle(user.id)),
            ),
            const SizedBox(width: 10),
            IconButton.filledTonal(
              tooltip: 'Send gift',
              onPressed: () => showSendGiftSheet(context, ref, user),
              style: IconButton.styleFrom(minimumSize: const Size(50, 50), foregroundColor: YoloColors.gold),
              icon: const Icon(Icons.card_giftcard_rounded),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => context.push('/chat', extra: user),
                style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(50), shape: const StadiumBorder(), foregroundColor: YoloColors.gold),
                icon: const Icon(Icons.chat_bubble_outline_rounded),
                label: const Text('Message'),
              ),
            ),
          ]),
        ),
        const SectionTitle('Badges'),
        SizedBox(
          height: 56,
          child: ListView(scrollDirection: Axis.horizontal, padding: const EdgeInsets.symmetric(horizontal: 20), children: [
            for (final b in badges)
              Padding(
                padding: const EdgeInsets.only(right: 10),
                child: Tooltip(
                  message: b.name,
                  child: Container(width: 52, decoration: BoxDecoration(shape: BoxShape.circle, color: b.color.withValues(alpha: 0.18)), child: Icon(b.icon, color: b.color)),
                ),
              ),
          ]),
        ),
        const SectionTitle('Gift wall'),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(children: [
            for (final (icon, name, count, color) in gifts)
              Expanded(
                child: Column(children: [
                  Icon(icon, color: color, size: 34),
                  const SizedBox(height: 4),
                  Text(name, style: const TextStyle(fontSize: 12)),
                  Text('×$count', style: const TextStyle(fontSize: 11, color: YoloColors.gold, fontWeight: FontWeight.w700)),
                ]),
              ),
          ]),
        ),
        const SectionTitle('Moments'),
        if (moments.isEmpty)
          const Padding(padding: EdgeInsets.fromLTRB(20, 0, 20, 40), child: Text('No moments yet', style: TextStyle(color: YoloColors.textMuted)))
        else
          for (final m in moments)
            GlassCard(
              margin: const EdgeInsets.fromLTRB(20, 0, 20, 10),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(m.text),
                if (m.photo != null) ...[
                  const SizedBox(height: 8),
                  Container(height: 140, decoration: BoxDecoration(borderRadius: BorderRadius.circular(12), gradient: LinearGradient(colors: m.photo!))),
                ],
                const SizedBox(height: 6),
                Text('${m.time} · ${m.likes} likes · ${m.comments} comments', style: const TextStyle(fontSize: 12, color: YoloColors.textMuted)),
              ]),
            ),
        const SizedBox(height: 40),
      ]),
    );
  }
}
