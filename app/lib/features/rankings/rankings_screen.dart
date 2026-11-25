import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../core/theme.dart';
import '../../data/demo_content.dart';
import '../../data/family_providers.dart';
import '../../data/gift_providers.dart';
import '../../data/models.dart';
import '../../data/providers.dart';
import '../../data/social_providers.dart';
import '../../widgets/common.dart';
import '../../widgets/page_kit.dart';
import '../family/family_screen.dart';
import '../room/room_sheets.dart';

/// One leaderboard row (user, room or family).
class RankRow {
  final String id;
  final String name;
  final int score;
  final YoloUser? user;
  final Room? room;
  final FamilyInfo? family;
  const RankRow(this.id, this.name, this.score, {this.user, this.room, this.family});
}

const rankingTabs = ['Wealth', 'Charm', 'Rooms', 'Families', 'Popular', 'Games', 'Events'];
const _units = ['coins sent', 'coins received', 'heat', 'activeness', 'new followers', 'wins', 'points'];
const _periods = ['Daily', 'Weekly', 'Monthly'];
const _periodScale = [1, 6, 22];

/// Global leaderboards. Laravel: GET /rankings/{type}?period=&scope=
class RankingsScreen extends ConsumerStatefulWidget {
  const RankingsScreen({super.key, this.initialTab = 0});
  final int initialTab;

  @override
  ConsumerState<RankingsScreen> createState() => _RankingsScreenState();
}

class _RankingsScreenState extends ConsumerState<RankingsScreen> {
  late int _tab = widget.initialTab;
  int _period = 1;
  bool _friendsOnly = false;

  List<RankRow> _rows(YoloUser me) {
    final scale = _periodScale[_period];
    final users = [...demoAllUsers, me];
    final records = ref.read(giftCenterProvider).records;
    final friends = ref.read(friendsProvider).map((u) => u.id).toSet()..add(me.id);
    List<RankRow> rows;
    switch (_tab) {
      case 0:
      case 1:
        rows = [
          for (final (u, total) in giftRanking(records, senders: _tab == 0))
            RankRow('u${u.id}', u.name, total * scale ~/ 6, user: u),
          if (!giftRanking(records, senders: _tab == 0).any((r) => r.$1.id == me.id)) RankRow('u${me.id}', me.name, 0, user: me),
        ];
      case 2:
        final rooms = ref.read(roomsProvider('popular')).value ?? const <Room>[];
        rows = [for (final r in rooms) RankRow('r${r.id}', r.name, r.online * 137 * scale, room: r)];
      case 3:
        final fam = ref.read(familyProvider);
        rows = [for (final (f, score) in familyRanking(fam, ref.read(familyProvider.notifier).allFamilies)) RankRow('f${f.id}', f.name, score * scale, family: f)];
      case 4:
        rows = [for (final u in users) RankRow('u${u.id}', u.name, ((u.id * 37) % 900 + 120) * scale, user: u)];
      case 5:
        rows = [for (final u in users) RankRow('u${u.id}', u.name, ((u.id * 13) % 60 + 5) * scale, user: u)];
      default:
        rows = [for (final u in users) RankRow('u${u.id}', u.name, ((u.id * 53) % 4000 + 300) * scale, user: u)];
    }
    if (_friendsOnly && rows.any((r) => r.user != null)) rows = rows.where((r) => r.user == null || friends.contains(r.user!.id)).toList();
    rows.sort((a, b) => b.score.compareTo(a.score));
    return rows;
  }

  void _open(RankRow r) {
    if (r.user != null && r.user!.id != ref.read(sessionProvider)?.id) context.push('/user', extra: r.user);
    if (r.room != null) openRoom(context, ref, r.room!);
    if (r.family != null) context.push('/family/profile', extra: r.family);
  }

