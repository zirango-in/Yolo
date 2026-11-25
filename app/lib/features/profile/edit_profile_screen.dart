import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:material_ui/material_ui.dart';

import '../../core/theme.dart';
import '../../data/demo_content.dart';
import '../../data/profile_providers.dart';
import '../../data/providers.dart';
import '../../data/social_providers.dart';
import '../../widgets/avatar_figure.dart';
import '../../widgets/page_kit.dart';

class EditProfileScreen extends ConsumerStatefulWidget {
  const EditProfileScreen({super.key});

  @override
  ConsumerState<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends ConsumerState<EditProfileScreen> {
  late final _name = TextEditingController(text: ref.read(sessionProvider)?.name ?? '');
  late final _bio = TextEditingController(text: ref.read(profileExtrasProvider).bio);
  late String _gender = ref.read(sessionProvider)?.gender ?? 'female';
  late DateTime _birthday = ref.read(profileExtrasProvider).birthday;
  String? _error;

  @override
  void dispose() {
    _name.dispose();
    _bio.dispose();
    super.dispose();
  }

  int _ageOf(DateTime b) {
    final n = DateTime.now();
    return n.year - b.year - ((n.month < b.month || (n.month == b.month && n.day < b.day)) ? 1 : 0);
  }

  void _save() {
    final name = _name.text.trim();
    if (name.length < 2) {
      setState(() => _error = 'Nickname must be at least 2 characters');
      return;
    }
    ref.read(sessionProvider.notifier).updateProfile(name: name, gender: _gender, age: _ageOf(_birthday));
    ref.read(profileExtrasProvider.notifier).update((x) => x.copyWith(bio: _bio.text.trim(), birthday: _birthday));
    showYoloToast(context, 'Profile saved');
    context.pop();
  }

  void _photoSheet() {
    final extras = ref.read(profileExtrasProvider.notifier);
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: YoloColors.sheet,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      builder: (sheet) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('Profile photo', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
            const SizedBox(height: 12),
            ListTile(
              leading: const Icon(Icons.photo_library_rounded, color: YoloColors.gold),
              title: const Text('Choose from gallery'),
              onTap: () async {
                Navigator.pop(sheet);
                try {
                  final img = await ImagePicker().pickImage(source: ImageSource.gallery, maxWidth: 1024, imageQuality: 85);
                  if (img != null) extras.update((x) => x.copyWith(photoPath: img.path, useAvatarFigure: false));
                } catch (_) {
                  if (mounted) showYoloToast(context, 'Could not open gallery');
                }
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_camera_rounded, color: YoloColors.gold),
              title: const Text('Take a photo'),
              onTap: () async {
                Navigator.pop(sheet);
                try {
                  final img = await ImagePicker().pickImage(source: ImageSource.camera, maxWidth: 1024, imageQuality: 85);
                  if (img != null) extras.update((x) => x.copyWith(photoPath: img.path, useAvatarFigure: false));
                } catch (_) {
                  if (mounted) showYoloToast(context, 'Could not open camera');
                }
              },
            ),
            ListTile(
              leading: const Icon(Icons.face_retouching_natural_rounded, color: YoloColors.gold),
              title: const Text('Use my avatar'),
              onTap: () {
                Navigator.pop(sheet);
                context.push('/profile/avatar');
              },
            ),
            const SizedBox(height: 8),
            const Text('Or pick a color', style: TextStyle(color: YoloColors.textMuted)),
            const SizedBox(height: 10),
            Wrap(spacing: 12, children: [
              for (var i = 0; i < ProfileExtras.photoColors.length; i++)
                Semantics(
                  button: true,
                  label: 'Color ${i + 1}',
                  child: GestureDetector(
                    onTap: () {
                      extras.update((x) => x.copyWith(photoColor: i, clearPhoto: true, useAvatarFigure: false));
                      Navigator.pop(sheet);
                    },
                    child: Container(width: 44, height: 44, decoration: BoxDecoration(shape: BoxShape.circle, gradient: LinearGradient(colors: ProfileExtras.photoColors[i]))),
                  ),
                ),
            ]),
          ]),
        ),
      ),
    );
  }

  InputDecoration _deco(String label) => InputDecoration(
        labelText: label,
        filled: true,
        fillColor: Colors.white.withValues(alpha: 0.07),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
      );

  @override
  Widget build(BuildContext context) {
    final x = ref.watch(profileExtrasProvider);
    final owned = ref.watch(ownedItemsProvider);
    final equipped = ref.watch(equippedItemsProvider);
    final frames = demoShopItems.where((s) => s.category == 'frame' && owned.contains(s.id)).toList();

    return YoloPage(
      title: 'Edit profile',
      actions: [TextButton(onPressed: _save, child: const Text('Save', style: TextStyle(color: YoloColors.gold, fontWeight: FontWeight.w800)))],
      body: ListView(padding: const EdgeInsets.fromLTRB(20, 8, 20, 40), children: [
        Center(
          child: Stack(children: [
            GestureDetector(onTap: _photoSheet, child: const MyAvatar(size: 110)),
            Positioned(
              right: 0,
              bottom: 0,
              child: Material(
                color: YoloColors.gold,
                shape: const CircleBorder(),
                child: IconButton(tooltip: 'Change photo', icon: const Icon(Icons.camera_alt_rounded, color: YoloColors.onGold, size: 18), onPressed: _photoSheet),
              ),
            ),
          ]),
        ),
        const SizedBox(height: 8),
        Center(
          child: TextButton.icon(
            onPressed: () => context.push('/profile/avatar'),
            icon: const Icon(Icons.face_retouching_natural_rounded, color: YoloColors.gold),
            label: const Text('Customize avatar', style: TextStyle(color: YoloColors.gold)),
          ),
        ),
        const SizedBox(height: 12),
        TextField(controller: _name, maxLength: 20, decoration: _deco('Nickname').copyWith(errorText: _error)),
        const SizedBox(height: 4),
        TextField(controller: _bio, maxLength: 80, maxLines: 2, decoration: _deco('Bio')),
        const SizedBox(height: 12),
        Row(children: [
          for (final (v, label) in [('female', 'Female'), ('male', 'Male')])
            Expanded(
              child: Padding(
                padding: EdgeInsets.only(right: v == 'female' ? 6 : 0, left: v == 'male' ? 6 : 0),
                child: ChoiceChip(
                  label: SizedBox(width: double.infinity, child: Text(label, textAlign: TextAlign.center)),
                  selected: _gender == v,
                  onSelected: (_) => setState(() => _gender = v),
                  selectedColor: YoloColors.gold,
                  showCheckmark: false,
                  labelStyle: TextStyle(color: _gender == v ? YoloColors.onGold : YoloColors.text, fontWeight: FontWeight.w700),
                ),
              ),
            ),
        ]),
        const SizedBox(height: 12),
        GlassCard(
          onTap: () async {
            final d = await showDatePicker(context: context, initialDate: _birthday, firstDate: DateTime(1950), lastDate: DateTime.now());
            if (d != null) setState(() => _birthday = d);
          },
          child: Row(children: [
            const Icon(Icons.cake_rounded, color: YoloColors.gold),
            const SizedBox(width: 12),
            Expanded(child: Text('Birthday  ${_birthday.day}/${_birthday.month}/${_birthday.year}')),
            const Icon(Icons.chevron_right_rounded, color: YoloColors.textMuted),
          ]),
        ),
        const SectionTitle('Profile background'),
        SizedBox(
          height: 86,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: ProfileExtras.covers.length,
            separatorBuilder: (_, _) => const SizedBox(width: 10),
            itemBuilder: (_, i) => Semantics(
              button: true,
              selected: x.cover == i,
              label: ProfileExtras.coverNames[i],
              child: GestureDetector(
                onTap: () => ref.read(profileExtrasProvider.notifier).update((e) => e.copyWith(cover: i)),
                child: Container(
                  width: 120,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(14),
                    gradient: LinearGradient(colors: ProfileExtras.covers[i]),
                    border: Border.all(color: x.cover == i ? YoloColors.gold : Colors.transparent, width: 2.5),
                  ),
                  alignment: Alignment.bottomLeft,
                  padding: const EdgeInsets.all(8),
                  child: Text(ProfileExtras.coverNames[i], style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                ),
              ),
            ),
          ),
        ),
        SectionTitle('Avatar frame', action: 'Get more', onAction: () => context.push('/shop')),
        if (frames.isEmpty)
          const Text('No frames yet. Buy one in the shop.', style: TextStyle(color: YoloColors.textMuted))
        else
          Wrap(spacing: 12, runSpacing: 12, children: [
            for (final f in frames)
              ChoiceChip(
                avatar: Icon(f.icon, size: 18, color: f.colors.first),
                label: Text(f.name),
                selected: equipped.contains(f.id),
                showCheckmark: false,
                selectedColor: YoloColors.gold.withValues(alpha: 0.25),
                onSelected: (_) {
                  final eq = ref.read(equippedItemsProvider.notifier);
                  final wasOn = equipped.contains(f.id);
                  for (final o in frames) {
                    eq.remove(o.id);
                  }
                  if (!wasOn) eq.add(f.id);
                },
              ),
          ]),
      ]),
    );
  }
}
