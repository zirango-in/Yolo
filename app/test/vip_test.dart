import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:material_ui/material_ui.dart';

import 'package:yolo/data/providers.dart';
import 'package:yolo/data/vip_providers.dart';
import 'package:yolo/main.dart';

Future<void> settle(WidgetTester t, [int frames = 12]) async {
  for (var i = 0; i < frames; i++) {
    await t.pump(const Duration(milliseconds: 100));
  }
}

void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  testWidgets('VIP: daily coins, browse tiers, upgrade with credit, ring, cancel, history', (tester) async {
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

    router.push('/vip');
    await settle(tester);
    expect(find.text('VIP 5 · Marquis'), findsWidgets);

    // Daily VIP coins (VIP 5 = 1,500)
    var before = coins();
    await tester.tap(find.text('+1,500'));
    await settle(tester);
    expect(coins(), before + 1500);

    // Upgrade to VIP 6 without enough coins → message
    // VIP 6 is off-screen in the tier strip: scroll it into view first.
    final strip = find.byWidgetPredicate((w) => w is Scrollable && w.axisDirection == AxisDirection.right).first;
    await tester.scrollUntilVisible(find.text('Duke'), 80, scrollable: strip);
    await settle(tester);
    await tester.tap(find.text('Duke'));
    await settle(tester);
    expect(find.text('Upgrade to VIP 6'), findsOneWidget);
    await tester.tap(find.text('Upgrade to VIP 6'));
    await settle(tester);
    await tester.tap(find.text('Confirm'));
    await settle(tester);
    expect(find.text('Not enough coins'), findsOneWidget);
    expect(c.read(sessionProvider)!.vipLevel, 5);

    // With enough coins: pays 300,000 − credit for 18 unused VIP 5 days (60,000) = 240,000
    c.read(sessionProvider.notifier).earn(500000);
    await settle(tester, 20);
    before = coins();
    await tester.tap(find.text('Upgrade to VIP 6'));
    await settle(tester);
    expect(find.text('You pay 240,000 coins'), findsOneWidget);
    await tester.tap(find.text('Confirm'));
    await settle(tester);
    expect(coins(), before - 240000);
    expect(c.read(sessionProvider)!.vipLevel, 6);
    expect(c.read(vipProvider).daysLeft, 30);

    // Lower tier button is disabled
    await tester.scrollUntilVisible(find.text('Viscount'), -80, scrollable: strip);
    await settle(tester);
    await tester.tap(find.text('Viscount'));
    await settle(tester);
    expect(find.text('You already have a higher level.'), findsOneWidget);

    // VIP ring
    await tester.scrollUntilVisible(find.text('Equip'), 200, scrollable: find.byType(Scrollable).first);
    await tester.tap(find.text('Equip'));
    await settle(tester);
    expect(c.read(vipProvider).ringEquipped, isTrue);

    // Manage → cancel auto-renew
    router.push('/vip/manage');
    await settle(tester);
    await tester.tap(find.text('Cancel subscription'));
    await settle(tester);
    expect(c.read(vipProvider).autoRenew, isFalse);
    router.pop();
    await settle(tester);

    // History
    router.push('/vip/history');
    await settle(tester);
    expect(find.text('VIP 6 Duke · upgrade'), findsOneWidget);

    await tester.pumpWidget(const SizedBox());
    await settle(tester, 30);
    FlutterError.onError = original;
  });
}
