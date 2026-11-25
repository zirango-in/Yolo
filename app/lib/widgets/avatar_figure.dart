import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../core/theme.dart';
import '../data/profile_providers.dart';
import '../data/providers.dart';

/// Draws the layered 2D avatar (face, hair, outfit, accessory).
class AvatarFigure extends StatelessWidget {
  const AvatarFigure({super.key, required this.config, this.size = 120, this.background});
  final AvatarConfig config;
  final double size;
  final List<Color>? background;

  @override
  Widget build(BuildContext context) => ClipOval(
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(gradient: LinearGradient(colors: background ?? const [Color(0xFF2E1A5E), Color(0xFF4C1D95)], begin: Alignment.topLeft, end: Alignment.bottomRight)),
          child: CustomPaint(painter: _AvatarPainter(config)),
        ),
      );
}

class _AvatarPainter extends CustomPainter {
  _AvatarPainter(this.c);
  final AvatarConfig c;

  @override
  void paint(Canvas canvas, Size s) {
    final w = s.width;
    final p = Paint()..isAntiAlias = true;
    final skin = AvatarConfig.skins[c.skin];
    final hairC = AvatarConfig.hairColors[c.hairColor];
    final outfitC = AvatarConfig.outfitColors[c.outfitColor];
    final headC = Offset(w * 0.5, w * 0.42);
    final headR = w * 0.2;

    // Hair behind head (long / bob)
    p.color = hairC;
    if (c.hair == 2) canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromCenter(center: headC.translate(0, w * 0.1), width: headR * 2.5, height: headR * 2.8), Radius.circular(w * 0.18)), p);
    if (c.hair == 5) canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromCenter(center: headC.translate(0, w * 0.03), width: headR * 2.5, height: headR * 2.2), Radius.circular(w * 0.15)), p);

    // Body / outfit
    final body = Path()
      ..moveTo(w * 0.16, w)
      ..quadraticBezierTo(w * 0.18, w * 0.7, w * 0.5, w * 0.68)
      ..quadraticBezierTo(w * 0.82, w * 0.7, w * 0.84, w)
      ..close();
    p.color = outfitC;
    canvas.drawPath(body, p);
    // Neck
    p.color = skin;
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromCenter(center: Offset(w * 0.5, w * 0.64), width: w * 0.12, height: w * 0.1), Radius.circular(w * 0.03)), p);
    // Outfit details
    final detail = Paint()..color = Colors.white.withValues(alpha: 0.85)..strokeWidth = w * 0.015..style = PaintingStyle.stroke;
    switch (c.outfit) {
      case 1: // suit: lapels + tie
        canvas.drawLine(Offset(w * 0.5, w * 0.7), Offset(w * 0.38, w * 0.9), detail);
        canvas.drawLine(Offset(w * 0.5, w * 0.7), Offset(w * 0.62, w * 0.9), detail);
        p.color = const Color(0xFFDC2626);
        canvas.drawPath(Path()..moveTo(w * 0.47, w * 0.71)..lineTo(w * 0.53, w * 0.71)..lineTo(w * 0.51, w * 0.88)..lineTo(w * 0.49, w * 0.88)..close(), p);
      case 2: // dress: necklace
        canvas.drawArc(Rect.fromCenter(center: Offset(w * 0.5, w * 0.68), width: w * 0.2, height: w * 0.12), 0, math.pi, false, detail);
      case 3: // jersey: number
        final tp = TextPainter(text: TextSpan(text: '7', style: TextStyle(color: Colors.white, fontSize: w * 0.14, fontWeight: FontWeight.w900)), textDirection: TextDirection.ltr)..layout();
        tp.paint(canvas, Offset(w * 0.5 - tp.width / 2, w * 0.76));
      default: // hoodie strings
        canvas.drawLine(Offset(w * 0.46, w * 0.7), Offset(w * 0.45, w * 0.82), detail);
        canvas.drawLine(Offset(w * 0.54, w * 0.7), Offset(w * 0.55, w * 0.82), detail);
    }

    // Head
    p.color = skin;
    canvas.drawOval(Rect.fromCenter(center: headC, width: headR * 2, height: headR * 2.15), p);
    // Cheeks
    p.color = const Color(0x55F472B6);
    canvas.drawCircle(headC.translate(-headR * 0.55, headR * 0.35), headR * 0.16, p);
    canvas.drawCircle(headC.translate(headR * 0.55, headR * 0.35), headR * 0.16, p);
    // Eyes
    final eyeP = Paint()..color = const Color(0xFF1F1B24)..strokeWidth = w * 0.018..strokeCap = StrokeCap.round..style = PaintingStyle.stroke;
    final le = headC.translate(-headR * 0.4, 0);
    final re = headC.translate(headR * 0.4, 0);
    switch (c.eyes) {
      case 1:
        canvas.drawCircle(le, headR * 0.12, eyeP..style = PaintingStyle.fill);
        canvas.drawLine(re.translate(-headR * 0.14, 0), re.translate(headR * 0.14, 0), eyeP..style = PaintingStyle.stroke);
      case 2:
        canvas.drawLine(le.translate(-headR * 0.16, 0), le.translate(headR * 0.16, 0), eyeP);
        canvas.drawLine(re.translate(-headR * 0.16, 0), re.translate(headR * 0.16, 0), eyeP);
      case 3:
        final star = Paint()..color = const Color(0xFFF5C451);
        canvas.drawCircle(le, headR * 0.14, star);
        canvas.drawCircle(re, headR * 0.14, star);
      default:
        canvas.drawArc(Rect.fromCenter(center: le, width: headR * 0.3, height: headR * 0.25), math.pi, math.pi, false, eyeP);
        canvas.drawArc(Rect.fromCenter(center: re, width: headR * 0.3, height: headR * 0.25), math.pi, math.pi, false, eyeP);
    }
    // Smile
    canvas.drawArc(Rect.fromCenter(center: headC.translate(0, headR * 0.4), width: headR * 0.6, height: headR * 0.4), 0.2, math.pi - 0.4, false, eyeP..color = const Color(0xFFB4235A));

    // Hair on top
    p.color = hairC;
    switch (c.hair) {
      case 1: // short
        canvas.drawArc(Rect.fromCenter(center: headC.translate(0, -headR * 0.15), width: headR * 2.2, height: headR * 2), math.pi, math.pi, true, p);
      case 2: // long top
        canvas.drawArc(Rect.fromCenter(center: headC.translate(0, -headR * 0.1), width: headR * 2.3, height: headR * 2.1), math.pi, math.pi, true, p);
      case 3: // bun
        canvas.drawArc(Rect.fromCenter(center: headC.translate(0, -headR * 0.15), width: headR * 2.2, height: headR * 2), math.pi, math.pi, true, p);
        canvas.drawCircle(headC.translate(0, -headR * 1.25), headR * 0.45, p);
      case 4: // spiky
        final spikes = Path()..moveTo(headC.dx - headR * 1.1, headC.dy - headR * 0.2);
        for (var i = 0; i < 5; i++) {
          final x0 = headC.dx - headR * 1.1 + i * headR * 0.44;
          spikes.lineTo(x0 + headR * 0.22, headC.dy - headR * 1.45);
          spikes.lineTo(x0 + headR * 0.44, headC.dy - headR * 0.6);
        }
        spikes.close();
        canvas.drawPath(spikes, p);
      case 5: // bob fringe
        canvas.drawArc(Rect.fromCenter(center: headC.translate(0, -headR * 0.05), width: headR * 2.3, height: headR * 2.1), math.pi, math.pi, true, p);
      default:
        break;
    }

    // Accessory
    final acc = Paint()..color = const Color(0xFF111827)..strokeWidth = w * 0.02..style = PaintingStyle.stroke;
    switch (c.accessory) {
      case 1: // glasses
        canvas.drawCircle(le, headR * 0.28, acc);
        canvas.drawCircle(re, headR * 0.28, acc);
        canvas.drawLine(le.translate(headR * 0.28, 0), re.translate(-headR * 0.28, 0), acc);
      case 2: // shades
        final fill = Paint()..color = const Color(0xFF111827);
        canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromCenter(center: le, width: headR * 0.65, height: headR * 0.4), Radius.circular(headR * 0.12)), fill);
        canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromCenter(center: re, width: headR * 0.65, height: headR * 0.4), Radius.circular(headR * 0.12)), fill);
        canvas.drawLine(le, re, acc);
      case 3: // crown
        final crown = Path()
          ..moveTo(headC.dx - headR * 0.7, headC.dy - headR * 0.95)
          ..lineTo(headC.dx - headR * 0.8, headC.dy - headR * 1.6)
          ..lineTo(headC.dx - headR * 0.35, headC.dy - headR * 1.25)
          ..lineTo(headC.dx, headC.dy - headR * 1.75)
          ..lineTo(headC.dx + headR * 0.35, headC.dy - headR * 1.25)
          ..lineTo(headC.dx + headR * 0.8, headC.dy - headR * 1.6)
          ..lineTo(headC.dx + headR * 0.7, headC.dy - headR * 0.95)
          ..close();
        canvas.drawPath(crown, Paint()..color = YoloColors.gold);
      case 4: // headphones
        final band = Paint()..color = const Color(0xFF111827)..strokeWidth = w * 0.035..style = PaintingStyle.stroke;
        canvas.drawArc(Rect.fromCenter(center: headC, width: headR * 2.4, height: headR * 2.4), math.pi, math.pi, false, band);
        final cup = Paint()..color = const Color(0xFFEC4899);
        canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromCenter(center: headC.translate(-headR * 1.15, headR * 0.1), width: headR * 0.4, height: headR * 0.7), Radius.circular(headR * 0.15)), cup);
        canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromCenter(center: headC.translate(headR * 1.15, headR * 0.1), width: headR * 0.4, height: headR * 0.7), Radius.circular(headR * 0.15)), cup);
      case 5: // cap
        final cap = Paint()..color = const Color(0xFFDC2626);
        canvas.drawArc(Rect.fromCenter(center: headC.translate(0, -headR * 0.3), width: headR * 2.2, height: headR * 1.8), math.pi, math.pi, true, cap);
        canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(headC.dx - headR * 0.2, headC.dy - headR * 0.4, headR * 1.4, headR * 0.25), Radius.circular(headR * 0.1)), cap);
      default:
        break;
    }
  }

  @override
  bool shouldRepaint(_AvatarPainter old) => old.c != c;
}

