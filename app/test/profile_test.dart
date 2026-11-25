import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:material_ui/material_ui.dart';

import 'package:yolo/data/profile_providers.dart';
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

  testWidgets('profile: edit, avatar studio, background, frame, levels, badges, achievements, other profile', (tester) async {
    final original = FlutterError.onError;
    FlutterError.onError = (d) {
      if (!d.exceptionAsString().contains('overflowed')) original?.call(d);
    };
    await tester.binding.setSurfaceSize(const Size(390, 844));
    await tester.pumpWidget(const ProviderScope(child: YoloApp()));
    await settle(tester);
    final c = ProviderScope.containerOf(tester.element(find.byType(YoloApp)));
    final login = c.read(sessionProvider.notifier).login('google');
    await settle(tester);
    await login;
    final router = c.read(routerProvider);
    router.go('/home');
    await settle(tester);

    // Me tab shows profile sections
    await tester.tap(find.text('Me'));
    await settle(tester);
    expect(find.text('Avatar studio'), findsOneWidget);
    expect(find.text('Badges'), findsOneWidget);

    // Edit profile: nickname, bio, background
    router.push('/profile/edit');
    await settle(tester);
    await tester.enterText(find.byType(TextField).at(0), 'Aria Star');
    await tester.enterText(find.byType(TextField).at(1), 'Singer and Ludo queen');
    // (TextFields contain their own Scrollable, so scroll the page's ListView directly.)
    await tester.drag(find.byType(ListView).first, const Offset(0, -500));
    await settle(tester);
    await tester.tap(find.text('Deep Space'));
    await settle(tester);
    expect(c.read(profileExtrasProvider).cover, 1);
    await tester.tap(find.text('Save'));
    await settle(tester);
    expect(c.read(sessionProvider)!.name, 'Aria Star');
    expect(c.read(profileExtrasProvider).bio, 'Singer and Ludo queen');

    // Equip an owned frame (Neon Love is owned in demo data)
    router.push('/profile/edit');
    await settle(tester);
    await tester.drag(find.byType(ListView).first, const Offset(0, -800));
    await settle(tester);
    await tester.tap(find.text('Neon Love'));
    await settle(tester);
    expect(c.read(equippedFrameProvider)?.name, 'Neon Love');
    router.pop();
    await settle(tester);

    // Avatar studio: pick hair, accessory, outfit, save
    router.push('/profile/avatar');
    await settle(tester);
    await tester.tap(find.text('Hair'));
    await settle(tester);
    await tester.tap(find.text('Spiky'));
    await tester.tap(find.text('Accessories'));
    await settle(tester);
    await tester.tap(find.text('Crown'));
    await tester.tap(find.text('Outfit'));
    await settle(tester);
    await tester.tap(find.text('Suit'));
    await settle(tester);
    await tester.tap(find.text('Use this avatar'));
    await settle(tester);
    final a = c.read(profileExtrasProvider);
    expect(a.useAvatarFigure, isTrue);
    expect(a.avatar.hair, 4);
    expect(a.avatar.accessory, 3);
    expect(a.avatar.outfit, 1);

    // Levels
    router.push('/profile/levels');
    await settle(tester);
    expect(find.text('Wealth level'), findsOneWidget);
    expect(find.text('Charm level'), findsOneWidget);
    router.pop();
    await settle(tester);

    // Badges + claim an achievement reward
    router.push('/profile/achievements');
    await settle(tester);
    final coins = c.read(sessionProvider)!.coins;
    await tester.tap(find.text('Claim 50'));
    await settle(tester);
    expect(c.read(sessionProvider)!.coins, coins + 50);
    expect(find.text('Claimed'), findsOneWidget);
    await tester.tap(find.textContaining('Badges '));
    await settle(tester);
    expect(find.text('Newcomer'), findsOneWidget);
    router.pop();
    await settle(tester);

    // Other user's profile: follow back → friends
    router.push('/discover');
    await settle(tester);
    await tester.tap(find.text('Mia'));
    await settle(tester);
    expect(find.text('Gift wall'), findsOneWidget);
    expect(find.text('Follow back'), findsOneWidget);
    await tester.tap(find.text('Follow back'));
    await settle(tester);
    expect(c.read(followingProvider).contains(2003), isTrue);
    expect(find.text('Friends'), findsWidgets);

    await tester.pumpWidget(const SizedBox());
    await settle(tester, 30);
    FlutterError.onError = original;
  });
}
