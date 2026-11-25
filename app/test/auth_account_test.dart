import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:material_ui/material_ui.dart';

import 'package:yolo/data/account_providers.dart';
import 'package:yolo/data/providers.dart';
import 'package:yolo/main.dart';

Future<void> settle(WidgetTester t, [int frames = 12]) async {
  for (var i = 0; i < frames; i++) {
    await t.pump(const Duration(milliseconds: 100));
  }
}

void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  Future<ProviderContainer> start(WidgetTester tester) async {
    final original = FlutterError.onError;
    FlutterError.onError = (d) {
      if (!d.exceptionAsString().contains('overflowed')) original?.call(d);
    };
    addTearDown(() => FlutterError.onError = original);
    await tester.binding.setSurfaceSize(const Size(390, 844));
    await tester.pumpWidget(const ProviderScope(child: YoloApp()));
    await settle(tester);
    return ProviderScope.containerOf(tester.element(find.byType(YoloApp)));
  }

  testWidgets('welcome → phone → OTP (wrong, then right) → register → account management → delete', (tester) async {
    final c = await start(tester);

    // Welcome carousel
    expect(find.text('Voice party rooms'), findsOneWidget);
    await tester.tap(find.text('Next'));
    await settle(tester);
    await tester.tap(find.text('Next'));
    await settle(tester);
    await tester.tap(find.text('Get started'));
    await settle(tester);

    // Phone entry with validation
    await tester.tap(find.text('Continue with phone'));
    await settle(tester);
    await tester.tap(find.text('Send code'));
    await settle(tester);
    expect(find.text('Enter a valid phone number'), findsOneWidget);
    await tester.enterText(find.byType(TextField), '9876543210');
    await tester.tap(find.text('Send code'));
    await settle(tester);

    // OTP: wrong code then correct code
    expect(find.text('Enter the code'), findsOneWidget);
    await tester.enterText(find.byKey(const Key('otp-field')), '111111');
    await settle(tester);
    expect(find.text('Wrong code. Please try again.'), findsOneWidget);
    await tester.enterText(find.byKey(const Key('otp-field')), OtpService.demoCode);
    await settle(tester);

    // Registration
    expect(find.text('Tell us about you'), findsOneWidget);
    await tester.tap(find.text('Start partying'));
    await settle(tester);
    expect(find.text('Nickname must be 2–20 characters'), findsOneWidget);
    await tester.enterText(find.byType(TextField), 'Sunny');
    await tester.tap(find.text('Male'));
    await tester.tap(find.text('Start partying'));
    await settle(tester);
    expect(c.read(sessionProvider)!.name, 'Sunny');
    expect(c.read(sessionProvider)!.gender, 'male');
    expect(c.read(accountProvider).phone, '+919876543210');
    expect(find.text('Hot rooms'), findsOneWidget);

    // Account management
    final router = c.read(routerProvider);
    router.push('/account');
    await settle(tester);
    expect(find.text('Yolo ID'), findsOneWidget);

    // Change nickname
    await tester.tap(find.text('Nickname'));
    await settle(tester);
    await tester.enterText(find.byType(TextField).last, 'Sunny Star');
    await tester.tap(find.text('Save'));
    await settle(tester);
    expect(c.read(sessionProvider)!.name, 'Sunny Star');

    // Buy lucky number 123456 (12,000 coins)
    final coins = c.read(sessionProvider)!.coins;
    await tester.tap(find.text('Lucky number'));
    await settle(tester);
    await tester.tap(find.text('123456'));
    await settle(tester);
    expect(c.read(sessionProvider)!.id, 123456);
    expect(c.read(sessionProvider)!.coins, coins - 12000);

    // Link Google
    expect(c.read(accountProvider).bindings.contains('google'), isFalse);
    await tester.tap(find.text('Google'));
    await settle(tester);
    expect(c.read(accountProvider).bindings.contains('google'), isTrue);

    // Delete account
    await tester.scrollUntilVisible(find.text('Delete account'), 200, scrollable: find.byType(Scrollable).first);
    await settle(tester);
    await tester.tap(find.text('Delete account'));
    await settle(tester);
    await tester.enterText(find.byType(TextField).last, 'DELETE');
    await tester.tap(find.text('Delete'));
    await settle(tester);
    expect(c.read(sessionProvider), isNull);
    expect(find.text('Skip'), findsOneWidget);

    await tester.pumpWidget(const SizedBox());
    await settle(tester, 30);
  });

  testWidgets('guest login and email login', (tester) async {
    final c = await start(tester);
    await tester.tap(find.text('Skip'));
    await settle(tester);

    await tester.tap(find.text('Guest'));
    await settle(tester);
    expect(c.read(accountProvider).isGuest, isTrue);
    expect(find.text('Hot rooms'), findsOneWidget);

    c.read(sessionProvider.notifier).logout();
    c.read(routerProvider).go('/login/email');
    await settle(tester);
    await tester.tap(find.text('Log in'));
    await settle(tester);
    expect(find.text('Enter a valid email'), findsOneWidget);
    await tester.enterText(find.byType(TextField).first, 'me@yolo.app');
    await tester.enterText(find.byType(TextField).last, 'secret123');
    await tester.tap(find.text('Log in'));
    await settle(tester);
    expect(c.read(accountProvider).email, 'me@yolo.app');
    expect(find.text('Hot rooms'), findsOneWidget);

    await tester.pumpWidget(const SizedBox());
    await settle(tester, 30);
  });
}
