import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../core/theme.dart';
import '../../data/models.dart';
import '../../data/providers.dart';
import '../../data/room_levels.dart';
import '../../data/room_look.dart';
import '../../data/settings_providers.dart';
import '../../data/social_providers.dart';
import '../../widgets/common.dart';
import '../../widgets/page_kit.dart';
import 'floating_room.dart';
import 'gift_sheet.dart';
import 'room_background.dart';
import 'room_drawer.dart';
import 'room_panels.dart';
import 'room_sheets.dart';
import 'room_stage.dart';

/// The voice room. Built from small parts that each watch only the room data they show,
/// so a speaking ring, a new message or the treasure timer never rebuilds the whole room.
class RoomScreen extends ConsumerStatefulWidget {
  const RoomScreen({super.key, required this.room});
  final Room room;

  @override
  ConsumerState<RoomScreen> createState() => _RoomScreenState();
}

class _RoomScreenState extends ConsumerState<RoomScreen> {
  final _input = TextEditingController();

  /// The live room instance (reused when restoring a minimized room, so nothing reloads).
  late final Room room;
  late final RoomScreenOpen _openCounter;
  late final bool _restored; // reopened from the floating mini room
  RoomController get ctrl => ref.read(roomProvider(room).notifier);

  @override
  void initState() {
    super.initState();
    final active = ref.read(activeRoomProvider.notifier);
    _restored = ref.read(activeRoomProvider)?.id == widget.room.id;
    room = active.canonical(widget.room);
    _openCounter = ref.read(roomScreenOpenProvider.notifier);
    // Providers can't change while widgets build, so register right after this frame starts.
    Future.microtask(() {
      active.enter(room);
      _openCounter.opened();
    });
  }

  @override
  void dispose() {
    final counter = _openCounter;
    Future.microtask(counter.closed);
    _input.dispose();
    super.dispose();
  }

  void _toast(String msg) => showYoloToast(context, msg);

  void _send() {
    if (!ctrl.sendChat(_input.text)) {
      _toast('Text chat is turned off in this room');
      return;
    }
    _input.clear();
  }

  void _mention(String text) {
    _input.text = text;
    _input.selection = TextSelection.collapsed(offset: text.length);
  }

  void _seatTapped(Seat seat) {
    final meId = ref.read(sessionProvider)?.id;
    if (seat.isEmpty && !ctrl.canManage) {
      final msg = ctrl.takeSeat(seat.index);
      _toast(msg.isEmpty ? 'You are on mic' : msg);
      return;
    }
    if (!seat.isEmpty && (seat.user!.id == meId || !ctrl.canManage)) {
      _userCard(seat.user!);
      return;
    }
    showSeatActions(context, ref, room, seat, onGift: () => _openGifts(seat.user));
  }

  void _userCard(YoloUser u) => showUserCard(context, ref, room, u, onMention: _mention, onGift: () => _openGifts(u));

