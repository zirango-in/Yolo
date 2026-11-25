import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:material_ui/material_ui.dart';

import 'package:yolo/data/moments_providers.dart';
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

  testWidgets('moments: post, comment, like, share, follow topic, delete, report', (tester) async {
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

    // Create a post with a topic
    router.push('/moments');
    await settle(tester);
    await tester.tap(find.byTooltip('New post'));
    await settle(tester);
    await tester.enterText(find.byType(TextField), 'My first Yolo moment!');
    await tester.tap(find.text('#Poetry'));
    await settle(tester);
    await tester.tap(find.text('Post'));
    await settle(tester);
    final mine = c.read(momentsProvider).first;
    expect(mine.text, 'My first Yolo moment!');
    expect(mine.topic, '#Poetry');
    expect(find.text('My first Yolo moment!'), findsOneWidget);

    // Open details, add a comment, like
    await tester.tap(find.text('My first Yolo moment!'));
    await settle(tester);
    expect(find.text('Comments (0)'), findsOneWidget);
    await tester.enterText(find.byType(TextField), 'Love it');
    await tester.tap(find.byTooltip('Post comment'));
    await settle(tester);
    expect(find.text('Comments (1)'), findsOneWidget);
    expect(c.read(commentsProvider(mine.id)).single.text, 'Love it');
    await tester.tap(find.byIcon(Icons.favorite_border_rounded));
    await settle(tester);
    expect(c.read(likedMomentsProvider).contains(mine.id), isTrue);

    // Share to a friend (sends a chat message)
    await tester.tap(find.byTooltip('Share'));
    await settle(tester);
    await tester.tap(find.text('Zara'));
    await settle(tester);
    expect(c.read(chatProvider('u:2001')).last.text, contains('moment'));

    // Delete my post from details
    await settle(tester, 20);
    await tester.tap(find.byTooltip('Post options'));
    await settle(tester);
    await tester.tap(find.text('Delete post'));
    await settle(tester);
    expect(c.read(momentsProvider).any((m) => m.id == mine.id), isFalse);

    // Topics tab: follow a topic
    await settle(tester, 20);
    await tester.tap(find.text('Topics'));
    await settle(tester);
    await tester.tap(find.text('#Ludo').first);
    await settle(tester);
    expect(find.textContaining('Won 3 Ludo games'), findsOneWidget);
    await tester.tap(find.text('Follow topic'));
    await settle(tester);
    expect(c.read(followedTopicsProvider).contains('#Ludo'), isTrue);

    // Report someone else's post
    await tester.tap(find.byTooltip('Post options').first);
    await settle(tester);
    await tester.tap(find.text('Report post'));
    await settle(tester);
    await tester.tap(find.text('Spam or scam'));
    await settle(tester);
    expect(find.text('Report sent. Our team will review it.'), findsOneWidget);

    await tester.pumpWidget(const SizedBox());
    await settle(tester, 30);
    FlutterError.onError = original;
  });
}
