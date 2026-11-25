import 'dart:io';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:material_ui/material_ui.dart';

import '../../core/theme.dart';
import '../../data/models.dart';
import '../../data/providers.dart';
import '../../data/room_levels.dart';
import '../../data/room_look.dart';
import '../../widgets/page_kit.dart';
import 'room_background.dart';
import 'room_sheets.dart';

/// Room theme picker: predefined themes as live previews, plus upload / remove a custom photo.
/// Changes apply to the open room immediately (and are saved / sent to the server).
void showRoomThemeSheet(BuildContext context, WidgetRef ref, Room room) {
  showRoomSheet<void>(
    context,
    scroll: true,
    (c) => Consumer(builder: (c, ref, _) {
      final st = ref.watch(roomProvider(room));
      final ctrl = ref.read(roomProvider(room).notifier);
      final lvl = levelForExp(st.exp).level;
      final custom = st.bgPath != null;

      Widget tile({required RoomLook look, required String label, required bool selected, bool locked = false, String? lockText, required VoidCallback onTap, IconData? icon}) =>
          Semantics(
            button: true,
            selected: selected,
            excludeSemantics: true,
            label: label,
            child: GestureDetector(
              onTap: onTap,
              child: Column(children: [
                AspectRatio(
                  aspectRatio: 0.72,
                  child: Container(
                    clipBehavior: Clip.antiAlias,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: selected ? look.accent : Colors.white12, width: selected ? 2 : 1),
                    ),
                    child: Stack(fit: StackFit.expand, children: [
                      RoomBackdrop(look: look),
                      // mini seats in the theme's accent
                      Align(
                        alignment: const Alignment(0, -0.2),
                        child: Wrap(spacing: 5, runSpacing: 5, children: [
                          for (var i = 0; i < 4; i++)
                            Container(width: 13, height: 13, decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: look.accent, width: 1.5))),
                        ]),
                      ),
                      if (icon != null) Center(child: Icon(icon, color: Colors.white, size: 28)),
                      if (locked)
                        Container(
                          color: Colors.black54,
                          alignment: Alignment.center,
                          child: Column(mainAxisSize: MainAxisSize.min, children: [
                            const Icon(Icons.lock_rounded, size: 18),
                            Text(lockText ?? '', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700)),
                          ]),
                        ),
                      if (selected)
                        Positioned(
                          right: 5,
                          top: 5,
                          child: CircleAvatar(radius: 9, backgroundColor: look.accent, child: Icon(Icons.check_rounded, size: 13, color: look.onAccent)),
                        ),
                    ]),
                  ),
                ),
                const SizedBox(height: 5),
                Text(label, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 11, fontWeight: selected ? FontWeight.w800 : FontWeight.w500)),
              ]),
            ),
          );

      return Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            const Expanded(child: Text('Room theme', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800))),
            if (custom)
              TextButton.icon(
                onPressed: () => ctrl.updateSettings(clearBg: true),
                icon: const Icon(Icons.hide_image_rounded, size: 18),
                label: const Text('Remove photo'),
              ),
          ]),
          const SizedBox(height: 4),
          const Text('Everyone in the room sees the new look right away.', style: TextStyle(fontSize: 12, color: YoloColors.textMuted)),
          const SizedBox(height: 12),
          GridView.count(
            crossAxisCount: 4,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            childAspectRatio: 0.58,
            children: [
              tile(
                look: custom ? st.look : RoomLook.themes[5],
                label: custom ? 'My photo' : 'Upload photo',
                selected: custom,
                icon: custom ? null : Icons.add_photo_alternate_rounded,
                onTap: () => pickRoomBackground(c, ref, room),
              ),
              for (var i = 0; i < RoomLook.themes.length; i++)
                tile(
                  look: RoomLook.themes[i],
                  label: RoomLook.themes[i].name,
                  selected: !custom && st.theme == i,
                  locked: RoomState.themeUnlock[i] > lvl,
                  lockText: 'Lv${RoomState.themeUnlock[i]}',
                  onTap: () {
                    if (RoomState.themeUnlock[i] > lvl) {
                      showYoloToast(c, 'Reach room level ${RoomState.themeUnlock[i]} to use this background');
                      return;
                    }
                    ctrl.setTheme(i);
                  },
                ),
            ],
          ),
        ]),
      );
    }),
  );
}