  void _openGifts([YoloUser? target]) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black54,
      isScrollControlled: true,
      builder: (_) => GiftSheet(room: room, initialTarget: target),
    );
  }

  /// Exit: leave the seat, end the room session (voice disconnects, mini room goes away).
  void _exitRoom() {
    ctrl.leaveSeat();
    ref.read(activeRoomProvider.notifier).exit();
    if (mounted) context.pop();
  }

  void _openDrawer() => showRoomTopDrawer(context, ref, room, onExit: _exitRoom);

  /// Four-dot menu: room features in one compact grid (the bottom bar keeps its own shortcuts).
  void _menuGrid() {
    final look = ref.read(roomProvider(room)).look;
    final treasureReady = _treasureReady(ref.read(roomProvider(room)));
    final items = <(IconData, String, Color, VoidCallback, bool)>[
      (Icons.redeem_rounded, 'Daily Treasure', const Color(0xFF22D3EE), () => showTreasureSheet(context, ref, room), treasureReady),
      (Icons.mail_rounded, 'Red Packet', const Color(0xFFEF4444), () => showRedPacketSheet(context, ref, room), false),
      (Icons.library_music_rounded, 'Music', const Color(0xFFF9A8D4), () => ctrl.canManage ? showMusicSheet(context, ref, room) : _toast('Only admins can play room music'), false),
      (Icons.emoji_emotions_rounded, 'Emotes', const Color(0xFFFDE047), () => showInteractionPanel(context, ref, room), false),
      (Icons.card_giftcard_rounded, 'Gifting', const Color(0xFFFB7185), () => _openGifts(), false),
      (Icons.info_outline_rounded, 'Room Info', const Color(0xFFC4B5FD), () => showRoomInfoSheet(context, ref, room), false),
      (Icons.workspace_premium_rounded, 'Room Level', const Color(0xFFC084FC), () => context.push('/room/level', extra: room), false),
      (Icons.people_alt_rounded, 'Members', const Color(0xFF7DD3FC), () => showMembersSheet(context, ref, room), false),
      (Icons.person_add_alt_1_rounded, 'Invite', const Color(0xFF86EFAC), () => showInviteSheet(context, ref, room), false),
      (Icons.leaderboard_rounded, 'Ranking', const Color(0xFFFDE68A), () => showMembersSheet(context, ref, room, tab: 2), false),
    ];
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: look.sheet,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (c) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(10, 14, 10, 8),
          child: GridView.count(
            crossAxisCount: 5,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 4,
            childAspectRatio: 0.82,
            children: [
              for (final (icon, label, color, onTap, dot) in items)
                InkWell(
                  borderRadius: BorderRadius.circular(14),
                  onTap: () {
                    Navigator.pop(c);
                    onTap();
                  },
                  child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                    Badge(isLabelVisible: dot, smallSize: 9, child: TintIcon(icon, color: color, size: 42)),
                    const SizedBox(height: 5),
                    Text(label, maxLines: 1, overflow: TextOverflow.ellipsis, textAlign: TextAlign.center, style: const TextStyle(fontSize: 11)),
                  ]),
                ),
            ],
          ),
        ),
      ),
    );
  }

  bool _treasureReady(RoomState st) {
    final vip = (ref.read(sessionProvider)?.vipLevel ?? 0) > 0;
    final progress = st.treasureSecs + (ctrl.isMember ? 60 : 0);
    return [
      for (var i = 0; i < treasureMinutes.length; i++)
        if (!st.claimedBoxes.contains(i) && progress >= treasureMinutes[i] * 60 && (!treasureVipOnly.contains(i) || vip)) i,
    ].isNotEmpty;
  }

  @override
  Widget build(BuildContext context) {
    // Only the look is watched here: theme / background changes re-colour the room in place.
    final look = ref.watch(roomProvider(room).select((s) => s.look));

    // Gift sound (personal setting): a short sound + haptic tap on each gift.
    ref.listen(roomProvider(room).select((s) => s.lastGift?.serial), (prev, next) {
      if (next != null && next != prev && ref.read(settingsProvider).giftSounds) {
        SystemSound.play(SystemSoundType.click);
        HapticFeedback.lightImpact();
      }
    });

    // System back / swipe pops this screen; the room stays live and the floating mini room appears.
    return RoomLookScope(
      look: look,
      child: Scaffold(
        resizeToAvoidBottomInset: true,
        backgroundColor: look.bg.last,
        body: AnimatedRoomBackground(
          look: look,
          child: Stack(children: [
            SafeArea(
              child: Column(children: [
                _Header(room: room, onMenu: _openDrawer),
                _StageArea(room: room, onSeat: _seatTapped, onUser: _userCard),
                _PresenceStrip(room: room, skipExisting: _restored),
                Expanded(child: _ChatList(room: room, onUser: _userCard)),
                _BottomBar(room: room, input: _input, onSend: _send, onGift: _openGifts, onMenu: _menuGrid),
              ]),
            ),
            _RedPacketButton(room: room),
            _GiftLayer(room: room),
          ]),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Header: room image · name / Level / Room ID · top contributors · online · menu
class _Header extends ConsumerWidget {
  const _Header({required this.room, required this.onMenu});
  final Room room;
  final VoidCallback onMenu;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final (name, cover, exp, locked, contributions, online, groupId) =
        ref.watch(roomProvider(room).select((s) => (s.name, s.coverPath, s.exp, s.password.isNotEmpty, s.contributions, s.onlineCount, s.groupId)));
    final ctrl = ref.read(roomProvider(room).notifier);
    final look = RoomLookScope.of(context);
    final lvl = levelForExp(exp).level;
    final levelColor = roomLevelColors(lvl).first;
    // Group chip: only while no group is linked, and only for people who can link one.
    final showGroup = groupId == null && ctrl.canManage;

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 6, 2, 0),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Expanded(
            child: Semantics(
              button: true,
              excludeSemantics: true,
              label: 'Room details',
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => showRoomInfoSheet(context, ref, room),
                child: Row(children: [
                  RoomCover(room: room, name: name, coverPath: cover, size: 44, radius: 12),
                  const SizedBox(width: 10),
                  Flexible(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
                      Row(mainAxisSize: MainAxisSize.min, children: [
                        if (locked) Padding(padding: const EdgeInsets.only(right: 3), child: Icon(Icons.lock_rounded, size: 12, color: look.accent)),
                        Flexible(child: Text(name, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, height: 1.2))),
                      ]),
                      const SizedBox(height: 3),
                      Row(mainAxisSize: MainAxisSize.min, children: [
                        Container(
                          padding: const EdgeInsets.fromLTRB(2, 1, 6, 1),
                          decoration: BoxDecoration(color: levelColor.withValues(alpha: 0.18), borderRadius: BorderRadius.circular(8)),
                          child: Row(mainAxisSize: MainAxisSize.min, children: [
                            RoomLevelBadge(lvl, size: 13),
                            const SizedBox(width: 3),
                            Text('Level $lvl', style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.w800, color: levelColor)),
                          ]),
                        ),
                      ]),
                      const SizedBox(height: 2),
                      Text('Room ID: ${room.id}', maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 9.5, color: Color(0xFFC4B8E6))),
                    ]),
                  ),
                ]),
              ),
            ),
          ),
          const SizedBox(width: 4),
          _TopContributors(rows: ctrl.topGifters(), onTap: () => showMembersSheet(context, ref, room, tab: 2)),
          const SizedBox(width: 4),
          Semantics(
            button: true,
            excludeSemantics: true,
            label: 'Online users',
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => showMembersSheet(context, ref, room),
              child: Container(
                height: 24,
                padding: const EdgeInsets.symmetric(horizontal: 7),
                decoration: BoxDecoration(color: look.panel, borderRadius: BorderRadius.circular(12)),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  const Icon(Icons.people_alt_rounded, size: 12, color: YoloColors.online),
                  const SizedBox(width: 3),
                  Text(compactCount(online), style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800)),
                ]),
              ),
            ),
          ),
          IconButton(tooltip: 'Room menu', visualDensity: VisualDensity.compact, padding: EdgeInsets.zero, constraints: const BoxConstraints(minWidth: 36, minHeight: 40), icon: const Icon(Icons.more_vert_rounded, size: 22), onPressed: onMenu),
        ]),
        if (showGroup)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Semantics(
              button: true,
              excludeSemantics: true,
              label: 'Link a group',
              child: GestureDetector(
                onTap: () => _linkGroup(context, ref),
                child: Container(
                  height: 20,
                  padding: const EdgeInsets.symmetric(horizontal: 7),
                  decoration: BoxDecoration(color: look.panel, borderRadius: BorderRadius.circular(10)),
                  child: const Row(mainAxisSize: MainAxisSize.min, children: [
                    Icon(Icons.add_comment_rounded, size: 11, color: YoloColors.textSoft),
                    SizedBox(width: 3),
                    Text('Group', style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w600)),
                  ]),
                ),
              ),
            ),
          ),
      ]),
    );
  }

  /// Link one of my group chats to the room (same setting as Room settings → Associated group).
  void _linkGroup(BuildContext context, WidgetRef ref) {
    final groups = ref.read(groupsProvider);
    if (groups.isEmpty) {
      showYoloToast(context, 'Create a group chat in Messages first');
      return;
    }
    showRoomSheet<void>(
      context,
      (c) => Column(mainAxisSize: MainAxisSize.min, children: [
        const Padding(padding: EdgeInsets.fromLTRB(20, 18, 20, 8), child: Text('Link a group', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800))),
        for (final g in groups)
          ListTile(
            leading: const Icon(Icons.forum_rounded),
            title: Text(g.name),
            onTap: () {
              Navigator.pop(c);
              ref.read(roomProvider(room).notifier).updateSettings(groupId: g.id);
              showYoloToast(context, '${g.name} linked to the room');
            },
          ),
      ]),
    );
  }
}

