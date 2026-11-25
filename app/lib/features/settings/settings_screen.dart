import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../core/theme.dart';
import '../../data/providers.dart';
import '../../widgets/page_kit.dart';

/// Settings home. Detail pages are built in Step 14.
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    const groups = [
      ('Account', [
        (Icons.manage_accounts_rounded, 'Account & security', Color(0xFF7DD3FC)),
        (Icons.lock_rounded, 'Privacy', Color(0xFF86EFAC)),
        (Icons.block_rounded, 'Blocked users', Color(0xFFFCA5A5)),
      ]),
      ('App', [
        (Icons.notifications_rounded, 'Notifications', Color(0xFFF5C451)),
        (Icons.volume_up_rounded, 'Sound', Color(0xFFF9A8D4)),
        (Icons.language_rounded, 'Language', Color(0xFFC4B5FD)),
        (Icons.palette_rounded, 'Theme', Color(0xFFFDBA74)),
        (Icons.verified_user_rounded, 'Permissions', Color(0xFF93C5FD)),
        (Icons.cleaning_services_rounded, 'Clear cache', Color(0xFFD9D0F2)),
      ]),
      ('Support', [
        (Icons.help_rounded, 'Help center', Color(0xFF86EFAC)),
        (Icons.feedback_rounded, 'Feedback', Color(0xFF7DD3FC)),
        (Icons.shield_rounded, 'Safety guidelines', Color(0xFFF5C451)),
        (Icons.description_rounded, 'Terms & privacy policy', Color(0xFFD9D0F2)),
      ]),
    ];

    return YoloPage(
      title: 'Settings',
      body: ListView(padding: const EdgeInsets.only(bottom: 40), children: [
        for (final (title, items) in groups) ...[
          SectionTitle(title),
          GlassCard(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            padding: EdgeInsets.zero,
            child: Column(children: [
              for (final (icon, label, color) in items)
                ListTile(
                  leading: TintIcon(icon, color: color, size: 36),
                  title: Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
                  trailing: const Icon(Icons.chevron_right_rounded, color: YoloColors.textMuted),
                  onTap: () => showYoloToast(context, '$label arrives in Step 14'),
                ),
            ]),
          ),
        ],
        Padding(
          padding: const EdgeInsets.all(20),
          child: OutlinedButton(
            onPressed: () {
              ref.read(sessionProvider.notifier).logout();
              context.go('/login');
            },
            style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(50), shape: const StadiumBorder(), foregroundColor: const Color(0xFFF87171)),
            child: const Text('Log out'),
          ),
        ),
        const Center(child: Text('Yolo v0.1.0', style: TextStyle(color: YoloColors.textMuted, fontSize: 12))),
      ]),
    );
  }
}
