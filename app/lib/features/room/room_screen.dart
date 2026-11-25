import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../core/theme.dart';
import '../../data/models.dart';
import '../../data/providers.dart';
import '../../data/room_levels.dart';
import '../../data/social_providers.dart';
import '../../widgets/common.dart';
import '../../widgets/page_kit.dart';
import 'gift_sheet.dart';
import 'floating_room.dart';
import 'room_background.dart';
import 'room_panels.dart';
import 'room_sheets.dart';

class RoomScreen extends ConsumerStatefulWidget {
  const RoomScreen({super.key, required this.room});
  final Room room;

  @override
  ConsumerState<RoomScreen> createState() => _RoomScreenState();
}

class _RoomScreenState extends ConsumerState<RoomScreen> {
  final _input = TextEditingController();
  final _scroll = ScrollController();

  /// The live room instance (reused when restoring a minimized room, so nothing reloads).
  late final Room room;
  late final RoomScreenOpen _openCounter;
  RoomController get ctrl => ref.read(roomProvider(room).notifier);

  @override
  void initState() {
    super.initState();
    final active = ref.read(activeRoomProvider.notifier);
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
    _scroll.dispose();
    super.dispose();
  }

  /// Back / swipe / Minimize: leave the screen but stay in the room (floating mini room appears).
  void _minimize() => context.pop();

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