/// Top three contributors (by Charms they gave in this room, highest first).
/// Each picture carries its Charms number in a small tag attached to its bottom edge.
class _TopContributors extends StatelessWidget {
  const _TopContributors({required this.rows, required this.onTap});
  final List<(YoloUser, int)> rows;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    if (rows.isEmpty) return const SizedBox.shrink();
    final look = RoomLookScope.of(context);
    return Semantics(
      button: true,
      excludeSemantics: true,
      label: 'Top contributors: ${rows.map((r) => '${r.$1.name} ${r.$2} Charms').join(', ')}',
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          for (final (u, charms) in rows)
            Padding(
              key: ValueKey(u.id),
              padding: const EdgeInsets.symmetric(horizontal: 2),
              child: SizedBox(
                width: 34,
                height: 38,
                child: Stack(alignment: Alignment.topCenter, clipBehavior: Clip.none, children: [
                  YoloAvatar(user: u, size: 30, plain: true),
                  Positioned(
                    bottom: 0,
                    child: Container(
                      constraints: const BoxConstraints(minWidth: 26),
                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                      decoration: BoxDecoration(
                        color: look.bg.last,
                        borderRadius: BorderRadius.circular(7),
                        border: Border.all(color: look.accent.withValues(alpha: 0.7), width: 0.8),
                      ),
                      child: Text(compactCount(charms),
                          textAlign: TextAlign.center, style: const TextStyle(fontSize: 8.5, fontWeight: FontWeight.w800, height: 1.1)),
                    ),
                  ),
                ]),
              ),
            ),
        ]),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Host (+ partner), music indicator, mode stage and mic seats
class _StageArea extends ConsumerWidget {
  const _StageArea({required this.room, required this.onSeat, required this.onUser});
  final Room room;
  final void Function(Seat) onSeat;
  final void Function(YoloUser) onUser;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final (seats, mode, seatFx, admins, coOwners, members) =
        ref.watch(roomProvider(room).select((s) => (s.seats, s.mode, s.seatFx, s.admins, s.coOwners, s.members)));
    final meId = ref.watch(sessionProvider.select((u) => u?.id));
    final ctrl = ref.read(roomProvider(room).notifier);
    final look = RoomLookScope.of(context);
    final intimacy = mode == 'intimacy';
    final gridSeats = intimacy ? seats.skip(1).toList() : seats;
    final compact = gridSeats.length > 8;

