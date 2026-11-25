import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../core/theme.dart';
import '../../data/demo_content.dart';
import '../../data/models.dart';
import '../../data/providers.dart';
import '../../data/social_providers.dart';
import '../../widgets/common.dart';
import '../../widgets/page_kit.dart';

/// Opens a styled bottom sheet.
Future<T?> showRoomSheet<T>(BuildContext context, Widget Function(BuildContext) builder, {bool scroll = false}) => showModalBottomSheet<T>(
      context: context,
      isScrollControlled: scroll,
      backgroundColor: YoloColors.sheet,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      builder: (c) => SafeArea(child: builder(c)),
    );

Widget _sheetTitle(String t) => Padding(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 8),
      child: Text(t, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
    );

/// Actions for a seat. Admins/owner get management actions.
void showSeatActions(BuildContext context, WidgetRef ref, Room room, Seat seat, {required VoidCallback onGift}) {
  final ctrl = ref.read(roomProvider(room).notifier);
  final state = ref.read(roomProvider(room));
  final manage = ctrl.canManage;
  final u = seat.user;
  final meId = ref.read(sessionProvider)?.id;

  showRoomSheet<void>(context, (c) {
    void act(VoidCallback f, [String? toast]) {
      Navigator.pop(c);
      f();
      if (toast != null) showYoloToast(context, toast);
    }

    // Scrolls on short phones so every action stays reachable.
    return SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, children: [
      if (u != null)
        ListTile(
          contentPadding: const EdgeInsets.fromLTRB(20, 12, 20, 4),
          leading: YoloAvatar(user: u, size: 48),
          title: Text(u.name, style: const TextStyle(fontWeight: FontWeight.w800)),
          subtitle: Text('ID ${u.id}${state.admins.contains(u.id) ? ' · Admin' : ''}', style: const TextStyle(color: YoloColors.textMuted)),
        )
      else
        _sheetTitle('Seat ${seat.index + 1}'),
      if (u == null) ...[
        if (!seat.locked || manage)
          ListTile(leading: const Icon(Icons.mic_rounded), title: const Text('Take this seat'), onTap: () {
            Navigator.pop(c);
            final msg = ctrl.takeSeat(seat.index);
            showYoloToast(context, msg.isEmpty ? 'You are on mic' : msg);
          }),
        if (manage)
          ListTile(
            leading: Icon(seat.locked ? Icons.lock_open_rounded : Icons.lock_rounded),
            title: Text(seat.locked ? 'Unlock seat' : 'Lock seat'),
            onTap: () => act(() => ctrl.toggleLock(seat.index)),
          ),
        if (manage)
          ListTile(leading: const Icon(Icons.person_add_alt_1_rounded), title: const Text('Invite a friend to this seat'), onTap: () {
            Navigator.pop(c);
            showInviteSheet(context, ref, room);
          }),
      ] else ...[
        ListTile(leading: const Icon(Icons.person_rounded), title: const Text('View profile'), onTap: () => act(() => context.push('/user', extra: u))),
        if (u.id != meId) ListTile(leading: const Icon(Icons.card_giftcard_rounded, color: YoloColors.gold), title: const Text('Send gift'), onTap: () => act(onGift)),
        if (u.id == meId) ListTile(leading: const Icon(Icons.logout_rounded), title: const Text('Leave mic'), onTap: () => act(ctrl.leaveSeat, 'You left the mic')),
        if (manage && u.id != meId) ...[
          ListTile(
            leading: Icon(seat.muted ? Icons.mic_rounded : Icons.mic_off_rounded),
            title: Text(seat.muted ? 'Unmute' : 'Mute'),
            onTap: () => act(() => ctrl.toggleMute(seat.index)),
          ),
          ListTile(leading: const Icon(Icons.arrow_downward_rounded), title: const Text('Remove from mic'), onTap: () => act(() => ctrl.kickFromSeat(seat.index))),
          if (ctrl.isOwner)
            ListTile(
              leading: const Icon(Icons.admin_panel_settings_rounded),
              title: Text(state.admins.contains(u.id) ? 'Remove admin' : 'Make admin'),
              onTap: () => act(() {
                final err = ctrl.toggleAdmin(u);
                if (err.isNotEmpty) showYoloToast(context, err);
              }),
            ),
          ListTile(
            leading: const Icon(Icons.block_rounded, color: Color(0xFFF87171)),
            title: const Text('Ban from room', style: TextStyle(color: Color(0xFFF87171))),
            onTap: () => act(() => ctrl.ban(u)),
          ),
        ],
      ],
      const SizedBox(height: 8),
    ]));
  });
}

