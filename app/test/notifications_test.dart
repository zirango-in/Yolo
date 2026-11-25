import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:material_ui/material_ui.dart';

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

  testWidgets('notifications: badge, accept friend, thank gift, claim reward, categories, swipe delete, reply, mark all', (tester) async {
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

    // Unread badge on the Home bell
    expect(c.read(unreadNotificationsProvider), 7);
    expect(find.text('7'), findsWidgets);

    await tester.tap(find.bySemanticsLabel('Notifications'));
    await settle(tester);
    expect(find.text('Notifications (7)'), findsOneWidget);

    // Accept the friend request
    // Two Accept buttons: friend request first, then the CP request.
    await tester.tap(find.text('Accept').first);
    await settle(tester);
    expect(c.read(friendsProvider).any((u) => u.id == 2005), isTrue);
    expect(find.text('Accepted'), findsOneWidget);
    await tester.tap(find.text('Accept'));
    await settle(tester);
    expect(find.text('Accepted'), findsNWidgets(2));

    // Thank for the gift
    await tester.tap(find.text('Say thanks'));
    await settle(tester);
    expect(c.read(chatProvider('u:2001')).last.text, 'Thank you for the gift!');

    // Claim the reward (200 coins)
    final coins = c.read(sessionProvider)!.coins;
    await tester.tap(find.text('Claim'));
    await settle(tester);
    expect(c.read(sessionProvider)!.coins, coins + 200);
    expect(find.text('Claimed'), findsOneWidget);

    // Category filter
    await tester.ensureVisible(find.text('Invites'));
    await settle(tester);
    await tester.tap(find.text('Invites'));
    await settle(tester);
    expect(find.text('Room invitation'), findsOneWidget);
    expect(find.text('Game invitation'), findsOneWidget);
    expect(find.text('New friend request'), findsNothing);

    // Swipe to delete the game invite
    await tester.drag(find.text('Game invitation'), const Offset(-500, 0));
    await settle(tester);
    expect(c.read(notificationsProvider).any((n) => n.type == 'game'), isFalse);

    // Messages → Reply opens the chat
    await tester.ensureVisible(find.text('Messages').first);
    await settle(tester);
    await tester.tap(find.text('Messages').first);
    await settle(tester);
    await tester.tap(find.text('Reply'));
    await settle(tester);
    expect(find.text('Zara'), findsWidgets);
    expect(find.byTooltip('Chat options'), findsOneWidget);
    router.pop();
    await settle(tester);

    // Mark all as read
    await tester.tap(find.byTooltip('Notification options'));
    await settle(tester);
    await tester.tap(find.text('Mark all as read'));
    await settle(tester);
    expect(c.read(unreadNotificationsProvider), 0);
    expect(find.text('Notifications'), findsOneWidget);

    await tester.pumpWidget(const SizedBox());
    await settle(tester, 30);
    FlutterError.onError = original;
  });
}
