import 'dart:io';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../core/theme.dart';
import '../../data/models.dart';
import '../../data/providers.dart';

/// Room profile image: the cover photo if set, otherwise the room gradient with its initial.
class RoomCover extends StatelessWidget {
  const RoomCover({super.key, required this.room, required this.name, this.coverPath, this.size = 40, this.radius});
  final Room room;
  final String name;
  final String? coverPath;
  final double size;
  final double? radius;

  @override
  Widget build(BuildContext context) => ClipRRect(
    borderRadius: BorderRadius.circular(radius ?? size * 0.28),
    child: SizedBox(
      width: size,
      height: size,
      child: coverPath != null && !kIsWeb
          ? Image.file(File(coverPath!), fit: BoxFit.cover)
          : DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: room.cover, begin: Alignment.topLeft, end: Alignment.bottomRight),
              ),
              child: Center(
                child: Text(
                  name.isEmpty ? '?' : name[0].toUpperCase(),
                  style: TextStyle(fontSize: size * 0.44, fontWeight: FontWeight.w900, color: Colors.white),
                ),
              ),
            ),
    ),
  );
}

/// Three bars that bounce while the room is live.
class LiveBars extends StatelessWidget {
  const LiveBars({super.key, this.color = YoloColors.online});
  final Color color;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    crossAxisAlignment: CrossAxisAlignment.end,
    children: [
      for (var i = 0; i < 3; i++)
        Container(
          width: 3,
          height: 10,
          margin: const EdgeInsets.symmetric(horizontal: 1),
          decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(2)),
        ).animate(onPlay: (c) => c.repeat(reverse: true)).scaleY(begin: 0.3, end: 1, alignment: Alignment.bottomCenter, duration: (300 + i * 120).ms),
    ],
  );
}

/// Floating mini room shown on other pages while a room is minimized.
/// Tap → reopen the same live room. × → confirm and exit the room.
class FloatingRoomBubble extends ConsumerStatefulWidget {
  const FloatingRoomBubble({super.key, required this.onOpen, required this.dialogContext});
  final void Function(Room room) onOpen;
  final BuildContext? Function() dialogContext;

  @override
  ConsumerState<FloatingRoomBubble> createState() => _FloatingRoomBubbleState();
}

class _FloatingRoomBubbleState extends ConsumerState<FloatingRoomBubble> {
  static const _w = 168.0, _h = 56.0;
  Offset? _pos; // top-left; null = default (bottom right)
  bool _dragging = false;
  bool _faded = true; // fully hidden: build nothing so off-screen text and taps can't leak

