import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:material_ui/material_ui.dart';

import 'package:yolo/main.dart';

/// Pumps several frames so route and widget animations can run.
Future<void> settle(WidgetTester t) async {
  for (var i = 0; i < 10; i++) {
    await t.pump(const Duration(milliseconds: 100));
  }
}

void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  // The test font draws every letter as a wide square, so text is much wider
  // than on a real phone. Overflow warnings caused only by that are ignored here;
  // every functional check below must still pass.
  void ignoreTestFontOverflow() {
    final original = FlutterError.onError;
    FlutterError.onError = (details) {
      if (details.exceptionAsString().contains('overflowed')) return;
      original?.call(details);
    };
  }

  testWidgets('login → room → take seat → chat → send gift', (tester) async {
    ignoreTestFontOverflow();
    await tester.binding.setSurfaceSize(const Size(390, 844));
    await tester.pumpWidget(const ProviderScope(child: YoloApp()));
    await settle(tester);

    // Login
    await tester.tap(find.text('Skip'));
    await settle(tester);
    await tester.tap(find.text('Continue with Google'));
    await settle(tester);
    await settle(tester);

    // Home shows coins and rooms
    expect(find.text('Hot rooms'), findsOneWidget);
    expect(find.text('12,480'), findsOneWidget);
    expect(find.text('Late Night Talks'), findsOneWidget);

    // Open room
    await tester.scrollUntilVisible(find.text('Late Night Talks'), 200, scrollable: find.byType(Scrollable).first);
    await settle(tester);
    await tester.tap(find.text('Late Night Talks'));
    await settle(tester);
    await settle(tester);
    expect(find.bySemanticsLabel('Take seat 4'), findsOneWidget);

    // Take an empty seat
    // Aria owns this room, so tapping an empty seat opens the seat menu.
    await tester.tap(find.bySemanticsLabel('Take seat 4'));
    await settle(tester);
    await tester.tap(find.text('Take this seat'));
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.bySemanticsLabel('Take seat 4'), findsNothing);
    expect(find.byTooltip('Send'), findsOneWidget);

    // Chat
    await tester.enterText(find.byType(TextField), 'Hello Yolo');
    await tester.tap(find.byTooltip('Send'));
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.textContaining('Hello Yolo'), findsOneWidget);

    // Send a Crown (520 coins)
    await tester.tap(find.bySemanticsLabel('Send gift'));
    await settle(tester);
    await tester.tap(find.text('Crown'));
    await tester.pump(const Duration(milliseconds: 300));
    await tester.tap(find.text('Send').last);
    await settle(tester);
    expect(find.textContaining('sent Crown ×1'), findsWidgets);

    // Let animations finish and dispose cleanly.
    await tester.pump(const Duration(seconds: 4));
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 2));
  });
}
