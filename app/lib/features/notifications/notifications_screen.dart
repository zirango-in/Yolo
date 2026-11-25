import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../core/theme.dart';
import '../../data/cp_providers.dart';
import '../../data/events_providers.dart';
import '../../data/notifications_providers.dart';
import '../../data/providers.dart';
import '../../data/social_providers.dart';
import '../../widgets/common.dart';
import '../../widgets/page_kit.dart';
import '../room/room_sheets.dart';

class NotificationsScreen extends ConsumerStatefulWidget {
  const NotificationsScreen({super.key});

  @override
  ConsumerState<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends ConsumerState<NotificationsScreen> {
  static const _tabs = ['All', 'Friends', 'Messages', 'Gifts', 'Invites', 'Family', 'Events', 'Rewards', 'System'];
  static const _filters = <List<String>>[
    [],
    ['friend', 'cp'],
    ['message'],
    ['gift'],
    ['room', 'game'],
    ['family'],
    ['event'],
    ['reward'],
    ['system'],
  ];
  int _tab = 0;

  static const _style = {
    'friend': (Icons.person_add_rounded, Color(0xFF7DD3FC)),
    'cp': (Icons.favorite_rounded, Color(0xFFF472B6)),
    'message': (Icons.chat_rounded, Color(0xFF86EFAC)),
    'gift': (Icons.card_giftcard_rounded, Color(0xFFF5C451)),
    'room': (Icons.mic_rounded, Color(0xFFF9A8D4)),
    'game': (Icons.sports_esports_rounded, Color(0xFFC4B5FD)),
    'family': (Icons.groups_rounded, Color(0xFFA78BFA)),
    'system': (Icons.campaign_rounded, Color(0xFFD9D0F2)),
    'event': (Icons.celebration_rounded, Color(0xFFFDA4AF)),
    'reward': (Icons.redeem_rounded, Color(0xFFFDE68A)),
  };

  NotificationsController get _ctrl => ref.read(notificationsProvider.notifier);

  Future<void> _action(AppNotification n) async {
    _ctrl.markRead(n.id);
    switch (n.type) {
      case 'friend':
        acceptRequest(ref, n.ref);
        _ctrl.markDone(n.id);
        showYoloToast(context, 'You are now friends with ${userById(n.ref).name}');
      case 'cp':
        final req = ref.read(cpProvider).requests.where((r) => r.incoming && r.user.id == n.ref).firstOrNull;
        if (req == null) {
          context.push('/cp');
        } else {
          final err = ref.read(cpProvider.notifier).accept(req.id);
          if (err.isEmpty) _ctrl.markDone(n.id);
          showYoloToast(context, err.isEmpty ? 'You are now ${relationType(req.type).name} with ${req.user.name}!' : err);
        }
      case 'message':
        context.push('/chat', extra: userById(n.ref));
      case 'gift':
        ref.read(chatProvider('u:${n.ref}').notifier).send('Thank you for the gift!');
        _ctrl.markDone(n.id);
        showYoloToast(context, 'Thank-you sent to ${userById(n.ref).name}');
      case 'room':
        final rooms = await ref.read(roomsProvider('popular').future);
        final room = rooms.where((r) => r.id == n.ref).firstOrNull;
        if (room != null && mounted) await openRoom(context, ref, room);
      case 'game':
        showYoloToast(context, 'Games are coming soon');
      case 'family':
        context.push('/family');
      case 'event':
        final e = allEvents.where((e) => e.id == n.ref).firstOrNull;
        if (e != null) context.push('/events/detail', extra: e);
      case 'reward':
        if (_ctrl.claim(n)) showYoloToast(context, '+${n.ref} coins');
      default:
        showDialog<void>(
          context: context,
          builder: (c) => AlertDialog(
            backgroundColor: YoloColors.sheet,
            title: Text(n.title),
            content: Text(n.body),
            actions: [TextButton(onPressed: () => Navigator.pop(c), child: const Text('OK'))],
          ),
        );
    }
  }

  String? _actionLabel(AppNotification n) => switch (n.type) {
        'friend' => n.done ? null : 'Accept',
        'cp' => n.done ? null : (ref.read(cpProvider).requests.any((r) => r.incoming && r.user.id == n.ref) ? 'Accept' : 'View'),
        'message' => 'Reply',
        'gift' => n.done ? null : 'Say thanks',
        'room' => 'Join',
        'game' => 'Soon',
        'family' => 'Open',
        'event' => 'View',
        'reward' => n.done ? null : 'Claim',
        _ => 'Read',
      };

  String? _doneLabel(AppNotification n) => switch (n.type) {
        'friend' || 'cp' => 'Accepted',
        'gift' => 'Thanked',
        'reward' => 'Claimed',
        _ => null,
      };

  @override
  Widget build(BuildContext context) {
    final all = ref.watch(notificationsProvider);
    final list = all.where((n) => _filters[_tab].isEmpty || _filters[_tab].contains(n.type)).toList();
    final unread = all.where((n) => !n.read).length;

    return YoloPage(
      title: unread > 0 ? 'Notifications ($unread)' : 'Notifications',
      actions: [
        PopupMenuButton<String>(
          tooltip: 'Notification options',
          onSelected: (v) {
            if (v == 'read') _ctrl.markAllRead();
            if (v == 'clear') _ctrl.clearAll();
            if (v == 'settings') context.push('/settings/notifications');
          },
          itemBuilder: (_) => const [
            PopupMenuItem(value: 'read', child: Text('Mark all as read')),
            PopupMenuItem(value: 'clear', child: Text('Clear all')),
            PopupMenuItem(value: 'settings', child: Text('Notification settings')),
          ],
        ),
      ],
      bottom: YoloTabs(tabs: _tabs, index: _tab, onChanged: (i) => setState(() => _tab = i)),
      body: list.isEmpty
          ? const EmptyState(icon: Icons.notifications_none_rounded, title: 'All caught up', subtitle: 'New notifications will show up here.')
          : ListView.builder(
              itemCount: list.length,
              itemBuilder: (_, k) {
                final n = list[k];
                final (icon, color) = _style[n.type]!;
                final label = _actionLabel(n);
                return Dismissible(
                  key: ValueKey('n${n.id}'),
                  direction: DismissDirection.endToStart,
                  background: Container(
                    color: const Color(0xFFDC2626),
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.only(right: 24),
                    child: const Icon(Icons.delete_rounded, color: Colors.white),
                  ),
                  onDismissed: (_) {
                    _ctrl.delete(n.id);
                    showYoloToast(context, 'Notification deleted');
                  },
                  child: ListTile(
                    onTap: () => _ctrl.markRead(n.id),
                    tileColor: n.read ? null : YoloColors.gold.withValues(alpha: 0.05),
                    leading: Badge(
                      isLabelVisible: !n.read,
                      smallSize: 10,
                      backgroundColor: const Color(0xFFEF4444),
                      child: n.ref > 2000 && n.ref < 3000 && n.type != 'reward'
                          ? YoloAvatar(user: userById(n.ref), size: 46)
                          : TintIcon(icon, color: color, size: 46),
                    ),
                    title: Text(n.title, style: TextStyle(fontWeight: n.read ? FontWeight.w600 : FontWeight.w800)),
                    subtitle: Text('${n.body} · ${n.time}', maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(color: YoloColors.textMuted)),
                    trailing: label == null
                        ? Text(_doneLabel(n) ?? '', style: const TextStyle(color: YoloColors.online, fontWeight: FontWeight.w700))
                        : Row(mainAxisSize: MainAxisSize.min, children: [
                            if (n.type == 'friend')
                              IconButton(
                                tooltip: 'Decline',
                                icon: const Icon(Icons.close_rounded, color: YoloColors.textMuted),
                                onPressed: () {
                                  ref.read(incomingRequestsProvider.notifier).remove(n.ref);
                                  _ctrl.delete(n.id);
                                },
                              ),
                            SizedBox(
                              width: 84,
                              child: Opacity(
                                opacity: n.type == 'game' ? 0.5 : 1,
                                child: GoldButton(label: label, height: 34, onPressed: () => _action(n)),
                              ),
                            ),
                          ]),
                  ),
                ).entrance(k);
              },
            ),
    );
  }
}
