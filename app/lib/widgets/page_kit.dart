import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../core/theme.dart';

/// Standard Yolo page: dark gradient background, back button, title, actions.
class YoloPage extends StatelessWidget {
  const YoloPage({super.key, required this.title, required this.body, this.actions = const [], this.showBack = true, this.bottom});
  final String title;
  final Widget body;
  final List<Widget> actions;
  final bool showBack;
  final Widget? bottom;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF1E1046), YoloColors.bg],
            stops: [0, 0.35],
          ),
        ),
        child: SafeArea(
          bottom: false,
          child: Column(children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 6, 12, 6),
              child: Row(children: [
                if (showBack && context.canPop())
                  IconButton(
                    tooltip: 'Back',
                    icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
                    onPressed: () => context.pop(),
                  )
                else
                  const SizedBox(width: 12),
                Expanded(
                  child: Text(title,
                      maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
                ),
                ...actions,
              ]),
            ),
            ?bottom,
            Expanded(child: body),
          ]),
        ),
      ),
    );
  }
}

/// Underlined text tabs used across the app (rooms, gifts, shop, notifications…).
class YoloTabs extends StatelessWidget {
  const YoloTabs({super.key, required this.tabs, required this.index, required this.onChanged, this.padding = const EdgeInsets.fromLTRB(20, 4, 20, 10)});
  final List<String> tabs;
  final int index;
  final ValueChanged<int> onChanged;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: padding,
      child: Row(children: [
        for (var i = 0; i < tabs.length; i++)
          Padding(
            padding: const EdgeInsets.only(right: 22),
            child: InkWell(
              onTap: () => onChanged(i),
              borderRadius: BorderRadius.circular(8),
              child: Column(children: [
                AnimatedDefaultTextStyle(
                  duration: 200.ms,
                  style: TextStyle(
                    fontSize: i == index ? 16 : 14,
                    fontWeight: i == index ? FontWeight.w800 : FontWeight.w600,
                    color: i == index ? YoloColors.text : YoloColors.textMuted,
                    fontFamily: DefaultTextStyle.of(context).style.fontFamily,
                  ),
                  child: Text(tabs[i]),
                ),
                const SizedBox(height: 6),
                AnimatedContainer(
                  duration: 200.ms,
                  height: 3,
                  width: i == index ? 24 : 0,
                  decoration: BoxDecoration(color: YoloColors.gold, borderRadius: BorderRadius.circular(2)),
                ),
              ]),
            ),
          ),
      ]),
    );
  }
}

class SectionTitle extends StatelessWidget {
  const SectionTitle(this.text, {super.key, this.action, this.onAction});
  final String text;
  final String? action;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 10),
        child: Row(children: [
          Expanded(child: Text(text, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800))),
          if (action != null)
            TextButton(
              onPressed: onAction,
              style: TextButton.styleFrom(foregroundColor: YoloColors.gold, padding: EdgeInsets.zero, minimumSize: const Size(44, 32)),
              child: Text(action!, style: const TextStyle(fontWeight: FontWeight.w600)),
            ),
        ]),
      );
}

class GlassCard extends StatelessWidget {
  const GlassCard({super.key, required this.child, this.padding = const EdgeInsets.all(16), this.margin, this.onTap, this.gradient, this.border});
  final Widget child;
  final EdgeInsets padding;
  final EdgeInsets? margin;
  final VoidCallback? onTap;
  final Gradient? gradient;
  final Color? border;

  @override
  Widget build(BuildContext context) => Padding(
        padding: margin ?? EdgeInsets.zero,
        child: Material(
          color: gradient == null ? YoloColors.surface : Colors.transparent,
          borderRadius: BorderRadius.circular(18),
          clipBehavior: Clip.antiAlias,
          child: Ink(
            decoration: BoxDecoration(
              gradient: gradient,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: border ?? Colors.white.withValues(alpha: 0.06)),
            ),
            child: InkWell(onTap: onTap, child: Padding(padding: padding, child: child)),
          ),
        ),
      );
}

/// Rounded icon tile with tinted background.
class TintIcon extends StatelessWidget {
  const TintIcon(this.icon, {super.key, required this.color, this.size = 40});
  final IconData icon;
  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) => Container(
        width: size,
        height: size,
        decoration: BoxDecoration(color: color.withValues(alpha: 0.18), borderRadius: BorderRadius.circular(size * 0.32)),
        child: Icon(icon, color: color, size: size * 0.52),
      );
}

class EmptyState extends StatelessWidget {
  const EmptyState({super.key, required this.icon, required this.title, this.subtitle = ''});
  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.all(40),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Icon(icon, size: 56, color: YoloColors.gold).animate(onPlay: (c) => c.repeat(reverse: true)).moveY(begin: -3, end: 3, duration: 1200.ms),
            const SizedBox(height: 14),
            Text(title, textAlign: TextAlign.center, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
            if (subtitle.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(subtitle, textAlign: TextAlign.center, style: const TextStyle(color: YoloColors.textMuted)),
            ],
          ]),
        ),
      );
}

void showYoloToast(BuildContext context, String msg) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(
      content: Text(msg),
      behavior: SnackBarBehavior.floating,
      // Float above bottom bars (room controls, nav) so buttons stay tappable.
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 90),
      backgroundColor: YoloColors.surface,
      duration: const Duration(milliseconds: 1400),
    ));
}

/// Fade + slide-in used for list items (staggered by index).
extension YoloEntrance on Widget {
  Widget entrance(int i) => animate().fadeIn(delay: (40 * i).ms, duration: 300.ms).slideY(begin: 0.12, end: 0, curve: Curves.easeOut);
}
