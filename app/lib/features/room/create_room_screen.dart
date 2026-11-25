import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../core/theme.dart';
import '../../data/models.dart';
import '../../data/providers.dart';
import '../../widgets/common.dart';
import '../../widgets/page_kit.dart';

class CreateRoomScreen extends ConsumerStatefulWidget {
  const CreateRoomScreen({super.key});

  @override
  ConsumerState<CreateRoomScreen> createState() => _CreateRoomScreenState();
}

class _CreateRoomScreenState extends ConsumerState<CreateRoomScreen> {
  static const _tags = ['Chat', 'Music', 'Games', 'Friends', 'Dating', 'Poetry'];
  static const _covers = [
    [Color(0xFF7C3AED), Color(0xFFDB2777)],
    [Color(0xFF0EA5E9), Color(0xFF6366F1)],
    [Color(0xFFF59E0B), Color(0xFFEA580C)],
    [Color(0xFF10B981), Color(0xFF0EA5E9)],
    [Color(0xFF111827), Color(0xFFB45309)],
  ];
  final _name = TextEditingController();
  final _ann = TextEditingController();
  final _pass = TextEditingController();
  int _tag = 0;
  int _cover = 0;
  int _seats = 8;
  bool _private = false;
  String? _error;

  @override
  void dispose() {
    _name.dispose();
    _ann.dispose();
    _pass.dispose();
    super.dispose();
  }

  void _create() {
    final name = _name.text.trim();
    if (name.length < 2) {
      setState(() => _error = 'Give your room a name');
      return;
    }
    if (_private && _pass.text.length < 4) {
      setState(() => _error = 'Password must be 4–6 digits');
      return;
    }
    final me = ref.read(sessionProvider)!;
    final room = Room(
      id: 900000 + DateTime.now().millisecond * 37 % 99999,
      name: name,
      tag: _tags[_tag],
      owner: me,
      announcement: _ann.text.trim(),
      online: 1,
      cover: _covers[_cover],
      password: _private ? _pass.text : '',
      seatCount: _seats,
    );
    ref.read(createdRoomsProvider.notifier).add(room);
    context.pushReplacement('/room', extra: room);
  }

  @override
  Widget build(BuildContext context) {
    return YoloPage(
      title: 'Create room',
      body: ListView(padding: const EdgeInsets.fromLTRB(20, 8, 20, 40), children: [
        Center(
          child: Container(
            width: 96,
            height: 96,
            decoration: BoxDecoration(borderRadius: BorderRadius.circular(28), gradient: LinearGradient(colors: _covers[_cover])),
            alignment: Alignment.center,
            child: Text(_name.text.isEmpty ? '?' : _name.text[0].toUpperCase(), style: const TextStyle(fontSize: 40, fontWeight: FontWeight.w800)),
          ),
        ),
        const SizedBox(height: 12),
        Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          for (var i = 0; i < _covers.length; i++)
            Semantics(
              button: true,
              selected: _cover == i,
              label: 'Cover ${i + 1}',
              child: GestureDetector(
                onTap: () => setState(() => _cover = i),
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 6),
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(colors: _covers[i]),
                    border: Border.all(color: _cover == i ? YoloColors.gold : Colors.white24, width: _cover == i ? 3 : 1),
                  ),
                ),
              ),
            ),
        ]),
        const SizedBox(height: 18),
        TextField(controller: _name, maxLength: 30, onChanged: (_) => setState(() {}), decoration: const InputDecoration(labelText: 'Room name')),
        TextField(controller: _ann, maxLength: 120, maxLines: 2, decoration: const InputDecoration(labelText: 'Announcement (optional)')),
        const SizedBox(height: 8),
        const Text('Category', style: TextStyle(fontWeight: FontWeight.w700)),
        const SizedBox(height: 8),
        Wrap(spacing: 8, runSpacing: 8, children: [
          for (var i = 0; i < _tags.length; i++)
            ChoiceChip(
              label: Text(_tags[i]),
              selected: _tag == i,
              onSelected: (_) => setState(() => _tag = i),
              selectedColor: YoloColors.gold,
              showCheckmark: false,
              labelStyle: TextStyle(color: _tag == i ? YoloColors.onGold : YoloColors.text, fontWeight: FontWeight.w700),
            ),
        ]),
        const SizedBox(height: 16),
        const Text('Mic seats', style: TextStyle(fontWeight: FontWeight.w700)),
        const SizedBox(height: 8),
        SegmentedButton<int>(
          segments: const [ButtonSegment(value: 8, label: Text('8 seats')), ButtonSegment(value: 12, label: Text('12 seats'))],
          selected: {_seats},
          onSelectionChanged: (s) => setState(() => _seats = s.first),
        ),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('Private room'),
          subtitle: const Text('Only people with the password can enter', style: TextStyle(fontSize: 12)),
          value: _private,
          activeThumbColor: YoloColors.gold,
          onChanged: (v) => setState(() => _private = v),
        ),
        if (_private)
          TextField(
            controller: _pass,
            keyboardType: TextInputType.number,
            maxLength: 6,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            decoration: const InputDecoration(labelText: 'Password (4–6 digits)'),
          ),
        if (_error != null) Padding(padding: const EdgeInsets.only(top: 8), child: Text(_error!, style: const TextStyle(color: Color(0xFFF87171)))),
        const SizedBox(height: 20),
        GoldButton(label: 'Create room', icon: Icons.mic_rounded, onPressed: _create),
      ]),
    );
  }
}