/// Invite friends to the room.
void showInviteSheet(BuildContext context, WidgetRef ref, Room room) {
  final following = ref.read(followingProvider);
  final friends = demoAllUsers.where((u) => following.contains(u.id) || u.id == 2003).toList();
  final sent = <int>{};
  showRoomSheet<void>(
    context,
    (c) => StatefulBuilder(
      builder: (c, setState) => Column(mainAxisSize: MainAxisSize.min, children: [
        _sheetTitle('Invite friends'),
        for (final u in friends)
          ListTile(
            leading: YoloAvatar(user: u, size: 42),
            title: Text(u.name, style: const TextStyle(fontWeight: FontWeight.w700)),
            trailing: sent.contains(u.id)
                ? const Text('Sent', style: TextStyle(color: YoloColors.online, fontWeight: FontWeight.w700))
                : SizedBox(
                    width: 96,
                    child: GoldButton(label: 'Invite', height: 34, onPressed: () {
                      setState(() => sent.add(u.id));
                      ref.read(roomProvider(room).notifier).inviteToSeat(u);
                    }),
                  ),
          ),
        ListTile(
          leading: const Icon(Icons.link_rounded, color: YoloColors.gold),
          title: const Text('Copy room link'),
          onTap: () {
            Clipboard.setData(ClipboardData(text: 'https://yolo.app/room/${room.id}'));
            Navigator.pop(c);
            showYoloToast(context, 'Room link copied');
          },
        ),
        const SizedBox(height: 8),
      ]),
    ),
  );
}

/// Room contribution ranking (gifts sent in this room).
void showRankingSheet(BuildContext context, WidgetRef ref, Room room) {
  final st = ref.read(roomProvider(room));
  final me = ref.read(sessionProvider)!;
  final all = <int, YoloUser>{for (final u in [...demoAllUsers, me]) u.id: u};
  final rows = st.contributions.entries.where((e) => all.containsKey(e.key)).toList()..sort((a, b) => b.value.compareTo(a.value));
  const medal = [Color(0xFFF5C451), Color(0xFFD1D5DB), Color(0xFFD97706)];
  showRoomSheet<void>(
    context,
    (c) => Column(mainAxisSize: MainAxisSize.min, children: [
      _sheetTitle('Room ranking · Today'),
      if (rows.isEmpty) const Padding(padding: EdgeInsets.all(20), child: Text('No gifts yet today')),
      for (final (i, e) in rows.indexed)
        ListTile(
          leading: SizedBox(
            width: 80,
            child: Row(children: [
              SizedBox(
                width: 28,
                child: Text('${i + 1}', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: i < 3 ? medal[i] : YoloColors.textMuted)),
              ),
              YoloAvatar(user: all[e.key]!, size: 40, goldFrame: i == 0),
            ]),
          ),
          title: Text(all[e.key]!.id == me.id ? '${all[e.key]!.name} (you)' : all[e.key]!.name, style: const TextStyle(fontWeight: FontWeight.w700)),
          trailing: Row(mainAxisSize: MainAxisSize.min, children: [
            const CoinIcon(size: 14),
            const SizedBox(width: 4),
            Text(formatCoins(e.value), style: const TextStyle(color: YoloColors.gold, fontWeight: FontWeight.w800)),
          ]),
        ).entrance(i),
      const SizedBox(height: 10),
    ]),
  );
}

/// Room music player (owner / admins).
void showMusicSheet(BuildContext context, WidgetRef ref, Room room) {
  showRoomSheet<void>(
    context,
    (c) => Consumer(builder: (c, ref, _) {
      final st = ref.watch(roomProvider(room));
      final ctrl = ref.read(roomProvider(room).notifier);
      return Column(mainAxisSize: MainAxisSize.min, children: [
        _sheetTitle('Room music'),
        for (var i = 0; i < RoomState.tracks.length; i++)
          ListTile(
            leading: Icon(st.track == i && st.musicPlaying ? Icons.graphic_eq_rounded : Icons.music_note_rounded,
                color: st.track == i ? YoloColors.gold : YoloColors.textMuted),
            title: Text(RoomState.tracks[i], style: TextStyle(fontWeight: FontWeight.w700, color: st.track == i ? YoloColors.gold : YoloColors.text)),
            subtitle: const Text('Yolo Music · demo track', style: TextStyle(fontSize: 12, color: YoloColors.textMuted)),
            trailing: st.track == i
                ? IconButton(
                    tooltip: st.musicPlaying ? 'Pause' : 'Play',
                    icon: Icon(st.musicPlaying ? Icons.pause_circle_filled_rounded : Icons.play_circle_fill_rounded, color: YoloColors.gold, size: 34),
                    onPressed: ctrl.toggleMusic,
                  )
                : null,
            onTap: () => ctrl.playTrack(i),
          ),
        const Padding(
          padding: EdgeInsets.fromLTRB(20, 4, 20, 14),
          child: Text('Real songs need licensed music; these are placeholder tracks.', style: TextStyle(fontSize: 11, color: YoloColors.textMuted)),
        ),
      ]);
    }),
    scroll: true,
  );
}

