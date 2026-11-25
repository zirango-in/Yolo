import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../core/theme.dart';
import '../../data/account_providers.dart';
import '../../data/providers.dart';
import '../../widgets/common.dart';
import '../../widgets/page_kit.dart';
import 'phone_flow.dart';

final _emailRe = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

InputDecoration _field(String label, {Widget? suffix, String? error}) => InputDecoration(
      labelText: label,
      errorText: error,
      suffixIcon: suffix,
      filled: true,
      fillColor: Colors.white.withValues(alpha: 0.07),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
    );

class EmailLoginScreen extends ConsumerStatefulWidget {
  const EmailLoginScreen({super.key});

  @override
  ConsumerState<EmailLoginScreen> createState() => _EmailLoginScreenState();
}

class _EmailLoginScreenState extends ConsumerState<EmailLoginScreen> {
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _hide = true;
  bool _loading = false;
  String? _emailError;
  String? _passError;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    setState(() {
      _emailError = _emailRe.hasMatch(_email.text.trim()) ? null : 'Enter a valid email';
      _passError = _password.text.length >= 6 ? null : 'At least 6 characters';
    });
    if (_emailError != null || _passError != null) return;
    setState(() => _loading = true);
    await ref.read(sessionProvider.notifier).login('email');
    ref.read(accountProvider.notifier).signedInWith('email', email: _email.text.trim());
    if (mounted) context.go('/home');
  }

  @override
  Widget build(BuildContext context) {
    return YoloPage(
      title: 'Email login',
      body: ListView(padding: const EdgeInsets.all(24), children: [
        const Text('Welcome back', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800)),
        const SizedBox(height: 24),
        TextField(controller: _email, keyboardType: TextInputType.emailAddress, decoration: _field('Email', error: _emailError)),
        const SizedBox(height: 14),
        TextField(
          controller: _password,
          obscureText: _hide,
          onSubmitted: (_) => _login(),
          decoration: _field('Password',
              error: _passError,
              suffix: IconButton(
                tooltip: _hide ? 'Show password' : 'Hide password',
                icon: Icon(_hide ? Icons.visibility_rounded : Icons.visibility_off_rounded),
                onPressed: () => setState(() => _hide = !_hide),
              )),
        ),
        Align(
          alignment: Alignment.centerRight,
          child: TextButton(onPressed: () => context.push('/login/recover'), child: const Text('Forgot password?', style: TextStyle(color: YoloColors.gold))),
        ),
        const SizedBox(height: 12),
        GoldButton(label: 'Log in', loading: _loading, onPressed: _login),
        const SizedBox(height: 12),
        Center(
          child: TextButton(
            onPressed: () => context.push('/login/phone'),
            child: const Text('New here? Sign up with phone', style: TextStyle(color: YoloColors.textSoft)),
          ),
        ),
      ]),
    );
  }
}

/// Account recovery: choose how to verify, then reset.
class RecoveryScreen extends StatelessWidget {
  const RecoveryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return YoloPage(
      title: 'Account recovery',
      body: ListView(padding: const EdgeInsets.all(24), children: [
        const Text('Get back into your account', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
        const SizedBox(height: 6),
        const Text('Choose how you want to verify it is you.', style: TextStyle(color: YoloColors.textMuted)),
        const SizedBox(height: 24),
        GlassCard(
          onTap: () => context.push('/login/phone', extra: PhonePurpose.recover),
          child: const Row(children: [
            TintIcon(Icons.sms_rounded, color: Color(0xFF86EFAC)),
            SizedBox(width: 12),
            Expanded(child: Text('Verify with phone number', style: TextStyle(fontWeight: FontWeight.w700))),
            Icon(Icons.chevron_right_rounded),
          ]),
        ),
        const SizedBox(height: 12),
        GlassCard(
          onTap: () => _emailReset(context),
          child: const Row(children: [
            TintIcon(Icons.mail_rounded, color: Color(0xFF7DD3FC)),
            SizedBox(width: 12),
            Expanded(child: Text('Reset password by email', style: TextStyle(fontWeight: FontWeight.w700))),
            Icon(Icons.chevron_right_rounded),
          ]),
        ),
        const SizedBox(height: 12),
        GlassCard(
          onTap: () => context.push('/support/chat'),
          child: const Row(children: [
            TintIcon(Icons.support_agent_rounded, color: Color(0xFFF5C451)),
            SizedBox(width: 12),
            Expanded(child: Text('Contact customer service', style: TextStyle(fontWeight: FontWeight.w700))),
            Icon(Icons.chevron_right_rounded),
          ]),
        ),
      ]),
    );
  }

  void _emailReset(BuildContext context) {
    final ctrl = TextEditingController();
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: YoloColors.sheet,
        title: const Text('Reset password'),
        content: TextField(controller: ctrl, keyboardType: TextInputType.emailAddress, decoration: _field('Your email')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Cancel')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: YoloColors.gold, foregroundColor: YoloColors.onGold),
            onPressed: () {
              if (!_emailRe.hasMatch(ctrl.text.trim())) return;
              Navigator.pop(dialogContext);
              showYoloToast(context, 'Reset link sent to ${ctrl.text.trim()}');
            },
            child: const Text('Send link'),
          ),
        ],
      ),
    );
  }
}