/// My avatar everywhere: picked photo, avatar figure or gradient initial, inside the equipped frame.
class MyAvatar extends ConsumerWidget {
  const MyAvatar({super.key, this.size = 116});
  final double size;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final me = ref.watch(sessionProvider);
    final x = ref.watch(profileExtrasProvider);
    final frame = ref.watch(equippedFrameProvider);
    final ring = frame?.colors ?? const [YoloColors.gold, Color(0xFFFFF3CC), YoloColors.goldDeep];
    final inner = size * 0.9;

    Widget content;
    if (x.photoPath != null && !kIsWeb) {
      content = ClipOval(child: Image.file(File(x.photoPath!), width: inner, height: inner, fit: BoxFit.cover));
    } else if (x.useAvatarFigure) {
      content = AvatarFigure(config: x.avatar, size: inner);
    } else {
      content = Container(
        width: inner,
        height: inner,
        decoration: BoxDecoration(shape: BoxShape.circle, gradient: LinearGradient(colors: ProfileExtras.photoColors[x.photoColor])),
        alignment: Alignment.center,
        child: Text(me?.initial ?? '?', style: TextStyle(fontSize: size * 0.34, fontWeight: FontWeight.w800, color: Colors.white)),
      );
    }

    return Container(
      width: size,
      height: size,
      padding: EdgeInsets.all(size * 0.05),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: SweepGradient(colors: [...ring, ring.first]),
        boxShadow: [BoxShadow(color: ring.first.withValues(alpha: 0.5), blurRadius: size * 0.3)],
      ),
      child: Container(
        decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: YoloColors.bg, width: size * 0.03)),
        child: ClipOval(child: content),
      ),
    );
  }
}
