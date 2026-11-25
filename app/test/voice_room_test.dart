import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:material_ui/material_ui.dart';

import 'package:yolo/data/providers.dart';
import 'package:yolo/main.dart';

Future<void> settle(WidgetTester t, [int frames = 12]) async {
  for (var i = 0; i < frames; i++) {
    await t.pump(const Duration(milliseconds: 100));
  }
}

Future<void> closeSheet(WidgetTester t) async {
  await t.tapAt(const Offset(195, 30));
  await settle(t, 6);
}

void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  testWidgets('voice room: create, seats & admin, settings page, intimacy, members, level, user card, interactions, red packet, treasure, private room', (tester) async {
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
    int coins() => c.read(sessionProvider)!.coins;

    // Create a room (12 seats)
    await tester.tap(find.bySemanticsLabel('Open my room'));
    await settle(tester);
    await tester.enterText(find.byType(TextField).first, 'Aria Night Club');
    await tester.tap(find.text('12 seats'));
    await settle(tester);
    await tester.tap(find.text('Create room').last);
    await settle(tester, 40); // entry banner disappears
    final room = c.read(createdRoomsProvider).first;
    RoomState st() => c.read(roomProvider(room));
    expect(st().seats.length, 12);
    expect(find.text('Aria Night Club'), findsOneWidget);
    // Header: room image, Room ID, Level text; no Follow button on the main screen
    expect(find.text('Room ID: ${room.id}'), findsOneWidget);
    expect(find.textContaining('Level '), findsWidgets);
    expect(find.text('Follow'), findsNothing);
    expect(find.bySemanticsLabel('Back'), findsNothing);

    // Owner: lock an empty seat; mute, make admin, remove Zara from mic
    await tester.tap(find.bySemanticsLabel('Take seat 8'));
    await settle(tester);
    await tester.tap(find.text('Lock seat'));
    await settle(tester);
    expect(st().seats[7].locked, isTrue);
    await tester.tap(find.bySemanticsLabel('Zara'));
    await settle(tester);
    await tester.tap(find.text('Mute'));
    await settle(tester);
    expect(st().seats[0].muted, isTrue);
    await tester.tap(find.bySemanticsLabel('Zara'));
    await settle(tester);
    await tester.tap(find.text('Remove from mic'));
    await settle(tester);
    expect(st().seats[0].user, isNull);
    expect(st().records, isNotEmpty);

    // Settings page
    router.push('/room/settings', extra: room);
    await settle(tester);
    await tester.tap(find.text('Announcement'));
    await settle(tester);
    await tester.enterText(find.byKey(const Key('room-setting-Announcement')), 'Be nice!');
    await tester.tap(find.text('Save'));
    await settle(tester);
    expect(st().announcement, 'Be nice!');
    // Locked background (Starfield needs Lv6), then an unlocked one
    await tester.tap(find.text('Background'));
    await settle(tester);
    await tester.tap(find.textContaining('Starfield'));
    await settle(tester);
    expect(find.text('Reach room level 6 to use this background'), findsOneWidget);
    expect(st().theme, 0);
    await settle(tester, 20);
    await tester.tap(find.text('Background'));
    await settle(tester);
    await tester.tap(find.text('Ocean'));
    await settle(tester);
    expect(st().theme, 1);
    // Mode → intimacy
    await tester.tap(find.text('Mode'));
    await settle(tester);
    await tester.tap(find.textContaining('Intimacy seat'));
    await settle(tester);
    expect(st().mode, 'intimacy');
    // Toggles
    await tester.tap(find.text('Ban text chatting'));
    await settle(tester);
    expect(st().banText, isTrue);
    await tester.tap(find.text('Ban text chatting'));
    await settle(tester);
    // Password
    await tester.tap(find.text('Password'));
    await settle(tester);
    await tester.enterText(find.byType(TextField).last, '4321');
    await tester.tap(find.text('Save'));
    await settle(tester);
    expect(st().password, '4321');
    // Membership fee
    await tester.scrollUntilVisible(find.text('Membership fee'), 200, scrollable: find.byType(Scrollable).first);
    await tester.drag(find.byType(Scrollable).first, const Offset(0, -200));
    await settle(tester, 20);
    await tester.tap(find.text('Membership fee'));
    await settle(tester);
    await tester.tap(find.text('500 coins'));
    await settle(tester);
    expect(st().fee, 500);
    router.pop();
    await settle(tester);
    expect(find.text('Partner'), findsOneWidget); // intimacy seat on screen

    // Members sheet: tabs + make Zara admin
    await tester.tap(find.bySemanticsLabel('Online users'));
    await settle(tester);
    expect(find.textContaining('Online '), findsWidgets);
    await tester.tap(find.textContaining('Members '));
    await settle(tester);
    await tester.tap(find.byTooltip('Manage Zara'));
    await settle(tester);
    await tester.tap(find.textContaining('Set as admin'));
    await settle(tester);
    expect(st().admins.contains(2001), isTrue);
    await tester.ensureVisible(find.text('Contribution'));
    await settle(tester, 4);
    await tester.tap(find.text('Contribution'));
    await settle(tester);
    expect(find.text('Weekly'), findsOneWidget);
    await closeSheet(tester);

    // Room info sheet → level page
    await tester.tap(find.text('Aria Night Club'));
    await settle(tester);
    expect(find.text('Members'), findsWidgets);
    await tester.tap(find.textContaining('Room level '));
    await settle(tester);
    expect(find.text('Tasks today'), findsOneWidget);
    await tester.tap(find.text('Level explanation'));
    await settle(tester);
    expect(find.text('Guest seat'), findsOneWidget);
    router.pop();
    await settle(tester);

    // User card on the host → mention fills the input
    await tester.tap(find.text('HOST'));
    await settle(tester);
    await tester.tap(find.byTooltip('Mention Aria'));
    await settle(tester);
    expect(find.text('@Aria '), findsOneWidget);

    // Take a seat with the mic button, then roll a dice (shows on my seat)
    await tester.tap(find.bySemanticsLabel('Take a seat to talk'));
    await settle(tester, 20);
    await tester.tap(find.bySemanticsLabel('Interactions'));
    await settle(tester);
    await tester.tap(find.text('Dice'));
    await settle(tester);
    expect(st().seatFx[c.read(sessionProvider)!.id]?.kind, 'dice');
    expect(find.textContaining('rolled a dice'), findsOneWidget);

    // Red packet: send 100 coins in 5 shares, then grab one
    final before = coins();
    await tester.tap(find.bySemanticsLabel('Room tools'));
    await settle(tester);
    await tester.tap(find.text('Red packet'));
    await settle(tester);
    await tester.tap(find.text('Send 100 coins'));
    await settle(tester, 25);
    expect(coins(), before - 100);
    await tester.tap(find.bySemanticsLabel('Open red packet'));
    await settle(tester);
    await tester.tap(find.text('OPEN'));
    await settle(tester);
    expect(find.textContaining('You got'), findsOneWidget);
    expect(st().redPackets.first.grabbed.containsKey(c.read(sessionProvider)!.id), isTrue);
    await closeSheet(tester);

    // Treasure: member + gift/message tasks cut the timer; box 1 (1 min) opens
    await tester.tap(find.bySemanticsLabel('Treasure boxes'));
    await settle(tester);
    final b2 = coins();
    await tester.tap(find.text('Open').first);
    await settle(tester);
    expect(coins(), b2 + 10);
    expect(st().claimedBoxes.contains(0), isTrue);
    await tester.tap(find.byTooltip('Close'));
    await settle(tester);

    // Minimize with system back: still seated, mini room appears; restore it several times
    final seatedBefore = st().seats.indexWhere((x) => x.user?.id == c.read(sessionProvider)!.id);
    final micBefore = st().micOn;
    for (var i = 0; i < 3; i++) {
      await tester.binding.handlePopRoute();
      await settle(tester);
      expect(find.bySemanticsLabel('Send gift'), findsNothing);
      expect(c.read(activeRoomProvider)?.id, room.id);
      expect(find.bySemanticsLabel('Return to ${st().name}'), findsOneWidget);
      await tester.tap(find.bySemanticsLabel('Return to ${st().name}'));
      await settle(tester);
      expect(find.bySemanticsLabel('Send gift'), findsOneWidget);
      expect(find.bySemanticsLabel('Return to ${st().name}'), findsNothing);
      expect(st().seats.indexWhere((x) => x.user?.id == c.read(sessionProvider)!.id), seatedBefore);
      expect(st().micOn, micBefore);
      expect(st().claimedBoxes.contains(0), isTrue); // same session, nothing reloaded
    }

    // Exit explicitly from the room menu: session ends and the mini room goes away
    await tester.tap(find.byTooltip('Room menu'));
    await settle(tester);
    await tester.tap(find.text('Exit'));
    await settle(tester);
    await tester.tap(find.text('Exit room'));
    await settle(tester);
    expect(c.read(activeRoomProvider), isNull);
    expect(find.bySemanticsLabel('Return to Aria Night Club'), findsNothing);

    // Private room (VIP Lounge, 1234) as a guest: join as member, take a seat
    await tester.scrollUntilVisible(find.text('VIP Lounge'), 300, scrollable: find.byType(Scrollable).first);
    await settle(tester);
    await tester.tap(find.text('VIP Lounge'));
    await settle(tester);
    await tester.enterText(find.byKey(const Key('room-password')), '1234');
    await tester.tap(find.text('Enter'));
    await settle(tester, 40);
    // Follow lives in the room details panel (tap the room name / image)
    await tester.tap(find.bySemanticsLabel('Room details'));
    await settle(tester);
    await tester.tap(find.text('Follow'));
    await settle(tester);
    expect(find.text('Following'), findsOneWidget);
    await tester.tapAt(const Offset(195, 60));
    await settle(tester, 30);
    await tester.tap(find.bySemanticsLabel('Take seat 4'));
    await settle(tester);
    expect(find.bySemanticsLabel('Take seat 4'), findsNothing);

    await tester.pumpWidget(const SizedBox());
    await settle(tester, 30);
    FlutterError.onError = original;
  });
}
