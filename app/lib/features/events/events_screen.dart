import 'dart:async';

import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../core/theme.dart';
import '../../data/events_providers.dart';
import '../../data/gift_providers.dart';
import '../../data/providers.dart';
import '../../data/wallet_providers.dart';
import '../../widgets/common.dart';
import '../../widgets/page_kit.dart';

/// Rebuilds every second (for countdowns). The timer stops when the widget is removed.
class Ticker extends StatefulWidget {
  const Ticker({super.key, required this.builder});
  final Widget Function(BuildContext, DateTime) builder;

  @override
  State<Ticker> createState() => _TickerState();
}

class _TickerState extends State<Ticker> {
  late final Timer _t;
  @override
  void initState() {
    super.initState();
    _t = Timer.periodic(const Duration(seconds: 1), (_) => setState(() {}));
  }

  @override
  void dispose() {
    _t.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.builder(context, DateTime.now());
}

String _timeLabel(EventInfo e, DateTime now) => switch (e.status(now)) {
      'live' => 'Ends in ${countdown(e.end.difference(now))}',
      'upcoming' => 'Starts in ${countdown(e.start.difference(now))}',
      _ => 'Ended',
    };

class EventsScreen extends ConsumerStatefulWidget {
  const EventsScreen({super.key});

  @override
  ConsumerState<EventsScreen> createState() => _EventsScreenState();
}

class _EventsScreenState extends ConsumerState<EventsScreen> {
  static const _tabs = ['Current', 'Upcoming', 'Ended'];
  static const _status = ['live', 'upcoming', 'ended'];
  int _tab = 0;

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(eventsProvider);
    final now = DateTime.now();
    final live = allEvents.where((e) => e.status(now) == 'live').toList();
    final list = allEvents.where((e) => e.status(now) == _status[_tab]).toList();

    Widget shortcut(IconData icon, String label, Color color, String route) => Expanded(
          child: InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: () => context.push(route),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Column(children: [TintIcon(icon, color: color, size: 46), const SizedBox(height: 6), Text(label, style: const TextStyle(fontSize: 12))]),
            ),
          ),
        );

    return YoloPage(
      title: 'Events',
      body: ListView(padding: const EdgeInsets.only(bottom: 40), children: [
        // Banner carousel of live events
        SizedBox(
          height: 150,
          child: PageView(
            controller: PageController(viewportFraction: 0.9),
            children: [
              for (final e in live)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  child: GlassCard(
                    padding: const EdgeInsets.all(18),
                    gradient: LinearGradient(colors: e.colors),
                    onTap: () => context.push('/events/detail', extra: e),
                    child: Row(children: [
                      Expanded(
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.center, children: [
                          const Badge2('LIVE', bg: Color(0xFFEF4444), fg: Colors.white),
                          const SizedBox(height: 8),
                          Text(e.title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900)),
                          Ticker(builder: (_, t) => Text(_timeLabel(e, t), style: const TextStyle(color: Color(0xFFFDE7A8), fontWeight: FontWeight.w700))),
                        ]),
                      ),
                      Icon(e.icon, size: 60, color: Colors.white.withValues(alpha: 0.85)),
                    ]),
                  ),
                ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
          child: Row(children: [
            shortcut(Icons.task_alt_rounded, 'Missions', const Color(0xFF86EFAC), '/missions'),
            shortcut(Icons.event_available_rounded, 'Check-in', const Color(0xFFF5C451), '/rewards'),
            shortcut(Icons.emoji_events_rounded, 'Achievements', const Color(0xFFFDE68A), '/profile/achievements'),
            shortcut(Icons.leaderboard_rounded, 'Rankings', const Color(0xFF7DD3FC), '/rankings'),
          ]),
        ),
        YoloTabs(tabs: _tabs, index: _tab, onChanged: (i) => setState(() => _tab = i), padding: const EdgeInsets.fromLTRB(20, 14, 20, 10)),
        if (list.isEmpty) const Padding(padding: EdgeInsets.all(30), child: Center(child: Text('No events here', style: TextStyle(color: YoloColors.textMuted)))),
        for (final (i, e) in list.indexed)
          GlassCard(
            margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            padding: const EdgeInsets.all(16),
            gradient: LinearGradient(colors: e.colors, begin: Alignment.topLeft, end: Alignment.bottomRight),
            onTap: () => context.push('/events/detail', extra: e),
            child: Row(children: [
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(children: [
                    Flexible(child: Text(e.title, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800))),
                    if (s.joined.contains(e.id)) ...[const SizedBox(width: 6), const Badge2('Joined', bg: Color(0x334ADE80), fg: YoloColors.online)],
                    if (s.reminders.contains(e.id)) ...[const SizedBox(width: 6), const Icon(Icons.notifications_active_rounded, size: 16, color: YoloColors.gold)],
                  ]),
                  const SizedBox(height: 2),
                  Text(e.subtitle, style: const TextStyle(fontSize: 12, color: Color(0xFFF1E6FF))),
                  const SizedBox(height: 6),
                  Ticker(builder: (_, t) => Text(_timeLabel(e, t), style: const TextStyle(fontSize: 12, color: Color(0xFFFDE7A8), fontWeight: FontWeight.w700))),
                ]),
              ),
              Icon(e.icon, size: 44, color: Colors.white.withValues(alpha: 0.85)),
            ]),
          ).entrance(i),
      ]),
    );
  }
}

