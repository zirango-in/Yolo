import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../core/theme.dart';
import '../../data/settings_providers.dart';
import '../../widgets/page_kit.dart';

Widget _switch(String title, bool value, ValueChanged<bool> onChanged, {String? subtitle}) => SwitchListTile(
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
      subtitle: subtitle == null ? null : Text(subtitle, style: const TextStyle(fontSize: 12, color: YoloColors.textMuted)),
      value: value,
      activeThumbColor: YoloColors.gold,
      onChanged: onChanged,
    );

Widget _card(List<Widget> children) => GlassCard(margin: const EdgeInsets.symmetric(horizontal: 16), padding: EdgeInsets.zero, child: Column(children: children));

class PrivacySettingsScreen extends ConsumerWidget {
  const PrivacySettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(settingsProvider);
    final c = ref.read(settingsProvider.notifier);
    return YoloPage(
      title: 'Privacy',
      body: ListView(padding: const EdgeInsets.only(bottom: 40), children: [
        const SectionTitle('Who can message me'),
        _card([
          for (final (v, label) in [('everyone', 'Everyone'), ('friends', 'Friends only'), ('nobody', 'Nobody')])
            ListTile(
              title: Text(label),
              trailing: s.whoCanMessage == v ? const Icon(Icons.check_circle_rounded, color: YoloColors.gold) : const Icon(Icons.circle_outlined, color: YoloColors.textMuted),
              onTap: () => c.update((x) => x.copyWith(whoCanMessage: v)),
            ),
        ]),
        const SectionTitle('Visibility'),
        _card([
          _switch('Hide my online status', s.hideOnline, (v) => c.update((x) => x.copyWith(hideOnline: v))),
          _switch('Hide profile visitors', s.hideVisitors, (v) => c.update((x) => x.copyWith(hideVisitors: v)), subtitle: 'People will not see that you visited them'),
          _switch('Show my country / location', s.showLocation, (v) => c.update((x) => x.copyWith(showLocation: v))),
          _switch('Hide my gift wall', s.hideGiftWall, (v) => c.update((x) => x.copyWith(hideGiftWall: v))),
        ]),
      ]),
    );
  }
}

class NotificationSettingsScreen extends ConsumerWidget {
  const NotificationSettingsScreen({super.key});

  static const _labels = {
    'messages': 'Private messages',
    'friends': 'Friend requests & follows',
    'gifts': 'Gifts received',
    'rooms': 'Room invitations',
    'family': 'Family updates',
    'events': 'Events & rewards',
    'system': 'System announcements',
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(settingsProvider);
    final c = ref.read(settingsProvider.notifier);
    return YoloPage(
      title: 'Notification settings',
      body: ListView(padding: const EdgeInsets.only(bottom: 40), children: [
        const SectionTitle('Notify me about'),
        _card([for (final e in _labels.entries) _switch(e.value, s.notify[e.key] ?? true, (_) => c.toggleNotify(e.key))]),
        const SectionTitle('Alerts'),
        _card([
          _switch('Sound', s.notifySound, (v) => c.update((x) => x.copyWith(notifySound: v))),
          _switch('Vibrate', s.notifyVibrate, (v) => c.update((x) => x.copyWith(notifyVibrate: v))),
          _switch('Do not disturb', s.doNotDisturb, (v) => c.update((x) => x.copyWith(doNotDisturb: v)), subtitle: 'Silence notifications from 23:00 to 08:00'),
        ]),
      ]),
    );
  }
}

class SoundSettingsScreen extends ConsumerWidget {
  const SoundSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(settingsProvider);
    final c = ref.read(settingsProvider.notifier);
    Widget slider(String label, IconData icon, double v, ValueChanged<double> onChanged) => Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
          child: Row(children: [
            Icon(icon, color: YoloColors.gold),
            const SizedBox(width: 10),
            SizedBox(width: 96, child: Text(label, style: const TextStyle(fontWeight: FontWeight.w600))),
            Expanded(child: Slider(value: v, onChanged: onChanged, activeColor: YoloColors.gold, label: '${(v * 100).round()}%', divisions: 10)),
            SizedBox(width: 40, child: Text('${(v * 100).round()}%', style: const TextStyle(color: YoloColors.textMuted, fontSize: 12))),
          ]),
        );
    return YoloPage(
      title: 'Sound',
      body: ListView(padding: const EdgeInsets.only(bottom: 40), children: [
        const SectionTitle('Volume'),
        GlassCard(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          padding: const EdgeInsets.only(bottom: 8),
          child: Column(children: [
            slider('Voice rooms', Icons.record_voice_over_rounded, s.roomVolume, (v) => c.update((x) => x.copyWith(roomVolume: v))),
            slider('Effects', Icons.music_note_rounded, s.effectsVolume, (v) => c.update((x) => x.copyWith(effectsVolume: v))),
          ]),
        ),
        const SectionTitle('Options'),
        _card([
          _switch('Gift sounds', s.giftSounds, (v) => c.update((x) => x.copyWith(giftSounds: v))),
          _switch('Mic noise suppression', s.noiseSuppression, (v) => c.update((x) => x.copyWith(noiseSuppression: v)), subtitle: 'Reduce background noise when you talk'),
          _switch('Vibration', s.vibration, (v) => c.update((x) => x.copyWith(vibration: v))),
        ]),
      ]),
    );
  }
}

