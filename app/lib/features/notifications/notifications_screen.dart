import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../core/theme.dart';
import '../../data/demo_content.dart';
import '../../data/social_providers.dart';
import '../../widgets/page_kit.dart';

class NotificationsScreen extends ConsumerStatefulWidget {
  const NotificationsScreen({super.key});

  @override
  ConsumerState<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends ConsumerState<NotificationsScreen> {
  static const _tabs = ['All', 'Friends', 'Gifts', 'Invites', 'Family', 'System'];
  static const _filters = <List<String>>[
    [],
    ['friend', 'message'],
    ['gift', 'reward'],
    ['room', 'game'],
    ['family'],
    ['system', 'event'],
  ];
  int _tab = 0;

  static const _style = {
    'friend': (Icons.person_add_rounded, Color(0xFF7DD3FC)),
    'message': (Icons.chat_rounded, Color(0xFF86EFAC)),
    'gift': (Icons.card_giftcard_rounded, Color(0xFFF5C451)),
    'room': (Icons.mic_rounded, Color(0xFFF9A8D4)),
    'game': (Icons.sports_esports_rounded, Color(0xFFC4B5FD)),
    'family': (Icons.groups_rounded, Color(0xFFA78BFA)),
    'system': (Icons.campaign_rounded, Color(0xFFD9D0F2)),
    'event': (Icons.celebration_rounded, Color(0xFFFDA4AF)),
    'reward': (Icons.redeem_rounded, Color(0xFFFDE68A)),
  };

  @override
  Widget build(BuildContext context) {
    final read = ref.watch(readNotificationsProvider);
    final entries = [
      for (final (i, n) in demoNotifications.indexed)
        if (_filters[_tab].isEmpty || _filters[_tab].contains(n.type)) (i, n),
    ];

    return YoloPage(
      title: 'Notifications',
      actions: [
        TextButton(
          onPressed: () => ref.read(readNotificationsProvider.notifier).addAll(List.generate(demoNotifications.length, (i) => i)),
          child: const Text('Read all', style: TextStyle(color: YoloColors.gold)),
        ),
      ],
      bottom: YoloTabs(tabs: _tabs, index: _tab, onChanged: (i) => setState(() => _tab = i)),
      body: entries.isEmpty
          ? const EmptyState(icon: Icons.notifications_none_rounded, title: 'All caught up')
          : ListView.builder(
              itemCount: entries.length,
              itemBuilder: (_, k) {
                final (i, n) = entries[k];
                final unread = n.unread && !read.contains(i);
                final (icon, color) = _style[n.type]!;
                return ListTile(
                  onTap: () => ref.read(readNotificationsProvider.notifier).add(i),
                  tileColor: unread ? YoloColors.gold.withValues(alpha: 0.05) : null,
                  leading: TintIcon(icon, color: color, size: 46),
                  title: Text(n.title, style: TextStyle(fontWeight: unread ? FontWeight.w800 : FontWeight.w600)),
                  subtitle: Text(n.body, style: const TextStyle(color: YoloColors.textMuted)),
                  trailing: Column(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.end, children: [
                    Text(n.time, style: const TextStyle(fontSize: 11, color: YoloColors.textMuted)),
                    if (unread) ...[
                      const SizedBox(height: 6),
                      Container(width: 8, height: 8, decoration: const BoxDecoration(color: Color(0xFFEF4444), shape: BoxShape.circle)),
                    ],
                  ]),
                ).entrance(k);
              },
            ),
    );
  }
}
