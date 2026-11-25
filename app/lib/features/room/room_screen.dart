import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../core/theme.dart';
import '../../data/models.dart';
import '../../data/providers.dart';
import '../../widgets/common.dart';
import '../../widgets/page_kit.dart';
import 'gift_sheet.dart';
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
  bool _following = false;

  Room get room => widget.room;
  RoomController get ctrl => ref.read(roomProvider(room).notifier);

  @override
  void dispose() {
    _input.dispose();
    _scroll.dispose();
    super.dispose();
  }

  void _send() {
    ctrl.sendChat(_input.text);
    _input.clear();
  }

  void _scrollToEnd() => WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scroll.hasClients) _scroll.animateTo(_scroll.position.maxScrollExtent, duration: 250.ms, curve: Curves.easeOut);
      });

  void _toast(String msg) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(
        content: Text(msg),
        behavior: SnackBarBehavior.floating,
        // Keep the toast above the input bar so it never covers the gift button.
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 90),
        backgroundColor: YoloColors.surface,
        duration: const Duration(seconds: 1),
      ));
  }

  void _seatTapped(Seat seat) {
    final meId = ref.read(sessionProvider)?.id;
    if (seat.isEmpty && !ctrl.canManage) {
      final msg = ctrl.takeSeat(seat.index);
      _toast(msg.isEmpty ? 'You are on mic' : msg);
      return;
    }
    if (!seat.isEmpty && seat.user!.id != meId && !ctrl.canManage) {
      _openGifts(seat.user);
      return;
    }
    showSeatActions(context, ref, room, seat, onGift: () => _openGifts(seat.user));
  }

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
                  context.pop();
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
                  context.pop();
                },
              ),
            ),
          ]),
        ]),
      ),
    );
  }

  void _more() {
    final manage = ctrl.canManage;
    showRoomSheet<void>(
      context,
      (c) {
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
                  child: Column(children: [
                    TintIcon(icon, color: color, size: 48),
                    const SizedBox(height: 6),
                    Text(label, textAlign: TextAlign.center, style: const TextStyle(fontSize: 12)),
                  ]),
                ),
              ),
            );
        return Padding(
          padding: const EdgeInsets.all(16),
          child: Wrap(spacing: 4, runSpacing: 8, children: [
            if (manage) item(Icons.tune_rounded, 'Settings', () => showRoomSettings(context, ref, room), color: YoloColors.gold),
            if (manage) item(Icons.library_music_rounded, 'Music', () => showMusicSheet(context, ref, room), color: const Color(0xFFF9A8D4)),
            item(Icons.people_alt_rounded, 'Members', () => showMembersSheet(context, ref, room), color: const Color(0xFF7DD3FC)),
            item(Icons.person_add_alt_1_rounded, 'Invite', () => showInviteSheet(context, ref, room), color: const Color(0xFF86EFAC)),
            item(Icons.leaderboard_rounded, 'Ranking', () => showRankingSheet(context, ref, room), color: const Color(0xFFFDE68A)),
            item(Icons.info_outline_rounded, 'Details', () => showRoomDetails(context, ref, room), color: const Color(0xFFC4B5FD)),
            item(Icons.flag_rounded, 'Report', () => showReportSheet(context, 'room'), color: const Color(0xFFF87171)),
            item(Icons.logout_rounded, 'Exit', _exit),
          ]),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(roomProvider(room));
    final meId = ref.watch(sessionProvider)?.id;
    ref.watch(giftsProvider); // preload gifts so the gift panel opens instantly
    final onMic = state.seats.any((s) => s.user?.id == meId);
    final theme = RoomState.themes[state.theme];

    ref.listen(roomProvider(room).select((s) => s.messages.length), (_, _) => _scrollToEnd());

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _exit();
      },
      child: Scaffold(
        resizeToAvoidBottomInset: true,
        body: AnimatedContainer(
          duration: 500.ms,
          decoration: BoxDecoration(
            gradient: RadialGradient(center: const Alignment(0, -1.1), radius: 1.3, colors: [theme[0], theme[1], YoloColors.bg], stops: const [0, 0.55, 1]),
          ),
          child: Stack(children: [
            SafeArea(
              child: Column(children: [
                // Header
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 8, 8, 8),
                  child: Row(children: [
                    GlassIconButton(icon: Icons.arrow_back_ios_new_rounded, label: 'Back', onTap: _exit),
                    const SizedBox(width: 10),
                    Expanded(
                      child: InkWell(
                        borderRadius: BorderRadius.circular(12),
                        onTap: () => showRoomDetails(context, ref, room),
                        child: Row(children: [
                          Hero(
                            tag: 'room-${room.id}',
                            child: Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(borderRadius: BorderRadius.circular(12), gradient: LinearGradient(colors: room.cover)),
                              alignment: Alignment.center,
                              child: Text(state.name[0], style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                              Row(children: [
                                if (state.password.isNotEmpty) const Padding(padding: EdgeInsets.only(right: 4), child: Icon(Icons.lock_rounded, size: 14, color: YoloColors.gold)),
                                Flexible(child: Text(state.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800))),
                              ]),
                              Text('ID ${room.id} · ${room.online} online', style: const TextStyle(fontSize: 11, color: Color(0xFFC4B8E6))),
                            ]),
                          ),
                        ]),
                      ),
                    ),
                    if (room.owner.id != meId)
                      AnimatedSwitcher(
                        duration: 200.ms,
                        child: _following
                            ? TextButton(key: const ValueKey('f'), onPressed: () => setState(() => _following = false), child: const Text('Following'))
                            : GoldButton(key: const ValueKey('nf'), label: 'Follow', height: 34, onPressed: () => setState(() => _following = true)),
                      ),
                    IconButton(tooltip: 'Room menu', icon: const Icon(Icons.more_horiz_rounded), onPressed: _more),
                  ]),
                ),
                // Announcement + music chip
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(children: [
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.06), borderRadius: BorderRadius.circular(12)),
                        child: Text(state.announcement.isEmpty ? 'Welcome to ${state.name}!' : state.announcement,
                            maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12, color: YoloColors.textSoft)),
                      ),
                    ),
                    if (state.track != null) ...[
                      const SizedBox(width: 8),
                      InkWell(
                        borderRadius: BorderRadius.circular(16),
                        onTap: () => showMusicSheet(context, ref, room),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                          decoration: BoxDecoration(color: YoloColors.gold.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(16)),
                          child: Row(children: [
                            Icon(state.musicPlaying ? Icons.graphic_eq_rounded : Icons.music_off_rounded, size: 16, color: YoloColors.gold)
                                .animate(target: state.musicPlaying ? 1 : 0, onPlay: (c) => c.repeat(reverse: true))
                                .scaleY(begin: 1, end: 0.6, duration: 400.ms),
                            const SizedBox(width: 4),
                            ConstrainedBox(
                              constraints: const BoxConstraints(maxWidth: 80),
                              child: Text(RoomState.tracks[state.track!], maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 11, color: YoloColors.gold)),
                            ),
                          ]),
                        ),
                      ),
                    ],
                  ]),
                ),
                // Host seat
                Padding(
                  padding: const EdgeInsets.only(top: 14, bottom: 6),
                  child: Column(children: [
                    YoloAvatar(user: room.owner, size: 80, goldFrame: true, speaking: true),
                    const SizedBox(height: 6),
                    Row(mainAxisSize: MainAxisSize.min, children: [
                      Text(room.owner.name, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
                      const SizedBox(width: 6),
                      const Badge2('HOST', bg: YoloColors.gold, fg: YoloColors.onGold),
                    ]),
                  ]),
                ),
                // Mic seats
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  child: GridView.count(
                    crossAxisCount: 4,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    mainAxisSpacing: 4,
                    childAspectRatio: state.seats.length > 8 ? 0.95 : 0.82,
                    children: [
                      for (final s in state.seats)
                        _SeatTile(
                          seat: s,
                          isMe: s.user?.id == meId,
                          isAdmin: s.user != null && state.admins.contains(s.user!.id),
                          compact: state.seats.length > 8,
                          onTap: () => _seatTapped(s),
                        ),
                    ],
                  ),
                ),
                // Chat
                Expanded(
                  child: ShaderMask(
                    shaderCallback: (r) => const LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Colors.transparent, Colors.black],
                      stops: [0, 0.12],
                    ).createShader(r),
                    blendMode: BlendMode.dstIn,
                    child: ListView.builder(
                      controller: _scroll,
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                      itemCount: state.messages.length,
                      itemBuilder: (_, i) => _MessageBubble(msg: state.messages[i]).animate(key: ValueKey(i)).fadeIn(duration: 250.ms).slideX(begin: -0.08, end: 0),
                    ),
                  ),
                ),
                // Input bar
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 6, 12, 10),
                  child: Row(children: [
                    Expanded(
                      child: TextField(
                        controller: _input,
                        onSubmitted: (_) => _send(),
                        textInputAction: TextInputAction.send,
                        decoration: InputDecoration(
                          hintText: 'Say hi...',
                          hintStyle: const TextStyle(color: YoloColors.textMuted),
                          filled: true,
                          fillColor: Colors.white.withValues(alpha: 0.08),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(24), borderSide: BorderSide.none),
                          suffixIcon: IconButton(tooltip: 'Send', icon: const Icon(Icons.send_rounded, color: YoloColors.gold), onPressed: _send),
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    GlassIconButton(
                      size: 42,
                      icon: state.speakerOn ? Icons.volume_up_rounded : Icons.volume_off_rounded,
                      label: state.speakerOn ? 'Mute speaker' : 'Unmute speaker',
                      onTap: ctrl.toggleSpeaker,
                    ),
                    if (onMic) ...[
                      const SizedBox(width: 6),
                      GlassIconButton(
                        size: 42,
                        icon: state.micOn ? Icons.mic_rounded : Icons.mic_off_rounded,
                        label: state.micOn ? 'Mute microphone' : 'Unmute microphone',
                        onTap: ctrl.toggleMic,
                      ),
                    ],
                    const SizedBox(width: 6),
                    GlassIconButton(size: 42, icon: Icons.sports_esports_rounded, label: 'Room games', onTap: () => _toast('Room games are coming later')),
                    const SizedBox(width: 6),
                    Semantics(
                      button: true,
                      label: 'Send gift',
                      child: GestureDetector(
                        onTap: _openGifts,
                        child: Container(
                          width: 46,
                          height: 46,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: YoloColors.goldGradient,
                            boxShadow: [BoxShadow(color: YoloColors.gold.withValues(alpha: 0.45), blurRadius: 20, offset: const Offset(0, 6))],
                          ),
                          child: const Icon(Icons.card_giftcard_rounded, color: YoloColors.onGold),
                        ),
                      ).animate(onPlay: (c) => c.repeat(reverse: true)).rotate(begin: -0.02, end: 0.02, duration: 900.ms),
                    ),
                  ]),
                ),
              ]),
            ),
            if (state.lastGift != null) _GiftOverlay(key: ValueKey(state.lastGift!.serial), event: state.lastGift!),
          ]),
        ),
      ),
    );
  }
}

