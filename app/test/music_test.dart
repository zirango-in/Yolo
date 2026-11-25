import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:material_ui/material_ui.dart';

import 'package:yolo/data/music_providers.dart';
import 'package:yolo/data/providers.dart';
import 'package:yolo/main.dart';

Future<void> settle(WidgetTester t, [int frames = 12]) async {
  for (var i = 0; i < frames; i++) {
    await t.pump(const Duration(milliseconds: 100));
  }
}

void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  testWidgets('music: library, favorite, preview, karaoke → results, singing room, battle, mic grab, upload', (tester) async {
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

    // Home → Music
    // ('Music' is also a room tag on Home, so tap the first one: the shortcut.)
    await tester.tap(find.text('Music').first);
    await settle(tester);
    expect(find.text('Hands Up Tonight'), findsOneWidget); // most played first

    // Search, favorite, preview
    await tester.enterText(find.byType(TextField), 'lo-fi');
    await settle(tester);
    expect(find.text('Coffee Rain'), findsOneWidget);
    await tester.tap(find.byTooltip('Favorite Coffee Rain'));
    await settle(tester);
    expect(c.read(musicProvider).favorites.contains(2), isTrue);
    await tester.tap(find.text('Coffee Rain'));
    await settle(tester);
    expect(c.read(musicProvider).playing, 2);
    expect(find.text('Preview · demo audio'), findsOneWidget);
    await tester.tap(find.byTooltip('Stop preview'));
    await settle(tester);

    // Karaoke: sing the whole song (6 lines × 3 s) → results
    await tester.tap(find.byTooltip('Sing Coffee Rain'));
    await settle(tester);
    expect(find.text('Rain on the window, coffee in hand'), findsOneWidget);
    final before = coins();
    await tester.tap(find.text('Start singing'));
    await settle(tester, 200);
    expect(find.textContaining('Score '), findsOneWidget);
    final r = c.read(musicProvider).history.first;
    expect(r.song.id, 2);
    expect(coins(), before + r.coins);
    router.pop();
    await settle(tester);

    // Singing room: join queue
    router.push('/music/room');
    await settle(tester);
    expect(find.text('NOW SINGING'), findsOneWidget);
    await tester.tap(find.text('Join the queue'));
    await settle(tester);
    await tester.tap(find.text('Paper Hearts'));
    await settle(tester);
    expect(c.read(musicProvider).queue.last.$1.id, c.read(sessionProvider)!.id);
    router.pop();
    await settle(tester);

    // Singing battle: vote, wait for the end
    router.push('/music/battle');
    await settle(tester);
    await tester.tap(find.text('Vote Zara'));
    await settle(tester);
    expect(find.text('Voted'), findsOneWidget);
    await settle(tester, 110);
    expect(find.text('Battle over!'), findsOneWidget);
    expect(find.textContaining('wins!'), findsOneWidget);
    router.pop();
    await settle(tester);

    // Mic grab: three rounds, tap as soon as the mic appears
    router.push('/music/micgrab');
    await settle(tester);
    final micBefore = coins();
    await tester.tap(find.text('Start'));
    for (var round = 0; round < 3; round++) {
      for (var i = 0; i < 40 && find.text('GRAB!').evaluate().isEmpty; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }
      expect(find.text('GRAB!'), findsOneWidget);
      await tester.tap(find.bySemanticsLabel('Grab the mic'));
      await tester.pump(const Duration(milliseconds: 50));
      expect(find.textContaining('You grabbed it'), findsOneWidget);
      await settle(tester, 13);
    }
    expect(find.text('You won 60 coins!'), findsOneWidget);
    expect(coins(), micBefore + 60);
    router.pop();
    await settle(tester);

    // Upload (needs title + rights confirmation)
    router.push('/music/upload');
    await settle(tester);
    await tester.enterText(find.byType(TextField), 'My First Song');
    await tester.tap(find.byType(CheckboxListTile));
    await settle(tester);
    await tester.tap(find.text('Upload').last);
    await settle(tester);
    expect(c.read(musicProvider).uploads.single.title, 'My First Song');

    await tester.pumpWidget(const SizedBox());
    await settle(tester, 30);
    FlutterError.onError = original;
  });
}