    Widget seatTile(Seat s, {double? size}) => _SeatTile(
          seat: s,
          isMe: s.user?.id == meId,
          role: s.user == null ? 'Guest' : ctrl.roleOf(s.user!.id),
          fx: s.user == null ? null : seatFx[s.user!.id],
          size: size ?? (compact ? 48 : 56),
          accent: look.accent,
          panel: look.panel,
          onTap: () => onSeat(s),
        );

    const sideWidth = 96.0;
    return Column(children: [
      // Host row — fixed height; the music disc sits in its own corner so it never covers a seat.
      SizedBox(
        height: 124,
        child: Stack(children: [
          Center(
            child: Row(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
              SizedBox(
                width: sideWidth,
                child: Semantics(
                  button: true,
                  excludeSemantics: true,
                  label: 'Host ${room.owner.name}',
                  child: GestureDetector(
                    onTap: () => onUser(room.owner),
                    child: Column(children: [
                      const SizedBox(height: 18),
                      YoloAvatar(user: room.owner, size: 72, goldFrame: true, speaking: true, ringColor: look.accent),
                      const SizedBox(height: 5),
                      Text(room.owner.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800)),
                    ]),
                  ),
                ),
              ),
              if (intimacy) ...[
                const Padding(padding: EdgeInsets.only(top: 46), child: HeartbeatLine(width: 44)),
                SizedBox(width: sideWidth, child: Padding(padding: const EdgeInsets.only(top: 18), child: seatTile(seats.first, size: 72))),
              ],
            ]),
          ),
          Positioned(right: 10, top: 20, child: _MusicDisc(room: room)),
        ]),
      ),
      RoomModeStage(room: room),
      // Mic seats — a little more space above them to separate from the host row.
      Padding(
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 0),
        child: GridView.count(
          crossAxisCount: 4,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 6,
          padding: EdgeInsets.zero,
          childAspectRatio: compact ? 1.0 : 0.9,
          children: [for (final s in gridSeats) seatTile(s)],
        ),
      ),
    ]);
  }
}