  void _scrollToEnd() => WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scroll.hasClients) _scroll.animateTo(_scroll.position.maxScrollExtent, duration: 250.ms, curve: Curves.easeOut);
      });

  void _toast(String msg) => showYoloToast(context, msg);

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

  void _exit() {
    showRoomSheet<void>(
      context,
      (c) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Text('Leave the room?', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
          const SizedBox(height: 16),
          Row(children: [
            Expanded(
              child: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(50), shape: const StadiumBorder()),
                onPressed: () {
                  Navigator.pop(c);
                  _minimize();
                },
                icon: const Icon(Icons.picture_in_picture_alt_rounded),
                label: const Text('Minimize'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: GoldButton(
                label: 'Exit room',
                height: 50,
                onPressed: () {
                  ctrl.leaveSeat();
                  Navigator.pop(c);
                  ref.read(activeRoomProvider.notifier).exit();
                  context.pop();
                },
              ),
            ),
          ]),
        ]),
      ),
    );
  }

  /// Toolbox: room tools.
  void _tools() {
    showRoomSheet<void>(context, (c) {
      Widget item(IconData icon, String label, Color color, VoidCallback onTap) => SizedBox(
            width: 80,
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: () {
                Navigator.pop(c);
                onTap();
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Column(children: [TintIcon(icon, color: color, size: 48), const SizedBox(height: 6), Text(label, textAlign: TextAlign.center, style: const TextStyle(fontSize: 12))]),
              ),
            ),
          );
      return Padding(
        padding: const EdgeInsets.all(16),
        child: Wrap(spacing: 4, runSpacing: 8, children: [
          item(Icons.mail_rounded, 'Red packet', const Color(0xFFEF4444), () => showRedPacketSheet(context, ref, room)),
          item(Icons.library_music_rounded, 'Music', const Color(0xFFF9A8D4), () => ctrl.canManage ? showMusicSheet(context, ref, room) : _toast('Only admins can play room music')),
        ]),
      );
    });
  }

  void _more() {
    final manage = ctrl.canManage;
    showRoomSheet<void>(context, (c) {
      Widget item(IconData icon, String label, VoidCallback onTap, {Color color = YoloColors.textSoft}) => SizedBox(
            width: 80,
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: () {
                Navigator.pop(c);
                onTap();
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Column(children: [TintIcon(icon, color: color, size: 48), const SizedBox(height: 6), Text(label, textAlign: TextAlign.center, style: const TextStyle(fontSize: 12))]),
              ),
            ),
          );
      return Padding(
        padding: const EdgeInsets.all(16),
        child: Wrap(spacing: 4, runSpacing: 8, children: [
          item(Icons.picture_in_picture_alt_rounded, 'Minimize', _minimize, color: const Color(0xFF86EFAC)),
          if (manage) item(Icons.tune_rounded, 'Settings', () => context.push('/room/settings', extra: room), color: YoloColors.gold),
          item(Icons.info_outline_rounded, 'Room info', () => showRoomInfoSheet(context, ref, room), color: const Color(0xFFC4B5FD)),
          item(Icons.workspace_premium_rounded, 'Room level', () => context.push('/room/level', extra: room), color: const Color(0xFFC084FC)),
          item(Icons.people_alt_rounded, 'Members', () => showMembersSheet(context, ref, room), color: const Color(0xFF7DD3FC)),
          item(Icons.person_add_alt_1_rounded, 'Invite', () => showInviteSheet(context, ref, room), color: const Color(0xFF86EFAC)),
          item(Icons.leaderboard_rounded, 'Ranking', () => showMembersSheet(context, ref, room, tab: 2), color: const Color(0xFFFDE68A)),
          item(Icons.flag_rounded, 'Report', () => showReportSheet(context, 'room'), color: const Color(0xFFF87171)),
          item(Icons.logout_rounded, 'Exit', _exit),
        ]),
      );
    });
  }

  void _group(RoomState st) {
    final g = ref.read(groupsProvider).where((x) => x.id == st.groupId).firstOrNull;
    if (g != null) {
      context.push('/chat', extra: g);
    } else {
      _toast(ctrl.canManage ? 'Link a group in Room settings → Associated group' : 'This room has no group yet');
    }
  }

  @override
  Widget build(BuildContext context) {
    final st = ref.watch(roomProvider(room));
    final me = ref.watch(sessionProvider);
    final meId = me?.id;
    ref.watch(giftsProvider); // preload gifts so the gift panel opens instantly
    final onMic = st.seats.any((s) => s.user?.id == meId);
    final lvl = levelForExp(st.exp);
    final intimacy = st.mode == 'intimacy';
    final gridSeats = intimacy ? st.seats.skip(1).toList() : st.seats;
    final packet = st.redPackets.where((p) => !p.empty && !p.grabbed.containsKey(meId)).lastOrNull;
    final boxReady = [
      for (var i = 0; i < treasureMinutes.length; i++)
        if (!st.claimedBoxes.contains(i) && ctrl.treasureProgress >= treasureMinutes[i] * 60 && (!treasureVipOnly.contains(i) || (me?.vipLevel ?? 0) > 0)) i,
    ].isNotEmpty;
    final chatLocked = st.banText && !ctrl.canManage;

    ref.listen(roomProvider(room).select((s) => s.messages.length), (_, _) => _scrollToEnd());

    Widget seatTile(Seat s, {double? size}) => _SeatTile(
          seat: s,
          isMe: s.user?.id == meId,
          role: s.user == null ? 'Guest' : ctrl.roleOf(s.user!.id),
          fx: s.user == null ? null : st.seatFx[s.user!.id],
          size: size ?? (st.seats.length > 8 ? 50 : 58),
          onTap: () => _seatTapped(s),
        );

    // System back / swipe pops this screen; the room stays live and the floating mini room appears.
    return Scaffold(
        resizeToAvoidBottomInset: true,
        body: AnimatedRoomBackground(
          theme: st.theme,
          child: Stack(children: [
            SafeArea(
              child: Column(children: [
                // Header: room image · name / Room ID / Level · top gifters · online · menu
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 6, 4, 0),
                  child: Row(children: [
                    Expanded(
                      child: Semantics(
                        button: true,
                        excludeSemantics: true,
                        label: 'Room details',
                        child: GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTap: () => showRoomInfoSheet(context, ref, room),
                          child: Row(children: [
                            Container(
                              padding: const EdgeInsets.all(1.5),
                              decoration: BoxDecoration(borderRadius: BorderRadius.circular(13), border: Border.all(color: YoloColors.gold.withValues(alpha: 0.7))),
                              child: RoomCover(room: room, name: st.name, coverPath: st.coverPath, size: 46, radius: 12),
                            ),
                            const SizedBox(width: 8),
                            Flexible(
                              child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
                                Row(mainAxisSize: MainAxisSize.min, children: [
                                  if (st.password.isNotEmpty) const Padding(padding: EdgeInsets.only(right: 4), child: Icon(Icons.lock_rounded, size: 12, color: YoloColors.gold)),
                                  Flexible(child: Text(st.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, height: 1.2))),
                                ]),
                                const SizedBox(height: 3),
                                Row(mainAxisSize: MainAxisSize.min, children: [
                                  Container(
                                    padding: const EdgeInsets.fromLTRB(2, 1, 6, 1),
                                    decoration: BoxDecoration(color: roomLevelColors(lvl.level).first.withValues(alpha: 0.18), borderRadius: BorderRadius.circular(8)),
                                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                                      RoomLevelBadge(lvl.level, size: 13),
                                      const SizedBox(width: 3),
                                      Text('Level ${lvl.level}', style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.w800, color: roomLevelColors(lvl.level).first)),
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
                    const SizedBox(width: 6),
                    _TopGifters(rows: ctrl.topGifters(), onTap: () => showMembersSheet(context, ref, room, tab: 2)),
                    const SizedBox(width: 6),
                    Semantics(
                      button: true,
                      excludeSemantics: true,
                      label: 'Online users',
                      child: GestureDetector(
                        behavior: HitTestBehavior.opaque, // whole area is tappable, including gaps
                        onTap: () => showMembersSheet(context, ref, room),
                        child: Container(
                          height: 26,
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          decoration: BoxDecoration(color: Colors.black26, borderRadius: BorderRadius.circular(13)),
                          child: Row(mainAxisSize: MainAxisSize.min, children: [
                            const Icon(Icons.people_alt_rounded, size: 13, color: YoloColors.online),
                            const SizedBox(width: 3),
                            Text(compactCount(st.onlineCount), style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800)),
                          ]),
                        ),
                      ),
                    ),
                    IconButton(tooltip: 'Room menu', visualDensity: VisualDensity.compact, icon: const Icon(Icons.more_horiz_rounded), onPressed: _more),
                  ]),
                ),
                // Group chat link (compact)
                Align(
                  alignment: Alignment.centerLeft,
                  child: Padding(
                    padding: const EdgeInsets.only(left: 12, top: 6),
                    child: Semantics(
                      button: true,
                      excludeSemantics: true,
                      label: 'Room group',
                      child: GestureDetector(
                        onTap: () => _group(st),
                        child: Container(
                          height: 22,
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          decoration: BoxDecoration(color: Colors.black26, borderRadius: BorderRadius.circular(11)),
                          child: const Row(mainAxisSize: MainAxisSize.min, children: [
                            Icon(Icons.forum_rounded, size: 12, color: YoloColors.textSoft),
                            SizedBox(width: 4),
                            Text('Group', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
                          ]),
                        ),
                      ),
                    ),
                  ),
                ),
                // Host (+ partner seat in intimacy mode)
                Padding(
                  padding: const EdgeInsets.only(top: 4, bottom: 6),
                  child: Row(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.start, children: [
                    GestureDetector(
                      onTap: () => _userCard(room.owner),
                      child: Column(children: [
                        YoloAvatar(user: room.owner, size: 76, goldFrame: true, speaking: true),
                        const SizedBox(height: 4),
                        Row(mainAxisSize: MainAxisSize.min, children: [
                          Text(room.owner.name, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800)),
                          const SizedBox(width: 6),
                          const Badge2('HOST', bg: YoloColors.gold, fg: YoloColors.onGold),
                        ]),
                      ]),
                    ),
                    if (intimacy) ...[
                      const Padding(padding: EdgeInsets.only(top: 26, left: 6, right: 6), child: HeartbeatLine()),
                      Column(children: [
                        seatTile(st.seats.first, size: 76),
                        const Text('Partner', style: TextStyle(fontSize: 10, color: Color(0xFFF9A8D4), fontWeight: FontWeight.w800)),
                      ]),
                    ],
                  ]),
                ),
                // Mic seats
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: GridView.count(
                    crossAxisCount: 4,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    mainAxisSpacing: 2,
                    childAspectRatio: gridSeats.length > 8 ? 0.95 : 0.84,
                    children: [for (final s in gridSeats) seatTile(s)],
                  ),
                ),
                // Announcement
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
                  child: InkWell(
                    onTap: () => showRoomInfoSheet(context, ref, room),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                      decoration: BoxDecoration(color: Colors.black26, borderRadius: BorderRadius.circular(12)),
                      child: Text.rich(
                        TextSpan(children: [
                          const WidgetSpan(alignment: PlaceholderAlignment.middle, child: Icon(Icons.campaign_rounded, size: 16, color: YoloColors.gold)),
                          const TextSpan(text: ' Announcement: ', style: TextStyle(color: YoloColors.gold, fontWeight: FontWeight.w700)),
                          TextSpan(text: st.announcement.isEmpty ? 'Welcome to ${st.name}!' : st.announcement),
                        ]),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 12, color: YoloColors.textSoft),
                      ),
                    ),
                  ),
                ),
                // Chat
                Expanded(
                  child: ShaderMask(
                    shaderCallback: (r) => const LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Colors.transparent, Colors.black],
                      stops: [0, 0.08],
                    ).createShader(r),
                    blendMode: BlendMode.dstIn,
                    child: ListView.builder(
                      controller: _scroll,
                      padding: const EdgeInsets.fromLTRB(16, 10, 70, 8),
                      itemCount: st.messages.length,
                      itemBuilder: (_, i) {
                        final m = st.messages[i];
                        final u = m.senderId == 0 ? null : roomUser(ref, m.senderId);
                        return _MessageBubble(
                          msg: m,
                          user: u,
                          role: u == null ? 'Guest' : ctrl.roleOf(u.id),
                          member: u != null && st.members.contains(u.id),
                          roomName: st.name,
                          onUser: u == null ? null : () => _userCard(u),
                        ).animate(key: ValueKey(i)).fadeIn(duration: 250.ms).slideX(begin: -0.06, end: 0);
                      },
                    ),
                  ),
                ),
                // Bottom bar
                Padding(
                  padding: const EdgeInsets.fromLTRB(8, 6, 8, 8),
                  child: Row(children: [
                    GlassIconButton(
                      size: 40,
                      icon: st.speakerOn ? Icons.volume_up_rounded : Icons.volume_off_rounded,
                      label: st.speakerOn ? 'Mute speaker' : 'Unmute speaker',
                      onTap: ctrl.toggleSpeaker,
                    ),
                    const SizedBox(width: 6),
                    GlassIconButton(
                      size: 40,
                      icon: onMic && st.micOn ? Icons.mic_rounded : Icons.mic_off_rounded,
                      label: onMic ? (st.micOn ? 'Mute microphone' : 'Unmute microphone') : 'Take a seat to talk',
                      onTap: () {
                        if (onMic) {
                          ctrl.toggleMic();
                        } else {
                          final msg = ctrl.takeAnySeat();
                          _toast(msg.isEmpty ? 'You are on mic' : msg);
                        }
                      },
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: TextField(
                        controller: _input,
                        enabled: !chatLocked,
                        onSubmitted: (_) => _send(),
                        textInputAction: TextInputAction.send,
                        decoration: InputDecoration(
                          hintText: chatLocked ? 'Chat is off' : 'Type...',
                          hintStyle: const TextStyle(color: YoloColors.textMuted),
                          isDense: true,
                          filled: true,
                          fillColor: Colors.white.withValues(alpha: 0.08),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(24), borderSide: BorderSide.none),
                          suffixIcon: chatLocked
                              ? null
                              : IconButton(tooltip: 'Send', icon: const Icon(Icons.send_rounded, color: YoloColors.gold, size: 20), onPressed: _send),
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    GlassIconButton(size: 40, icon: Icons.emoji_emotions_rounded, label: 'Interactions', onTap: () => showInteractionPanel(context, ref, room)),
                    const SizedBox(width: 6),
                    Semantics(
                      button: true,
                      excludeSemantics: true,
                      label: 'Send gift',
                      child: GestureDetector(
                        onTap: _openGifts,
                        child: Container(
                          width: 42,
                          height: 42,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: const LinearGradient(colors: [Color(0xFFF9A8D4), Color(0xFFF43F5E)]),
                            boxShadow: [BoxShadow(color: const Color(0xFFF43F5E).withValues(alpha: 0.45), blurRadius: 16)],
                          ),
                          child: const Icon(Icons.card_giftcard_rounded, color: Colors.white, size: 22),
                        ),
                      ).animate(onPlay: (c) => c.repeat(reverse: true)).rotate(begin: -0.03, end: 0.03, duration: 900.ms),
                    ),
                    const SizedBox(width: 6),
                    GlassIconButton(size: 40, icon: Icons.work_outline_rounded, label: 'Room tools', onTap: _tools),
                  ]),
                ),
              ]),
            ),
            // Entry banner / now playing pill (top right)
            Positioned(
              top: MediaQuery.paddingOf(context).top + 92,
              right: 0,
              child: AnimatedSwitcher(
                duration: 400.ms,
                transitionBuilder: (c, a) => SlideTransition(position: Tween(begin: const Offset(1, 0), end: Offset.zero).animate(a), child: c),
                child: st.entryBanner != null
                    ? _Pill(key: const ValueKey('entry'), icon: Icons.login_rounded, text: st.entryBanner!)
                    : (st.track != null
                        ? GestureDetector(
                            key: ValueKey('music${st.track}'),
                            onTap: () => showMusicSheet(context, ref, room),
                            child: _Pill(icon: st.musicPlaying ? Icons.music_note_rounded : Icons.music_off_rounded, text: RoomState.tracks[st.track!], spin: st.musicPlaying),
                          )
                        : const SizedBox.shrink()),
              ),
            ),
            // Red packet envelope + treasure box (bottom right)
            Positioned(
              right: 10,
              bottom: MediaQuery.paddingOf(context).bottom + 70,
              child: Column(children: [
                if (packet != null)
                  Semantics(
                    button: true,
                    excludeSemantics: true,
                    label: 'Open red packet',
                    child: GestureDetector(
                      onTap: () => showGrabRedPacket(context, ref, room, packet),
                      child: Container(
                        width: 50,
                        height: 60,
                        margin: const EdgeInsets.only(bottom: 10),
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
                Semantics(
                  button: true,
                  label: 'Treasure boxes',
                  child: GestureDetector(
                    onTap: () => showTreasureSheet(context, ref, room),
                    child: Badge(
                      isLabelVisible: boxReady,
                      smallSize: 12,
                      child: Container(
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: const LinearGradient(colors: [Color(0xFF22D3EE), Color(0xFF6366F1)]),
                          boxShadow: [BoxShadow(color: const Color(0xFF22D3EE).withValues(alpha: 0.4), blurRadius: 14)],
                        ),
                        child: const Icon(Icons.redeem_rounded, color: Colors.white),
                      ),
                    ),
                  ),
                ),
              ]),
            ),
            if (st.lastGift != null) _GiftOverlay(key: ValueKey(st.lastGift!.serial), event: st.lastGift!),
          ]),
        ),
    );
  }
}

