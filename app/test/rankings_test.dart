import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:material_ui/material_ui.dart';

import 'package:yolo/data/providers.dart';
import 'package:yolo/main.dart';

Future<void> settle(WidgetTester t, [int frames = 12]) async {
  for (var i = 0; i < frames; i++) {
    await t.pump(const Duration(milliseconds: 100));
  }
}

void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  testWidgets('rankings: every tab, periods, friends filter, my position, open room / family', (tester) async {
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
    final rooms = c.read(roomsProvider('popular').future);
    await settle(tester);
    await rooms;
    final router = c.read(routerProvider);
    router.go('/home');
    await settle(tester);

    // From the Home header
    await tester.tap(find.bySemanticsLabel('Rankings'));
    await settle(tester);
    expect(find.text('My position'), findsOneWidget);

    // Every tab renders a podium
    for (final tab in ['Charm', 'Rooms', 'Families', 'Popular', 'Games', 'Events', 'Wealth']) {
      await tester.ensureVisible(find.text(tab));
      await settle(tester);
      await tester.tap(find.text(tab));
      await settle(tester);
      expect(find.byIcon(Icons.emoji_events_rounded), findsWidgets, reason: tab);
    }

    // Period changes the numbers (Wealth: Zara is #1)
    // Zara: 86,000 base + 520 Crown she sent = 86,520 weekly; daily = 1/6 → 14,420
    expect(find.text('86,520'), findsOneWidget);
    await tester.tap(find.text('Daily'));
    await settle(tester);
    expect(find.text('86,520'), findsNothing);
    expect(find.text('14,420'), findsOneWidget);

    // Friends-only filter keeps me and my friends
    await tester.tap(find.text('Global'));
    await settle(tester);
    expect(find.text('Friends'), findsWidgets);
    expect(find.text('My position'), findsOneWidget);

    // Rooms tab → open the top room
    await tester.ensureVisible(find.text('Rooms'));
    await tester.tap(find.text('Rooms'));
    await settle(tester);
    await tester.tap(find.text('Late Night Talks'));
    await settle(tester);
    expect(find.bySemanticsLabel('Send gift'), findsOneWidget);
    await tester.tap(find.bySemanticsLabel('Back'));
    await settle(tester);
    await tester.tap(find.text('Exit room'));
    await settle(tester);

    // Families tab → open family profile
    await tester.ensureVisible(find.text('Families'));
    await tester.tap(find.text('Families'));
    await settle(tester);
    await tester.tap(find.text('Golden Lions').first);
    await settle(tester);
    expect(find.text('Join family'), findsOneWidget);

    await tester.pumpWidget(const SizedBox());
    await settle(tester, 30);
    FlutterError.onError = original;
  });
}