/// Spinning disc + bars while music plays (tap → music controls). Same size when idle,
/// so starting or stopping music never moves anything.
class _MusicDisc extends ConsumerWidget {
  const _MusicDisc({required this.room});
  final Room room;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final (track, playing) = ref.watch(roomProvider(room).select((s) => (s.track, s.musicPlaying)));
    final look = RoomLookScope.of(context);
    if (track == null) return const SizedBox(width: 34, height: 48);
    final disc = Container(
      width: 34,
      height: 34,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: SweepGradient(colors: [look.panel, look.accent.withValues(alpha: 0.6), look.panel]),
        border: Border.all(color: look.accent.withValues(alpha: 0.6)),
      ),
      child: Icon(Icons.music_note_rounded, size: 16, color: look.accent),
    );
    return Semantics(
      button: true,
      excludeSemantics: true,
      label: 'Now playing ${RoomState.tracks[track]}',
      child: GestureDetector(
        onTap: () => showMusicSheet(context, ref, room),
        child: SizedBox(
          width: 34,
          height: 48,
          child: Column(children: [
            playing ? disc.animate(onPlay: (c) => c.repeat()).rotate(duration: 4.seconds) : disc,
            const SizedBox(height: 3),
            playing ? LiveBars(color: look.accent) : Icon(Icons.pause_rounded, size: 11, color: look.accent),
          ]),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
/// Fixed strip under the seats for "X entered / left the room". Events are queued and shown one
/// at a time in the same spot; the strip never changes height, so seats and chat never move.
class _PresenceStrip extends ConsumerStatefulWidget {
  const _PresenceStrip({required this.room, required this.skipExisting});
  final Room room;
  final bool skipExisting;

  @override
  ConsumerState<_PresenceStrip> createState() => _PresenceStripState();
}

class _PresenceStripState extends ConsumerState<_PresenceStrip> {
  final _queue = <PresenceEvent>[];
  PresenceEvent? _shown;
  Timer? _timer;
  late int _lastSerial;

  @override
  void initState() {
    super.initState();
    final log = ref.read(roomProvider(widget.room)).presence;
    if (widget.skipExisting || log.isEmpty) {
      _lastSerial = log.isEmpty ? 0 : log.last.serial;
    } else {
      _lastSerial = log.last.serial - 1; // fresh entry: show my own "entered" notice
      _enqueue(log);
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _enqueue(List<PresenceEvent> log) {
    for (final e in log) {
      if (e.serial > _lastSerial) {
        _queue.add(e);
        _lastSerial = e.serial;
      }
    }
    _next();
  }

  void _next() {
    if (_shown != null || _queue.isEmpty) return;
    _shown = _queue.removeAt(0);
    if (mounted) setState(() {});
    // Busy room → shorter notices so the queue keeps up.
    final hold = _queue.length > 2 ? 1200 : 2400;
    _timer = Timer(Duration(milliseconds: hold), () {
      if (!mounted) return;
      setState(() => _shown = null);
      _timer = Timer(const Duration(milliseconds: 320), _next); // let the exit animation finish
    });
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(roomProvider(widget.room).select((s) => s.presence), (_, log) => _enqueue(log));
    final look = RoomLookScope.of(context);
    final e = _shown;
    return SizedBox(
      height: 30,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
        child: Align(
          alignment: Alignment.centerLeft,
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            transitionBuilder: (c, a) => FadeTransition(
              opacity: a,
              child: SlideTransition(position: Tween(begin: const Offset(-0.3, 0), end: Offset.zero).animate(CurvedAnimation(parent: a, curve: Curves.easeOutCubic)), child: c),
            ),
            child: e == null
                ? const SizedBox.shrink()
                : Container(
                    key: ValueKey(e.serial),
                    padding: const EdgeInsets.fromLTRB(3, 3, 12, 3),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(14),
                      gradient: LinearGradient(colors: [look.accent.withValues(alpha: e.entered ? 0.45 : 0.22), look.accent.withValues(alpha: 0.04)]),
                    ),
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      YoloAvatar(user: e.user, size: 20, plain: true),
                      const SizedBox(width: 6),
                      Flexible(
                        child: Text.rich(
                          TextSpan(children: [
                            TextSpan(text: e.user.name, style: const TextStyle(fontWeight: FontWeight.w800)),
                            TextSpan(text: e.entered ? ' entered the room' : ' left the room'),
                          ]),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 12, color: YoloColors.text),
                        ),
                      ),
                    ]),
                  ),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
/// System note → announcement → chat, all in one scrolling list.
class _ChatList extends ConsumerStatefulWidget {
  const _ChatList({required this.room, required this.onUser});
  final Room room;
  final void Function(YoloUser) onUser;

  @override
  ConsumerState<_ChatList> createState() => _ChatListState();
}

class _ChatListState extends ConsumerState<_ChatList> {
  final _scroll = ScrollController();

  /// Messages already shown once, so their entry animation never replays while scrolling.
  final _animated = <int>{};
  late final int _firstLiveIndex = ref.read(roomProvider(widget.room)).messages.length;

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  /// Follow new messages only when the reader is at the bottom (or wrote it themselves).
  void _onNewMessage({required bool mine}) {
    if (!_scroll.hasClients) return;
    final pos = _scroll.position;
    if (pos.maxScrollExtent - pos.pixels > 120 && !mine) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) _scroll.animateTo(_scroll.position.maxScrollExtent, duration: 250.ms, curve: Curves.easeOut);
    });
  }

  @override
  Widget build(BuildContext context) {
    final room = widget.room;
    final (messages, announcement, name, members, admins, coOwners) =
        ref.watch(roomProvider(room).select((s) => (s.messages, s.announcement, s.name, s.members, s.admins, s.coOwners)));
    final ctrl = ref.read(roomProvider(room).notifier);
    final meId = ref.read(sessionProvider)?.id;
    final look = RoomLookScope.of(context);
    ref.listen(roomProvider(room).select((s) => s.messages.length), (prev, next) {
      if (next > (prev ?? 0)) _onNewMessage(mine: ref.read(roomProvider(room)).messages.last.senderId == meId);
    });
    final lead = messages.takeWhile((m) => m.kind == MessageKind.system).length;

    return ShaderMask(
      shaderCallback: (r) => const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Colors.transparent, Colors.black],
        stops: [0, 0.05],
      ).createShader(r),
      blendMode: BlendMode.dstIn,
      child: ListView.builder(
        controller: _scroll,
        padding: const EdgeInsets.fromLTRB(12, 6, 12, 6),
        itemCount: messages.length + 1,
        itemBuilder: (_, i) {
          if (i == lead) {
            return _AnnouncementNote(
              key: const ValueKey('announcement'),
              text: announcement.isEmpty ? 'Welcome to $name!' : announcement,
              look: look,
              onTap: () => showRoomInfoSheet(context, ref, room),
            );
          }
          final index = i < lead ? i : i - 1;
          final m = messages[index];
          final u = m.senderId == 0 ? null : roomUser(ref, m.senderId);
          Widget bubble = _MessageBubble(
            key: ValueKey('m$index'),
            msg: m,
            user: u,
            role: u == null ? 'Guest' : ctrl.roleOf(u.id),
            member: u != null && members.contains(u.id),
            roomName: name,
            look: look,
            onUser: u == null ? null : () => widget.onUser(u),
          );
          // Chat lines keep clear of the red-packet envelope; notes use the full width.
          if (m.kind != MessageKind.system) bubble = Padding(padding: const EdgeInsets.only(right: 48), child: bubble);
          if (_animated.add(index) && index >= _firstLiveIndex) {
            bubble = bubble.animate().fadeIn(duration: 220.ms).slideX(begin: -0.04, end: 0);
          }
          return bubble;
        },
      ),
    );
  }
}

