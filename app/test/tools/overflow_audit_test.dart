// Layout audit: renders every screen with a REAL font (Roboto, text scaled ×1.1 to be
// stricter than Plus Jakarta Sans) on small and normal phones, scrolls each page and opens
// the main sheets, and fails if any RenderFlex overflows.
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:material_ui/material_ui.dart';

import 'package:yolo/data/cp_providers.dart';
import 'package:yolo/data/demo_content.dart';
import 'package:yolo/data/events_providers.dart';
import 'package:yolo/data/music_providers.dart';
import 'package:yolo/data/providers.dart';
import 'package:yolo/data/settings_providers.dart';
import 'package:yolo/main.dart';

const _fontDir = '/opt/flutter/bin/cache/dart-sdk/bin/resources/devtools/assets/packages/devtools_app_shared/fonts/Roboto';
const _iconFont = '/opt/flutter/bin/cache/dart-sdk/bin/resources/devtools/assets/fonts/MaterialIcons-Regular.otf';

Future<void> _load(String family, String path) async {
  final loader = FontLoader(family)..addFont(Future.value(ByteData.view(File(path).readAsBytesSync().buffer)));
  await loader.load();
}

Future<void> settle(WidgetTester t, [int frames = 10]) async {
  for (var i = 0; i < frames; i++) {
    await t.pump(const Duration(milliseconds: 100));
  }
}