/// Event details: countdown, rules, milestone rewards, event gifts, leaderboard.
class EventDetailScreen extends ConsumerWidget {
  const EventDetailScreen({super.key, required this.event});
  final EventInfo event;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final e = event;
    final s = ref.watch(eventsProvider);
    final me = ref.watch(sessionProvider)!;
    final ctrl = ref.read(eventsProvider.notifier);
    final status = e.status(DateTime.now());
    final joined = s.joined.contains(e.id);
    final pts = s.points[e.id] ?? 0;
    final board = eventBoard(e, pts, me);
    final myRank = board.indexWhere((r) => r.$1.id == me.id) + 1;

    return YoloPage(
      title: e.title,
      body: ListView(padding: const EdgeInsets.fromLTRB(16, 4, 16, 40), children: [
        GlassCard(
          padding: const EdgeInsets.all(20),
          gradient: LinearGradient(colors: e.colors),
          child: Column(children: [
            Icon(e.icon, size: 64, color: Colors.white).animate(onPlay: (c) => c.repeat(reverse: true)).scaleXY(end: 1.08, duration: 900.ms),
            const SizedBox(height: 8),
            Text(e.subtitle, textAlign: TextAlign.center, style: const TextStyle(color: Color(0xFFF1E6FF))),
            const SizedBox(height: 10),
            Ticker(builder: (_, t) => Text(_timeLabel(e, t), style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Color(0xFFFDE7A8)))),
          ]),
        ),
        const SizedBox(height: 12),
        if (status == 'live' && !joined)
          GoldButton(label: 'Join event', icon: Icons.flag_rounded, onPressed: () {
            ctrl.join(e.id);
            showYoloToast(context, 'You joined ${e.title}!');
          })
        else if (status == 'upcoming')
          GoldButton(
            label: s.reminders.contains(e.id) ? 'Reminder set' : 'Remind me',
            icon: Icons.notifications_active_rounded,
            onPressed: () => ctrl.toggleReminder(e.id),
          )
        else if (joined)
          GlassCard(
            child: Row(children: [
              const Icon(Icons.stars_rounded, color: YoloColors.gold, size: 30),
              const SizedBox(width: 10),
              Expanded(child: Text('My points: ${formatCoins(pts)}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800))),
              Text('Rank #$myRank', style: const TextStyle(color: YoloColors.gold, fontWeight: FontWeight.w800)),
            ]),
          ),
        const SectionTitle('Rules'),
        for (final r in e.rules)
          Padding(
            padding: const EdgeInsets.fromLTRB(4, 0, 4, 8),
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('•  ', style: TextStyle(color: YoloColors.gold)),
              Expanded(child: Text(r, style: const TextStyle(color: YoloColors.textSoft, height: 1.4))),
            ]),
          ),
        const SectionTitle('Rewards'),
        for (final (i, (need, label, _)) in e.tiers.indexed)
          GlassCard(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(12),
            child: Row(children: [
              const Icon(Icons.redeem_rounded, color: YoloColors.gold),
              const SizedBox(width: 10),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(label, style: const TextStyle(fontWeight: FontWeight.w700)),
                  Text('$need points', style: const TextStyle(fontSize: 12, color: YoloColors.textMuted)),
                ]),
              ),
              if (s.claimed.contains('${e.id}:$i'))
                const Text('Claimed', style: TextStyle(color: YoloColors.online, fontWeight: FontWeight.w700))
              else
                SizedBox(
                  width: 84,
                  child: Opacity(
                    opacity: pts >= need && joined ? 1 : 0.4,
                    child: GoldButton(label: 'Claim', height: 34, onPressed: pts >= need && joined ? () => showYoloToast(context, ctrl.claimTier(e, i)) : null),
                  ),
                ),
            ]),
          ),
        if (e.giftIds.isNotEmpty) ...[
          const SectionTitle('Event gifts'),
          Wrap(spacing: 12, runSpacing: 12, children: [
            for (final id in e.giftIds)
              GlassCard(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                onTap: () => context.push('/gifts'),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  Icon(giftById(id).icon, color: giftById(id).tint),
                  const SizedBox(width: 8),
                  Text(giftById(id).name, style: const TextStyle(fontWeight: FontWeight.w700)),
                  const SizedBox(width: 6),
                  Text('+${giftById(id).price} pts', style: const TextStyle(fontSize: 11, color: YoloColors.gold)),
                ]),
              ),
          ]),
        ],
        const SectionTitle('Leaderboard'),
        for (final (i, (u, p)) in board.indexed)
          ListTile(
            contentPadding: EdgeInsets.zero,
            tileColor: u.id == me.id ? YoloColors.gold.withValues(alpha: 0.06) : null,
            leading: SizedBox(
              width: 80,
              child: Row(children: [
                SizedBox(width: 28, child: Text('${i + 1}', style: TextStyle(fontWeight: FontWeight.w900, color: i < 3 ? YoloColors.gold : YoloColors.textMuted))),
                YoloAvatar(user: u, size: 40, goldFrame: i == 0),
              ]),
            ),
            title: Text(u.id == me.id ? '${u.name} (you)' : u.name, style: const TextStyle(fontWeight: FontWeight.w700)),
            trailing: Text(formatCoins(p), style: const TextStyle(color: YoloColors.gold, fontWeight: FontWeight.w800)),
          ),
      ]),
    );
  }
}