/// Room details + report.
void showRoomDetails(BuildContext context, WidgetRef ref, Room room) {
  final st = ref.read(roomProvider(room));
  showRoomSheet<void>(
    context,
    (c) => Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
      child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(borderRadius: BorderRadius.circular(16), gradient: LinearGradient(colors: room.cover)),
            alignment: Alignment.center,
            child: Text(st.name[0], style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(st.name, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
              Text('ID ${room.id} · ${room.tag}${st.password.isNotEmpty ? ' · Locked' : ''}', style: const TextStyle(color: YoloColors.textMuted)),
            ]),
          ),
        ]),
        const SizedBox(height: 14),
        Text('Host: ${room.owner.name}', style: const TextStyle(fontWeight: FontWeight.w600)),
        const SizedBox(height: 6),
        Text(st.announcement.isEmpty ? 'No announcement' : st.announcement, style: const TextStyle(color: YoloColors.textSoft)),
        const SizedBox(height: 16),
        Row(children: [
          Expanded(
            child: OutlinedButton.icon(
              onPressed: () {
                Navigator.pop(c);
                showInviteSheet(context, ref, room);
              },
              icon: const Icon(Icons.share_rounded),
              label: const Text('Share'),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: OutlinedButton.icon(
              style: OutlinedButton.styleFrom(foregroundColor: const Color(0xFFF87171)),
              onPressed: () {
                Navigator.pop(c);
                showReportSheet(context, 'room');
              },
              icon: const Icon(Icons.flag_rounded),
              label: const Text('Report'),
            ),
          ),
        ]),
      ]),
    ),
  );
}

/// Generic report flow (room, user, post...).
void showReportSheet(BuildContext context, String what) {
  const reasons = ['Harassment or bullying', 'Sexual content', 'Hate speech', 'Spam or scam', 'Violence', 'Underage user', 'Other'];
  showRoomSheet<void>(
    context,
    (c) => Column(mainAxisSize: MainAxisSize.min, children: [
      _sheetTitle('Report this $what'),
      for (final r in reasons)
        ListTile(
          title: Text(r),
          trailing: const Icon(Icons.chevron_right_rounded),
          onTap: () {
            Navigator.pop(c);
            showYoloToast(context, 'Report sent. Our team will review it.');
          },
        ),
      const SizedBox(height: 8),
    ]),
    scroll: true,
  );
}

/// Ask for the password before entering a private room.
Future<bool> askRoomPassword(BuildContext context, Room room) async {
  final ctrl = TextEditingController();
  String? error;
  final ok = await showDialog<bool>(
    context: context,
    builder: (c) => StatefulBuilder(
      builder: (c, setState) => AlertDialog(
        backgroundColor: YoloColors.sheet,
        title: const Text('Private room'),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          const Icon(Icons.lock_rounded, color: YoloColors.gold, size: 40).animate().shake(),
          const SizedBox(height: 10),
          TextField(
            key: const Key('room-password'),
            controller: ctrl,
            autofocus: true,
            obscureText: true,
            keyboardType: TextInputType.number,
            maxLength: 6,
            decoration: InputDecoration(hintText: 'Enter password', errorText: error),
          ),
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Cancel')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: YoloColors.gold, foregroundColor: YoloColors.onGold),
            onPressed: () {
              if (ctrl.text == room.password) {
                Navigator.pop(c, true);
              } else {
                setState(() => error = 'Wrong password');
              }
            },
            child: const Text('Enter'),
          ),
        ],
      ),
    ),
  );
  return ok ?? false;
}

/// Opens a room, asking for the password first when it is private.
Future<void> openRoom(BuildContext context, WidgetRef ref, Room room) async {
  final me = ref.read(sessionProvider);
  if (room.isPrivate && room.owner.id != me?.id) {
    if (!await askRoomPassword(context, room)) return;
  }
  if (context.mounted) context.push('/room', extra: room);
}
