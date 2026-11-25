import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:material_ui/material_ui.dart';

import 'package:yolo/data/providers.dart';
import 'package:yolo/data/support_providers.dart';
import 'package:yolo/main.dart';

Future<void> settle(WidgetTester t, [int frames = 12]) async {
  for (var i = 0; i < frames; i++) {
    await t.pump(const Duration(milliseconds: 100));
  }
}

void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  testWidgets('support: FAQ search, customer service bot + human, feedback, bug, report, tickets, legal', (tester) async {
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
    List<Ticket> tickets() => c.read(supportProvider).tickets;

    // Help center + FAQ search + expand
    router.push('/support');
    await settle(tester);
    await tester.enterText(find.byType(TextField), 'refund');
    await settle(tester);
    expect(find.text('Can I get a refund?'), findsOneWidget);
    await tester.tap(find.text('Can I get a refund?'));
    await settle(tester);
    expect(find.textContaining('non-refundable'), findsOneWidget);
    await tester.enterText(find.byType(TextField), '');
    await settle(tester);

    // Customer service: bot answer, then human handoff creates a ticket
    expect(find.text('Customer service'), findsOneWidget);
    router.push('/support/chat');
    await settle(tester);
    await tester.tap(find.text('Coins not received'));
    await settle(tester);
    expect(find.textContaining('order ID'), findsOneWidget);
    final before = tickets().length;
    await tester.enterText(find.byType(TextField), 'I need a human agent');
    await tester.tap(find.byTooltip('Send'));
    await settle(tester);
    expect(tickets().length, before + 1);
    expect(tickets().first.kind, 'Support');
    router.pop();
    await settle(tester);

    // Feedback (needs stars + text)
    router.push('/support/feedback');
    await settle(tester);
    await tester.tap(find.byTooltip('5 stars'));
    await tester.enterText(find.byType(TextField), 'Love the gold design!');
    await settle(tester);
    await tester.tap(find.text('Send feedback'));
    await settle(tester);
    expect(tickets().first.kind, 'Feedback');
    expect(tickets().first.summary, contains('5★'));

    // Bug report
    router.push('/support/bug');
    await settle(tester);
    await tester.tap(find.text('Chat'));
    await tester.enterText(find.byType(TextField), 'Voice message does not play on my phone');
    await settle(tester);
    await tester.tap(find.text('Send bug report'));
    await settle(tester);
    expect(tickets().first.kind, 'Bug');
    expect(tickets().first.summary, startsWith('Chat:'));

    // Report a room
    router.push('/support/report');
    await settle(tester);
    await tester.tap(find.text('Room'));
    await settle(tester);
    await tester.enterText(find.byType(TextField).first, '884216');
    await tester.tap(find.text('Scam / fraud'));
    await settle(tester);
    await tester.tap(find.text('Submit report'));
    await settle(tester);
    expect(tickets().first.summary, 'Room 884216: Scam / fraud');

    // Tickets list
    router.push('/support/tickets');
    await settle(tester);
    expect(find.text('Room 884216: Scam / fraud'), findsOneWidget);
    expect(find.text('Resolved'), findsOneWidget);
    router.pop();
    await settle(tester);

    // Legal pages
    router.push('/legal/terms');
    await settle(tester);
    expect(find.text('Terms of service'), findsOneWidget);
    expect(find.textContaining('[COUNTRY]'), findsWidgets);
    router.pop();
    await settle(tester);
    router.push('/legal/safety');
    await settle(tester);
    expect(find.text('Protect yourself'), findsOneWidget);

    await tester.pumpWidget(const SizedBox());
    await settle(tester, 30);
    FlutterError.onError = original;
  });
}
