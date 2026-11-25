import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:material_ui/material_ui.dart';

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

  testWidgets('friends & chat: requests, add by ID, group chat, voice message, block, report', (tester) async {
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

    // Friend requests: accept Leo, decline Omar
    router.push('/friends/requests');
    await settle(tester);
    await tester.tap(find.text('Accept').first);
    await settle(tester);
    final friendIds = c.read(friendsProvider).map((u) => u.id);
    expect(friendIds.contains(2005) || friendIds.contains(2004), isTrue);
    await tester.tap(find.byTooltip(RegExp('Decline')).first);
    await settle(tester);
    expect(c.read(incomingRequestsProvider), isEmpty);
    router.pop();
    await settle(tester);

    // Add friend by Yolo ID
    router.push('/friends/add');
    await settle(tester);
    await tester.enterText(find.byType(TextField), '2003');
    await settle(tester);
    expect(find.text('Yolo ID match'), findsOneWidget);
    expect(find.text('Mia'), findsOneWidget);
    router.pop();
    await settle(tester);

    // Create a group with 2 friends, send a message
    router.push('/chat/new-group');
    await settle(tester);
    await tester.enterText(find.byType(TextField), 'Night Owls');
    await tester.tap(find.byType(CheckboxListTile).at(0));
    await tester.tap(find.byType(CheckboxListTile).at(1));
    await settle(tester);
    await tester.tap(find.text('Create group'));
    await settle(tester);
    expect(c.read(groupsProvider).last.name, 'Night Owls');
    expect(find.text('Night Owls'), findsOneWidget);
    await tester.enterText(find.byType(TextField), 'Welcome to the group!');
    await settle(tester);
    await tester.tap(find.byTooltip('Send'));
    await settle(tester);
    expect(find.text('Welcome to the group!'), findsOneWidget);
    router.pop();
    await settle(tester);

    // 1-to-1 chat: voice message (hold mic), clear history
    router.push('/chat', extra: userById(2001));
    await settle(tester);
    expect(find.text('Online'), findsOneWidget);
    final gesture = await tester.startGesture(tester.getCenter(find.bySemanticsLabel('Hold to record voice message')));
    await tester.pump(const Duration(milliseconds: 600));
    await settle(tester, 25);
    expect(find.textContaining('Recording'), findsOneWidget);
    await gesture.up();
    await settle(tester);
    final msgs = c.read(chatProvider('u:2001'));
    expect(msgs.last.kind, ChatKind.voice);
    expect(msgs.last.seconds, greaterThanOrEqualTo(1));

    await tester.tap(find.byTooltip('Chat options'));
    await settle(tester);
    await tester.tap(find.text('Clear chat history'));
    await settle(tester);
    expect(c.read(chatProvider('u:2001')), isEmpty);
    expect(find.text('No messages yet'), findsOneWidget);

    // Block from chat menu → input replaced; report
    await settle(tester, 20);
    await tester.tap(find.byTooltip('Chat options'));
    await settle(tester);
    await tester.tap(find.text('Block Zara'));
    await settle(tester);
    expect(c.read(blockedProvider).contains(2001), isTrue);
    expect(find.text('You blocked Zara.'), findsOneWidget);
    await settle(tester, 20);
    await tester.tap(find.byTooltip('Chat options'));
    await settle(tester);
    await tester.tap(find.text('Report user'));
    await settle(tester);
    await tester.tap(find.text('Harassment or bullying'));
    await settle(tester);
    router.pop();
    await settle(tester);

    // Blocked list → unblock
    router.push('/blocked');
    await settle(tester);
    expect(find.text('Zara'), findsOneWidget);
    await tester.tap(find.text('Unblock'));
    await settle(tester);
    expect(c.read(blockedProvider), isEmpty);

    await tester.pumpWidget(const SizedBox());
    await settle(tester, 30);
    FlutterError.onError = original;
  });
}