  Future<void> _confirmExit(Room room) async {
    final ctx = widget.dialogContext();
    if (ctx == null) return;
    final ok = await showDialog<bool>(
      context: ctx,
      builder: (c) => AlertDialog(
        backgroundColor: YoloColors.sheet,
        title: const Text('Exit the room?'),
        content: Text('You will leave ${ref.read(roomProvider(room)).name} and your seat.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Stay')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: YoloColors.gold, foregroundColor: YoloColors.onGold),
            onPressed: () => Navigator.pop(c, true),
            child: const Text('Exit room'),
          ),
        ],
      ),
    );
    if (ok == true) {
      ref.read(roomProvider(room).notifier).leaveSeat();
      ref.read(activeRoomProvider.notifier).exit();
    }
  }

  @override
  Widget build(BuildContext context) {
    final room = ref.watch(activeRoomProvider);
    final open = ref.watch(roomScreenOpenProvider);
    final visible = room != null && open == 0;
    if (visible) _faded = false;
    final pad = MediaQuery.paddingOf(context);
    // Measure the real space the app has (works in split screen / any window size).
    return Positioned.fill(
      child: LayoutBuilder(
        builder: (context, box) {
          final size = box.biggest;
          final pos = _clamp(_pos ?? Offset(size.width - _w - 12, size.height - _h - pad.bottom - 96), size, pad);
          return Stack(children: [_positioned(room, visible, pos, size, pad)]);
        },
      ),
    );
  }

  Offset _clamp(Offset p, Size size, EdgeInsets pad) => Offset(
    p.dx.clamp(8, (size.width - _w - 8).clamp(8, double.infinity)),
    p.dy.clamp(pad.top + 8, (size.height - _h - pad.bottom - 8).clamp(pad.top + 8, double.infinity)),
  );

  Widget _positioned(Room? room, bool visible, Offset pos, Size size, EdgeInsets pad) {
    return AnimatedPositioned(
      duration: _dragging ? Duration.zero : 250.ms,
      curve: Curves.easeOutCubic,
      left: pos.dx,
      top: pos.dy,
      child: IgnorePointer(
        ignoring: !visible,
        child: AnimatedScale(
          duration: 250.ms,
          curve: Curves.easeOutBack,
          scale: visible ? 1 : 0.6,
          child: AnimatedOpacity(
            duration: 200.ms,
            opacity: visible ? 1 : 0,
            onEnd: () {
              if (!visible && mounted) setState(() => _faded = true);
            },
            child: room == null || (!visible && _faded) ? const SizedBox(width: _w, height: _h) : _bubble(room, size, pad),
          ),
        ),
      ),
    );
  }

  Widget _bubble(Room room, Size size, EdgeInsets pad) {
    final st = ref.watch(roomProvider(room));
    final meId = ref.watch(sessionProvider)?.id;
    final onMic = st.seats.any((s) => s.user?.id == meId);
    return Semantics(
      button: true,
      label: 'Return to ${st.name}',
      container: true,
      child: GestureDetector(
        onTap: () => widget.onOpen(room),
        onPanStart: (_) => setState(() => _dragging = true),
        onPanUpdate: (d) => setState(() {
          final p = (_pos ?? Offset(size.width - _w - 12, size.height - _h - pad.bottom - 96)) + d.delta;
          _pos = _clamp(p, size, pad);
        }),
        onPanEnd: (_) => setState(() {
          _dragging = false;
          final p = _pos!;
          // Snap to the nearest side.
          _pos = Offset(p.dx + _w / 2 < size.width / 2 ? 12 : size.width - _w - 12, p.dy);
        }),
        child: MediaQuery.withClampedTextScaling(
          maxScaleFactor: 1.15, // fixed-size bubble: keep text inside it at large font settings
          child: Material(
            color: Colors.transparent,
            child: Container(
              width: _w,
              height: _h,
              padding: const EdgeInsets.fromLTRB(6, 6, 2, 6),
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [Color(0xF22A1460), Color(0xF2160C33)]),
                borderRadius: BorderRadius.circular(_h / 2),
                border: Border.all(color: YoloColors.gold.withValues(alpha: 0.6)),
                boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.45), blurRadius: 16, offset: const Offset(0, 6))],
              ),
              child: Row(
                children: [
                  Stack(
                    clipBehavior: Clip.none,
                    children: [
                      // A real cover photo spins like a record; the letter cover stays upright.
                      st.coverPath != null
                          ? RoomCover(room: room, name: st.name, coverPath: st.coverPath, size: 44, radius: 22)
                              .animate(onPlay: (c) => c.repeat())
                              .rotate(duration: 8.seconds)
                          : RoomCover(room: room, name: st.name, size: 44, radius: 22),
                      Positioned(
                        right: -1,
                        bottom: -1,
                        child: Container(
                          width: 14,
                          height: 14,
                          decoration: BoxDecoration(
                            color: YoloColors.online,
                            shape: BoxShape.circle,
                            border: Border.all(color: YoloColors.bg, width: 2),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          st.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800),
                        ),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            const LiveBars(),
                            const SizedBox(width: 4),
                            Flexible(
                              child: Text(
                                onMic ? (st.micOn ? 'On mic' : 'Muted') : 'Live',
                                maxLines: 1,
                                style: const TextStyle(fontSize: 10, color: YoloColors.online, fontWeight: FontWeight.w700),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  // Plain button: this bubble sits above the navigator, where tooltips have no overlay.
                  Semantics(
                    button: true,
                    excludeSemantics: true,
                    label: 'Exit room',
                    child: InkResponse(
                      onTap: () => _confirmExit(room),
                      radius: 20,
                      child: const SizedBox(width: 36, height: 44, child: Icon(Icons.close_rounded, size: 18, color: YoloColors.textSoft)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
