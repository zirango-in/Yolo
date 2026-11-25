import 'dart:io';
import 'dart:math';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:material_ui/material_ui.dart';

import '../../data/room_look.dart';

/// Animated room background: the room look's gradient or custom photo, slow light orbs and
/// twinkling sparkles in the look's accent colour. Cross-fades when the look changes.
/// Turns static when the system asks to reduce motion.
class AnimatedRoomBackground extends StatefulWidget {
  const AnimatedRoomBackground({super.key, required this.look, required this.child});
  final RoomLook look;
  final Widget child;

  @override
  State<AnimatedRoomBackground> createState() => _AnimatedRoomBackgroundState();
}

class _AnimatedRoomBackgroundState extends State<AnimatedRoomBackground> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: const Duration(seconds: 12));
  final _seed = Random(7);
  late final List<(double, double, double, double)> _stars =
      List.generate(42, (_) => (_seed.nextDouble(), _seed.nextDouble(), 0.6 + _seed.nextDouble() * 1.8, _seed.nextDouble()));

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.of(context).disableAnimations) {
      _c.stop();
    } else if (!_c.isAnimating) {
      _c.repeat();
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final look = widget.look;
    return ColoredBox(
      color: look.bg.last, // never white, even for a frame
      child: Stack(children: [
        Positioned.fill(
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 450),
            // Old and new backgrounds both fill the room while cross-fading.
            layoutBuilder: (current, previous) => Stack(fit: StackFit.expand, children: [...previous, ?current]),
            child: KeyedSubtree(key: ValueKey(look), child: RoomBackdrop(look: look)),
          ),
        ),
        Positioned.fill(
          child: IgnorePointer(
            child: RepaintBoundary(
              child: AnimatedBuilder(
                animation: _c,
                builder: (_, _) => CustomPaint(painter: _SparklePainter(_c.value, _stars, look.accent, orbs: look.imagePath == null)),
              ),
            ),
          ),
        ),
        widget.child,
      ]),
    );
  }
}

/// Static part of the background: gradient, or the photo (cropped to fill, never stretched)
/// under a soft dark veil so text and seats stay readable.
class RoomBackdrop extends StatelessWidget {
  const RoomBackdrop({super.key, required this.look});
  final RoomLook look;

  /// Photo decoded at screen size only (saves memory); Flutter's image cache reuses it.
  static ImageProvider imageFor(String path, BuildContext context) {
    final mq = MediaQuery.of(context);
    final w = (mq.size.width * mq.devicePixelRatio).round().clamp(320, 1440);
    final ImageProvider base = path.startsWith('http') ? NetworkImage(path) : FileImage(File(path));
    return ResizeImage(base, width: w, policy: ResizeImagePolicy.fit);
  }

  @override
  Widget build(BuildContext context) {
    final gradient = DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: look.bg, stops: const [0, 0.45, 1]),
      ),
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: RadialGradient(center: const Alignment(0, -0.9), radius: 0.9, colors: [look.accent.withValues(alpha: 0.18), Colors.transparent]),
        ),
      ),
    );
    final path = look.imagePath;
    if (path == null || (kIsWeb && !path.startsWith('http'))) return SizedBox.expand(child: gradient);
    return Stack(fit: StackFit.expand, children: [
      gradient, // shows while the photo loads
      Image(
        image: imageFor(path, context),
        fit: BoxFit.cover,
        alignment: Alignment(0, look.imageAlignY),
        filterQuality: FilterQuality.medium,
        gaplessPlayback: true,
        frameBuilder: (_, child, frame, sync) => sync ? child : AnimatedOpacity(opacity: frame == null ? 0 : 1, duration: const Duration(milliseconds: 300), child: child),
        errorBuilder: (_, _, _) => const SizedBox.shrink(),
      ),
      DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.black.withValues(alpha: 0.35), Colors.black.withValues(alpha: 0.10), look.bg.last.withValues(alpha: 0.75)],
            stops: const [0, 0.35, 1],
          ),
        ),
      ),
    ]);
  }
}

class _SparklePainter extends CustomPainter {
  _SparklePainter(this.t, this.stars, this.tint, {this.orbs = true});
  final double t;
  final List<(double, double, double, double)> stars;
  final Color tint;
  final bool orbs;

  @override
  void paint(Canvas canvas, Size size) {
    // Floating light orbs (not over a photo)
    for (var i = 0; orbs && i < 4; i++) {
      final phase = t * 2 * pi + i * 1.7;
      final c = Offset(size.width * (0.2 + 0.2 * i) + sin(phase) * 30, size.height * (0.25 + 0.15 * (i % 2)) + cos(phase) * 40);
      final paint = Paint()
        ..shader = RadialGradient(colors: [tint.withValues(alpha: 0.14), Colors.transparent])
            .createShader(Rect.fromCircle(center: c, radius: 120));
      canvas.drawCircle(c, 120, paint);
    }
    // Twinkling sparkles
    for (final (x, y, r, p) in stars) {
      final a = (0.5 + 0.5 * sin((t * 6 + p * 10) * pi)).clamp(0.0, 1.0);
      final paint = Paint()..color = Color.lerp(tint, Colors.white, 0.6)!.withValues(alpha: 0.15 + a * 0.6);
      final c = Offset(x * size.width, y * size.height * 0.75);
      canvas.drawCircle(c, r, paint);
      if (r > 1.8) {
        final line = Paint()
          ..color = Color.lerp(tint, Colors.white, 0.6)!.withValues(alpha: a * 0.5)
          ..strokeWidth = 0.8;
        canvas.drawLine(c.translate(-r * 3, 0), c.translate(r * 3, 0), line);
        canvas.drawLine(c.translate(0, -r * 3), c.translate(0, r * 3), line);
      }
    }
  }

  @override
  bool shouldRepaint(_SparklePainter old) => old.t != t || old.tint != tint || old.orbs != orbs;
}

/// Heartbeat line drawn between the intimacy seats.
class HeartbeatLine extends StatelessWidget {
  const HeartbeatLine({super.key, this.width = 56});
  final double width;

  @override
  Widget build(BuildContext context) => SizedBox(width: width, height: 24, child: CustomPaint(painter: _BeatPainter()));
}

class _BeatPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size s) {
    final p = Paint()
      ..color = const Color(0xFFF9A8D4)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    final m = s.height / 2;
    final path = Path()
      ..moveTo(0, m)
      ..lineTo(s.width * 0.3, m)
      ..lineTo(s.width * 0.4, 2)
      ..lineTo(s.width * 0.5, s.height - 2)
      ..lineTo(s.width * 0.6, m)
      ..lineTo(s.width, m);
    canvas.drawPath(path, p);
  }

  @override
  bool shouldRepaint(_BeatPainter old) => false;
}
