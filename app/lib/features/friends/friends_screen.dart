import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../core/theme.dart';
import '../../data/demo_content.dart';
import '../../data/models.dart';
import '../../data/social_providers.dart';
import '../../widgets/common.dart';
import '../../widgets/page_kit.dart';

Widget _onlineDot(int id) => onlineIds.contains(id)
    ? Positioned(
        right: 2,
        bottom: 2,
        child: Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(color: YoloColors.online, shape: BoxShape.circle, border: Border.all(color: YoloColors.bg, width: 2)),
        ),
      )
    : const SizedBox.shrink();

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
    final followers = ref.watch(followersProvider);
    final blocked = ref.watch(blockedProvider);
    final requests = ref.watch(incomingRequestsProvider);
    final friends = ref.watch(friendsProvider);
    final visible = demoAllUsers.where((u) => !blocked.contains(u.id));
    final lists = [
      friends,
      visible.where((u) => following.contains(u.id)).toList(),
      visible.where((u) => followers.contains(u.id)).toList(),
    ];
    final list = lists[_tab];

    return YoloPage(
      title: 'Friends',
      actions: [
        IconButton(tooltip: 'Add friends', icon: const Icon(Icons.person_add_alt_1_rounded), onPressed: () => context.push('/friends/add')),
      ],
      bottom: Column(children: [
        if (requests.isNotEmpty)
          GlassCard(
            margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            onTap: () => context.push('/friends/requests'),
            child: Row(children: [
              const TintIcon(Icons.person_add_rounded, color: Color(0xFF7DD3FC), size: 36),
              const SizedBox(width: 10),
              Expanded(child: Text('Friend requests (${requests.length})', style: const TextStyle(fontWeight: FontWeight.w700))),
              const Icon(Icons.chevron_right_rounded),
            ]),
          ),
        YoloTabs(
          tabs: ['Friends ${lists[0].length}', 'Following ${lists[1].length}', 'Followers ${lists[2].length}'],
          index: _tab,
          onChanged: (i) => setState(() => _tab = i),
        ),
      ]),
      body: list.isEmpty
          ? const EmptyState(icon: Icons.people_alt_rounded, title: 'Nobody here yet', subtitle: 'Add friends by name or Yolo ID.')
          : ListView.builder(
              itemCount: list.length,
              itemBuilder: (_, i) {
                final u = list[i];
                return ListTile(
                  onTap: () => context.push('/user', extra: u),
                  leading: Stack(children: [YoloAvatar(user: u, size: 50), _onlineDot(u.id)]),
                  title: Text(u.name, style: const TextStyle(fontWeight: FontWeight.w700)),
                  subtitle: Text(presence(u.id), style: TextStyle(fontSize: 12, color: onlineIds.contains(u.id) ? YoloColors.online : YoloColors.textMuted)),
                  trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                    IconButton(tooltip: 'Message ${u.name}', icon: const Icon(Icons.chat_bubble_outline_rounded, color: YoloColors.gold), onPressed: () => context.push('/chat', extra: u)),
                    if (_tab == 2 && !following.contains(u.id))
                      TextButton(onPressed: () => ref.read(followingProvider.notifier).add(u.id), child: const Text('Follow back')),
                  ]),
                ).entrance(i);
              },
            ),
    );
  }
}

class FriendRequestsScreen extends ConsumerWidget {
  const FriendRequestsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final incoming = ref.watch(incomingRequestsProvider).map(userById).toList();
    final sent = ref.watch(sentRequestsProvider).map(userById).toList();
    return YoloPage(
      title: 'Friend requests',
      body: ListView(children: [
        const SectionTitle('Received'),
        if (incoming.isEmpty) const Padding(padding: EdgeInsets.symmetric(horizontal: 20), child: Text('No new requests', style: TextStyle(color: YoloColors.textMuted))),
        for (final u in incoming)
          ListTile(
            leading: YoloAvatar(user: u, size: 48),
            title: Text(u.name, style: const TextStyle(fontWeight: FontWeight.w700)),
            subtitle: Text('ID ${u.id}', style: const TextStyle(fontSize: 12, color: YoloColors.textMuted)),
            trailing: Row(mainAxisSize: MainAxisSize.min, children: [
              IconButton(
                tooltip: 'Decline ${u.name}',
                icon: const Icon(Icons.close_rounded, color: YoloColors.textMuted),
                onPressed: () => ref.read(incomingRequestsProvider.notifier).remove(u.id),
              ),
              SizedBox(
                width: 92,
                child: GoldButton(label: 'Accept', height: 36, onPressed: () {
                  acceptRequest(ref, u.id);
                  showYoloToast(context, 'You and ${u.name} are now friends');
                }),
              ),
            ]),
          ),
        const SectionTitle('Sent'),
        if (sent.isEmpty) const Padding(padding: EdgeInsets.symmetric(horizontal: 20), child: Text('No pending requests', style: TextStyle(color: YoloColors.textMuted))),
        for (final u in sent)
          ListTile(
            leading: YoloAvatar(user: u, size: 48),
            title: Text(u.name, style: const TextStyle(fontWeight: FontWeight.w700)),
            trailing: TextButton(onPressed: () => ref.read(sentRequestsProvider.notifier).remove(u.id), child: const Text('Cancel')),
          ),
      ]),
    );
  }
}

