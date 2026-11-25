import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../core/theme.dart';
import '../../data/demo_content.dart';
import '../../data/models.dart';
import '../../data/social_providers.dart';
import '../../widgets/common.dart';
import '../../widgets/page_kit.dart';

/// Inbox tab: system shortcuts + conversations.
class MessagesScreen extends ConsumerWidget {
  const MessagesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final read = ref.watch(readNotificationsProvider);
    final unreadNotes = [for (final (i, n) in demoNotifications.indexed) if (n.unread && !read.contains(i)) i].length;

    Widget shortcut(IconData icon, String label, Color color, String route, {int badge = 0}) => Expanded(
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () => context.push(route),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Column(children: [
                Badge(isLabelVisible: badge > 0, label: Text('$badge'), child: TintIcon(icon, color: color, size: 48)),
                const SizedBox(height: 6),
                Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
              ]),
            ),
          ),
        );

    return SafeArea(
      bottom: false,
      child: ListView(padding: const EdgeInsets.only(bottom: 120), children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 14, 12, 8),
          child: Row(children: [
            const Expanded(child: Text('Messages', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800))),
            IconButton(tooltip: 'Friends', icon: const Icon(Icons.people_alt_rounded), onPressed: () => context.push('/friends')),
          ]),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Row(children: [
            shortcut(Icons.notifications_rounded, 'Notices', const Color(0xFFF5C451), '/notifications', badge: unreadNotes),
            shortcut(Icons.person_add_rounded, 'Requests', const Color(0xFF7DD3FC), '/notifications'),
            shortcut(Icons.people_alt_rounded, 'Friends', const Color(0xFF86EFAC), '/friends'),
            shortcut(Icons.groups_rounded, 'Family', const Color(0xFFC4B5FD), '/family'),
          ]),
        ),
        const SectionTitle('Chats'),
        for (final (i, c) in demoConversations.indexed)
          ListTile(
            onTap: () => context.push('/chat', extra: c.user),
            leading: Stack(children: [
              YoloAvatar(user: c.user, size: 52),
              if (c.online)
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
            title: Text(c.user.name, style: const TextStyle(fontWeight: FontWeight.w700)),
            subtitle: Text(c.last, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: YoloColors.textMuted)),
            trailing: Column(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.end, children: [
              Text(c.time, style: const TextStyle(fontSize: 11, color: YoloColors.textMuted)),
              const SizedBox(height: 4),
              if (c.unread > 0)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                  decoration: BoxDecoration(color: const Color(0xFFEF4444), borderRadius: BorderRadius.circular(10)),
                  child: Text('${c.unread}', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800)),
                ),
            ]),
          ).entrance(i),
      ]),
    );
  }
}

class ChatScreen extends ConsumerStatefulWidget {
  const ChatScreen({super.key, required this.user});
  final YoloUser user;

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final _input = TextEditingController();

  @override
  void dispose() {
    _input.dispose();
    super.dispose();
  }

  void _send() {
    ref.read(chatProvider(widget.user.id).notifier).send(_input.text);
    _input.clear();
  }

  @override
  Widget build(BuildContext context) {
    final messages = ref.watch(chatProvider(widget.user.id));
    return YoloPage(
      title: widget.user.name,
      actions: [
        IconButton(tooltip: 'Profile', icon: const Icon(Icons.person_rounded), onPressed: () => context.push('/user', extra: widget.user)),
      ],
      body: Column(children: [
        Expanded(
          child: ListView.builder(
            reverse: true,
            padding: const EdgeInsets.all(16),
            itemCount: messages.length,
            itemBuilder: (_, i) {
              final m = messages[messages.length - 1 - i];
              return Align(
                alignment: m.mine ? Alignment.centerRight : Alignment.centerLeft,
                child: Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  constraints: const BoxConstraints(maxWidth: 280),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    gradient: m.mine ? YoloColors.goldGradient : null,
                    color: m.mine ? null : YoloColors.surface,
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(18),
                      topRight: const Radius.circular(18),
                      bottomLeft: Radius.circular(m.mine ? 18 : 4),
                      bottomRight: Radius.circular(m.mine ? 4 : 18),
                    ),
                  ),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                    Text(m.text, style: TextStyle(color: m.mine ? YoloColors.onGold : YoloColors.text, fontSize: 14)),
                    const SizedBox(height: 2),
                    Text(m.time, style: TextStyle(fontSize: 10, color: m.mine ? const Color(0x991A1200) : YoloColors.textMuted)),
                  ]),
                ),
              ).entrance(0);
            },
          ),
        ),
        SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 4, 12, 10),
            child: Row(children: [
              IconButton(tooltip: 'Send photo', icon: const Icon(Icons.image_outlined), onPressed: () => showYoloToast(context, 'Photo sharing arrives in Step 5')),
              Expanded(
                child: TextField(
                  controller: _input,
                  onSubmitted: (_) => _send(),
                  textInputAction: TextInputAction.send,
                  decoration: InputDecoration(
                    hintText: 'Message',
                    filled: true,
                    fillColor: Colors.white.withValues(alpha: 0.08),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(24), borderSide: BorderSide.none),
                  ),
                ),
              ),
              IconButton(tooltip: 'Send', icon: const Icon(Icons.send_rounded, color: YoloColors.gold), onPressed: _send),
            ]),
          ),
        ),
      ]),
    );
  }
}
