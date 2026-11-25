import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../core/theme.dart';
import '../../data/demo_content.dart';
import '../../data/providers.dart';
import '../../data/social_providers.dart';
import '../../widgets/common.dart';
import '../../widgets/page_kit.dart';
import '../room/room_sheets.dart';

class DiscoverScreen extends ConsumerStatefulWidget {
  const DiscoverScreen({super.key});

  @override
  ConsumerState<DiscoverScreen> createState() => _DiscoverScreenState();
}

class _DiscoverScreenState extends ConsumerState<DiscoverScreen> {
  String _q = '';

  @override
  Widget build(BuildContext context) {
    final rooms = ref.watch(roomsProvider('popular')).value ?? const [];
    final following = ref.watch(followingProvider);
    final q = _q.toLowerCase();
    final users = demoAllUsers.where((u) => q.isEmpty || u.name.toLowerCase().contains(q) || '${u.id}'.contains(q)).toList();
    final filteredRooms = rooms.where((r) => q.isEmpty || r.name.toLowerCase().contains(q) || '${r.id}'.contains(q)).toList();
    const topics = ['#Ludo', '#Music', '#Life', '#Family', '#Gaming', '#Poetry', '#Friends'];

    return YoloPage(
      title: 'Discover',
      body: ListView(padding: const EdgeInsets.only(bottom: 40), children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 0),
          child: TextField(
            onChanged: (v) => setState(() => _q = v),
            decoration: InputDecoration(
              hintText: 'Search users, rooms or Yolo ID',
              prefixIcon: const Icon(Icons.search_rounded),
              filled: true,
              fillColor: Colors.white.withValues(alpha: 0.07),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(24), borderSide: BorderSide.none),
            ),
          ),
        ),
        if (q.isEmpty) ...[
          const SectionTitle('Trending topics'),
          SizedBox(
            height: 38,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              itemCount: topics.length,
              separatorBuilder: (_, _) => const SizedBox(width: 8),
              itemBuilder: (_, i) => ActionChip(
                label: Text(topics[i]),
                onPressed: () => context.push('/moments'),
                shape: const StadiumBorder(),
                side: BorderSide(color: YoloColors.gold.withValues(alpha: 0.3)),
                backgroundColor: YoloColors.gold.withValues(alpha: 0.08),
                labelStyle: const TextStyle(color: YoloColors.gold, fontWeight: FontWeight.w700),
              ),
            ),
          ),
        ],
        SectionTitle(q.isEmpty ? 'Popular users' : 'Users'),
        if (users.isEmpty) const Padding(padding: EdgeInsets.all(20), child: Text('No users found', style: TextStyle(color: YoloColors.textMuted))),
        for (final (i, u) in users.indexed)
          ListTile(
            onTap: () => context.push('/user', extra: u),
            leading: YoloAvatar(user: u, size: 48),
            title: Text(u.name, style: const TextStyle(fontWeight: FontWeight.w700)),
            subtitle: Text('ID ${u.id}', style: const TextStyle(color: YoloColors.textMuted, fontSize: 12)),
            trailing: FilledButton.tonal(
              onPressed: () => ref.read(followingProvider.notifier).toggle(u.id),
              style: FilledButton.styleFrom(
                backgroundColor: following.contains(u.id) ? Colors.white.withValues(alpha: 0.08) : YoloColors.gold,
                foregroundColor: following.contains(u.id) ? YoloColors.textSoft : YoloColors.onGold,
              ),
              child: Text(following.contains(u.id) ? 'Following' : 'Follow'),
            ),
          ).entrance(i),
        SectionTitle(q.isEmpty ? 'Popular rooms' : 'Rooms'),
        for (final (i, r) in filteredRooms.indexed)
          ListTile(
            onTap: () => openRoom(context, ref, r),
            leading: Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(borderRadius: BorderRadius.circular(14), gradient: LinearGradient(colors: r.cover)),
              alignment: Alignment.center,
              child: Text(r.name[0], style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
            ),
            title: Text(r.name, style: const TextStyle(fontWeight: FontWeight.w700)),
            subtitle: Text('${r.tag} · ${r.online} online', style: const TextStyle(color: YoloColors.textMuted, fontSize: 12)),
            trailing: const Icon(Icons.chevron_right_rounded, color: YoloColors.textMuted),
          ).entrance(i),
      ]),
    );
  }
}