class LanguageSettingsScreen extends ConsumerWidget {
  const LanguageSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(settingsProvider);
    return YoloPage(
      title: 'Language',
      body: ListView(padding: const EdgeInsets.only(bottom: 40), children: [
        const Padding(
          padding: EdgeInsets.fromLTRB(20, 4, 20, 8),
          child: Text('Arabic and Urdu switch the layout to right-to-left. Full translations are added with the language files.',
              style: TextStyle(fontSize: 12, color: YoloColors.textMuted)),
        ),
        _card([
          for (final (code, native, english) in appLanguages)
            ListTile(
              title: Text(native, style: const TextStyle(fontWeight: FontWeight.w700)),
              subtitle: Text(english, style: const TextStyle(fontSize: 12, color: YoloColors.textMuted)),
              trailing: s.language == code ? const Icon(Icons.check_circle_rounded, color: YoloColors.gold) : null,
              onTap: () {
                ref.read(settingsProvider.notifier).update((x) => x.copyWith(language: code));
                showYoloToast(context, 'Language: $english');
              },
            ),
        ]),
      ]),
    );
  }
}

class DisplaySettingsScreen extends ConsumerWidget {
  const DisplaySettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(settingsProvider);
    final c = ref.read(settingsProvider.notifier);
    return YoloPage(
      title: 'Theme & display',
      body: ListView(padding: const EdgeInsets.only(bottom: 40), children: [
        const SectionTitle('Theme'),
        _card([
          const ListTile(
            leading: Icon(Icons.dark_mode_rounded, color: YoloColors.gold),
            title: Text('Royal dark (purple & gold)', style: TextStyle(fontWeight: FontWeight.w700)),
            trailing: Icon(Icons.check_circle_rounded, color: YoloColors.gold),
          ),
          ListTile(
            leading: const Icon(Icons.light_mode_rounded, color: YoloColors.textMuted),
            title: const Text('Light theme'),
            subtitle: const Text('Coming later', style: TextStyle(fontSize: 12, color: YoloColors.textMuted)),
            onTap: () => showYoloToast(context, 'Light theme is coming in a later update'),
          ),
        ]),
        const SectionTitle('Text size'),
        GlassCard(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(children: [
            SegmentedButton<double>(
              showSelectedIcon: false,
              segments: const [
                ButtonSegment(value: 0.9, label: Text('Small')),
                ButtonSegment(value: 1.0, label: Text('Default')),
                ButtonSegment(value: 1.15, label: Text('Large')),
              ],
              selected: {s.textScale},
              onSelectionChanged: (v) => c.update((x) => x.copyWith(textScale: v.first)),
            ),
            const SizedBox(height: 12),
            const Text('Preview: Welcome to Yolo!', style: TextStyle(fontSize: 16)),
          ]),
        ),
        const SectionTitle('Motion'),
        _card([_switch('Reduce motion', s.reduceMotion, (v) => c.update((x) => x.copyWith(reduceMotion: v)), subtitle: 'Fewer screen transition animations')]),
      ]),
    );
  }
}

/// App permissions with live status and a button to request / open settings.
class PermissionsScreen extends StatefulWidget {
  const PermissionsScreen({super.key});

  @override
  State<PermissionsScreen> createState() => _PermissionsScreenState();
}

class _PermissionsScreenState extends State<PermissionsScreen> {
  static final _items = [
    (Permission.microphone, 'Microphone', 'Talk in voice rooms and send voice messages', Icons.mic_rounded),
    (Permission.camera, 'Camera', 'Take profile photos and share pictures', Icons.photo_camera_rounded),
    (Permission.photos, 'Photos & videos', 'Pick photos for your profile, chats and moments', Icons.photo_library_rounded),
    (Permission.locationWhenInUse, 'Location', 'Show your country and find people nearby', Icons.location_on_rounded),
    (Permission.notification, 'Notifications', 'Get messages and invites when the app is closed', Icons.notifications_rounded),
  ];
  final _status = <Permission, String>{};

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  Future<void> _refresh() async {
    for (final (p, _, _, _) in _items) {
      try {
        final s = await p.status;
        _status[p] = s.isGranted ? 'Allowed' : (s.isPermanentlyDenied ? 'Blocked' : 'Not allowed');
      } catch (_) {
        _status[p] = 'Not available';
      }
    }
    if (mounted) setState(() {});
  }

