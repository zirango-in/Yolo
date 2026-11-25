import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:material_ui/material_ui.dart';

import 'package:yolo/data/events_providers.dart';
import 'package:yolo/data/gift_providers.dart';
import 'package:yolo/data/providers.dart';
import 'package:yolo/data/social_providers.dart';
import 'package:yolo/main.dart';

Future<void> settle(WidgetTester t, [int frames = 12]) async {
  for (var i = 0; i < frames; i++) {
    await t.pump(const Duration(milliseconds: 100));
  }
}

void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  testWidgets('events & missions: tabs, countdown, join, points from gifts, claim, reminder, missions', (tester) async {
    final original = FlutterError.onError;
    FlutterError.onError = (d) {
      if (!d.exceptionAsString().contains('overflowed')) original?.call(d);
    };
    await tester.binding.setSurfaceSize(const Size(390, 1200));
    await tester.pumpWidget(const ProviderScope(child: YoloApp()));
    await settle(tester);
    final c = ProviderScope.containerOf(tester.element(find.byType(YoloApp)));
    final login = c.read(sessionProvider.notifier).login('google');
    await settle(tester);
    await login;
    final router = c.read(routerProvider);
    router.go('/home');
    await settle(tester);
    int coins() => c.read(sessionProvider)!.coins;

    // Events home: live events + countdown, tabs
    router.push('/events');
    await settle(tester);
    expect(find.textContaining('Ends in'), findsWidgets);
    await tester.tap(find.text('Upcoming'));
    await settle(tester);
    expect(find.text('Singing Star'), findsOneWidget);
    expect(find.textContaining('Starts in'), findsWidgets);

    // Upcoming → remind me
    await tester.tap(find.text('Singing Star'));
    await settle(tester);
    await tester.tap(find.text('Remind me'));
    await settle(tester);
    expect(c.read(eventsProvider).reminders.contains(3), isTrue);
    router.pop();
    await settle(tester);

    await tester.tap(find.text('Ended'));
    await settle(tester);
    expect(find.text('Welcome Festival'), findsOneWidget);
    await tester.tap(find.text('Current'));
    await settle(tester);

    // Gift King Week: join, then sending a Crown earns 520 points
    await tester.tap(find.text('Gift King Week').last);
    await settle(tester);
    await tester.tap(find.text('Join event'));
    await settle(tester);
    expect(c.read(eventsProvider).joined.contains(2), isTrue);
    final before = c.read(eventsProvider).points[2]!;
    c.read(giftCenterProvider.notifier).send(giftById(3), userById(2001), 1);
    await settle(tester);
    expect(c.read(eventsProvider).points[2], before + 520);

    // Claim the 520-point milestone (300 coins)
    final cBefore = coins();
    await tester.scrollUntilVisible(find.text('300 coins'), 200, scrollable: find.byType(Scrollable).first);
    await tester.tap(find.text('Claim').first);
    await settle(tester);
    expect(coins(), cBefore + 300);
    expect(find.text('Claimed'), findsOneWidget);
    expect(find.text('Leaderboard'), findsOneWidget);
    router.pop();
    await settle(tester);

    // Missions: weekly + new user claims, daily resets countdown
    router.push('/missions');
    await settle(tester);
    expect(find.textContaining('Resets in'), findsOneWidget);
    await tester.tap(find.text('Weekly'));
    await settle(tester);
    var m = coins();
    await tester.tap(find.text('Claim').first);
    await settle(tester);
    expect(coins(), m + 300);
    await tester.tap(find.text('New user'));
    await settle(tester);
    m = coins();
    await tester.tap(find.text('Claim').first);
    await settle(tester);
    expect(coins(), m + 100);
    expect(c.read(eventsProvider).claimed.contains('n1'), isTrue);

    await tester.pumpWidget(const SizedBox());
    await settle(tester, 30);
    FlutterError.onError = original;
  });
}
