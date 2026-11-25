import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../core/theme.dart';
import '../../data/models.dart';
import '../../data/providers.dart';
import '../../widgets/common.dart';
import 'gift_sheet.dart';

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

  @override
  void dispose() {
    _input.dispose();
    _scroll.dispose();
    super.dispose();
  }

  void _send() {
    ref.read(roomProvider(widget.room).notifier).sendChat(_input.text);
    _input.clear();
    _scrollToEnd();
  }

  void _scrollToEnd() => WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scroll.hasClients) {
          _scroll.animateTo(_scroll.position.maxScrollExtent, duration: 250.ms, curve: Curves.easeOut);
        }
      });

  void _seatTapped(Seat seat) {
    final ctrl = ref.read(roomProvider(widget.room).notifier);
    final meId = ref.read(sessionProvider)?.id;
    if (seat.locked) {
      _toast('This seat is locked');
    } else if (seat.isEmpty) {
      ctrl.takeSeat(seat.index);
      _toast('You are on mic');
    } else if (seat.user!.id == meId) {
      ctrl.leaveSeat();
      _toast('You left the mic');
    } else {
      _openGifts(seat.user);
    }
  }

  void _openGifts([YoloUser? target]) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black54,
      isScrollControlled: true,
      builder: (_) => GiftSheet(room: widget.room, initialTarget: target),
    );
  }

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

  @override
  Widget build(BuildContext context) {
    final room = widget.room;
    final state = ref.watch(roomProvider(room));
    final meId = ref.watch(sessionProvider)?.id;
    ref.watch(giftsProvider); // preload gifts so the gift panel opens instantly
    final onMic = state.seats.any((s) => s.user?.id == meId);

    ref.listen(roomProvider(room).select((s) => s.messages.length), (_, _) => _scrollToEnd());

    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: Container(
        decoration: const BoxDecoration(gradient: YoloColors.roomBackground),
        child: Stack(children: [
          SafeArea(
            child: Column(children: [
              // Header
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
                child: Row(children: [
                  GlassIconButton(icon: Icons.arrow_back_ios_new_rounded, label: 'Back', onTap: () => context.pop()),
                  const SizedBox(width: 10),
                  Hero(
                    tag: 'room-${room.id}',
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(borderRadius: BorderRadius.circular(12), gradient: LinearGradient(colors: room.cover)),
                      alignment: Alignment.center,
                      child: Text(room.name[0], style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(room.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800)),
                      Text('ID ${room.id} · ${room.online} online', style: const TextStyle(fontSize: 11, color: Color(0xFFC4B8E6))),
                    ]),
                  ),
                  AnimatedSwitcher(
                    duration: 200.ms,
                    child: _following
                        ? OutlinedButton(
                            key: const ValueKey('f'),
                            onPressed: () => setState(() => _following = false),
                            style: OutlinedButton.styleFrom(shape: const StadiumBorder(), foregroundColor: YoloColors.textSoft),
                            child: const Text('Following'),
                          )
                        : GoldButton(key: const ValueKey('nf'), label: 'Follow', height: 34, onPressed: () => setState(() => _following = true)),
                  ),
                ]),
              ),
              if (room.announcement.isNotEmpty)
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  width: double.infinity,
                  decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.06), borderRadius: BorderRadius.circular(12)),
                  child: Text(room.announcement, style: const TextStyle(fontSize: 12, color: YoloColors.textSoft)),
                ),
              // Host seat
              Padding(
                padding: const EdgeInsets.only(top: 16, bottom: 8),
                child: Column(children: [
                  YoloAvatar(user: room.owner, size: 84, goldFrame: true, speaking: true),
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
                  mainAxisSpacing: 8,
                  childAspectRatio: 0.82,
                  children: [for (final s in state.seats) _SeatTile(seat: s, isMe: s.user?.id == meId, onTap: () => _seatTapped(s))],
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
                    itemBuilder: (_, i) => _MessageBubble(msg: state.messages[i])
                        .animate(key: ValueKey(i))
                        .fadeIn(duration: 250.ms)
                        .slideX(begin: -0.08, end: 0),
                  ),
                ),
              ),
              // Input bar
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 6, 14, 10),
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
                        suffixIcon: IconButton(
                          tooltip: 'Send',
                          icon: const Icon(Icons.send_rounded, color: YoloColors.gold),
                          onPressed: _send,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  if (onMic) ...[
                    GlassIconButton(
                      size: 44,
                      icon: state.micOn ? Icons.mic_rounded : Icons.mic_off_rounded,
                      label: state.micOn ? 'Mute microphone' : 'Unmute microphone',
                      onTap: () => ref.read(roomProvider(room).notifier).toggleMic(),
                    ),
                    const SizedBox(width: 8),
                  ],
                  Semantics(
                    button: true,
                    label: 'Send gift',
                    child: GestureDetector(
                      onTap: _openGifts,
                      child: Container(
                        width: 48,
                        height: 48,
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
          // Full-screen gift animation overlay
          if (state.lastGift != null) _GiftOverlay(key: ValueKey(state.lastGift!.serial), event: state.lastGift!),
        ]),
      ),
    );
  }
}

class _SeatTile extends StatelessWidget {
  const _SeatTile({required this.seat, required this.isMe, required this.onTap});
  final Seat seat;
  final bool isMe;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final user = seat.user;
    return Semantics(
      button: true,
      label: user == null ? (seat.locked ? 'Locked seat' : 'Take seat ${seat.index + 1}') : user.name,
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Column(children: [
          AnimatedSwitcher(
            duration: 300.ms,
            transitionBuilder: (c, a) => ScaleTransition(scale: CurvedAnimation(parent: a, curve: Curves.easeOutBack), child: c),
            child: user != null
                ? YoloAvatar(key: ValueKey(user.id), user: user, size: 60, speaking: seat.speaking, goldFrame: isMe)
                : Container(
                    key: ValueKey('empty-${seat.index}'),
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withValues(alpha: 0.05),
                      border: Border.all(color: const Color(0x73C4B8E6), width: 1.5),
                    ),
                    child: Icon(seat.locked ? Icons.lock_rounded : Icons.add_rounded, color: const Color(0xFFC4B8E6), size: 22),
                  ),
          ),
          const SizedBox(height: 6),
          Text(
            user?.name ?? (seat.locked ? 'Locked' : 'Seat ${seat.index + 1}'),
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
        child = Text.rich(TextSpan(children: [
          TextSpan(text: '${msg.sender}: ', style: TextStyle(fontWeight: FontWeight.w700, color: msg.color)),
          TextSpan(text: msg.text),
        ]), style: const TextStyle(fontSize: 13, height: 1.4));
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
