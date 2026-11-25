import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:material_ui/material_ui.dart';

import 'package:yolo/data/family_providers.dart';
import 'package:yolo/data/providers.dart';
import 'package:yolo/main.dart';

Future<void> settle(WidgetTester t, [int frames = 12]) async {
  for (var i = 0; i < frames; i++) {
    await t.pump(const Duration(milliseconds: 100));
  }
}

void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  testWidgets('family: search, join, sign in, donate, quests, chests, roll, shop, members, ranking, leave, create', (tester) async {
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
    FamilyState fam() => c.read(familyProvider);

    // Search and open a family profile, join it
    router.push('/family');
    await settle(tester);
    await tester.enterText(find.byType(TextField), 'ocean');
    await settle(tester);
    expect(find.text('Ocean Breeze'), findsOneWidget);
    await tester.tap(find.text('Ocean Breeze'));
    await settle(tester);
    await tester.tap(find.text('Join family'));
    await settle(tester);
    expect(fam().familyId, 3);
    expect(find.text('Family funds'), findsOneWidget);

    // Sign in
    await tester.tap(find.text('Sign in'));
    await settle(tester);
    expect(fam().signedIn, isTrue);
    expect(fam().activeness, 10);
    expect(fam().familyCoins, 20);

    // Donate 1,000
    final coins = c.read(sessionProvider)!.coins;
    final funds = fam().funds;
    await tester.tap(find.text('Donate'));
    await settle(tester);
    await tester.tap(find.text('1,000'));
    await settle(tester);
    expect(c.read(sessionProvider)!.coins, coins - 1000);
    expect(fam().funds, funds + 1000);

    // Quests: claim completed ones; open a chest
    router.push('/family/quests');
    await settle(tester);
    await tester.tap(find.text('Claim').first);
    await settle(tester);
    expect(fam().claimedQuests, isNotEmpty);
    final before = c.read(sessionProvider)!.coins;
    await tester.tap(find.text('Open').first);
    await settle(tester);
    expect(fam().claimedChests.contains(0), isTrue);
    expect(c.read(sessionProvider)!.coins, before + 100);
    router.pop();
    await settle(tester);

    // Lucky roll: free roll
    router.push('/family/gacha');
    await settle(tester);
    await tester.tap(find.text('Free roll today'));
    await settle(tester, 40);
    expect(fam().freeRollUsed, isTrue);
    expect(find.textContaining('You won'), findsOneWidget);
    router.pop();
    await settle(tester);

    // Family shop: buy and equip a title
    router.push('/family/shop');
    await settle(tester);
    await tester.tap(find.text('Guardian'));
    await settle(tester);
    expect(fam().title, 'Guardian');
    router.pop();
    await settle(tester);

    // Members and ranking open
    router.push('/family/members');
    await settle(tester);
    expect(find.text('Aria (you)'), findsOneWidget);
    router.pop();
    await settle(tester);
    router.push('/family/ranking');
    await settle(tester);
    expect(find.text('Ocean Breeze'), findsOneWidget);
    router.pop();
    await settle(tester);

    // Leave
    await tester.tap(find.text('Leave'));
    await settle(tester);
    await tester.tap(find.text('Leave').last);
    await settle(tester);
    expect(fam().familyId, isNull);

    // Create a family (5,000 coins) → leader, can upgrade members
    await tester.tap(find.text('Create'));
    await settle(tester);
    await tester.enterText(find.byType(TextField).first, 'Night Kings');
    await tester.tap(find.text('Create for 5,000 coins'));
    await settle(tester);
    expect(fam().role, 'leader');
    expect(find.text('Night Kings'), findsOneWidget);
    expect(find.text('Upgrade'), findsOneWidget);
    await tester.tap(find.text('Upgrade'));
    await settle(tester);
    expect(find.textContaining('family funds'), findsWidgets);

    await tester.pumpWidget(const SizedBox());
    await settle(tester, 30);
    FlutterError.onError = original;
  });
}