/// Top three gift senders (gold, silver, bronze), highest first.
class _TopGifters extends StatelessWidget {
  const _TopGifters({required this.rows, required this.onTap});
  final List<(YoloUser, int)> rows;
  final VoidCallback onTap;

  static const _ring = [Color(0xFFF5C451), Color(0xFFD1D5DB), Color(0xFFD97706)];

  @override
  Widget build(BuildContext context) {
    if (rows.isEmpty) return const SizedBox.shrink();
    return Semantics(
      button: true,
      excludeSemantics: true,
      label: 'Top gifters: ${rows.map((r) => r.$1.name).join(', ')}',
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          for (final (i, (u, _)) in rows.indexed)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 1.5),
              child: Stack(clipBehavior: Clip.none, alignment: Alignment.bottomCenter, children: [
                Container(
                  padding: const EdgeInsets.all(1.5),
                  decoration: BoxDecoration(shape: BoxShape.circle, color: _ring[i]),
                  child: YoloAvatar(user: u, size: 25),
                ),
                Positioned(
                  bottom: -5,
                  child: Container(
                    width: 13,
                    height: 13,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(color: _ring[i], shape: BoxShape.circle, border: Border.all(color: YoloColors.bg, width: 1)),
                    child: Text('${i + 1}', style: const TextStyle(fontSize: 8, fontWeight: FontWeight.w900, color: Color(0xFF1A1200))),
                  ),
                ),
              ]),
            ).animate(key: ValueKey('${u.id}-$i')).fadeIn(duration: 250.ms).scaleXY(begin: 0.7, end: 1),
        ]),
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({super.key, required this.icon, required this.text, this.spin = false});
  final IconData icon;
  final String text;
  final bool spin;

  @override
  Widget build(BuildContext context) {
    final i = Container(
      width: 30,
      height: 30,
      decoration: const BoxDecoration(shape: BoxShape.circle, color: Colors.black45),
      child: Icon(icon, size: 16, color: YoloColors.gold),
    );
    return Container(
      constraints: const BoxConstraints(maxWidth: 190),
      padding: const EdgeInsets.fromLTRB(4, 4, 12, 4),
      decoration: const BoxDecoration(color: Color(0x66000000), borderRadius: BorderRadius.horizontal(left: Radius.circular(20))),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        spin ? i.animate(onPlay: (c) => c.repeat()).rotate(duration: 4.seconds) : i,
        const SizedBox(width: 6),
        Flexible(child: Text(text, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600))),
      ]),
    );
  }
}