class _AnnouncementNote extends StatelessWidget {
  const _AnnouncementNote({super.key, required this.text, required this.look, required this.onTap});
  final String text;
  final RoomLook look;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: Container(
          width: double.infinity,
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            color: look.panel,
            border: Border(left: BorderSide(color: look.accent, width: 2.5)),
          ),
          child: Text.rich(
            TextSpan(children: [
              WidgetSpan(alignment: PlaceholderAlignment.middle, child: Icon(Icons.campaign_rounded, size: 15, color: look.accent)),
              TextSpan(text: ' Announcement: ', style: TextStyle(color: look.accent, fontWeight: FontWeight.w700)),
              TextSpan(text: text),
            ]),
            style: const TextStyle(fontSize: 12, color: YoloColors.text, height: 1.4),
          ),
        ),
      );
}

class _MessageBubble extends StatelessWidget {
  const _MessageBubble(
      {super.key, required this.msg, required this.user, required this.role, required this.member, required this.roomName, required this.look, this.onUser});
  final RoomMessage msg;
  final YoloUser? user;
  final String role;
  final bool member;
  final String roomName;
  final RoomLook look;
  final VoidCallback? onUser;

  @override
  Widget build(BuildContext context) {
    switch (msg.kind) {
      case MessageKind.system:
        return Container(
          width: double.infinity,
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(color: look.panel, borderRadius: BorderRadius.circular(12)),
          child: Text.rich(
            TextSpan(children: [
              WidgetSpan(alignment: PlaceholderAlignment.middle, child: Icon(Icons.notifications_rounded, size: 14, color: look.accent)),
              TextSpan(text: ' System: ', style: TextStyle(color: look.accent, fontWeight: FontWeight.w700)),
              TextSpan(text: msg.text),
            ]),
            style: const TextStyle(fontSize: 12, color: YoloColors.textSoft, height: 1.4),
          ),
        );
      case MessageKind.gift:
        return Align(
          alignment: Alignment.centerLeft,
          child: Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              gradient: LinearGradient(colors: [look.accent.withValues(alpha: 0.30), look.accent.withValues(alpha: 0.06)]),
            ),
            child: Text(msg.text, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color.lerp(look.accent, Colors.white, 0.4))),
          ),
        );
      case MessageKind.chat:
        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            GestureDetector(
              onTap: onUser,
              child: Wrap(spacing: 5, crossAxisAlignment: WrapCrossAlignment.center, children: [
                if (user != null) YoloAvatar(user: user!, size: 24, plain: true),
                if (role != 'Guest' && role != 'Member') Icon(roleIcon(role), size: 14, color: roleColor(role)),
                Text(msg.sender, style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12, color: msg.color)),
                if (user != null) LevelCrown(user!.level + 7),
                if (member) MemberTitle(roomName),
              ]),
            ),
            const SizedBox(height: 4),
            Container(
              margin: const EdgeInsets.only(left: 29),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(color: look.panel, borderRadius: BorderRadius.circular(14)),
              child: Text(msg.text, style: const TextStyle(fontSize: 13, height: 1.35)),
            ),
          ]),
        );
    }
  }
}

// ---------------------------------------------------------------------------
/// Bottom bar: speaker · mic · chat input · emotes · gift · four-dot menu — all 36 px circles
/// with 44 px touch targets.
class _BottomBar extends ConsumerWidget {
  const _BottomBar({required this.room, required this.input, required this.onSend, required this.onGift, required this.onMenu});
  final Room room;
  final TextEditingController input;
  final VoidCallback onSend;
  final void Function([YoloUser?]) onGift;
  final VoidCallback onMenu;

  static const _d = 36.0;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final meId = ref.watch(sessionProvider.select((u) => u?.id));
    final (micOn, speakerOn, banText, onMic) =
        ref.watch(roomProvider(room).select((s) => (s.micOn, s.speakerOn, s.banText, s.seats.any((x) => x.user?.id == meId))));
    final ctrl = ref.read(roomProvider(room).notifier);
    final look = RoomLookScope.of(context);
    final chatLocked = banText && !ctrl.canManage;

