import 'package:flutter_animate/flutter_animate.dart';
import 'package:material_ui/material_ui.dart';

import '../core/theme.dart';
import '../data/models.dart';

/// Gradient avatar with optional gold frame and animated speaking glow.
class YoloAvatar extends StatelessWidget {
  const YoloAvatar({
    super.key,
    required this.user,
    this.size = 60,
    this.goldFrame = false,
    this.speaking = false,
  });

  final YoloUser user;
  final double size;
  final bool goldFrame;
  final bool speaking;

  @override
  Widget build(BuildContext context) {
    final ring = goldFrame || speaking;
    final avatar = Container(
      width: size,
      height: size,
      padding: EdgeInsets.all(size * 0.05),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: ring
            ? const SweepGradient(colors: [YoloColors.gold, Color(0xFFFFE9A8), YoloColors.goldDeep, YoloColors.gold])
            : null,
        color: ring ? null : Colors.white.withValues(alpha: 0.14),
        boxShadow: speaking
            ? [BoxShadow(color: YoloColors.gold.withValues(alpha: 0.6), blurRadius: 18, spreadRadius: 1)]
            : null,
      ),
      child: Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: const Color(0xFF1A0F38), width: size * 0.035),
          gradient: LinearGradient(colors: user.avatarColors, begin: Alignment.topLeft, end: Alignment.bottomRight),
        ),
        alignment: Alignment.center,
        child: Text(
          user.initial,
          style: TextStyle(fontSize: size * 0.34, fontWeight: FontWeight.w800, color: Colors.white),
        ),
      ),
    );
    if (!speaking) return avatar;
    // Gentle pulse while talking.
    return avatar
        .animate(onPlay: (c) => c.repeat(reverse: true))
        .scaleXY(begin: 1, end: 1.06, duration: 600.ms, curve: Curves.easeInOut);
  }
}

class CoinIcon extends StatelessWidget {
  const CoinIcon({super.key, this.size = 16});
  final double size;

  @override
  Widget build(BuildContext context) => Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: YoloColors.gold,
          border: Border.all(color: const Color(0xFFB8860B), width: size * 0.12),
        ),
      );
}

class CoinPill extends StatelessWidget {
  const CoinPill({super.key, required this.coins, this.onTap});
  final int coins;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => Material(
        color: YoloColors.gold.withValues(alpha: 0.10),
        shape: StadiumBorder(side: BorderSide(color: YoloColors.gold.withValues(alpha: 0.35))),
        child: InkWell(
          customBorder: const StadiumBorder(),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              const CoinIcon(),
              const SizedBox(width: 6),
              Text(formatCoins(coins),
                  style: const TextStyle(color: YoloColors.gold, fontWeight: FontWeight.w700, fontSize: 13)),
            ]),
          ),
        ),
      );
}

String formatCoins(int n) {
  final s = n.toString();
  final b = StringBuffer();
  for (var i = 0; i < s.length; i++) {
    if (i > 0 && (s.length - i) % 3 == 0) b.write(',');
    b.write(s[i]);
  }
  return b.toString();
}

String compactCount(int n) => n >= 1000 ? '${(n / 1000).toStringAsFixed(1)}K' : '$n';

class GlassIconButton extends StatelessWidget {
  const GlassIconButton({super.key, required this.icon, required this.label, this.onTap, this.size = 40});
  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  final double size;

  @override
  Widget build(BuildContext context) => Semantics(
        button: true,
        label: label,
        child: Material(
          color: Colors.white.withValues(alpha: 0.08),
          shape: const CircleBorder(),
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: onTap,
            child: SizedBox(width: size, height: size, child: Icon(icon, size: size * 0.5, color: YoloColors.text)),
          ),
        ),
      );
}

/// Gold gradient call-to-action button with press animation.
class GoldButton extends StatefulWidget {
  const GoldButton({super.key, required this.label, required this.onPressed, this.icon, this.height = 54, this.loading = false});
  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final double height;
  final bool loading;

  @override
  State<GoldButton> createState() => _GoldButtonState();
}

class _GoldButtonState extends State<GoldButton> {
  bool _down = false;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: widget.label,
      child: GestureDetector(
        onTapDown: (_) => setState(() => _down = true),
        onTapCancel: () => setState(() => _down = false),
        onTapUp: (_) => setState(() => _down = false),
        onTap: widget.loading ? null : widget.onPressed,
        child: AnimatedScale(
          scale: _down ? 0.96 : 1,
          duration: 120.ms,
          child: Container(
            height: widget.height,
            decoration: BoxDecoration(
              gradient: YoloColors.goldGradient,
              borderRadius: BorderRadius.circular(widget.height / 2),
              boxShadow: [BoxShadow(color: YoloColors.gold.withValues(alpha: 0.35), blurRadius: 24, offset: const Offset(0, 8))],
            ),
            alignment: Alignment.center,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: widget.loading
                ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2.5, color: YoloColors.onGold))
                : Row(mainAxisSize: MainAxisSize.min, children: [
                    if (widget.icon != null) ...[Icon(widget.icon, color: YoloColors.onGold, size: 20), const SizedBox(width: 10)],
                    // Shrinks to fit narrow buttons and large accessibility fonts.
                    Flexible(
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(widget.label,
                            maxLines: 1, style: const TextStyle(color: YoloColors.onGold, fontWeight: FontWeight.w800, fontSize: 16)),
                      ),
                    ),
                  ]),
          ),
        ),
      ),
    );
  }
}

class Badge2 extends StatelessWidget {
  const Badge2(this.text, {super.key, this.bg = const Color(0x33F5C451), this.fg = YoloColors.gold});
  final String text;
  final Color bg;
  final Color fg;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(8)),
        child: Text(text, style: TextStyle(color: fg, fontSize: 11, fontWeight: FontWeight.w800)),
      );
}