class _SeatTile extends StatelessWidget {
  const _SeatTile({required this.seat, required this.isMe, required this.isAdmin, required this.compact, required this.onTap});
  final Seat seat;
  final bool isMe;
  final bool isAdmin;
  final bool compact;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final user = seat.user;
    final size = compact ? 50.0 : 60.0;
    return Semantics(
      button: true,
      excludeSemantics: true,
      label: user == null ? (seat.locked ? 'Locked seat ${seat.index + 1}' : 'Take seat ${seat.index + 1}') : user.name,
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Column(children: [
          Stack(clipBehavior: Clip.none, children: [
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
                        border: Border.all(color: const Color(0x73C4B8E6), width: 1.5),
                      ),
                      child: Icon(seat.locked ? Icons.lock_rounded : Icons.add_rounded, color: const Color(0xFFC4B8E6), size: 22),
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
            if (isAdmin)
              Positioned(
                left: -2,
                top: -2,
                child: Container(
                  padding: const EdgeInsets.all(3),
                  decoration: const BoxDecoration(color: Color(0xFF6366F1), shape: BoxShape.circle),
                  child: const Icon(Icons.shield_rounded, size: 11, color: Colors.white),
                ),
              ),
          ]),
          const SizedBox(height: 5),
          Text(
            user?.name ?? (seat.locked ? 'Locked' : '${seat.index + 1}'),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 11,
              fontWeight: user != null ? FontWeight.w600 : FontWeight.w500,
              color: user != null ? (isMe ? YoloColors.gold : YoloColors.text) : YoloColors.textMuted,
            ),
          ),
        ]),
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  const _MessageBubble({required this.msg});
  final RoomMessage msg;

  @override
  Widget build(BuildContext context) {
    final Widget child;
    final BoxDecoration deco;
    switch (msg.kind) {
      case MessageKind.system:
        child = Text(msg.text, style: const TextStyle(fontSize: 12, color: YoloColors.textMuted));
        deco = const BoxDecoration();
      case MessageKind.gift:
        child = Text(msg.text, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFFFDE7A8)));
        deco = BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          gradient: LinearGradient(colors: [YoloColors.gold.withValues(alpha: 0.28), YoloColors.gold.withValues(alpha: 0.06)]),
        );
      case MessageKind.chat:
        child = Text.rich(
            TextSpan(children: [
              TextSpan(text: '${msg.sender}: ', style: TextStyle(fontWeight: FontWeight.w700, color: msg.color)),
              TextSpan(text: msg.text),
            ]),
            style: const TextStyle(fontSize: 13, height: 1.4));
        deco = BoxDecoration(color: YoloColors.bg.withValues(alpha: 0.55), borderRadius: BorderRadius.circular(14));
    }
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        constraints: const BoxConstraints(maxWidth: 300),
        padding: msg.kind == MessageKind.system ? EdgeInsets.zero : const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: deco,
        child: child,
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
    return IgnorePointer(
      child: Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Stack(alignment: Alignment.center, children: [
            Container(
              width: big ? 240 : 150,
              height: big ? 240 : 150,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(colors: [event.gift.tint.withValues(alpha: 0.6), event.gift.tint.withValues(alpha: 0)]),
              ),
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
            child: Text('${event.from} sent ${event.gift.name} ×${event.qty} to ${event.to}',
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Color(0xFFFDE7A8))),
          ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.5, end: 0),
        ]),
      ).animate().fadeOut(delay: 2600.ms, duration: 400.ms),
    );
  }
}
