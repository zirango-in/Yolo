import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:material_ui/material_ui.dart';

import 'package:yolo/data/cp_providers.dart';
import 'package:yolo/data/notifications_providers.dart';
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

  testWidgets('CP & relationships: accept, CP space, intimacy from gifts, request + auto-accept, slots, ranking, profiles, break up', (tester) async {
    final original = FlutterError.onError;
    FlutterError.onError = (d) {
      if (!d.exceptionAsString().contains('overflowed')) original?.call(d);
    };
    await tester.binding.setSurfaceSize(const Size(390, 1000));
    await tester.pumpWidget(const ProviderScope(child: YoloApp()));
    await settle(tester);
    final c = ProviderScope.containerOf(tester.element(find.byType(YoloApp)));
    final login = c.read(sessionProvider.notifier).login('google');
    await settle(tester);
    await login;
    final router = c.read(routerProvider);
    router.go('/home');
    await settle(tester);
    CpState cp() => c.read(cpProvider);

    // Relationships page: no CP yet, Mia is a best friend, Leo's couple request waiting
    router.push('/cp');
    await settle(tester);
    expect(find.text('Find your CP'), findsOneWidget);
    expect(find.text('Mia'), findsOneWidget);
    expect(find.text('Wants to be your Couple'), findsOneWidget);
    await tester.tap(find.text('Accept'));
    await settle(tester);
    expect(cp().couple?.partner.id, 2005);
    expect(find.text('Aria & Leo'), findsOneWidget);

    // CP space: gift raises intimacy
    await tester.tap(find.text('Aria & Leo'));
    await settle(tester);
    expect(find.text('Level rewards'), findsOneWidget);
    final before = cp().couple!.intimacy;
    await tester.tap(find.text('Send a gift to grow intimacy'));
    await settle(tester);
    await tester.tap(find.text('Crown').last);
    await tester.tap(find.text('Send'));
    await settle(tester);
    expect(cp().couple!.intimacy, before + 52);
    router.pop();
    await settle(tester);

    // Send a Brother request to Kenji (Diamond 999) → accepted after 3 s + notification
    final coins = c.read(sessionProvider)!.coins;
    await tester.tap(find.text('New relationship'));
    await settle(tester);
    await tester.tap(find.textContaining('Brother').last);
    await settle(tester);
    await tester.tap(find.text('Kenji').last);
    await settle(tester);
    await tester.tap(find.text('Send request'));
    await settle(tester);
    expect(c.read(sessionProvider)!.coins, coins - 999);
    expect(cp().requests.any((r) => r.user.id == 2002 && !r.incoming), isTrue);
    await settle(tester, 35);
    expect(cp().relations.any((r) => r.type == 'brother' && r.partner.id == 2002), isTrue);
    expect(c.read(notificationsProvider).first.title, 'Brother accepted');

    // Couple slot is full now
    expect(c.read(cpProvider.notifier).sendRequest('couple', userById(2001)), contains('slots are full'));

    // Ranking includes my couple
    router.push('/cp/ranking');
    await settle(tester);
    expect(find.text('Aria & Leo'), findsOneWidget);
    router.pop();
    await settle(tester);

    // Other profiles show their CP
    router.push('/user', extra: userById(2001));
    await settle(tester);
    expect(find.text('CP: Omar'), findsOneWidget);
    router.pop();
    await settle(tester);

    // Break up the couple
    router.push('/cp/space', extra: cp().couple!);
    await settle(tester);
    await tester.scrollUntilVisible(find.text('End couple'), 200, scrollable: find.byType(Scrollable).first);
    await tester.tap(find.text('End couple'));
    await settle(tester);
    await tester.tap(find.text('End'));
    await settle(tester);
    expect(cp().couple, isNull);

    await tester.pumpWidget(const SizedBox());
    await settle(tester, 40);
    FlutterError.onError = original;
  });
}
