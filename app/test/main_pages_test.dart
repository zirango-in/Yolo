import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:material_ui/material_ui.dart';

import 'package:yolo/data/providers.dart';
import 'package:yolo/data/social_providers.dart';
import 'package:yolo/main.dart';

Future<void> settle(WidgetTester t) async {
  for (var i = 0; i < 12; i++) {
    await t.pump(const Duration(milliseconds: 100));
  }
}

void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  testWidgets('Step 1 pages open and their main actions work', (tester) async {
    // Test font draws wide squares; ignore overflow caused only by that.
    final original = FlutterError.onError;
    FlutterError.onError = (d) {
      if (!d.exceptionAsString().contains('overflowed')) original?.call(d);
    };
    await tester.binding.setSurfaceSize(const Size(390, 844));
    await tester.pumpWidget(const ProviderScope(child: YoloApp()));
    await settle(tester);
    await tester.tap(find.text('Continue with phone'));
    await settle(tester);
    await settle(tester);

    final container = ProviderScope.containerOf(tester.element(find.byType(YoloApp)));
    final router = container.read(routerProvider);

    Future<void> open(String route, String title) async {
      router.push(route);
      await settle(tester);
      expect(find.text(title), findsWidgets, reason: route);
    }

    Future<void> back() async {
      router.pop();
      await settle(tester);
    }

    // Home quick entries are visible.
    for (final label in ['Discover', 'Events', 'Shop', 'Family', 'Moments', 'Friends']) {
      expect(find.text(label), findsWidgets);
    }

    // Discover: search filters users, follow toggles.
    await open('/discover', 'Discover');
    await tester.enterText(find.byType(TextField), 'leo');
    await settle(tester);
    expect(find.text('Leo'), findsOneWidget);
    expect(container.read(followingProvider).contains(2005), isFalse);
    await tester.tap(find.text('Follow').first);
    await settle(tester);
    expect(container.read(followingProvider).contains(2005), isTrue);
    await back();

    // Moments: like a post.
    await open('/moments', 'Moments');
    await tester.tap(find.byIcon(Icons.favorite_border_rounded).first);
    await settle(tester);
    expect(container.read(likedMomentsProvider), isNotEmpty);
    await back();

    // Shop: buy the Golden Crown frame (3,000 coins).
    await open('/shop', 'Shop');
    final before = container.read(sessionProvider)!.coins;
    await tester.tap(find.text('Golden Crown'));
    await settle(tester);
    await tester.tap(find.text('Buy'));
    await settle(tester);
    expect(container.read(sessionProvider)!.coins, before - 3000);
    expect(container.read(ownedItemsProvider).contains(1), isTrue);
    await back();

    // Family: join a family, then leave it.
    await open('/family', 'Family');
    await tester.tap(find.text('Join').first);
    await settle(tester);
    expect(container.read(joinedFamilyProvider), isNotNull);
    expect(find.text('Members'), findsOneWidget);
    await tester.ensureVisible(find.text('Leave family'));
    await settle(tester);
    await tester.tap(find.text('Leave family'));
    await settle(tester);
    expect(container.read(joinedFamilyProvider), isNull);
    await back();

    // Notifications: read all.
    await open('/notifications', 'Notifications');
    await tester.tap(find.text('Read all'));
    await settle(tester);
    expect(container.read(readNotificationsProvider).length, greaterThan(0));
    await back();

    // Friends, events, settings, game center open.
    await open('/friends', 'Friends');
    await back();
    await open('/events', 'Events');
    await tester.tap(find.text('Ludo Party Night'));
    await settle(tester);
    expect(find.text('Rules'), findsOneWidget);
    await tester.tap(find.text('Join now'));
    await settle(tester);
    await back();
    await open('/settings', 'Settings');
    await back();
    await open('/games', 'Game Center');
    await back();

    // Messages tab → chat → send a message.
    await tester.tap(find.text('Messages').last);
    await settle(tester);
    expect(find.text('Chats'), findsOneWidget);
    await tester.tap(find.text('Zara').first);
    await settle(tester);
    await tester.enterText(find.byType(TextField), 'Hi Zara!');
    await tester.tap(find.byTooltip('Send'));
    await settle(tester);
    expect(find.text('Hi Zara!'), findsOneWidget);

    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 2));
    FlutterError.onError = original;
  });
}
