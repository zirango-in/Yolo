import 'dart:math';

import 'package:material_ui/material_ui.dart';

import '../../core/theme.dart';
import '../../data/providers.dart';

/// Animated room background: theme gradient, slow floating light orbs and twinkling sparkles.
/// Turns static when the system asks to reduce motion.
class AnimatedRoomBackground extends StatefulWidget {
  const AnimatedRoomBackground({super.key, required this.theme, required this.child});
  final int theme;
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
    final colors = RoomState.themes[widget.theme.clamp(0, RoomState.themes.length - 1)];
    return AnimatedContainer(
      duration: const Duration(milliseconds: 500),
      decoration: BoxDecoration(
        gradient: RadialGradient(center: const Alignment(0, -1.1), radius: 1.3, colors: [colors[0], colors[1], YoloColors.bg], stops: const [0, 0.55, 1]),
      ),
      child: Stack(children: [
        Positioned.fill(
          child: IgnorePointer(
            child: RepaintBoundary(
              child: AnimatedBuilder(
                animation: _c,
                builder: (_, _) => CustomPaint(painter: _SparklePainter(_c.value, _stars, colors[0])),
              ),
            ),
          ),
        ),
        widget.child,
      ]),
    );
  }
}

class _SparklePainter extends CustomPainter {
  _SparklePainter(this.t, this.stars, this.tint);
  final double t;
  final List<(double, double, double, double)> stars;
  final Color tint;

  @override
  void paint(Canvas canvas, Size size) {
    // Floating light orbs
    for (var i = 0; i < 4; i++) {
      final phase = t * 2 * pi + i * 1.7;
      final c = Offset(size.width * (0.2 + 0.2 * i) + sin(phase) * 30, size.height * (0.25 + 0.15 * (i % 2)) + cos(phase) * 40);
      final paint = Paint()
        ..shader = RadialGradient(colors: [Color.lerp(tint, const Color(0xFFF5C451), 0.5)!.withValues(alpha: 0.16), Colors.transparent])
            .createShader(Rect.fromCircle(center: c, radius: 120));
      canvas.drawCircle(c, 120, paint);
    }
    // Twinkling sparkles
    for (final (x, y, r, p) in stars) {
      final a = (0.5 + 0.5 * sin((t * 6 + p * 10) * pi)).clamp(0.0, 1.0);
      final paint = Paint()..color = const Color(0xFFFFF3CC).withValues(alpha: 0.15 + a * 0.6);
      final c = Offset(x * size.width, y * size.height * 0.75);
      canvas.drawCircle(c, r, paint);
      if (r > 1.8) {
        final line = Paint()
          ..color = const Color(0xFFFFF3CC).withValues(alpha: a * 0.5)
          ..strokeWidth = 0.8;
        canvas.drawLine(c.translate(-r * 3, 0), c.translate(r * 3, 0), line);
        canvas.drawLine(c.translate(0, -r * 3), c.translate(0, r * 3), line);
      }
    }
  }

  @override
  bool shouldRepaint(_SparklePainter old) => old.t != t || old.tint != tint;
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