void main() {
  final hasFonts = File('$_fontDir/Roboto-Regular.ttf').existsSync();

  setUpAll(() async {
    GoogleFonts.config.allowRuntimeFetching = false;
    if (!hasFonts) return;
    for (final f in ['PlusJakartaSans_regular', 'PlusJakartaSans_500', 'Roboto', '.SF UI Text', '.SF UI Display']) {
      await _load(f, '$_fontDir/Roboto-Regular.ttf');
    }
    for (final f in ['PlusJakartaSans_600', 'PlusJakartaSans_700', 'PlusJakartaSans_800']) {
      await _load(f, '$_fontDir/Roboto-Bold.ttf');
    }
    await _load('MaterialIcons', _iconFont);
  });

  for (final size in const [Size(360, 640), Size(390, 844)]) {
    testWidgets('no overflow on ${size.width.toInt()}×${size.height.toInt()}', (tester) async {
      final problems = <String>{};
      String? current;
      final original = FlutterError.onError;
      FlutterError.onError = (d) {
        final text = d.toString();
        if (text.contains('overflowed')) {
          final by = RegExp(r'overflowed by ([\d.]+) pixels on the (\w+)').firstMatch(text);
          final where = RegExp(r'file:///home/user/yolo/app/lib/([^\s:]+):(\d+)').firstMatch(text);
          problems.add('[$current] ${where?.group(1)}:${where?.group(2)} · ${by?.group(1)}px ${by?.group(2)}');
        } else if (!text.contains('A RenderFlex')) {
          original?.call(d);
        }
      };

      await tester.binding.setSurfaceSize(size);
      await tester.pumpWidget(const ProviderScope(child: YoloApp()));
      await settle(tester);
      final c = ProviderScope.containerOf(tester.element(find.byType(YoloApp)));
      c.read(settingsProvider.notifier).update((s) => s.copyWith(textScale: double.parse(const String.fromEnvironment('AUDIT_SCALE', defaultValue: '1.1'))));

      current = 'welcome';
      await settle(tester);
      final router = c.read(routerProvider);
      for (final r in ['/login', '/login/phone', '/login/email', '/login/recover', '/login/register']) {
        current = r;
        router.go(r);
        await settle(tester);
      }

      final login = c.read(sessionProvider.notifier).login('google');
      await settle(tester);
      await login;
      final roomsF = c.read(roomsProvider('popular').future);
      await settle(tester);
      final rooms = await roomsF;

      Future<void> closeTop() async {
        for (final type in [BottomSheet, Dialog, AlertDialog]) {
          final f = find.byType(type);
          if (f.evaluate().isNotEmpty) {
            Navigator.of(tester.element(f.last)).pop();
            await settle(tester, 6);
            return;
          }
        }
      }

      Future<void> scrollAll() async {
        for (var i = 0; i < 6; i++) {
          final scrollables = find.byType(Scrollable);
          if (scrollables.evaluate().isEmpty) break;
          await tester.drag(scrollables.first, const Offset(0, -400), warnIfMissed: false);
          await tester.pump(const Duration(milliseconds: 200));
        }
      }

      Future<void> visit(String route, {Object? extra, bool scroll = true}) async {
        current = route;
        router.go('/home');
        await settle(tester, 3);
        router.push(route, extra: extra);
        await settle(tester);
        if (scroll) await scrollAll();
      }

      // Home tabs
      router.go('/home');
      current = '/home';
      await settle(tester);
      await scrollAll();
      for (final tab in ['Games', 'Messages', 'Me']) {
        current = 'tab:$tab';
        router.go('/home');
        await settle(tester, 3);
        await tester.tap(find.text(tab).last, warnIfMissed: false);
        await settle(tester);
        await scrollAll();
      }

      final routes = <(String, Object?)>[
        ('/discover', null), ('/games', null), ('/friends', null), ('/friends/requests', null), ('/friends/add', null),
        ('/chat', demoAllUsers.first), ('/chat/new-group', null), ('/blocked', null), ('/user', demoAllUsers[2]),
        ('/moments', null), ('/moments/new', null), ('/moments/post', demoMoments.first), ('/moments/topic', '#Ludo'),
        ('/family', null), ('/family/create', null), ('/family/profile', demoFamilies.first), ('/family/ranking', null),
        ('/events', null), ('/events/detail', allEvents.first), ('/events/detail', allEvents[2]), ('/missions', null),
        ('/shop', null), ('/gifts', null), ('/gifts/history', null), ('/gifts/ranking', null), ('/backpack', null),
        ('/wallet', null), ('/wallet/transactions', null), ('/wallet/purchases', null), ('/rewards', null), ('/rewards/invite', null),
        ('/vip', null), ('/vip/manage', null), ('/vip/history', null), ('/rankings', null),
        ('/notifications', null), ('/settings', null), ('/settings/privacy', null), ('/settings/notifications', null),
        ('/settings/sound', null), ('/settings/language', null), ('/settings/display', null), ('/settings/permissions', null),
        ('/settings/storage', null), ('/account', null), ('/profile/edit', null), ('/profile/avatar', null),
        ('/profile/levels', null), ('/profile/badges', null), ('/profile/achievements', null),
        ('/support', null), ('/support/chat', null), ('/support/feedback', null), ('/support/bug', null),
        ('/support/report', null), ('/support/tickets', null), ('/legal/privacy', null),
        ('/music', null), ('/music/karaoke', demoSongs.first), ('/music/room', null), ('/music/micgrab', null),
        ('/music/upload', null), ('/music/result', SingResult(demoSongs.first, 92, 100, '20:00')),
        ('/room/create', null), ('/cp', null), ('/cp/ranking', null),
      ];
      for (final (r, extra) in routes) {
        await visit(r, extra: extra);
      }

      await visit('/cp/space', extra: c.read(cpProvider).relations.first);
      // Family member view (join first)
      await visit('/family/profile', extra: demoFamilies[2], scroll: false);
      await tester.tap(find.text('Join family'), warnIfMissed: false);
      await settle(tester);
      for (final r in ['/family', '/family/quests', '/family/gacha', '/family/shop', '/family/members']) {
        await visit(r);
      }

      // Voice room + sheets
      await visit('/room', extra: rooms.first, scroll: false);
      current = 'room:gift sheet';
      await tester.tap(find.bySemanticsLabel('Send gift'), warnIfMissed: false);
      await settle(tester);
      for (final t in ['Lucky', 'VIP', 'Backpack']) {
        await tester.tap(find.text(t).last, warnIfMissed: false);
        await settle(tester, 4);
      }
      await tester.tapAt(const Offset(20, 60));
      await settle(tester, 30);
      current = 'room:menu';
      await tester.tap(find.byTooltip('Room menu'), warnIfMissed: false);
      await settle(tester);
      await tester.tapAt(const Offset(20, 60));
      await settle(tester);
      current = 'room:seat';
      await tester.tap(find.bySemanticsLabel('Zara'), warnIfMissed: false);
      await settle(tester);
      await tester.tapAt(const Offset(20, 60));
      await settle(tester);
      current = 'room:info';
      await tester.tap(find.text(rooms.first.name).first, warnIfMissed: false);
      await settle(tester);
      await closeTop();
      await settle(tester);
      current = 'room:members';
      await tester.tap(find.bySemanticsLabel('Online users'), warnIfMissed: false);
      await settle(tester);
      await closeTop();
      await settle(tester);
      for (final label in ['Interactions', 'Room tools', 'Treasure boxes']) {
        current = 'room:$label';
        await tester.tap(find.bySemanticsLabel(label), warnIfMissed: false);
        await settle(tester);
        await closeTop();
        await settle(tester);
      }
      current = 'room:user card';
      await tester.tap(find.text('HOST'), warnIfMissed: false);
      await settle(tester);
      await closeTop();
      await settle(tester);
      await visit('/room/settings', extra: rooms.first);
      await visit('/room/level', extra: rooms.first);
      // 12-seat private room
      await visit('/room', extra: rooms.last, scroll: false);

      // Battle (let it finish)
      await visit('/music/battle', scroll: false);
      await settle(tester, 110);
      await scrollAll();

      await tester.pumpWidget(const SizedBox());
      await settle(tester, 30);
      FlutterError.onError = original;

      if (problems.isNotEmpty) {
        // ignore: avoid_print
        print('OVERFLOWS (${problems.length}):\n${problems.join('\n')}');
      }
      expect(problems, isEmpty);
    }, skip: !hasFonts);
  }
}