/// Missions: daily (shared with Rewards), weekly, new user.
class MissionsScreen extends ConsumerStatefulWidget {
  const MissionsScreen({super.key});

  @override
  ConsumerState<MissionsScreen> createState() => _MissionsScreenState();
}

class _MissionsScreenState extends ConsumerState<MissionsScreen> {
  int _tab = 0;

  @override
  Widget build(BuildContext context) {
    final w = ref.watch(walletProvider);
    final ev = ref.watch(eventsProvider);
    final now = DateTime.now();
    final reset = _tab == 0 ? DateTime(now.year, now.month, now.day + 1) : DateTime(now.year, now.month, now.day + (8 - now.weekday));

    Widget row(String name, int progress, int target, int reward, bool claimed, VoidCallback onClaim) => GlassCard(
          margin: const EdgeInsets.fromLTRB(16, 0, 16, 10),
          padding: const EdgeInsets.all(14),
          child: Row(children: [
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(name, style: const TextStyle(fontWeight: FontWeight.w700)),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(value: (progress / target).clamp(0.0, 1.0), minHeight: 6, color: YoloColors.gold, backgroundColor: const Color(0x22FFFFFF)),
                ),
                const SizedBox(height: 4),
                Text('$progress/$target · +$reward coins', style: const TextStyle(fontSize: 11, color: YoloColors.textMuted)),
              ]),
            ),
            const SizedBox(width: 12),
            if (claimed)
              const Text('Claimed', style: TextStyle(color: YoloColors.online, fontWeight: FontWeight.w700))
            else
              SizedBox(
                width: 84,
                child: Opacity(opacity: progress >= target ? 1 : 0.4, child: GoldButton(label: 'Claim', height: 34, onPressed: progress >= target ? onClaim : null)),
              ),
          ]),
        );

    final List<Widget> items = switch (_tab) {
      0 => [
          for (final (i, t) in dailyTasks.indexed) row(t.name, t.progress, t.target, t.reward, w.claimedTasks.contains(i), () => ref.read(walletProvider.notifier).claimTask(i)),
        ],
      1 => [for (final m in weeklyMissions) row(m.name, m.progress, m.target, m.reward, ev.claimed.contains(m.id), () => ref.read(eventsProvider.notifier).claimMission(m))],
      _ => [for (final m in newUserMissions) row(m.name, m.progress, m.target, m.reward, ev.claimed.contains(m.id), () => ref.read(eventsProvider.notifier).claimMission(m))],
    };

    return YoloPage(
      title: 'Missions',
      bottom: Column(children: [
        YoloTabs(tabs: const ['Daily', 'Weekly', 'New user'], index: _tab, onChanged: (i) => setState(() => _tab = i)),
        if (_tab < 2)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Ticker(builder: (_, t) => Text('Resets in ${countdown(reset.difference(t))}', style: const TextStyle(color: YoloColors.textMuted, fontSize: 12))),
          ),
      ]),
      body: ListView(padding: const EdgeInsets.only(bottom: 40), children: items),
    );
  }
}
