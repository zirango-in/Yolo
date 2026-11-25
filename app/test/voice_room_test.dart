import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:material_ui/material_ui.dart';

import 'package:yolo/data/providers.dart';
import 'package:yolo/data/repository.dart';
import 'package:yolo/data/room_look.dart';
import 'package:yolo/data/settings_providers.dart';
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
    expect(find.text(st().tag), findsWidgets); // current category word, no level prefix
    expect(find.text('Follow'), findsNothing);
    expect(find.bySemanticsLabel('Back'), findsNothing);

    // Chat: system note then the announcement, in the scrolling list
    expect(find.textContaining('Announcement:'), findsOneWidget);
    expect(find.textContaining('System:'), findsOneWidget);
    // Enter / leave notices: fixed strip under the seats, queued, not in the chat, no duplicates
    final ctl = c.read(roomProvider(room).notifier);
    ctl.userEntered(DemoUsers.leo);
    ctl.userEntered(DemoUsers.leo); // already in → no second notice
    await settle(tester, 3);
    expect(st().presence.where((e) => e.user.id == DemoUsers.leo.id).length, 1);
    expect(st().onlineIds.contains(DemoUsers.leo.id), isTrue);
    expect(find.text('Leo entered the room'), findsOneWidget);
    ctl.userLeft(DemoUsers.leo); // queued behind the entry notice
    expect(st().onlineIds.contains(DemoUsers.leo.id), isFalse);
    await settle(tester, 30);
    expect(find.text('Leo left the room'), findsOneWidget);
    await settle(tester, 30);
    expect(st().messages.any((m) => m.text.contains('entered the room')), isFalse);

    // Top contributors come from the room's real gifting totals (Zara leads)
    expect(ctl.topGifters().first.$1.id, DemoUsers.zara.id);

    // Four-dot menu holds every room feature, including Red packet and Music
    await tester.tap(find.bySemanticsLabel('More features'));
    await settle(tester);
    for (final label in ['Daily Treasure', 'Red Packet', 'Music', 'Emotes', 'Gifting', 'Room Info', 'Room Level', 'Members', 'Invite', 'Ranking']) {
      expect(find.text(label), findsOneWidget, reason: label);
    }
    await tester.tap(find.text('Music'));
    await settle(tester);
    expect(find.textContaining('Music'), findsWidgets);
    await tester.tapAt(const Offset(195, 60));
    await settle(tester, 30);

    // Top drawer: five room modes, four categories, room functions
    await tester.tap(find.byTooltip('Room menu'));
    await settle(tester);
    for (final m in ['Normal Room', 'Acquaint Room', 'Auction Room', 'Video Room', 'Game Room']) {
      expect(find.bySemanticsLabel(m), findsOneWidget, reason: m);
    }
    for (final cat in ['Friends', 'Music', 'Game', 'Chats']) {
      expect(find.bySemanticsLabel('Category $cat'), findsOneWidget, reason: cat);
    }
    for (final f in ['Share', 'Gift Sound', 'Report Room', 'Exit', 'Settings', 'Recommendation Card', 'Rally Fans']) {
      expect(find.bySemanticsLabel(f), findsOneWidget, reason: f);
    }
    await tester.tap(find.bySemanticsLabel('Auction Room'));
    await settle(tester);
    expect(st().roomMode, 'auction');
    await tester.tap(find.bySemanticsLabel('Category Music'));
    await settle(tester);
    expect(st().tag, 'Music');
    await tester.tap(find.bySemanticsLabel('Gift Sound'));
    await settle(tester);
    expect(c.read(settingsProvider).giftSounds, isFalse);
    await tester.tap(find.byTooltip('Close room menu')); // the ••• again closes it
    await settle(tester);
    expect(find.bySemanticsLabel('Auction Room'), findsNothing);
    await settle(tester, 30);

    // Auction stage: start, bid with coins, end → winner announced
    await tester.tap(find.text('Start'));
    await settle(tester);
    await tester.enterText(find.byKey(const Key('auction-item')), 'Song request');
    await tester.tap(find.text('OK'));
    await settle(tester);
    expect(st().auctionItem, 'Song request');
    final cb = coins();
    await tester.tap(find.text('Bid'));
    await settle(tester);
    await tester.tap(find.text('500').last);
    await settle(tester);
    expect(coins(), cb - 500);
    expect(st().topBid?.$2, 500);
    await tester.tap(find.text('End'));
    await settle(tester);
    expect(st().auctionItem, isNull);
    expect(find.textContaining('SOLD!'), findsOneWidget);
    // Game room: start Mic Grab for the room; video room validates links
    expect(ctl.setRoomMode('game'), '');
    await settle(tester);
    await tester.tap(find.text('Mic Grab'));
    await settle(tester);
    expect(st().roomGame, 'Mic Grab');
    expect(find.text('Playing Mic Grab'), findsOneWidget);
    expect(ctl.setRoomMode('video'), '');
    expect(ctl.setVideo('not a link', 'x'), isNotEmpty);
    expect(ctl.setRoomMode('normal'), '');
    expect(st().roomGame, isNull);
    await settle(tester, 30);

    // Recommendation card → room shows first on Home; rally fans (with cooldown)
    await tester.tap(find.byTooltip('Room menu'));
    await settle(tester);
    await tester.tap(find.bySemanticsLabel('Recommendation Card'));
    await settle(tester);
    await tester.tap(find.text('Use a card'));
    await settle(tester);
    expect(st().promoted, isTrue);
    expect(c.read(promotedRoomsProvider).containsKey(room.id), isTrue);
    await closeSheet(tester);
    await tester.tap(find.byTooltip('Room menu'));
    await settle(tester);
    await tester.tap(find.bySemanticsLabel('Rally Fans'));
    await settle(tester);
    await tester.tap(find.text('Rally now'));
    await settle(tester);
    expect(st().lastRallyAt, isNotNull);
    expect(ctl.rallyFans(''), contains('rally again'));
    await settle(tester, 30);

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
    // Theme sheet: locked theme (Starfield needs Lv6), then Ocean re-colours the room
    await tester.tap(find.text('Theme & background'));
    await settle(tester);
    await tester.tap(find.bySemanticsLabel('Starfield'));
    await settle(tester);
    expect(find.text('Reach room level 6 to use this background'), findsOneWidget);
    expect(st().theme, 0);
    await settle(tester, 20);
    await tester.tap(find.bySemanticsLabel('Ocean'));
    await settle(tester);
    expect(st().theme, 1);
    expect(st().look.accent, RoomLook.themes[1].accent);
    // Custom photo: its colour drives the room accent; picking a theme removes it again
    ctl.updateSettings(bgPath: '/missing/bg.jpg', bgAccent: 0xFF22AA66, bgAlignY: 0.3);
    await settle(tester);
    expect(st().look.imagePath, '/missing/bg.jpg');
    expect(st().look.accent, isNot(RoomLook.themes[1].accent));
    await tester.tap(find.bySemanticsLabel('Ocean'));
    await settle(tester);
    expect(st().bgPath, isNull);
    await closeSheet(tester);
    // Room mode → Acquaint (host + partner seats)
    await tester.tap(find.text('Room mode'));
    await settle(tester);
    await tester.tap(find.text('Acquaint Room'));
    await settle(tester);
    expect(st().mode, 'intimacy');
    expect(st().roomMode, 'acquaint');
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
    expect(find.bySemanticsLabel('Take seat 1'), findsOneWidget); // partner seat next to the host
    expect(find.text('HOST'), findsNothing); // labels removed, roles kept

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
    await tester.tap(find.bySemanticsLabel('Host Aria'));
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
    await tester.tap(find.bySemanticsLabel('More features'));
    await settle(tester);
    await tester.tap(find.text('Red Packet'));
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
    expect(find.bySemanticsLabel('Treasure boxes'), findsNothing); // moved into the four-dot menu
    await tester.tap(find.bySemanticsLabel('More features'));
    await settle(tester);
    await tester.tap(find.text('Daily Treasure'));
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

    // Exit from the top drawer: session ends and the mini room goes away
    await tester.tap(find.byTooltip('Room menu'));
    await settle(tester);
    await tester.tap(find.bySemanticsLabel('Exit'));
    await settle(tester);
    expect(c.read(activeRoomProvider), isNull);
    expect(find.bySemanticsLabel('Return to Aria Night Club'), findsNothing);

    // Rejoin: theme, mode and category come back (saved per room)
    router.push('/room', extra: room);
    await settle(tester, 20);
    expect(st().theme, 1);
    expect(st().roomMode, 'acquaint');
    expect(st().tag, 'Music');
    expect(st().seats.any((x) => x.user?.id == c.read(sessionProvider)!.id), isFalse); // seat was released on exit
    await tester.tap(find.byTooltip('Room menu'));
    await settle(tester);
    await tester.tap(find.bySemanticsLabel('Exit'));
    await settle(tester);
    expect(c.read(activeRoomProvider), isNull);

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
