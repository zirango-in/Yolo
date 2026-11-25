import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../core/theme.dart';
import '../../widgets/common.dart';

/// First-launch onboarding carousel.
class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  final _pager = PageController();
  int _page = 0;

  static const _slides = [
    (Icons.mic_rounded, 'Voice party rooms', 'Hop on a mic, meet new friends and talk all night.'),
    (Icons.card_giftcard_rounded, 'Gifts & effects', 'Send stunning animated gifts to the people you love.'),
    (Icons.groups_rounded, 'Families & friends', 'Join a family, complete quests and rise up the ranks.'),
  ];

  @override
  void dispose() {
    _pager.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final last = _page == _slides.length - 1;
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: RadialGradient(center: Alignment(0, -0.4), radius: 1.0, colors: [Color(0xFF4C1D95), Color(0xFF1A0F38), YoloColors.bg], stops: [0, 0.55, 1]),
        ),
        child: SafeArea(
          child: Column(children: [
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(onPressed: () => context.go('/login'), child: const Text('Skip', style: TextStyle(color: YoloColors.textSoft))),
            ),
            Expanded(
              child: PageView.builder(
                controller: _pager,
                onPageChanged: (i) => setState(() => _page = i),
                itemCount: _slides.length,
                itemBuilder: (_, i) {
                  final (icon, title, body) = _slides[i];
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32),
                    child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                      Container(
                        width: 160,
                        height: 160,
                        decoration: BoxDecoration(
                          gradient: YoloColors.goldGradient,
                          borderRadius: BorderRadius.circular(48),
                          boxShadow: [BoxShadow(color: YoloColors.gold.withValues(alpha: 0.45), blurRadius: 60, offset: const Offset(0, 20))],
                        ),
                        child: Icon(icon, size: 80, color: YoloColors.onGold),
                      ).animate(key: ValueKey(i)).scale(begin: const Offset(0.7, 0.7), duration: 600.ms, curve: Curves.easeOutBack),
                      const SizedBox(height: 40),
                      Text(title, textAlign: TextAlign.center, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w800))
                          .animate(key: ValueKey('t$i'))
                          .fadeIn(delay: 150.ms)
                          .slideY(begin: 0.3, end: 0),
                      const SizedBox(height: 10),
                      Text(body, textAlign: TextAlign.center, style: const TextStyle(fontSize: 15, color: YoloColors.textSoft, height: 1.5))
                          .animate(key: ValueKey('b$i'))
                          .fadeIn(delay: 300.ms),
                    ]),
                  );
                },
              ),
            ),
            Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              for (var i = 0; i < _slides.length; i++)
                AnimatedContainer(
                  duration: 250.ms,
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  width: i == _page ? 24 : 8,
                  height: 8,
                  decoration: BoxDecoration(color: i == _page ? YoloColors.gold : Colors.white24, borderRadius: BorderRadius.circular(4)),
                ),
            ]),
            Padding(
              padding: const EdgeInsets.fromLTRB(28, 28, 28, 24),
              child: SizedBox(
                width: double.infinity,
                child: GoldButton(
                  label: last ? 'Get started' : 'Next',
                  onPressed: () => last ? context.go('/login') : _pager.nextPage(duration: 350.ms, curve: Curves.easeOut),
                ),
              ),
            ),
          ]),
        ),
      ),
    );
  }
}
