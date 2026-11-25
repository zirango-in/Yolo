import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../core/theme.dart';
import '../../data/account_providers.dart';
import '../../data/providers.dart';
import '../../widgets/common.dart';
import '../../widgets/page_kit.dart';

/// Why the phone + OTP flow is running.
enum PhonePurpose { login, change, recover }

const _countries = [('+91', 'IN'), ('+92', 'PK'), ('+971', 'AE'), ('+966', 'SA'), ('+880', 'BD'), ('+62', 'ID'), ('+90', 'TR'), ('+1', 'US'), ('+44', 'UK')];

/// Step 1: enter phone number.
class PhoneEntryScreen extends StatefulWidget {
  const PhoneEntryScreen({super.key, this.purpose = PhonePurpose.login});
  final PhonePurpose purpose;

  @override
  State<PhoneEntryScreen> createState() => _PhoneEntryScreenState();
}

class _PhoneEntryScreenState extends State<PhoneEntryScreen> {
  final _phone = TextEditingController();
  String _code = '+91';
  bool _sending = false;
  String? _error;

  @override
  void dispose() {
    _phone.dispose();
    super.dispose();
  }

  Future<void> _next() async {
    final digits = _phone.text.replaceAll(RegExp(r'\D'), '');
    if (digits.length < 7 || digits.length > 13) {
      setState(() => _error = 'Enter a valid phone number');
      return;
    }
    setState(() {
      _error = null;
      _sending = true;
    });
    final full = '$_code$digits';
    await OtpService.send(full);
    if (!mounted) return;
    setState(() => _sending = false);
    context.push('/login/otp', extra: (full, widget.purpose));
  }

  @override
  Widget build(BuildContext context) {
    final title = switch (widget.purpose) {
      PhonePurpose.login => 'Phone login',
      PhonePurpose.change => 'Change phone number',
      PhonePurpose.recover => 'Recover account',
    };
    return YoloPage(
      title: title,
      body: ListView(padding: const EdgeInsets.all(24), children: [
        Text(widget.purpose == PhonePurpose.change ? 'Enter your new number' : 'Enter your phone number',
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800)),
        const SizedBox(height: 6),
        const Text('We will send you a 6-digit verification code.', style: TextStyle(color: YoloColors.textMuted)),
        const SizedBox(height: 28),
        Row(children: [
          Container(
            height: 56,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.07), borderRadius: BorderRadius.circular(16)),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _code,
                dropdownColor: YoloColors.sheet,
                items: [for (final (c, n) in _countries) DropdownMenuItem(value: c, child: Text('$n $c'))],
                onChanged: (v) => setState(() => _code = v!),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: TextField(
              controller: _phone,
              autofocus: true,
              keyboardType: TextInputType.phone,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(13)],
              onSubmitted: (_) => _next(),
              style: const TextStyle(fontSize: 18, letterSpacing: 1),
              decoration: InputDecoration(
                hintText: 'Phone number',
                errorText: _error,
                filled: true,
                fillColor: Colors.white.withValues(alpha: 0.07),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
              ),
            ),
          ),
        ]),
        const SizedBox(height: 28),
        GoldButton(label: 'Send code', loading: _sending, onPressed: _next),
      ]),
    );
  }
}

/// Step 2: enter the 6-digit code.
class OtpScreen extends ConsumerStatefulWidget {
  const OtpScreen({super.key, required this.phone, required this.purpose});
  final String phone;
  final PhonePurpose purpose;

  @override
  ConsumerState<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends ConsumerState<OtpScreen> {
  final _code = TextEditingController();
  Timer? _timer;
  int _left = 60;
  bool _checking = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  void _startTimer() {
    _timer?.cancel();
    setState(() => _left = 60);
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (_left <= 1) t.cancel();
      if (mounted) setState(() => _left--);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _code.dispose();
    super.dispose();
  }

  Future<void> _verify() async {
    if (_code.text.length != 6) return;
    setState(() {
      _checking = true;
      _error = null;
    });
    final ok = await OtpService.verify(widget.phone, _code.text);
    if (!mounted) return;
    setState(() => _checking = false);
    if (!ok) {
      setState(() => _error = 'Wrong code. Please try again.');
      _code.clear();
      return;
    }
    final account = ref.read(accountProvider.notifier);
    switch (widget.purpose) {
      case PhonePurpose.login:
        account.signedInWith('phone', phone: widget.phone);
        context.go('/login/register');
      case PhonePurpose.change:
        account.setPhone(widget.phone);
        showYoloToast(context, 'Phone number updated');
        context.go('/account');
      case PhonePurpose.recover:
        await ref.read(sessionProvider.notifier).login('phone');
        account.signedInWith('phone', phone: widget.phone);
        if (mounted) context.go('/home');
    }
  }

  @override
  Widget build(BuildContext context) {
    final code = _code.text;
    return YoloPage(
      title: 'Verification',
      body: ListView(padding: const EdgeInsets.all(24), children: [
        const Text('Enter the code', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800)),
        const SizedBox(height: 6),
        Text('Sent to ${maskPhone(widget.phone)}', style: const TextStyle(color: YoloColors.textMuted)),
        const SizedBox(height: 28),
        // Six boxes drawn over one hidden text field.
        Stack(children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            for (var i = 0; i < 6; i++)
              AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                width: 48,
                height: 58,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.07),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: i == code.length ? YoloColors.gold : (_error != null ? const Color(0xFFF87171) : Colors.transparent), width: 1.5),
                ),
                child: Text(i < code.length ? code[i] : '', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800)),
              ),
          ]),
          Positioned.fill(
            child: Opacity(
              opacity: 0,
              child: TextField(
                key: const Key('otp-field'),
                controller: _code,
                autofocus: true,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(6)],
                onChanged: (v) {
                  setState(() {});
                  if (v.length == 6) _verify();
                },
              ),
            ),
          ),
        ]),
        if (_error != null) Padding(padding: const EdgeInsets.only(top: 10), child: Text(_error!, style: const TextStyle(color: Color(0xFFF87171)))),
        const SizedBox(height: 18),
        Center(
          child: _left > 0
              ? Text('Resend code in ${_left}s', style: const TextStyle(color: YoloColors.textMuted))
              : TextButton(
                  onPressed: () async {
                    await OtpService.send(widget.phone);
                    _startTimer();
                    if (context.mounted) showYoloToast(context, 'Code sent again');
                  },
                  child: const Text('Resend code', style: TextStyle(color: YoloColors.gold)),
                ),
        ),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: YoloColors.gold.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(12)),
          child: const Text('Demo mode: use code ${OtpService.demoCode}. Real SMS codes come from the server.',
              style: TextStyle(fontSize: 12, color: YoloColors.textSoft)),
        ),
        const SizedBox(height: 20),
        GoldButton(label: 'Verify', loading: _checking, onPressed: code.length == 6 ? _verify : null),
      ]),
    );
  }
}
