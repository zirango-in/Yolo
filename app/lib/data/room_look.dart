import 'dart:io';
import 'dart:math';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:material_ui/material_ui.dart';

/// Everything that makes a voice room look the way it does. Built from the room's theme
/// or its custom background photo, and read by every part of the room (background, seats,
/// header pills, chat bubbles, buttons, menus) so a change re-colours the whole room at once.
@immutable
class RoomLook {
  const RoomLook({
    required this.name,
    required this.bg,
    required this.accent,
    required this.panel,
    this.imagePath,
    this.imageAlignY = 0,
  });

  final String name;

  /// Background gradient, top → bottom (used under a photo as well, while it loads).
  final List<Color> bg;

  /// Highlights: seat rings, selected items, icons, links.
  final Color accent;

  /// Glass colour for pills, chat bubbles, buttons and menus.
  final Color panel;

  /// Custom background photo (fills the room, cropped — never stretched).
  final String? imagePath;

  /// Vertical crop position of the photo, -1 (top) … 1 (bottom).
  final double imageAlignY;

  /// Text / icon colour that stays readable on [accent].
  Color get onAccent => accent.computeLuminance() > 0.45 ? const Color(0xFF1A1200) : Colors.white;

  /// Solid colour for menus and drawers (panel without transparency, a bit lighter).
  Color get sheet => Color.alphaBlend(panel.withValues(alpha: 0.92), bg.last);

  @override
  bool operator ==(Object other) =>
      other is RoomLook && other.name == name && other.accent == accent && other.imagePath == imagePath && other.imageAlignY == imageAlignY && other.panel == panel;

  @override
  int get hashCode => Object.hash(name, accent, imagePath, imageAlignY, panel);

  /// Predefined themes. Index = RoomState.theme.
  static const themes = [
    RoomLook(name: 'Royal', bg: [Color(0xFF5B21B6), Color(0xFF2E1065), Color(0xFF12082A)], accent: Color(0xFFF5C451), panel: Color(0x66160A33)),
    RoomLook(name: 'Ocean', bg: [Color(0xFF0369A1), Color(0xFF0C4A6E), Color(0xFF041627)], accent: Color(0xFF67E8F9), panel: Color(0x66031A2E)),
    RoomLook(name: 'Rose', bg: [Color(0xFFDB2777), Color(0xFF831843), Color(0xFF1F0A17)], accent: Color(0xFFFBCFE8), panel: Color(0x662A0A1C)),
    RoomLook(name: 'Forest', bg: [Color(0xFF16A34A), Color(0xFF14532D), Color(0xFF05140C)], accent: Color(0xFFBBF7D0), panel: Color(0x66061A0F)),
    RoomLook(name: 'Sunset', bg: [Color(0xFFF97316), Color(0xFF9A3412), Color(0xFF1C0D05)], accent: Color(0xFFFED7AA), panel: Color(0x66241005)),
    RoomLook(name: 'Midnight', bg: [Color(0xFF475569), Color(0xFF1E293B), Color(0xFF020617)], accent: Color(0xFFE2E8F0), panel: Color(0x66020617)),
    RoomLook(name: 'Club', bg: [Color(0xFFC026D3), Color(0xFF581C87), Color(0xFF0F0A1F)], accent: Color(0xFFF0ABFC), panel: Color(0x66180826)),
    RoomLook(name: 'Golden Party', bg: [Color(0xFFD97706), Color(0xFF78350F), Color(0xFF1A0E02)], accent: Color(0xFFFDE68A), panel: Color(0x66221203)),
    RoomLook(name: 'Diamond Party', bg: [Color(0xFF06B6D4), Color(0xFF155E75), Color(0xFF06121C)], accent: Color(0xFFCFFAFE), panel: Color(0x66061826)),
    RoomLook(name: 'Starfield', bg: [Color(0xFF3730A3), Color(0xFF1E1B4B), Color(0xFF030014)], accent: Color(0xFFC7D2FE), panel: Color(0x66080628)),
    RoomLook(name: 'Future City', bg: [Color(0xFF0D9488), Color(0xFF134E4A), Color(0xFF0B1220)], accent: Color(0xFF5EEAD4), panel: Color(0x66061A1A)),
  ];

  static RoomLook theme(int i) => themes[i.clamp(0, themes.length - 1)];

  /// Look for a custom photo: colours are derived from the photo's own main colour,
  /// so every background gets a matching accent instead of the same default scheme.
  factory RoomLook.photo(String path, Color dominant, {double alignY = 0}) {
    final hsl = HSLColor.fromColor(dominant);
    final s = max(hsl.saturation, 0.45);
    final accent = hsl.withSaturation(s).withLightness(0.72).toColor();
    final dark = hsl.withSaturation(min(s, 0.6)).withLightness(0.10).toColor();
    final mid = hsl.withSaturation(min(s, 0.6)).withLightness(0.22).toColor();
    return RoomLook(
      name: 'Custom',
      bg: [mid, dark, Color.lerp(dark, Colors.black, 0.5)!],
      accent: accent,
      panel: dark.withValues(alpha: 0.55),
      imagePath: path,
      imageAlignY: alignY,
    );
  }
}

/// Makes the room look available to every widget inside the voice room.
class RoomLookScope extends InheritedWidget {
  const RoomLookScope({super.key, required this.look, required super.child});
  final RoomLook look;

  static RoomLook of(BuildContext context) => context.dependOnInheritedWidgetOfExactType<RoomLookScope>()?.look ?? RoomLook.themes.first;

  @override
  bool updateShouldNotify(RoomLookScope old) => old.look != look;
}

/// Main colour of a photo (decoded at 32 px wide, so it is cheap). Vivid pixels count more
/// than grey ones, so the result is the colour people actually notice.
Future<Color> dominantColorOf(String path) async {
  final Uint8List bytes = await File(path).readAsBytes();
  final codec = await ui.instantiateImageCodec(bytes, targetWidth: 32);
  final frame = await codec.getNextFrame();
  final data = await frame.image.toByteData(format: ui.ImageByteFormat.rawRgba);
  frame.image.dispose();
  if (data == null) return const Color(0xFF5B21B6);
  double r = 0, g = 0, b = 0, w = 0;
  for (var i = 0; i + 3 < data.lengthInBytes; i += 4) {
    final pr = data.getUint8(i) / 255, pg = data.getUint8(i + 1) / 255, pb = data.getUint8(i + 2) / 255;
    final mx = max(pr, max(pg, pb)), mn = min(pr, min(pg, pb));
    final weight = 0.15 + (mx - mn) * 2; // saturation weight
    r += pr * weight;
    g += pg * weight;
    b += pb * weight;
    w += weight;
  }
  if (w == 0) return const Color(0xFF5B21B6);
  return Color.fromARGB(255, (r / w * 255).round(), (g / w * 255).round(), (b / w * 255).round());
}
