import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../core/theme.dart';
import '../../data/providers.dart';
import '../../widgets/common.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  String? _loading;

  Future<void> _login(String method) async {
    setState(() => _loading = method);
    await ref.read(sessionProvider.notifier).login(method);
    if (mounted) context.go('/home');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            center: Alignment(0, -0.4),
            radius: 1.0,
            colors: [Color(0xFF4C1D95), Color(0xFF1A0F38), YoloColors.bg],
            stops: [0, 0.55, 1],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(28, 0, 28, 24),
            child: Column(children: [
              const Spacer(flex: 3),
              // Animated logo with pulsing halo.
              Stack(alignment: Alignment.center, children: [
                Container(
                  width: 260,
                  height: 260,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: YoloColors.gold.withValues(alpha: 0.18)),
                  ),
                ).animate(onPlay: (c) => c.repeat(reverse: true)).scaleXY(begin: 0.92, end: 1.05, duration: 2.seconds),
                Container(
                  width: 132,
                  height: 132,
                  decoration: BoxDecoration(
                    gradient: YoloColors.goldGradient,
                    borderRadius: BorderRadius.circular(40),
                    boxShadow: [BoxShadow(color: YoloColors.gold.withValues(alpha: 0.45), blurRadius: 60, offset: const Offset(0, 20))],
                  ),
                  child: const Icon(Icons.mic_none_rounded, size: 68, color: YoloColors.onGold),
                ).animate().scale(begin: const Offset(0.6, 0.6), duration: 700.ms, curve: Curves.easeOutBack),
              ]),
              const SizedBox(height: 20),
              const Text('Yolo',
                      style: TextStyle(fontSize: 44, fontWeight: FontWeight.w800, letterSpacing: -1, color: YoloColors.gold))
                  .animate()
                  .fadeIn(delay: 200.ms, duration: 500.ms)
                  .slideY(begin: 0.3, end: 0),
              const SizedBox(height: 6),
              const Text('Talk, play and party with friends',
                      style: TextStyle(fontSize: 15, color: YoloColors.textSoft))
                  .animate()
                  .fadeIn(delay: 350.ms, duration: 500.ms),
              const Spacer(flex: 4),
              GoldButton(
                label: 'Continue with phone',
                icon: Icons.smartphone_rounded,
                loading: _loading == 'phone',
                onPressed: () => _login('phone'),
              ).animate().fadeIn(delay: 500.ms).slideY(begin: 0.4, end: 0),
              const SizedBox(height: 12),
              SizedBox(
                height: 54,
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: _loading == null ? () => _login('google') : null,
                  style: OutlinedButton.styleFrom(
                    shape: const StadiumBorder(),
                    side: BorderSide(color: Colors.white.withValues(alpha: 0.14)),
                    backgroundColor: Colors.white.withValues(alpha: 0.08),
                    foregroundColor: YoloColors.text,
                  ),
                  icon: _loading == 'google'
                      ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                      : const Icon(Icons.g_mobiledata_rounded, size: 30),
                  label: const Text('Continue with Google', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                ),
              ).animate().fadeIn(delay: 600.ms).slideY(begin: 0.4, end: 0),
              const SizedBox(height: 16),
              const Text('By continuing you agree to our Terms and Privacy Policy',
                  textAlign: TextAlign.center, style: TextStyle(fontSize: 12, color: YoloColors.textMuted)),
            ]),
          ),
        ),
      ),
    );
  }
}
