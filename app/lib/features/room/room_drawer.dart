import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../core/theme.dart';
import '../../data/models.dart';
import '../../data/providers.dart';
import '../../data/settings_providers.dart';
import '../../widgets/common.dart';
import '../../widgets/page_kit.dart';
import 'room_sheets.dart';

/// Room menu: a drawer that slides down from the top over the live room.
/// Tap outside or the ••• button again to slide it back up.
Future<void> showRoomTopDrawer(BuildContext context, WidgetRef ref, Room room, {required VoidCallback onExit}) {
  return showGeneralDialog<void>(
    context: context,
    barrierDismissible: true,
    barrierLabel: 'Close room menu',
    barrierColor: Colors.black45,
    transitionDuration: const Duration(milliseconds: 280),
    pageBuilder: (c, _, _) => Align(
      alignment: Alignment.topCenter,
      child: _RoomDrawer(room: room, host: context, onExit: onExit),
    ),
    transitionBuilder: (_, a, _, child) => SlideTransition(
      position: Tween(begin: const Offset(0, -1), end: Offset.zero).animate(CurvedAnimation(parent: a, curve: Curves.easeOutCubic, reverseCurve: Curves.easeInCubic)),
      child: child,
    ),
  );
}

class _RoomDrawer extends ConsumerWidget {
  const _RoomDrawer({required this.room, required this.host, required this.onExit});
  final Room room;

  /// The room screen's context: sheets opened from the drawer live there (the drawer closes first).
  final BuildContext host;
  final VoidCallback onExit;

  static const _modeArt = {
    'normal': (Icons.mic_rounded, [Color(0xFF8B5CF6), Color(0xFF4C1D95)]),
    'acquaint': (Icons.favorite_rounded, [Color(0xFFF472B6), Color(0xFFBE185D)]),
    'auction': (Icons.gavel_rounded, [Color(0xFFFBBF24), Color(0xFFC2410C)]),
    'video': (Icons.smart_display_rounded, [Color(0xFF38BDF8), Color(0xFF1D4ED8)]),
    'game': (Icons.sports_esports_rounded, [Color(0xFF4ADE80), Color(0xFF047857)]),
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final (roomMode, tag, look) = ref.watch(roomProvider(room).select((s) => (s.roomMode, s.tag, s.look)));
    final giftSound = ref.watch(settingsProvider.select((s) => s.giftSounds));
    final ctrl = ref.read(roomProvider(room).notifier);
    final top = MediaQuery.paddingOf(context).top;

    void toast(String m) {
      if (m.isNotEmpty) showYoloToast(context, m);
    }

    // Close the drawer, then run the action on the room screen underneath.
    void run(VoidCallback action) {
      Navigator.pop(context);
      action();
    }

    Widget section(String title) => Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: Text(title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: YoloColors.textSoft)),
        );

    Widget fn(IconData icon, String label, VoidCallback onTap, {Color? color}) => Expanded(
          child: Semantics(
            button: true,
            excludeSemantics: true,
            label: label,
            child: InkWell(
              borderRadius: BorderRadius.circular(14),
              onTap: onTap,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Column(children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white.withValues(alpha: 0.08)),
                    child: Icon(icon, size: 21, color: color ?? Colors.white),
                  ),
                  const SizedBox(height: 5),
                  Text(label, maxLines: 2, textAlign: TextAlign.center, style: const TextStyle(fontSize: 11, height: 1.15)),
                ]),
              ),
            ),
          ),
        );

    return Material(
      color: look.sheet,
      elevation: 3,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(bottom: Radius.circular(24))),
      child: Padding(
        padding: EdgeInsets.only(top: top, bottom: 10),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          // Title row with the same ••• button (tap again to close)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 4, 0),
            child: Row(children: [
              const Expanded(child: Text('Room mode', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: YoloColors.textSoft))),
              IconButton(tooltip: 'Close room menu', icon: const Icon(Icons.more_horiz_rounded), onPressed: () => Navigator.pop(context)),
            ]),
          ),
          // Room modes (scrolls sideways on narrow phones)
          SizedBox(
            height: 92,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 10),
              children: [
                for (final m in RoomState.roomModes)
                  _ModeTile(
                    label: RoomState.roomModeNames[m]!,
                    icon: _modeArt[m]!.$1,
                    colors: _modeArt[m]!.$2,
                    selected: roomMode == m,
                    accent: look.accent,
                    onTap: () => toast(ctrl.setRoomMode(m)),
                  ),
              ],
            ),
          ),
          section('Room category'),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(children: [
              for (final (i, (label, value)) in RoomState.categories.indexed) ...[
                if (i > 0) const SizedBox(width: 8),
                Expanded(
                  child: Semantics(
                    button: true,
                    selected: tag == value,
                    excludeSemantics: true,
                    label: 'Category $label',
                    child: GestureDetector(
                      onTap: () => toast(ctrl.setCategory(value)),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        height: 32,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: tag == value ? look.accent : Colors.white.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(label,
                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: tag == value ? look.onAccent : YoloColors.text)),
                      ),
                    ),
                  ),
                ),
              ],
            ]),
          ),
          section('Function of the room'),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Column(children: [
              Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                fn(Icons.ios_share_rounded, 'Share', () => run(() => showInviteSheet(host, ref, room))),
                fn(giftSound ? Icons.volume_up_rounded : Icons.volume_off_rounded, 'Gift Sound', () {
                  ctrl.toggleGiftSound();
                  toast(giftSound ? 'Gift sounds off' : 'Gift sounds on');
                }, color: giftSound ? Colors.white : YoloColors.textMuted),
                fn(Icons.report_gmailerrorred_rounded, 'Report Room', () => run(() => showReportSheet(host, 'room'))),
                fn(Icons.logout_rounded, 'Exit', () => run(onExit), color: const Color(0xFFF87171)),
              ]),
              Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                fn(Icons.settings_rounded, 'Settings', () {
                  if (!ctrl.canManage) return toast('Only the owner and admins can open room settings');
                  run(() => host.push('/room/settings', extra: room));
                }),
                fn(Icons.style_rounded, 'Recommendation Card', () => run(() => showRecommendSheet(host, ref, room))),
                fn(Icons.flag_rounded, 'Rally Fans', () => run(() => showRallySheet(host, ref, room))),
                const Spacer(),
              ]),
            ]),
          ),
        ]),
      ),
    );
  }
}

