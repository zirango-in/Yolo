import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../core/theme.dart';
import '../../data/demo_content.dart';
import '../../data/social_providers.dart';
import '../../widgets/common.dart';
import '../../widgets/page_kit.dart';

class FriendsScreen extends ConsumerStatefulWidget {
  const FriendsScreen({super.key});

  @override
  ConsumerState<FriendsScreen> createState() => _FriendsScreenState();
}

class _FriendsScreenState extends ConsumerState<FriendsScreen> {
  int _tab = 0;

  @override
  Widget build(BuildContext context) {
    final following = ref.watch(followingProvider);
    // Demo: Zara, Kenji and Mia follow me back; friends = mutual follows.
    const followers = {2001, 2002, 2003};
    final lists = [
      demoAllUsers.where((u) => following.contains(u.id) && followers.contains(u.id)).toList(),
      demoAllUsers.where((u) => following.contains(u.id)).toList(),
      demoAllUsers.where((u) => followers.contains(u.id)).toList(),
    ];
    final list = lists[_tab];

    return YoloPage(
      title: 'Friends',
      actions: [
        IconButton(tooltip: 'Add friends', icon: const Icon(Icons.person_add_alt_1_rounded), onPressed: () => context.push('/discover')),
      ],
      bottom: YoloTabs(
        tabs: ['Friends ${lists[0].length}', 'Following ${lists[1].length}', 'Followers ${lists[2].length}'],
        index: _tab,
        onChanged: (i) => setState(() => _tab = i),
      ),
      body: list.isEmpty
          ? const EmptyState(icon: Icons.people_alt_rounded, title: 'Nobody here yet', subtitle: 'Find people in Discover and follow them.')
          : ListView.builder(
              itemCount: list.length,
              itemBuilder: (_, i) {
                final u = list[i];
                final isFollowing = following.contains(u.id);
                return ListTile(
                  onTap: () => context.push('/user', extra: u),
                  leading: Stack(children: [
                    YoloAvatar(user: u, size: 50),
                    if (i.isEven)
                      Positioned(
                        right: 2,
                        bottom: 2,
                        child: Container(
                          width: 12,
                          height: 12,
                          decoration: BoxDecoration(color: YoloColors.online, shape: BoxShape.circle, border: Border.all(color: YoloColors.bg, width: 2)),
                        ),
                      ),
                  ]),
                  title: Text(u.name, style: const TextStyle(fontWeight: FontWeight.w700)),
                  subtitle: Text(i.isEven ? 'Online' : 'Last seen 2h ago', style: const TextStyle(fontSize: 12, color: YoloColors.textMuted)),
                  trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                    IconButton(tooltip: 'Message', icon: const Icon(Icons.chat_bubble_outline_rounded, color: YoloColors.gold), onPressed: () => context.push('/chat', extra: u)),
                    if (_tab == 2 && !isFollowing)
                      TextButton(onPressed: () => ref.read(followingProvider.notifier).add(u.id), child: const Text('Follow back')),
                  ]),
                ).entrance(i);
              },
            ),
    );
  }
}
