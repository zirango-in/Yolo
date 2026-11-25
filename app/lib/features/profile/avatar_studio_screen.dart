import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../core/theme.dart';
import '../../data/profile_providers.dart';
import '../../widgets/avatar_figure.dart';
import '../../widgets/common.dart';
import '../../widgets/page_kit.dart';

/// Avatar customization: face, hairstyle, outfit, accessories.
class AvatarStudioScreen extends ConsumerStatefulWidget {
  const AvatarStudioScreen({super.key});

  @override
  ConsumerState<AvatarStudioScreen> createState() => _AvatarStudioScreenState();
}

class _AvatarStudioScreenState extends ConsumerState<AvatarStudioScreen> {
  late AvatarConfig _c = ref.read(profileExtrasProvider).avatar;
  int _tab = 0;

  void _save() {
    ref.read(profileExtrasProvider.notifier).update((x) => x.copyWith(avatar: _c, useAvatarFigure: true, clearPhoto: true));
    showYoloToast(context, 'Avatar saved');
    context.pop();
  }

  Widget _options(List<String> names, int selected, ValueChanged<int> onPick) => Wrap(spacing: 10, runSpacing: 10, children: [
        for (var i = 0; i < names.length; i++)
          ChoiceChip(
            label: Text(names[i]),
            selected: i == selected,
            onSelected: (_) => onPick(i),
            selectedColor: YoloColors.gold,
            labelStyle: TextStyle(color: i == selected ? YoloColors.onGold : YoloColors.text, fontWeight: FontWeight.w700),
            backgroundColor: Colors.white.withValues(alpha: 0.06),
            shape: const StadiumBorder(),
            showCheckmark: false,
          ),
      ]);

  Widget _swatches(List<Color> colors, int selected, ValueChanged<int> onPick, String label) => Wrap(spacing: 12, runSpacing: 12, children: [
        for (var i = 0; i < colors.length; i++)
          Semantics(
            button: true,
            selected: i == selected,
            label: '$label ${i + 1}',
            child: GestureDetector(
              onTap: () => onPick(i),
              child: AnimatedContainer(
                duration: 200.ms,
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: colors[i],
                  shape: BoxShape.circle,
                  border: Border.all(color: i == selected ? YoloColors.gold : Colors.white24, width: i == selected ? 3 : 1),
                ),
              ),
            ),
          ),
      ]);

  @override
  Widget build(BuildContext context) {
    final panels = [
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('Skin tone', style: TextStyle(fontWeight: FontWeight.w700)),
        const SizedBox(height: 10),
        _swatches(AvatarConfig.skins, _c.skin, (i) => setState(() => _c = _c.copyWith(skin: i)), 'Skin'),
        const SizedBox(height: 18),
        const Text('Eyes', style: TextStyle(fontWeight: FontWeight.w700)),
        const SizedBox(height: 10),
        _options(AvatarConfig.eyeNames, _c.eyes, (i) => setState(() => _c = _c.copyWith(eyes: i))),
      ]),
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('Hairstyle', style: TextStyle(fontWeight: FontWeight.w700)),
        const SizedBox(height: 10),
        _options(AvatarConfig.hairNames, _c.hair, (i) => setState(() => _c = _c.copyWith(hair: i))),
        const SizedBox(height: 18),
        const Text('Hair color', style: TextStyle(fontWeight: FontWeight.w700)),
        const SizedBox(height: 10),
        _swatches(AvatarConfig.hairColors, _c.hairColor, (i) => setState(() => _c = _c.copyWith(hairColor: i)), 'Hair color'),
      ]),
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('Outfit', style: TextStyle(fontWeight: FontWeight.w700)),
        const SizedBox(height: 10),
        _options(AvatarConfig.outfitNames, _c.outfit, (i) => setState(() => _c = _c.copyWith(outfit: i))),
        const SizedBox(height: 18),
        const Text('Outfit color', style: TextStyle(fontWeight: FontWeight.w700)),
        const SizedBox(height: 10),
        _swatches(AvatarConfig.outfitColors, _c.outfitColor, (i) => setState(() => _c = _c.copyWith(outfitColor: i)), 'Outfit color'),
      ]),
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('Accessories', style: TextStyle(fontWeight: FontWeight.w700)),
        const SizedBox(height: 10),
        _options(AvatarConfig.accessoryNames, _c.accessory, (i) => setState(() => _c = _c.copyWith(accessory: i))),
      ]),
    ];

    return YoloPage(
      title: 'Avatar studio',
      actions: [TextButton(onPressed: _save, child: const Text('Save', style: TextStyle(color: YoloColors.gold, fontWeight: FontWeight.w800)))],
      body: Column(children: [
        const SizedBox(height: 8),
        AvatarFigure(config: _c, size: 200)
            .animate(key: ValueKey(_c.hashCode ^ _c.hair ^ _c.accessory ^ _c.outfit))
            .scaleXY(begin: 0.96, end: 1, duration: 200.ms, curve: Curves.easeOut),
        const SizedBox(height: 10),
        TextButton.icon(
          onPressed: () => setState(() => _c = AvatarConfig(
                skin: DateTime.now().millisecond % 5,
                hair: DateTime.now().microsecond % 6,
                hairColor: DateTime.now().millisecond % 6,
                outfit: DateTime.now().microsecond % 4,
                outfitColor: (DateTime.now().millisecond ~/ 7) % 6,
                accessory: (DateTime.now().microsecond ~/ 3) % 6,
                eyes: DateTime.now().millisecond % 4,
              )),
          icon: const Icon(Icons.casino_rounded, color: YoloColors.gold),
          label: const Text('Randomize', style: TextStyle(color: YoloColors.gold)),
        ),
        YoloTabs(tabs: const ['Face', 'Hair', 'Outfit', 'Accessories'], index: _tab, onChanged: (i) => setState(() => _tab = i)),
        Expanded(
          child: Container(
            width: double.infinity,
            decoration: const BoxDecoration(color: YoloColors.sheet, borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
            child: SingleChildScrollView(padding: const EdgeInsets.all(20), child: panels[_tab]),
          ),
        ),
        Container(
          color: YoloColors.sheet,
          padding: EdgeInsets.fromLTRB(20, 0, 20, MediaQuery.paddingOf(context).bottom + 12),
          child: GoldButton(label: 'Use this avatar', onPressed: _save),
        ),
      ]),
    );
  }
}