class _ModeTile extends StatelessWidget {
  const _ModeTile({required this.label, required this.icon, required this.colors, required this.selected, required this.accent, required this.onTap});
  final String label;
  final IconData icon;
  final List<Color> colors;
  final bool selected;
  final Color accent;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Semantics(
        button: true,
        selected: selected,
        excludeSemantics: true,
        label: label,
        child: GestureDetector(
          onTap: onTap,
          child: SizedBox(
            width: 72,
            child: Column(children: [
              Stack(clipBehavior: Clip.none, children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    gradient: LinearGradient(colors: colors, begin: Alignment.topLeft, end: Alignment.bottomRight),
                    border: Border.all(color: selected ? accent : Colors.transparent, width: 2),
                    boxShadow: [BoxShadow(color: colors.first.withValues(alpha: selected ? 0.55 : 0.25), blurRadius: selected ? 14 : 6, offset: const Offset(0, 3))],
                  ),
                  child: Stack(alignment: Alignment.center, children: [
                    // glossy top highlight
                    Positioned(
                      top: 3,
                      left: 6,
                      right: 6,
                      height: 18,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Colors.white.withValues(alpha: 0.35), Colors.white.withValues(alpha: 0)]),
                        ),
                      ),
                    ),
                    Icon(icon, size: 27, color: Colors.white, shadows: const [Shadow(color: Colors.black38, blurRadius: 6, offset: Offset(0, 2))]),
                  ]),
                ),
                if (selected)
                  Positioned(
                    right: -4,
                    top: -4,
                    child: Container(
                      width: 18,
                      height: 18,
                      decoration: BoxDecoration(color: accent, shape: BoxShape.circle, border: Border.all(color: Colors.black26)),
                      child: Icon(Icons.check_rounded, size: 13, color: accent.computeLuminance() > 0.45 ? Colors.black : Colors.white),
                    ),
                  ),
              ]),
              const SizedBox(height: 6),
              Text(label.replaceFirst(' ', '\n'), // "Normal\nRoom": two short lines, never clipped
                  maxLines: 2,
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 11, height: 1.15, fontWeight: selected ? FontWeight.w800 : FontWeight.w500, color: selected ? accent : YoloColors.text)),
            ]),
          ),
        ),
      );
}

