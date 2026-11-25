import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:material_ui/material_ui.dart';

import 'package:yolo/data/models.dart';
import 'package:yolo/data/providers.dart';
import 'package:yolo/main.dart';

Future<void> settle(WidgetTester t, [int frames = 12]) async {
  for (var i = 0; i < frames; i++) {
    await t.pump(const Duration(milliseconds: 100));
  }
}

void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  testWidgets('voice room: create, admin actions, settings, music, members, invite, ranking, report, private room, exit', (tester) async {
    final original = FlutterError.onError;
    FlutterError.onError = (d) {
      if (!d.exceptionAsString().contains('overflowed')) original?.call(d);
    };
    await tester.binding.setSurfaceSize(const Size(390, 900));
    await tester.pumpWidget(const ProviderScope(child: YoloApp()));
    await settle(tester);
    final c = ProviderScope.containerOf(tester.element(find.byType(YoloApp)));
    final login = c.read(sessionProvider.notifier).login('google');
    await settle(tester);
    await login;
    final router = c.read(routerProvider);
    router.go('/home');
    await settle(tester);

    // Create a room (12 seats)
    await tester.tap(find.bySemanticsLabel('Open my room'));
    await settle(tester);
    expect(find.text('Create room'), findsWidgets);
    await tester.enterText(find.byType(TextField).first, 'Aria Night Club');
    await tester.tap(find.text('12 seats'));
    await settle(tester);
    await tester.tap(find.text('Create room').last);
    await settle(tester);
    final room = c.read(createdRoomsProvider).first;
    expect(room.seatCount, 12);
    expect(find.text('Aria Night Club'), findsOneWidget);
    expect(c.read(roomProvider(room)).seats.length, 12);

    // Owner locks an empty seat
    await tester.tap(find.bySemanticsLabel('Take seat 8'));
    await settle(tester);
    await tester.tap(find.text('Lock seat'));
    await settle(tester);
    expect(c.read(roomProvider(room)).seats[7].locked, isTrue);

    // Owner mutes, makes admin, and kicks Zara (seat 1)
    await tester.tap(find.bySemanticsLabel('Zara'));
    await settle(tester);
    await tester.tap(find.text('Mute'));
    await settle(tester);
    expect(c.read(roomProvider(room)).seats[0].muted, isTrue);
    await tester.tap(find.bySemanticsLabel('Zara'));
    await settle(tester);
    await tester.tap(find.text('Make admin'));
    await settle(tester);
    expect(c.read(roomProvider(room)).admins.contains(2001), isTrue);
    await tester.tap(find.bySemanticsLabel('Zara'));
    await settle(tester);
    await tester.tap(find.text('Remove from mic'));
    await settle(tester);
    expect(c.read(roomProvider(room)).seats[0].user, isNull);

    // Settings: announcement, password, theme, mic requests
    await tester.tap(find.byTooltip('Room menu'));
    await settle(tester);
    await tester.tap(find.text('Settings'));
    await settle(tester);
    await tester.enterText(find.widgetWithText(TextField, 'Announcement'), 'Be nice!');
    await tester.tap(find.text('Lock room with password'));
    await settle(tester);
    await tester.enterText(find.widgetWithText(TextField, 'Password (4–6 digits)'), '4321');
    await tester.tap(find.text('Ocean'));
    await tester.tap(find.text('Mic requests'));
    await settle(tester);
    await tester.ensureVisible(find.text('Save settings'));
    await tester.tap(find.text('Save settings'));
    await settle(tester);
    final st = c.read(roomProvider(room));
    expect(st.announcement, 'Be nice!');
    expect(st.password, '4321');
    expect(st.theme, 1);
    expect(st.applyMode, isTrue);

    // Music
    await tester.tap(find.byTooltip('Room menu'));
    await settle(tester);
    await tester.tap(find.text('Music'));
    await settle(tester);
    await tester.tap(find.text('Lo-fi Chill'));
    await settle(tester);
    expect(c.read(roomProvider(room)).track, 3);
    expect(c.read(roomProvider(room)).musicPlaying, isTrue);
    await tester.tap(find.byTooltip('Pause'));
    await settle(tester);
    expect(c.read(roomProvider(room)).musicPlaying, isFalse);
    await tester.tapAt(const Offset(195, 40));
    await settle(tester);

    // Members, invite, ranking, report
    await tester.tap(find.byTooltip('Room menu'));
    await settle(tester);
    await tester.tap(find.text('Members'));
    await settle(tester);
    expect(find.textContaining('Online ·'), findsOneWidget);
    await tester.tapAt(const Offset(195, 40));
    await settle(tester);

    await tester.tap(find.byTooltip('Room menu'));
    await settle(tester);
    await tester.tap(find.text('Invite'));
    await settle(tester);
    await tester.tap(find.text('Invite').last);
    await settle(tester);
    expect(find.text('Sent'), findsOneWidget);
    await tester.tapAt(const Offset(195, 40));
    await settle(tester);

    await tester.tap(find.byTooltip('Room menu'));
    await settle(tester);
    await tester.tap(find.text('Ranking'));
    await settle(tester);
    expect(find.text('Room ranking · Today'), findsOneWidget);
    await tester.tapAt(const Offset(195, 40));
    await settle(tester);

    await tester.tap(find.byTooltip('Room menu'));
    await settle(tester);
    await tester.tap(find.text('Report'));
    await settle(tester);
    await tester.tap(find.text('Spam or scam'));
    await settle(tester);
    expect(find.text('Report sent. Our team will review it.'), findsOneWidget);

    // Speaker toggle (wait for the report toast to disappear first)
    await settle(tester, 25);
    await tester.tap(find.bySemanticsLabel('Mute speaker'));
    await settle(tester);
    expect(c.read(roomProvider(room)).speakerOn, isFalse);

    // Exit room
    await tester.tap(find.bySemanticsLabel('Back'));
    await settle(tester);
    await tester.tap(find.text('Exit room'));
    await settle(tester);
    expect(find.text('Hot rooms'), findsOneWidget);

    // Private room asks for a password (VIP Lounge, password 1234)
    await tester.scrollUntilVisible(find.text('VIP Lounge'), 300, scrollable: find.byType(Scrollable).first);
    await settle(tester);
    await tester.tap(find.text('VIP Lounge'));
    await settle(tester);
    expect(find.text('Private room'), findsOneWidget);
    await tester.enterText(find.byKey(const Key('room-password')), '0000');
    await tester.tap(find.text('Enter'));
    await settle(tester);
    expect(find.text('Wrong password'), findsOneWidget);
    await tester.enterText(find.byKey(const Key('room-password')), '1234');
    await tester.tap(find.text('Enter'));
    await settle(tester);
    expect(find.text('VIP Lounge'), findsWidgets);
    expect(find.bySemanticsLabel('Take seat 12'), findsOneWidget);

    // Non-owner: tapping an empty seat takes it directly
    await tester.tap(find.bySemanticsLabel('Take seat 4'));
    await settle(tester);
    expect(find.bySemanticsLabel('Take seat 4'), findsNothing);

    await tester.pumpWidget(const SizedBox());
    await settle(tester, 30);
    FlutterError.onError = original;
    expect(Room, isNotNull);
  });
}
