import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../core/theme.dart';
import '../../data/account_providers.dart';
import '../../data/providers.dart';
import '../../widgets/common.dart';
import '../../widgets/page_kit.dart';
import '../auth/phone_flow.dart';

/// Account management: Yolo ID, lucky number, nickname, phone, bindings, deletion.
class AccountScreen extends ConsumerWidget {
  const AccountScreen({super.key});

  static const luckyIds = [(8888, 88000), (6666, 66000), (520520, 52000), (1314, 30000), (777777, 25000), (123456, 12000)];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final me = ref.watch(sessionProvider);
    final acc = ref.watch(accountProvider);
    if (me == null) return const SizedBox.shrink();

    Widget row(IconData icon, Color color, String label, String value, VoidCallback onTap, {Widget? trailing}) => ListTile(
          leading: TintIcon(icon, color: color, size: 36),
          title: Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
          trailing: trailing ??
              Row(mainAxisSize: MainAxisSize.min, children: [
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 140),
                  child: Text(value, overflow: TextOverflow.ellipsis, style: const TextStyle(color: YoloColors.textMuted)),
                ),
                const Icon(Icons.chevron_right_rounded, color: YoloColors.textMuted),
              ]),
          onTap: onTap,
        );

    const methods = [
      ('phone', 'Phone', Icons.smartphone_rounded),
      ('email', 'Email', Icons.mail_rounded),
      ('google', 'Google', Icons.g_mobiledata_rounded),
      ('facebook', 'Facebook', Icons.facebook_rounded),
      ('apple', 'Apple', Icons.apple_rounded),
    ];

    return YoloPage(
      title: 'Account',
      body: ListView(padding: const EdgeInsets.only(bottom: 40), children: [
        if (acc.isGuest)
          GlassCard(
            margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            gradient: const LinearGradient(colors: [Color(0xFF7C2D12), Color(0xFFB45309)]),
            child: const Row(children: [
              Icon(Icons.warning_amber_rounded, color: YoloColors.goldLight),
              SizedBox(width: 10),
              Expanded(child: Text('You are using a guest account. Bind a phone or email below so you never lose it.')),
            ]),
          ),
        const SectionTitle('Identity'),
        GlassCard(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          padding: EdgeInsets.zero,
          child: Column(children: [
            row(Icons.badge_rounded, const Color(0xFFF5C451), 'Yolo ID', '${me.id}', () {
              Clipboard.setData(ClipboardData(text: '${me.id}'));
              showYoloToast(context, 'Yolo ID copied');
            }, trailing: Row(mainAxisSize: MainAxisSize.min, children: [
              Text('${me.id}', style: const TextStyle(color: YoloColors.gold, fontWeight: FontWeight.w800)),
              const SizedBox(width: 6),
              const Icon(Icons.copy_rounded, size: 18, color: YoloColors.textMuted),
            ])),
            row(Icons.auto_awesome_rounded, const Color(0xFFF9A8D4), 'Lucky number', acc.luckyId != null ? 'Active' : 'Get a special ID',
                () => _luckySheet(context, ref)),
            row(Icons.edit_rounded, const Color(0xFF7DD3FC), 'Nickname', me.name, () => _nicknameDialog(context, ref, me.name)),
            row(Icons.smartphone_rounded, const Color(0xFF86EFAC), 'Phone number', acc.phone.isEmpty ? 'Not set' : maskPhone(acc.phone),
                () => context.push('/login/phone', extra: PhonePurpose.change)),
          ]),
        ),
        const SectionTitle('Linked accounts'),
        GlassCard(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          padding: EdgeInsets.zero,
          child: Column(children: [
            for (final (key, label, icon) in methods)
              SwitchListTile(
                secondary: Icon(icon, color: YoloColors.textSoft),
                title: Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
                subtitle: Text(acc.bindings.contains(key) ? 'Linked' : 'Not linked',
                    style: TextStyle(fontSize: 12, color: acc.bindings.contains(key) ? YoloColors.online : YoloColors.textMuted)),
                value: acc.bindings.contains(key),
                activeThumbColor: YoloColors.gold,
                onChanged: (on) {
                  if (!on && acc.bindings.length <= 1) {
                    showYoloToast(context, 'Keep at least one login method linked');
                    return;
                  }
                  if (key == 'phone' && on) {
                    context.push('/login/phone', extra: PhonePurpose.change);
                    return;
                  }
                  ref.read(accountProvider.notifier).toggleBinding(key);
                },
              ),
          ]),
        ),
        const SectionTitle('Danger zone'),
        GlassCard(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          padding: EdgeInsets.zero,
          child: ListTile(
            leading: const TintIcon(Icons.delete_forever_rounded, color: Color(0xFFF87171), size: 36),
            title: const Text('Delete account', style: TextStyle(fontWeight: FontWeight.w600, color: Color(0xFFF87171))),
            onTap: () => _deleteDialog(context, ref),
          ),
        ),
      ]),
    );
  }

  void _nicknameDialog(BuildContext context, WidgetRef ref, String current) {
    final ctrl = TextEditingController(text: current);
    String? error;
    showDialog<void>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setState) => AlertDialog(
          backgroundColor: YoloColors.sheet,
          title: const Text('Change nickname'),
          content: TextField(controller: ctrl, maxLength: 20, autofocus: true, decoration: InputDecoration(errorText: error)),
          actions: [
            TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Cancel')),
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: YoloColors.gold, foregroundColor: YoloColors.onGold),
              onPressed: () {
                final v = ctrl.text.trim();
                if (v.length < 2) {
                  setState(() => error = 'At least 2 characters');
                  return;
                }
                ref.read(sessionProvider.notifier).updateProfile(name: v);
                Navigator.pop(dialogContext);
                showYoloToast(context, 'Nickname updated');
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }

  void _luckySheet(BuildContext context, WidgetRef ref) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: YoloColors.sheet,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      builder: (sheetContext) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 28),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Lucky numbers', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
          const Text('A short, special Yolo ID that everyone remembers.', style: TextStyle(color: YoloColors.textMuted)),
          const SizedBox(height: 14),
          GridView.count(
            crossAxisCount: 3,
            shrinkWrap: true,
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            childAspectRatio: 1.1,
            children: [
              for (final (id, price) in luckyIds)
                GlassCard(
                  padding: const EdgeInsets.all(8),
                  border: YoloColors.gold.withValues(alpha: 0.4),
                  onTap: () {
                    if (!ref.read(sessionProvider.notifier).spend(price)) {
                      showYoloToast(context, 'Not enough coins');
                      return;
                    }
                    ref.read(sessionProvider.notifier).changeId(id);
                    ref.read(accountProvider.notifier).setLuckyId(id);
                    Navigator.pop(sheetContext);
                    showYoloToast(context, 'Your new Yolo ID is $id');
                  },
                  child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                    Text('$id', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: YoloColors.gold)),
                    const SizedBox(height: 4),
                    Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                      const CoinIcon(size: 11),
                      const SizedBox(width: 3),
                      Text(formatCoins(price), style: const TextStyle(fontSize: 11)),
                    ]),
                  ]),
                ),
            ],
          ),
        ]),
      ),
    );
  }

  void _deleteDialog(BuildContext context, WidgetRef ref) {
    final ctrl = TextEditingController();
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: YoloColors.sheet,
        title: const Text('Delete account?'),
        content: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Your profile, coins, items and friends will be permanently removed after 7 days. '
              'Log in again within 7 days to cancel.\n\nType DELETE to confirm.'),
          const SizedBox(height: 10),
          TextField(controller: ctrl, decoration: const InputDecoration(hintText: 'DELETE')),
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Cancel')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: const Color(0xFFDC2626)),
            onPressed: () {
              if (ctrl.text.trim() != 'DELETE') return;
              Navigator.pop(dialogContext);
              ref.read(sessionProvider.notifier).logout();
              ref.read(accountProvider.notifier).reset();
              context.go('/welcome');
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}
