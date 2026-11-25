import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:material_ui/material_ui.dart';

import 'package:yolo/data/providers.dart';
import 'package:yolo/data/wallet_providers.dart';
import 'package:yolo/main.dart';

Future<void> settle(WidgetTester t, [int frames = 12]) async {
  for (var i = 0; i < frames; i++) {
    await t.pump(const Duration(milliseconds: 100));
  }
}

void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  testWidgets('wallet: recharge (first double), exchange, gift card, transactions, purchases, check-in, tasks, monthly, events, invite', (tester) async {
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
    int coins() => c.read(sessionProvider)!.coins;

    // Recharge 3,000 (+150 bonus) with first-recharge double → +6,150
    router.push('/wallet');
    await settle(tester);
    expect(find.textContaining('First recharge bonus'), findsOneWidget);
    var before = coins();
    await tester.tap(find.text('3,000'));
    await settle(tester);
    await tester.tap(find.text('Pay \$4.99'));
    await settle(tester);
    expect(coins(), before + 6150);
    expect(c.read(walletProvider).orders, hasLength(1));

    // Exchange 1,000 diamonds → 100 coins
    before = coins();
    await tester.tap(find.text('Exchange'));
    await settle(tester);
    await tester.tap(find.text('1,000'));
    await settle(tester);
    expect(coins(), before + 100);

    // Gift card: invalid, then valid
    await tester.scrollUntilVisible(find.text('Redeem gift card'), 200, scrollable: find.byType(Scrollable).first);
    await tester.tap(find.text('Redeem gift card'));
    await settle(tester);
    await tester.enterText(find.byKey(const Key('gift-card')), 'nope');
    await tester.tap(find.text('Redeem'));
    await settle(tester);
    expect(find.text('Invalid gift card code'), findsOneWidget);
    await settle(tester, 20);
    before = coins();
    await tester.tap(find.text('Redeem gift card'));
    await settle(tester);
    await tester.enterText(find.byKey(const Key('gift-card')), 'welcome500');
    await tester.tap(find.text('Redeem'));
    await settle(tester);
    expect(coins(), before + 500);

    // Transactions show the ledger
    router.push('/wallet/transactions');
    await settle(tester);
    expect(find.text('Gift card WELCOME500'), findsOneWidget);
    await tester.tap(find.text('Spent'));
    await settle(tester);
    expect(find.text('Gift card WELCOME500'), findsNothing);
    router.pop();
    await settle(tester);

    // Purchase history
    router.push('/wallet/purchases');
    await settle(tester);
    expect(find.textContaining('×2'), findsOneWidget);
    router.pop();
    await settle(tester);

    // Rewards: check-in (day 3 = 80), task, monthly pack, event, invite
    router.push('/rewards');
    await settle(tester);
    before = coins();
    await tester.tap(find.text('Check in'));
    await settle(tester);
    expect(coins(), before + 80);
    expect(find.text('Checked in today'), findsOneWidget);

    await tester.tap(find.text(monthlyPackPrice));
    await settle(tester);
    expect(c.read(walletProvider).monthlyDaysLeft, 30);
    before = coins();
    await tester.tap(find.text('Claim'));
    await settle(tester);
    expect(coins(), before + monthlyPackDaily);

    before = coins();
    await tester.tap(find.text('+50'));
    await settle(tester);
    expect(coins(), before + 50);

    await tester.scrollUntilVisible(find.text('+500'), 200, scrollable: find.byType(Scrollable).first);
    await tester.drag(find.byType(Scrollable).first, const Offset(0, -150));
    await settle(tester, 25);
    before = coins();
    await tester.tap(find.text('+500'));
    await settle(tester);
    expect(coins(), before + 500);

    await tester.scrollUntilVisible(find.text('Get 500 coins per friend'), -200, scrollable: find.byType(Scrollable).first);
    await tester.tap(find.text('Get 500 coins per friend'));
    await settle(tester);
    expect(find.text('Invite friends, earn coins'), findsOneWidget);
    expect(find.text('Kenji'), findsOneWidget);

    await tester.pumpWidget(const SizedBox());
    await settle(tester, 30);
    FlutterError.onError = original;
  });
}
