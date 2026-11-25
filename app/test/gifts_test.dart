import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:material_ui/material_ui.dart';

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

  testWidgets('gifts: store, buy to backpack, send from profile, room backpack + VIP, history, ranking, my items', (tester) async {
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

    // Gift store: categories + buy a Diamond to backpack
    router.push('/gifts');
    await settle(tester);
    expect(find.text('Rose'), findsOneWidget);
    await tester.tap(find.text('Special'));
    await settle(tester);
    expect(find.text('Castle'), findsOneWidget);
    await tester.tap(find.text('Popular'));
    await settle(tester);
    final coins = c.read(sessionProvider)!.coins;
    await tester.tap(find.text('Diamond'));
    await settle(tester);
    await tester.tap(find.text('Buy to backpack'));
    await settle(tester);
    expect(c.read(giftCenterProvider).backpack[4], 1);
    expect(c.read(sessionProvider)!.coins, coins - 999);
    router.pop();
    await settle(tester);

    // Send a gift from another user's profile
    router.push('/user', extra: userById(2003));
    await settle(tester);
    await tester.tap(find.byTooltip('Send gift'));
    await settle(tester);
    await tester.tap(find.text('Heart').last);
    await tester.tap(find.text('Send'));
    await settle(tester);
    expect(c.read(giftCenterProvider).records.first.to.id, 2003);
    expect(c.read(chatProvider('u:2003')).last.text, contains('Heart'));
    router.pop();
    await settle(tester);

    // Room: send from backpack (Diamond), and VIP gift needs VIP level
    final rooms = await c.read(roomsProvider('popular').future);
    router.push('/room', extra: rooms.first);
    await settle(tester);
    await tester.tap(find.bySemanticsLabel('Send gift'));
    await settle(tester);
    await tester.tap(find.text('Backpack'));
    await settle(tester);
    expect(find.text('×1'), findsWidgets);
    await tester.tap(find.text('Diamond'));
    await tester.tap(find.text('Send').last);
    await settle(tester);
    expect(c.read(giftCenterProvider).backpack.containsKey(4), isFalse);
    await settle(tester, 40);

    await tester.tap(find.bySemanticsLabel('Send gift'));
    await settle(tester);
    await tester.tap(find.text('VIP'));
    await settle(tester);
    await tester.tap(find.text('VIP Dragon'));
    await tester.tap(find.text('Send').last);
    await settle(tester);
    expect(find.text('Needs VIP 7'), findsOneWidget);
    await tester.tapAt(const Offset(195, 60));
    await settle(tester, 30);
    await tester.tap(find.byTooltip('Room menu'));
    await settle(tester);
    await tester.tap(find.text('Exit'));
    await settle(tester);
    await tester.tap(find.text('Exit room'));
    await settle(tester);

    // History and ranking
    router.push('/gifts/history');
    await settle(tester);
    expect(find.text('From Zara'), findsOneWidget);
    await tester.tap(find.textContaining('Sent '));
    await settle(tester);
    expect(find.text('To Mia'), findsWidgets);
    router.pop();
    await settle(tester);
    router.push('/gifts/ranking');
    await settle(tester);
    expect(find.text('Zara'), findsOneWidget);
    router.pop();
    await settle(tester);

    // My items: gifts and equip an owned frame
    router.push('/backpack');
    await settle(tester);
    expect(find.text('Rose'), findsOneWidget);
    await tester.tap(find.text('Frames'));
    await settle(tester);
    await tester.tap(find.text('Equip'));
    await settle(tester);
    expect(c.read(equippedItemsProvider).contains(2), isTrue);

    await tester.pumpWidget(const SizedBox());
    await settle(tester, 30);
    FlutterError.onError = original;
  });
}