class AddFriendsScreen extends ConsumerStatefulWidget {
  const AddFriendsScreen({super.key});

  @override
  ConsumerState<AddFriendsScreen> createState() => _AddFriendsScreenState();
}

class _AddFriendsScreenState extends ConsumerState<AddFriendsScreen> {
  String _q = '';

  @override
  Widget build(BuildContext context) {
    final friends = ref.watch(friendsProvider).map((u) => u.id).toSet();
    final sent = ref.watch(sentRequestsProvider);
    final blocked = ref.watch(blockedProvider);
    final q = _q.trim().toLowerCase();
    final isId = RegExp(r'^\d+$').hasMatch(q);
    final results = demoAllUsers
        .where((u) => !blocked.contains(u.id))
        .where((u) => q.isEmpty || (isId ? '${u.id}' == q : u.name.toLowerCase().contains(q)))
        .toList();

    return YoloPage(
      title: 'Add friends',
      body: ListView(children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
          child: TextField(
            autofocus: true,
            onChanged: (v) => setState(() => _q = v),
            decoration: InputDecoration(
              hintText: 'Search by name or Yolo ID',
              prefixIcon: const Icon(Icons.search_rounded),
              filled: true,
              fillColor: Colors.white.withValues(alpha: 0.07),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(24), borderSide: BorderSide.none),
            ),
          ),
        ),
        SectionTitle(q.isEmpty ? 'People you may know' : (isId ? 'Yolo ID match' : 'Results')),
        if (results.isEmpty) const Padding(padding: EdgeInsets.all(20), child: Text('No user found', style: TextStyle(color: YoloColors.textMuted))),
        for (final u in results)
          ListTile(
            onTap: () => context.push('/user', extra: u),
            leading: YoloAvatar(user: u, size: 48),
            title: Text(u.name, style: const TextStyle(fontWeight: FontWeight.w700)),
            subtitle: Text('ID ${u.id}', style: const TextStyle(fontSize: 12, color: YoloColors.textMuted)),
            trailing: friends.contains(u.id)
                ? const Text('Friends', style: TextStyle(color: YoloColors.online, fontWeight: FontWeight.w700))
                : sent.contains(u.id)
                    ? const Text('Requested', style: TextStyle(color: YoloColors.textMuted))
                    : SizedBox(
                        width: 84,
                        child: GoldButton(label: 'Add', height: 34, onPressed: () {
                          ref.read(sentRequestsProvider.notifier).add(u.id);
                          ref.read(followingProvider.notifier).add(u.id);
                          showYoloToast(context, 'Friend request sent to ${u.name}');
                        }),
                      ),
          ),
      ]),
    );
  }
}

class CreateGroupScreen extends ConsumerStatefulWidget {
  const CreateGroupScreen({super.key});

  @override
  ConsumerState<CreateGroupScreen> createState() => _CreateGroupScreenState();
}

class _CreateGroupScreenState extends ConsumerState<CreateGroupScreen> {
  final _name = TextEditingController();
  final _picked = <int>{};

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final friends = ref.watch(friendsProvider);
    final ok = _name.text.trim().length >= 2 && _picked.length >= 2;
    return YoloPage(
      title: 'New group',
      body: ListView(padding: const EdgeInsets.only(bottom: 40), children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 0),
          child: TextField(controller: _name, maxLength: 30, onChanged: (_) => setState(() {}), decoration: const InputDecoration(labelText: 'Group name')),
        ),
        SectionTitle('Choose at least 2 friends (${_picked.length})'),
        if (friends.isEmpty) const Padding(padding: EdgeInsets.all(20), child: Text('Add some friends first', style: TextStyle(color: YoloColors.textMuted))),
        for (final u in friends)
          CheckboxListTile(
            value: _picked.contains(u.id),
            onChanged: (v) => setState(() => v! ? _picked.add(u.id) : _picked.remove(u.id)),
            secondary: YoloAvatar(user: u, size: 44),
            title: Text(u.name, style: const TextStyle(fontWeight: FontWeight.w700)),
            activeColor: YoloColors.gold,
            checkColor: YoloColors.onGold,
          ),
        Padding(
          padding: const EdgeInsets.all(20),
          child: Opacity(
            opacity: ok ? 1 : 0.5,
            child: GoldButton(
              label: 'Create group',
              onPressed: ok
                  ? () {
                      final g = ref.read(groupsProvider.notifier).create(_name.text.trim(), _picked.toList());
                      context.pushReplacement('/chat', extra: g);
                    }
                  : null,
            ),
          ),
        ),
      ]),
    );
  }
}

class BlockedUsersScreen extends ConsumerWidget {
  const BlockedUsersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final blocked = ref.watch(blockedProvider).map(userById).toList();
    return YoloPage(
      title: 'Blocked users',
      body: blocked.isEmpty
          ? const EmptyState(icon: Icons.block_rounded, title: 'No blocked users', subtitle: 'People you block cannot message you or join your room.')
          : ListView(children: [
              for (final YoloUser u in blocked)
                ListTile(
                  leading: YoloAvatar(user: u, size: 46),
                  title: Text(u.name, style: const TextStyle(fontWeight: FontWeight.w700)),
                  trailing: OutlinedButton(onPressed: () => ref.read(blockedProvider.notifier).remove(u.id), child: const Text('Unblock')),
                ),
            ]),
    );
  }
}