/// Pick a photo → preview & position it → apply. The photo is resized on pick (max 1440 px,
/// 85 % quality) so uploads stay small, and its main colour drives the room's accent colours.
Future<void> pickRoomBackground(BuildContext context, WidgetRef ref, Room room) async {
  final ctrl = ref.read(roomProvider(room).notifier);
  if (!ctrl.canManage) {
    showYoloToast(context, 'Only the owner and admins can change the background');
    return;
  }
  XFile? img;
  try {
    img = await ImagePicker().pickImage(source: ImageSource.gallery, maxWidth: 1440, maxHeight: 2560, imageQuality: 85);
  } catch (_) {
    if (context.mounted) showYoloToast(context, 'Could not open gallery');
    return;
  }
  if (img == null || !context.mounted) return;
  Color dominant;
  try {
    dominant = await dominantColorOf(img.path);
  } catch (_) {
    dominant = const Color(0xFF5B21B6);
  }
  if (!context.mounted) return;
  final align = await showBackgroundPreview(context, img.path, dominant);
  if (align == null || !context.mounted) return;
  try {
    final url = await ref.read(repositoryProvider).uploadRoomBackground(room.id, img.path);
    ctrl.updateSettings(bgPath: url, bgAccent: dominant.toARGB32(), bgAlignY: align);
    if (context.mounted) showYoloToast(context, 'Background updated');
  } catch (_) {
    if (context.mounted) showYoloToast(context, 'Upload failed — check your connection');
  }
}

/// Full-screen preview of how the room will look. Drag up/down (or use the slider) to choose
/// which part of the photo shows. Returns the vertical position, or null if cancelled.
Future<double?> showBackgroundPreview(BuildContext context, String path, Color dominant) {
  return Navigator.of(context, rootNavigator: true).push<double>(MaterialPageRoute(
    fullscreenDialog: true,
    builder: (_) => _BackgroundPreview(path: path, dominant: dominant),
  ));
}

class _BackgroundPreview extends StatefulWidget {
  const _BackgroundPreview({required this.path, required this.dominant});
  final String path;
  final Color dominant;

  @override
  State<_BackgroundPreview> createState() => _BackgroundPreviewState();
}

class _BackgroundPreviewState extends State<_BackgroundPreview> {
  double _y = 0;

  @override
  Widget build(BuildContext context) {
    final look = RoomLook.photo(widget.path, widget.dominant, alignY: _y);
    final h = MediaQuery.sizeOf(context).height;
    return Scaffold(
      backgroundColor: look.bg.last,
      body: GestureDetector(
        onVerticalDragUpdate: (d) => setState(() => _y = (_y - d.delta.dy / h * 3).clamp(-1.0, 1.0)),
        child: Stack(fit: StackFit.expand, children: [
          if (!kIsWeb && File(widget.path).existsSync()) RoomBackdrop(look: look),
          SafeArea(
            child: Column(children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 4, 8, 0),
                child: Row(children: [
                  IconButton(tooltip: 'Cancel', icon: const Icon(Icons.close_rounded), onPressed: () => Navigator.pop(context)),
                  const Expanded(child: Text('Preview', textAlign: TextAlign.center, style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800))),
                  const SizedBox(width: 48),
                ]),
              ),
              const Spacer(),
              // sample seats in the colours the room will use
              Wrap(spacing: 18, runSpacing: 14, alignment: WrapAlignment.center, children: [
                for (var i = 0; i < 8; i++)
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(shape: BoxShape.circle, color: look.panel, border: Border.all(color: look.accent.withValues(alpha: 0.8), width: 1.5)),
                    child: Icon(Icons.add_rounded, color: look.accent),
                  ),
              ]),
              const Spacer(),
              Container(
                margin: const EdgeInsets.all(16),
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 14),
                decoration: BoxDecoration(color: look.sheet, borderRadius: BorderRadius.circular(20)),
                child: Column(children: [
                  const Text('Drag the photo or use the slider to choose what shows', style: TextStyle(fontSize: 12, color: YoloColors.textSoft)),
                  Slider(value: _y, min: -1, max: 1, activeColor: look.accent, onChanged: (v) => setState(() => _y = v)),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      style: FilledButton.styleFrom(backgroundColor: look.accent, foregroundColor: look.onAccent),
                      onPressed: () => Navigator.pop(context, _y),
                      child: const Text('Apply background'),
                    ),
                  ),
                ]),
              ),
            ]),
          ),
        ]),
      ),
    );
  }
}