    return Padding(
      padding: const EdgeInsets.fromLTRB(6, 4, 6, 6),
      child: Row(children: [
        _RoundAction(
          icon: speakerOn ? Icons.volume_up_rounded : Icons.volume_off_rounded,
          label: speakerOn ? 'Mute speaker' : 'Unmute speaker',
          color: look.panel,
          onTap: ctrl.toggleSpeaker,
        ),
        _RoundAction(
          icon: onMic && micOn ? Icons.mic_rounded : Icons.mic_off_rounded,
          label: onMic ? (micOn ? 'Mute microphone' : 'Unmute microphone') : 'Take a seat to talk',
          color: look.panel,
          onTap: () {
            if (onMic) {
              ctrl.toggleMic();
            } else {
              final msg = ctrl.takeAnySeat();
              showYoloToast(context, msg.isEmpty ? 'You are on mic' : msg);
            }
          },
        ),
        const SizedBox(width: 4),
        Expanded(
          child: SizedBox(
            height: _d,
            child: TextField(
              controller: input,
              enabled: !chatLocked,
              onSubmitted: (_) => onSend(),
              textInputAction: TextInputAction.send,
              style: const TextStyle(fontSize: 13),
              textAlignVertical: TextAlignVertical.center,
              decoration: InputDecoration(
                hintText: chatLocked ? 'Chat is off' : 'Say hi…',
                hintStyle: const TextStyle(color: YoloColors.textMuted, fontSize: 13),
                isDense: true,
                filled: true,
                fillColor: look.panel,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(_d / 2), borderSide: BorderSide.none),
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              ),
            ),
          ),
        ),
        const SizedBox(width: 4),
        _RoundAction(icon: Icons.emoji_emotions_rounded, label: 'Interactions', color: look.panel, onTap: () => showInteractionPanel(context, ref, room)),
        _RoundAction(
          icon: Icons.card_giftcard_rounded,
          label: 'Send gift',
          gradient: const [Color(0xFFF9A8D4), Color(0xFFF43F5E)],
          onTap: () => onGift(),
        ),
        _FourDotButton(room: room, color: look.panel, onTap: onMenu),
      ]),
    );
  }
}

class _RoundAction extends StatelessWidget {
  const _RoundAction({required this.icon, required this.label, required this.onTap, this.color, this.gradient});
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color? color;
  final List<Color>? gradient;

  @override
  Widget build(BuildContext context) => Semantics(
        button: true,
        excludeSemantics: true,
        label: label,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: onTap,
          child: SizedBox(
            width: 42, // touch area
            height: 44,
            child: Center(
              child: Container(
                width: _BottomBar._d,
                height: _BottomBar._d,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: gradient == null ? color : null,
                  gradient: gradient == null ? null : LinearGradient(colors: gradient!),
                ),
                child: Icon(icon, size: 19, color: Colors.white),
              ),
            ),
          ),
        ),
      );
}

/// White four-dot button that opens the feature grid; shows a dot when a treasure box is ready.
class _FourDotButton extends ConsumerWidget {
  const _FourDotButton({required this.room, required this.color, required this.onTap});
  final Room room;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final meId = ref.watch(sessionProvider.select((u) => u?.id));
    final ready = ref.watch(roomProvider(room).select((s) {
      final progress = s.treasureSecs + (s.members.contains(meId) ? 60 : 0);
      return !s.claimedBoxes.contains(0) && progress >= treasureMinutes.first * 60;
    }));
    Widget dot() => Container(width: 6, height: 6, margin: const EdgeInsets.all(1.5), decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle));
    return Semantics(
      button: true,
      excludeSemantics: true,
      label: 'More features',
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: SizedBox(
          width: 42,
          height: 44,
          child: Center(
            child: Badge(
              isLabelVisible: ready,
              smallSize: 8,
              child: Container(
                width: _BottomBar._d,
                height: _BottomBar._d,
                decoration: BoxDecoration(shape: BoxShape.circle, color: color),
                alignment: Alignment.center,
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  Row(mainAxisSize: MainAxisSize.min, children: [dot(), dot()]),
                  Row(mainAxisSize: MainAxisSize.min, children: [dot(), dot()]),
                ]),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
/// Floating red-packet envelope while there is a packet I haven't grabbed.
class _RedPacketButton extends ConsumerWidget {
  const _RedPacketButton({required this.room});
  final Room room;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final meId = ref.watch(sessionProvider.select((u) => u?.id));
    final packets = ref.watch(roomProvider(room).select((s) => s.redPackets));
    final packet = packets.where((p) => !p.empty && !p.grabbed.containsKey(meId)).lastOrNull;
    if (packet == null) return const SizedBox.shrink();
    return Positioned(
      right: 10,
      bottom: MediaQuery.paddingOf(context).bottom + 64,
      child: Semantics(
        button: true,
        excludeSemantics: true,
        label: 'Open red packet',
        child: GestureDetector(
          onTap: () => showGrabRedPacket(context, ref, room, packet),
          child: Container(
            width: 44,
            height: 54,
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [Color(0xFFEF4444), Color(0xFF991B1B)], begin: Alignment.topCenter, end: Alignment.bottomCenter),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: YoloColors.gold, width: 1.5),
              boxShadow: [BoxShadow(color: const Color(0xFFEF4444).withValues(alpha: 0.6), blurRadius: 16)],
            ),
            child: const Icon(Icons.mail_rounded, color: YoloColors.goldLight),
          ),
        ).animate(onPlay: (c) => c.repeat(reverse: true)).moveY(begin: 0, end: -6, duration: 700.ms),
      ),
    );
  }
}

class _GiftLayer extends ConsumerWidget {
  const _GiftLayer({required this.room});
  final Room room;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final gift = ref.watch(roomProvider(room).select((s) => s.lastGift));
    return gift == null ? const SizedBox.shrink() : _GiftOverlay(key: ValueKey(gift.serial), event: gift);
  }
}

