import 'package:material_ui/material_ui.dart';
import 'package:google_fonts/google_fonts.dart';

/// Yolo premium palette — dark purple ground with gold accents.
/// Matches the design canvas.
class YoloColors {
  static const bg = Color(0xFF0D0820);
  static const surface = Color(0xFF1A1233);
  static const sheet = Color(0xFF150D2E);
  static const roomTop = Color(0xFF3B1D78);
  static const roomMid = Color(0xFF160C33);
  static const text = Color(0xFFF4F0FF);
  static const textMuted = Color(0xFFA79BC7);
  static const textSoft = Color(0xFFD9D0F2);
  static const gold = Color(0xFFF5C451);
  static const goldLight = Color(0xFFFFD97A);
  static const goldDeep = Color(0xFFE0A82E);
  static const onGold = Color(0xFF1A1200);
  static const purple = Color(0xFF8B5CF6);
  static const online = Color(0xFF4ADE80);
  static const line = Color(0x0FFFFFFF);

  static const goldGradient = LinearGradient(
    colors: [goldLight, goldDeep],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const roomBackground = RadialGradient(
    center: Alignment(0, -1.1),
    radius: 1.3,
    colors: [roomTop, roomMid, bg],
    stops: [0, 0.55, 1],
  );
}

ThemeData buildYoloTheme() {
  final base = ThemeData(brightness: Brightness.dark, useMaterial3: true);
  return base.copyWith(
    scaffoldBackgroundColor: YoloColors.bg,
    colorScheme: base.colorScheme.copyWith(
      primary: YoloColors.gold,
      onPrimary: YoloColors.onGold,
      secondary: YoloColors.purple,
      surface: YoloColors.surface,
      onSurface: YoloColors.text,
    ),
    textTheme: GoogleFonts.plusJakartaSansTextTheme(base.textTheme).apply(
      bodyColor: YoloColors.text,
      displayColor: YoloColors.text,
    ),
    splashFactory: InkSparkle.splashFactory,
    pageTransitionsTheme: const PageTransitionsTheme(
      builders: {
        TargetPlatform.android: FadeForwardsPageTransitionsBuilder(),
        TargetPlatform.iOS: FadeForwardsPageTransitionsBuilder(),
      },
    ),
  );
}