class _SeatTile extends StatelessWidget {
  const _SeatTile({required this.seat, required this.isMe, required this.role, required this.fx, required this.size, required this.onTap});
  final Seat seat;
  final bool isMe;
  final String role;
  final SeatFx? fx;
  final double size;
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
        child: Column(children: [
          Stack(clipBehavior: Clip.none, alignment: Alignment.center, children: [
            AnimatedSwitcher(
              duration: 300.ms,
              transitionBuilder: (c, a) => ScaleTransition(scale: CurvedAnimation(parent: a, curve: Curves.easeOutBack), child: c),
              child: user != null
                  ? YoloAvatar(key: ValueKey(user.id), user: user, size: size, speaking: seat.speaking, goldFrame: isMe)
                  : Container(
                      key: ValueKey('empty-${seat.index}-${seat.locked}'),
                      width: size,
                      height: size,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withValues(alpha: 0.05),
                        border: Border.all(color: seat.locked ? Colors.transparent : const Color(0x99F5C451), width: 1.5),
                      ),
                      child: Icon(seat.locked ? Icons.lock_outline_rounded : Icons.add_rounded, color: seat.locked ? Colors.white : const Color(0xFFF5C451), size: size * 0.42),
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
                  decoration: BoxDecoration(color: const Color(0xEE1A1233), borderRadius: BorderRadius.circular(12), border: Border.all(color: YoloColors.gold)),
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
                      color: YoloColors.gold,
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
            style: TextStyle(fontSize: 11, fontWeight: user != null ? FontWeight.w600 : FontWeight.w500, color: user != null ? (isMe ? YoloColors.gold : YoloColors.text) : YoloColors.textMuted),
          ),
        ]),
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  const _MessageBubble({required this.msg, required this.user, required this.role, required this.member, required this.roomName, this.onUser});
  final RoomMessage msg;
  final YoloUser? user;
  final String role;
  final bool member;
  final String roomName;
  final VoidCallback? onUser;

  @override
  Widget build(BuildContext context) {
    switch (msg.kind) {
      case MessageKind.system:
        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(color: Colors.black26, borderRadius: BorderRadius.circular(12)),
          child: Text.rich(
            TextSpan(children: [
              const WidgetSpan(alignment: PlaceholderAlignment.middle, child: Icon(Icons.notifications_rounded, size: 14, color: YoloColors.gold)),
              const TextSpan(text: ' System: ', style: TextStyle(color: YoloColors.gold, fontWeight: FontWeight.w700)),
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
              gradient: LinearGradient(colors: [YoloColors.gold.withValues(alpha: 0.28), YoloColors.gold.withValues(alpha: 0.06)]),
            ),
            child: Text(msg.text, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFFFDE7A8))),
          ),
        );
      case MessageKind.chat:
        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            GestureDetector(
              onTap: onUser,
              child: Wrap(spacing: 5, crossAxisAlignment: WrapCrossAlignment.center, children: [
                if (user != null) YoloAvatar(user: user!, size: 24),
                if (role != 'Guest' && role != 'Member') Icon(roleIcon(role), size: 14, color: roleColor(role)),
                Text(msg.sender, style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12, color: msg.color)),
                if (user != null) LevelCrown(user!.level + 7),
                if (member) MemberTitle(roomName),
              ]),
            ),
            const SizedBox(height: 4),
            Container(
              margin: const EdgeInsets.only(left: 28),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(color: YoloColors.bg.withValues(alpha: 0.55), borderRadius: BorderRadius.circular(14)),
              child: Text(msg.text, style: const TextStyle(fontSize: 13, height: 1.35)),
            ),
          ]),
        );
    }
  }
}

/// Big gift animation: glow burst, icon pop and banner, then fades out.
class _GiftOverlay extends StatelessWidget {
  const _GiftOverlay({super.key, required this.event});
  final GiftEvent event;

  @override
  Widget build(BuildContext context) {
    final big = event.gift.fullScreen;
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
              gradient: LinearGradient(colors: [YoloColors.gold.withValues(alpha: 0.35), YoloColors.gold.withValues(alpha: 0.08)]),
            ),
            child: Text('${event.from} sent ${event.gift.name} ×${event.qty} to ${event.to}', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Color(0xFFFDE7A8))),
          ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.5, end: 0),
        ]),
      ).animate().fadeOut(delay: 2600.ms, duration: 400.ms),
    );
  }
}
