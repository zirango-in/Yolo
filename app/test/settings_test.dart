import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:material_ui/material_ui.dart';

import 'package:yolo/data/providers.dart';
import 'package:yolo/data/settings_providers.dart';
import 'package:yolo/main.dart';

Future<void> settle(WidgetTester t, [int frames = 12]) async {
  for (var i = 0; i < frames; i++) {
    await t.pump(const Duration(milliseconds: 100));
  }
}

void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  testWidgets('settings: privacy, notifications, sound, language RTL, text size, permissions, storage, logout', (tester) async {
    final original = FlutterError.onError;
    FlutterError.onError = (d) {
      if (!d.exceptionAsString().contains('overflowed')) original?.call(d);
    };
    await tester.binding.setSurfaceSize(const Size(390, 1100));
    await tester.pumpWidget(const ProviderScope(child: YoloApp()));
    await settle(tester);
    final c = ProviderScope.containerOf(tester.element(find.byType(YoloApp)));
    final login = c.read(sessionProvider.notifier).login('google');
    await settle(tester);
    await login;
    final router = c.read(routerProvider);
    router.go('/home');
    await settle(tester);
    AppSettings s() => c.read(settingsProvider);

    router.push('/settings');
    await settle(tester);

    // Privacy
    await tester.tap(find.text('Privacy'));
    await settle(tester);
    await tester.tap(find.text('Friends only'));
    await tester.tap(find.text('Hide my online status'));
    await settle(tester);
    expect(s().whoCanMessage, 'friends');
    expect(s().hideOnline, isTrue);
    router.pop();
    await settle(tester);

    // Notifications
    await tester.tap(find.text('Notifications'));
    await settle(tester);
    await tester.tap(find.text('Gifts received'));
    await tester.tap(find.text('Do not disturb'));
    await settle(tester);
    expect(s().notify['gifts'], isFalse);
    expect(s().doNotDisturb, isTrue);
    router.pop();
    await settle(tester);

    // Sound
    await tester.tap(find.text('Sound'));
    await settle(tester);
    await tester.tap(find.text('Gift sounds'));
    await settle(tester);
    expect(s().giftSounds, isFalse);
    router.pop();
    await settle(tester);

    // Language → Arabic switches to right-to-left
    await tester.tap(find.text('Language'));
    await settle(tester);
    await tester.tap(find.text('العربية'));
    await settle(tester);
    expect(s().language, 'ar');
    expect(Directionality.of(tester.element(find.text('العربية'))), TextDirection.rtl);
    await tester.tap(find.text('English').first);
    await settle(tester);
    expect(Directionality.of(tester.element(find.text('English').first)), TextDirection.ltr);
    router.pop();
    await settle(tester);

    // Theme & display → Large text
    await tester.tap(find.text('Theme'));
    await settle(tester);
    await tester.tap(find.text('Large'));
    await settle(tester);
    expect(s().textScale, 1.15);
    expect(MediaQuery.textScalerOf(tester.element(find.text('Large'))).scale(10), closeTo(11.5, 0.01));
    await tester.tap(find.text('Default'));
    await settle(tester);
    router.pop();
    await settle(tester);

    // Permissions page renders (plugins are not available in tests)
    await tester.tap(find.text('Permissions'));
    await settle(tester);
    expect(find.text('Microphone'), findsOneWidget);
    expect(find.text('Camera'), findsOneWidget);
    router.pop();
    await settle(tester);

    // Cache & storage → clear
    await tester.tap(find.text('Clear cache'));
    await settle(tester);
    await tester.tap(find.textContaining('Clear cache ('));
    await settle(tester);
    expect(find.text('Cache is empty'), findsOneWidget);
    router.pop();
    await settle(tester);

    // Logout
    await tester.scrollUntilVisible(find.text('Log out'), 200, scrollable: find.byType(Scrollable).first);
    await tester.tap(find.text('Log out'));
    await settle(tester);
    expect(c.read(sessionProvider), isNull);

    await tester.pumpWidget(const SizedBox());
    await settle(tester, 30);
    FlutterError.onError = original;
  });
}
