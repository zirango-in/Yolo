import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../core/theme.dart';
import '../../data/providers.dart';
import '../../widgets/common.dart';
import '../../widgets/page_kit.dart';

/// New account setup after first phone/email verification.
class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _name = TextEditingController();
  String _gender = 'female';
  DateTime _birthday = DateTime(2002, 6, 15);
  bool _saving = false;
  String? _error;

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  int get _age {
    final now = DateTime.now();
    var a = now.year - _birthday.year;
    if (now.month < _birthday.month || (now.month == _birthday.month && now.day < _birthday.day)) a--;
    return a;
  }

  Future<void> _done() async {
    final name = _name.text.trim();
    if (name.length < 2 || name.length > 20) {
      setState(() => _error = 'Nickname must be 2–20 characters');
      return;
    }
    if (_age < 18) {
      setState(() => _error = 'You must be 18 or older to use Yolo');
      return;
    }
    setState(() {
      _error = null;
      _saving = true;
    });
    final session = ref.read(sessionProvider.notifier);
    await session.login('phone');
    session.updateProfile(name: name, gender: _gender, age: _age);
    if (mounted) context.go('/home');
  }

  @override
  Widget build(BuildContext context) {
    Widget genderChip(String value, String label, IconData icon) {
      final sel = _gender == value;
      return Expanded(
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => setState(() => _gender = value),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            height: 56,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              color: sel ? YoloColors.gold.withValues(alpha: 0.12) : Colors.white.withValues(alpha: 0.06),
              border: Border.all(color: sel ? YoloColors.gold : Colors.transparent, width: 1.5),
            ),
            child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              Icon(icon, color: sel ? YoloColors.gold : YoloColors.textMuted),
              const SizedBox(width: 8),
              Text(label, style: TextStyle(fontWeight: FontWeight.w700, color: sel ? YoloColors.gold : YoloColors.text)),
            ]),
          ),
        ),
      );
    }

    return YoloPage(
      title: 'Create account',
      showBack: false,
      body: ListView(padding: const EdgeInsets.all(24), children: [
        const Text('Tell us about you', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800)),
        const SizedBox(height: 6),
        const Text('You can change these later in your profile.', style: TextStyle(color: YoloColors.textMuted)),
        const SizedBox(height: 24),
        TextField(
          controller: _name,
          maxLength: 20,
          decoration: InputDecoration(
            labelText: 'Nickname',
            filled: true,
            fillColor: Colors.white.withValues(alpha: 0.07),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
          ),
        ),
        const SizedBox(height: 12),
        const Text('Gender', style: TextStyle(fontWeight: FontWeight.w700)),
        const SizedBox(height: 8),
        Row(children: [
          genderChip('female', 'Female', Icons.female_rounded),
          const SizedBox(width: 12),
          genderChip('male', 'Male', Icons.male_rounded),
        ]),
        const SizedBox(height: 20),
        const Text('Birthday', style: TextStyle(fontWeight: FontWeight.w700)),
        const SizedBox(height: 8),
        GlassCard(
          onTap: () async {
            final d = await showDatePicker(
              context: context,
              initialDate: _birthday,
              firstDate: DateTime(1950),
              lastDate: DateTime.now(),
            );
            if (d != null) setState(() => _birthday = d);
          },
          child: Row(children: [
            const Icon(Icons.cake_rounded, color: YoloColors.gold),
            const SizedBox(width: 12),
            Expanded(child: Text('${_birthday.day}/${_birthday.month}/${_birthday.year}', style: const TextStyle(fontSize: 16))),
            Text('Age $_age', style: const TextStyle(color: YoloColors.textMuted)),
          ]),
        ),
        if (_error != null) Padding(padding: const EdgeInsets.only(top: 12), child: Text(_error!, style: const TextStyle(color: Color(0xFFF87171)))),
        const SizedBox(height: 28),
        GoldButton(label: 'Start partying', loading: _saving, onPressed: _done),
      ]),
    );
  }
}
