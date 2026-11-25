import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../core/theme.dart';
import '../../data/models.dart';
import '../../data/social_providers.dart';
import '../../widgets/common.dart';
import '../../widgets/page_kit.dart';

/// Another user's profile (basic version; full version in Step 3).
class UserProfileScreen extends ConsumerWidget {
  const UserProfileScreen({super.key, required this.user});
  final YoloUser user;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final following = ref.watch(followingProvider).contains(user.id);
    return YoloPage(
      title: '',
      actions: [
        PopupMenuButton<String>(
          tooltip: 'More',
          onSelected: (v) => showYoloToast(context, v == 'block' ? '${user.name} blocked' : 'Report sent. Thank you.'),
          itemBuilder: (_) => const [
            PopupMenuItem(value: 'report', child: Text('Report')),
            PopupMenuItem(value: 'block', child: Text('Block')),
          ],
        ),
      ],
      body: ListView(children: [
        const SizedBox(height: 8),
        Center(child: YoloAvatar(user: user, size: 110, goldFrame: true)),
        const SizedBox(height: 12),
        Center(child: Text(user.name, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800))),
        const SizedBox(height: 6),
        Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          Text('ID ${user.id}', style: const TextStyle(color: YoloColors.textMuted, fontSize: 12)),
          const SizedBox(width: 8),
          Badge2('Lv ${user.level}', bg: const Color(0x338B5CF6), fg: const Color(0xFFC4B5FD)),
        ]),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
          child: Row(children: [
            Expanded(
              child: following
                  ? OutlinedButton(
                      onPressed: () => ref.read(followingProvider.notifier).toggle(user.id),
                      style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(50), shape: const StadiumBorder()),
                      child: const Text('Following'),
                    )
                  : GoldButton(label: 'Follow', height: 50, onPressed: () => ref.read(followingProvider.notifier).toggle(user.id)),
            ),
            const SizedBox(width: 12),
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
        const SectionTitle('Moments'),
        const Padding(padding: EdgeInsets.symmetric(horizontal: 20), child: Text('No moments yet', style: TextStyle(color: YoloColors.textMuted))),
      ]),
    );
  }
}