class _SeatTile extends StatelessWidget {
  const _SeatTile(
      {required this.seat, required this.isMe, required this.role, required this.fx, required this.size, required this.accent, required this.panel, required this.onTap});
  final Seat seat;
  final bool isMe;
  final String role;
  final SeatFx? fx;
  final double size;
  final Color accent;
  final Color panel;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final user = seat.user;
    return Semantics(
      button: true,
      excludeSemantics: true,
      label: user == null ? (seat.locked ? 'Locked seat ${seat.index + 1}' : 'Take seat ${seat.index + 1}') : user.name,
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Stack(clipBehavior: Clip.none, alignment: Alignment.center, children: [
            AnimatedSwitcher(
              duration: 300.ms,
              transitionBuilder: (c, a) => ScaleTransition(scale: CurvedAnimation(parent: a, curve: Curves.easeOutBack), child: c),
              child: user != null
                  ? YoloAvatar(key: ValueKey(user.id), user: user, size: size, speaking: seat.speaking, goldFrame: isMe, ringColor: accent)
                  : Container(
                      key: ValueKey('empty-${seat.index}-${seat.locked}'),
                      width: size,
                      height: size,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: panel,
                        border: Border.all(color: seat.locked ? Colors.transparent : accent.withValues(alpha: 0.6), width: 1.5),
                      ),
                      child: Icon(seat.locked ? Icons.lock_outline_rounded : Icons.add_rounded, color: seat.locked ? Colors.white70 : accent, size: size * 0.42),
                    ),
            ),
            if (user != null && seat.muted)
              Positioned(
                right: -2,
                bottom: -2,
                child: Container(
                  padding: const EdgeInsets.all(3),
                  decoration: const BoxDecoration(color: Color(0xFFEF4444), shape: BoxShape.circle),
                  child: const Icon(Icons.mic_off_rounded, size: 12, color: Colors.white),
                ),
              ),
            if (user != null && role != 'Guest' && role != 'Member')
              Positioned(left: -2, top: -2, child: CircleAvatar(radius: 10, backgroundColor: roleColor(role), child: Icon(roleIcon(role), size: 12, color: Colors.white))),
            if (fx != null)
              Positioned(
                top: -14,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(color: const Color(0xEE1A1233), borderRadius: BorderRadius.circular(12), border: Border.all(color: accent)),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    Icon(
                      switch (fx!.kind) {
                        'dice' => Icons.casino_rounded,
                        'rps' => Icons.back_hand_rounded,
                        'coin' => Icons.toll_rounded,
                        'lottery' => Icons.confirmation_number_rounded,
                        'light' => Icons.flare_rounded,
                        _ => Icons.emoji_emotions_rounded,
                      },
                      size: 14,
                      color: accent,
                    ),
                    const SizedBox(width: 3),
                    Text(fx!.label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800)),
                  ]),
                )
                    .animate(key: ValueKey(fx!.serial))
                    .scale(begin: const Offset(0.3, 0.3), curve: Curves.elasticOut, duration: 600.ms)
                    .then(delay: 2500.ms)
                    .fadeOut(duration: 400.ms),
              ),
          ]),
          const SizedBox(height: 4),
          Text(
            user?.name ?? (seat.locked ? '' : '${seat.index + 1}'),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(fontSize: 11, fontWeight: user != null ? FontWeight.w600 : FontWeight.w500, color: user != null ? (isMe ? accent : YoloColors.text) : YoloColors.textMuted),
          ),
        ]),
      ),
    );
  }
}

/// Big gift animation: glow burst, icon pop and banner, then fades out.
class _GiftOverlay extends StatelessWidget {
  const _GiftOverlay({super.key, required this.event});
  final GiftEvent event;

  @override
  Widget build(BuildContext context) {
    final big = event.gift.fullScreen;
    final look = RoomLookScope.of(context);
    return IgnorePointer(
      child: Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Stack(alignment: Alignment.center, children: [
            Container(
              width: big ? 240 : 150,
              height: big ? 240 : 150,
              decoration: BoxDecoration(shape: BoxShape.circle, gradient: RadialGradient(colors: [event.gift.tint.withValues(alpha: 0.6), event.gift.tint.withValues(alpha: 0)])),
            ).animate().scale(begin: const Offset(0.2, 0.2), duration: 500.ms, curve: Curves.easeOut),
            Icon(event.gift.icon, size: big ? 120 : 72, color: event.gift.tint)
                .animate()
                .scale(begin: const Offset(0, 0), duration: 600.ms, curve: Curves.elasticOut)
                .then(delay: 300.ms)
                .shake(hz: 3, rotation: 0.05, duration: 600.ms),
          ]),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              gradient: LinearGradient(colors: [look.accent.withValues(alpha: 0.35), look.accent.withValues(alpha: 0.08)]),
            ),
            child: Text('${event.from} sent ${event.gift.name} ×${event.qty} to ${event.to}',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Color.lerp(look.accent, Colors.white, 0.5))),
          ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.5, end: 0),
        ]),
      ).animate().fadeOut(delay: 2600.ms, duration: 400.ms),
    );
  }
}