  Widget _avatar(RankRow r, double size, {bool gold = false}) {
    if (r.user != null) return YoloAvatar(user: r.user!, size: size, goldFrame: gold);
    if (r.family != null) return FamilyBadge(r.family!, size: size);
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(size * 0.3), gradient: LinearGradient(colors: r.room?.cover ?? const [Colors.grey, Colors.black])),
      alignment: Alignment.center,
      child: Text(r.name[0], style: TextStyle(fontWeight: FontWeight.w800, fontSize: size * 0.4)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final me = ref.watch(sessionProvider)!;
    ref.watch(giftCenterProvider);
    ref.watch(familyProvider);
    ref.watch(followingProvider);
    final rows = _rows(me);
    final top = rows.take(3).toList();
    final rest = rows.skip(3).toList();
    final myIndex = rows.indexWhere((r) => r.user?.id == me.id);
    const medal = [Color(0xFFF5C451), Color(0xFFD1D5DB), Color(0xFFD97706)];

    Widget podium(int place) {
      if (place >= top.length) return const Expanded(child: SizedBox());
      final r = top[place];
      final size = place == 0 ? 76.0 : 60.0;
      return Expanded(
        child: GestureDetector(
          onTap: () => _open(r),
          child: Column(mainAxisAlignment: MainAxisAlignment.end, children: [
            Icon(Icons.emoji_events_rounded, color: medal[place], size: place == 0 ? 30 : 22)
                .animate(onPlay: (c) => place == 0 ? c.repeat(reverse: true) : null)
                .moveY(begin: 0, end: -4, duration: 900.ms),
            _avatar(r, size, gold: place == 0),
            const SizedBox(height: 6),
            Text(r.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w800)),
            Text(formatCoins(r.score), style: TextStyle(color: medal[place], fontWeight: FontWeight.w800, fontSize: 12)),
            const SizedBox(height: 6),
            Container(
              height: place == 0 ? 70 : (place == 1 ? 50 : 36),
              margin: const EdgeInsets.symmetric(horizontal: 6),
              decoration: BoxDecoration(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                gradient: LinearGradient(colors: [medal[place].withValues(alpha: 0.5), medal[place].withValues(alpha: 0.1)], begin: Alignment.topCenter, end: Alignment.bottomCenter),
              ),
              alignment: Alignment.center,
              child: Text('${place + 1}', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900)),
            ),
          ]),
        ).animate().fadeIn(delay: (100 * place).ms).slideY(begin: 0.3, end: 0),
      );
    }

    return YoloPage(
      title: 'Rankings',
      bottom: Column(children: [
        YoloTabs(tabs: rankingTabs, index: _tab, onChanged: (i) => setState(() => _tab = i)),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
          child: Row(children: [
            Expanded(
              child: SegmentedButton<int>(
                showSelectedIcon: false,
                segments: [for (var i = 0; i < 3; i++) ButtonSegment(value: i, label: Text(_periods[i]))],
                selected: {_period},
                onSelectionChanged: (s) => setState(() => _period = s.first),
              ),
            ),
            const SizedBox(width: 8),
            FilterChip(
              label: Text(_friendsOnly ? 'Friends' : 'Global'),
              selected: _friendsOnly,
              onSelected: (v) => setState(() => _friendsOnly = v),
              selectedColor: YoloColors.gold.withValues(alpha: 0.25),
            ),
          ]),
        ),
      ]),
      body: Column(children: [
        Expanded(
          child: ListView(padding: const EdgeInsets.only(bottom: 12), children: [
            if (_tab == 5)
              const Padding(
                padding: EdgeInsets.fromLTRB(20, 0, 20, 8),
                child: Text('Game rankings go live when games launch.', style: TextStyle(color: YoloColors.textMuted, fontSize: 12)),
              ),
            if (_tab == 6)
              const Padding(
                padding: EdgeInsets.fromLTRB(20, 0, 20, 8),
                child: Text('Event: Ludo Party Night', style: TextStyle(color: YoloColors.gold, fontWeight: FontWeight.w700)),
              ),
            SizedBox(
              height: 250,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Row(crossAxisAlignment: CrossAxisAlignment.end, children: [podium(1), podium(0), podium(2)]),
              ),
            ),
            for (final (i, r) in rest.indexed)
              ListTile(
                key: ValueKey('${_tab}_${r.id}'),
                onTap: () => _open(r),
                tileColor: r.user?.id == me.id ? YoloColors.gold.withValues(alpha: 0.06) : null,
                leading: SizedBox(
                  width: 88,
                  child: Row(children: [
                    SizedBox(width: 32, child: Text('${i + 4}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: YoloColors.textMuted))),
                    _avatar(r, 44),
                  ]),
                ),
                title: Text(r.user?.id == me.id ? '${r.name} (you)' : r.name, style: const TextStyle(fontWeight: FontWeight.w700)),
                subtitle: Text(_units[_tab], style: const TextStyle(fontSize: 11, color: YoloColors.textMuted)),
                trailing: Text(formatCoins(r.score), style: const TextStyle(color: YoloColors.gold, fontWeight: FontWeight.w800)),
              ).entrance(i),
          ]),
        ),
        if (myIndex >= 0)
          Container(
            decoration: BoxDecoration(color: YoloColors.sheet, border: Border(top: BorderSide(color: YoloColors.gold.withValues(alpha: 0.3)))),
            child: SafeArea(
              top: false,
              child: ListTile(
                leading: SizedBox(
                  width: 88,
                  child: Row(children: [
                    SizedBox(width: 32, child: Text('${myIndex + 1}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: YoloColors.gold))),
                    YoloAvatar(user: me, size: 44),
                  ]),
                ),
                title: const Text('My position', style: TextStyle(fontWeight: FontWeight.w800)),
                subtitle: Text(myIndex == 0 ? 'You are #1!' : '${formatCoins(rows[myIndex - 1].score - rows[myIndex].score)} to pass #$myIndex',
                    style: const TextStyle(fontSize: 12, color: YoloColors.textMuted)),
                trailing: Text(formatCoins(rows[myIndex].score), style: const TextStyle(color: YoloColors.gold, fontWeight: FontWeight.w900)),
              ),
            ),
          ),
      ]),
    );
  }
}