  Future<void> _request(Permission p) async {
    try {
      final s = await p.request();
      if (s.isPermanentlyDenied) await openAppSettings();
    } catch (_) {
      if (mounted) showYoloToast(context, 'Permissions can be changed on a real device');
    }
    await _refresh();
  }

  @override
  Widget build(BuildContext context) {
    return YoloPage(
      title: 'Permissions',
      body: ListView(padding: const EdgeInsets.only(bottom: 40), children: [
        const SizedBox(height: 4),
        _card([
          for (final (p, name, why, icon) in _items)
            ListTile(
              leading: TintIcon(icon, color: YoloColors.gold, size: 40),
              title: Text(name, style: const TextStyle(fontWeight: FontWeight.w700)),
              subtitle: Text(why, style: const TextStyle(fontSize: 12, color: YoloColors.textMuted)),
              trailing: _status[p] == 'Allowed'
                  ? const Text('Allowed', style: TextStyle(color: YoloColors.online, fontWeight: FontWeight.w700))
                  : TextButton(onPressed: () => _request(p), child: Text(_status[p] == 'Blocked' ? 'Settings' : 'Allow', style: const TextStyle(color: YoloColors.gold))),
            ),
        ]),
        Padding(
          padding: const EdgeInsets.all(20),
          child: OutlinedButton.icon(
            onPressed: () async {
              try {
                await openAppSettings();
              } catch (_) {}
            },
            icon: const Icon(Icons.settings_applications_rounded),
            label: const Text('Open phone settings'),
          ),
        ),
      ]),
    );
  }
}

/// Cache & storage: breakdown and clear cache.
class StorageScreen extends StatefulWidget {
  const StorageScreen({super.key});

  @override
  State<StorageScreen> createState() => _StorageScreenState();
}

class _StorageScreenState extends State<StorageScreen> {
  double _images = 48.6, _gifts = 31.2, _voice = 12.4;
  static const _app = 86.0;

  @override
  Widget build(BuildContext context) {
    final cache = _images + _gifts + _voice;
    Widget row(String label, double mb, Color color) => ListTile(
          leading: Container(width: 14, height: 14, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
          title: Text(label),
          trailing: Text('${mb.toStringAsFixed(1)} MB', style: const TextStyle(color: YoloColors.textMuted)),
        );
    return YoloPage(
      title: 'Cache & storage',
      body: ListView(padding: const EdgeInsets.only(bottom: 40), children: [
        GlassCard(
          margin: const EdgeInsets.all(16),
          child: Column(children: [
            Text('${(cache + _app).toStringAsFixed(1)} MB', style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: YoloColors.gold)),
            const Text('Total used by Yolo', style: TextStyle(color: YoloColors.textMuted)),
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: Row(children: [
                Expanded(flex: _app.round(), child: Container(height: 10, color: const Color(0xFF8B5CF6))),
                if (cache > 0) Expanded(flex: cache.round().clamp(1, 1000), child: Container(height: 10, color: YoloColors.gold)),
              ]),
            ),
          ]),
        ),
        _card([
          row('App', _app, const Color(0xFF8B5CF6)),
          row('Image cache', _images, YoloColors.gold),
          row('Gift animations', _gifts, const Color(0xFFF9A8D4)),
          row('Voice messages', _voice, const Color(0xFF7DD3FC)),
        ]),
        Padding(
          padding: const EdgeInsets.all(20),
          child: OutlinedButton.icon(
            style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(50), shape: const StadiumBorder(), foregroundColor: YoloColors.gold),
            onPressed: cache == 0
                ? null
                : () {
                    PaintingBinding.instance.imageCache.clear();
                    setState(() => _images = _gifts = _voice = 0);
                    showYoloToast(context, 'Cache cleared (${cache.toStringAsFixed(1)} MB freed)');
                  },
            icon: const Icon(Icons.cleaning_services_rounded),
            label: Text(cache == 0 ? 'Cache is empty' : 'Clear cache (${cache.toStringAsFixed(1)} MB)'),
          ),
        ),
      ]),
    );
  }
}