/// Recommendation card: puts the room at the top of Home → Popular for 30 minutes.
/// Cards per day come from the room level table.
void showRecommendSheet(BuildContext context, WidgetRef ref, Room room) {
  showRoomSheet<void>(
    context,
    (c) => Consumer(builder: (c, ref, _) {
      final st = ref.watch(roomProvider(room));
      final ctrl = ref.read(roomProvider(room).notifier);
      final look = st.look;
      final left = ctrl.recommendCardsLeft;
      final mins = st.promoted ? st.promotedUntil!.difference(DateTime.now()).inMinutes + 1 : 0;
      return Padding(
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 16),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Icon(Icons.style_rounded, color: look.accent),
            const SizedBox(width: 8),
            const Text('Recommendation card', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
          ]),
          const SizedBox(height: 8),
          const Text('Show this room at the top of Home → Popular for 30 minutes so more people find it.',
              style: TextStyle(color: YoloColors.textSoft, height: 1.4)),
          const SizedBox(height: 14),
          Row(children: [
            Expanded(child: _Stat(label: 'Cards left today', value: '$left', color: look.accent)),
            const SizedBox(width: 10),
            Expanded(child: _Stat(label: 'Status', value: st.promoted ? '$mins min left' : 'Not active', color: st.promoted ? YoloColors.online : YoloColors.textMuted)),
          ]),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              style: FilledButton.styleFrom(backgroundColor: look.accent, foregroundColor: look.onAccent, minimumSize: const Size.fromHeight(46)),
              onPressed: () {
                final msg = ctrl.useRecommendCard();
                showYoloToast(c, msg.isEmpty ? 'Room recommended for 30 minutes' : msg);
              },
              icon: const Icon(Icons.rocket_launch_rounded),
              label: const Text('Use a card'),
            ),
          ),
        ]),
      );
    }),
  );
}

/// Rally fans: notify the room's members and fans to come in (30-min cooldown), or invite friends.
void showRallySheet(BuildContext context, WidgetRef ref, Room room) {
  final text = TextEditingController();
  showRoomSheet<void>(
    context,
    scroll: true,
    (c) => Consumer(builder: (c, ref, _) {
      final st = ref.watch(roomProvider(room));
      final ctrl = ref.read(roomProvider(room).notifier);
      final look = st.look;
      return Padding(
        padding: EdgeInsets.fromLTRB(20, 18, 20, 16 + MediaQuery.viewInsetsOf(c).bottom),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Icon(Icons.flag_rounded, color: look.accent),
            const SizedBox(width: 8),
            const Text('Rally fans', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
          ]),
          const SizedBox(height: 12),
          Row(children: [
            Expanded(child: _Stat(label: 'Members', value: formatCoins(st.memberCount), color: look.accent)),
            const SizedBox(width: 10),
            Expanded(child: _Stat(label: 'Fans', value: formatCoins(st.fans), color: look.accent)),
          ]),
          const SizedBox(height: 12),
          TextField(
            key: const Key('rally-message'),
            controller: text,
            maxLength: 80,
            decoration: InputDecoration(
              hintText: 'Come join ${st.name}!',
              filled: true,
              fillColor: Colors.white.withValues(alpha: 0.07),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
            ),
          ),
          Row(children: [
            Expanded(
              child: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(46)),
                onPressed: () {
                  Navigator.pop(c);
                  showInviteSheet(context, ref, room);
                },
                icon: const Icon(Icons.person_add_alt_1_rounded),
                label: const Text('Invite friends'),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: FilledButton.icon(
                style: FilledButton.styleFrom(backgroundColor: look.accent, foregroundColor: look.onAccent, minimumSize: const Size.fromHeight(46)),
                onPressed: () {
                  final msg = ctrl.rallyFans(text.text);
                  if (msg.isEmpty) Navigator.pop(c);
                  showYoloToast(context, msg.isEmpty ? 'Rally sent to ${formatCoins(st.memberCount + st.fans)} members & fans' : msg);
                },
                icon: const Icon(Icons.campaign_rounded),
                label: const Text('Rally now'),
              ),
            ),
          ]),
        ]),
      );
    }),
  );
}

class _Stat extends StatelessWidget {
  const _Stat({required this.label, required this.value, required this.color});
  final String label, value;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
        decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.06), borderRadius: BorderRadius.circular(12)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label, style: const TextStyle(fontSize: 11, color: YoloColors.textMuted)),
          const SizedBox(height: 2),
          Text(value, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: color)),
        ]),
      );
}
