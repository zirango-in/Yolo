import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import 'models.dart';
import 'providers.dart';
import 'repository.dart';

/// Events & missions. Laravel: GET /events, POST /events/{id}/join, /events/{id}/claim/{tier},
/// GET /events/{id}/leaderboard, GET /missions, POST /missions/{id}/claim.
class EventInfo {
  final int id;
  final String title;
  final String subtitle;
  final DateTime start;
  final DateTime end;
  final List<Color> colors;
  final IconData icon;
  final List<String> rules;
  final List<(int, String, int)> tiers; // (points needed, reward label, coins)
  final List<int> giftIds; // gifts that earn points (1 point per coin)
  const EventInfo(this.id, this.title, this.subtitle, this.start, this.end, this.colors, this.icon, this.rules, this.tiers, this.giftIds);

  String status(DateTime now) => now.isBefore(start) ? 'upcoming' : (now.isAfter(end) ? 'ended' : 'live');
}

final _now = DateTime.now();

final allEvents = [
  EventInfo(1, 'Ludo Party Night', 'Send Rose & Heart gifts to climb the board', _now.subtract(const Duration(hours: 2)), _now.add(const Duration(hours: 4)),
      const [Color(0xFF6D28D9), Color(0xFFA21CAF)], Icons.casino_rounded,
      const ['Send event gifts (Rose, Heart) in any room to earn points: 1 coin = 1 point.', 'Reach milestones to unlock rewards.', 'Top 10 win exclusive frames.'],
      const [(10, '100 coins', 100), (100, '500 coins', 500), (1000, 'Neon frame + 2,000 coins', 2000)], const [1, 2]),
  EventInfo(2, 'Gift King Week', 'Top senders win exclusive frames', _now.subtract(const Duration(days: 2)), _now.add(const Duration(days: 3)),
      const [Color(0xFFB45309), Color(0xFFF59E0B)], Icons.workspace_premium_rounded,
      const ['Every Crown or Diamond you send earns points.', 'Leaderboard resets Monday 00:00.'],
      const [(520, '300 coins', 300), (5000, '1,500 coins', 1500), (20000, 'King frame + 8,000 coins', 8000)], const [3, 4]),
  EventInfo(3, 'Singing Star', 'Karaoke battle with live voting', _now.add(const Duration(days: 1, hours: 3)), _now.add(const Duration(days: 3)),
      const [Color(0xFF0E7490), Color(0xFF6366F1)], Icons.mic_rounded,
      const ['Sing in a music room and collect Rocket gifts.', 'Voting opens when the event starts.'],
      const [(1999, '800 coins', 800)], const [5]),
  EventInfo(4, 'Family Clash', 'Families compete for the crown', _now.add(const Duration(days: 4)), _now.add(const Duration(days: 11)),
      const [Color(0xFF9D174D), Color(0xFF7C3AED)], Icons.groups_rounded,
      const ['Family activeness counts as points.', 'Top 3 families win a family title.'],
      const [(100, '500 family coins', 0)], const []),
  EventInfo(5, 'Welcome Festival', 'Thanks for joining Yolo!', _now.subtract(const Duration(days: 10)), _now.subtract(const Duration(days: 3)),
      const [Color(0xFF1F2937), Color(0xFF4B5563)], Icons.celebration_rounded,
      const ['This event has ended. Rewards were sent to winners.'], const [(0, 'Participation 200 coins', 200)], const []),
];

class Mission {
  final String id;
  final String name;
  final int progress, target, reward;
  const Mission(this.id, this.name, this.progress, this.target, this.reward);
  bool get done => progress >= target;
}

const weeklyMissions = [
  Mission('w1', 'Be online 5 days this week', 5, 5, 300),
  Mission('w2', 'Send gifts worth 1,000 coins', 620, 1000, 400),
  Mission('w3', 'Spend 2 hours on mic', 2, 2, 350),
  Mission('w4', 'Make 3 new friends', 1, 3, 250),
];

const newUserMissions = [
  Mission('n1', 'Complete your profile', 1, 1, 100),
  Mission('n2', 'Join your first voice room', 1, 1, 100),
  Mission('n3', 'Follow 3 people', 2, 3, 150),
  Mission('n4', 'Send your first gift', 1, 1, 200),
  Mission('n5', 'Join a family', 0, 1, 300),
];

class EventsState {
  final Set<int> joined;
  final Set<int> reminders;
  final Map<int, int> points; // eventId -> my points
  final Set<String> claimed; // '<eventId>:<tierIndex>' and mission ids
  const EventsState({this.joined = const {1}, this.reminders = const {}, this.points = const {1: 25, 2: 520}, this.claimed = const {}});

  EventsState copyWith({Set<int>? joined, Set<int>? reminders, Map<int, int>? points, Set<String>? claimed}) => EventsState(
        joined: joined ?? this.joined,
        reminders: reminders ?? this.reminders,
        points: points ?? this.points,
        claimed: claimed ?? this.claimed,
      );
}

final eventsProvider = NotifierProvider<EventsController, EventsState>(EventsController.new);

class EventsController extends Notifier<EventsState> {
  @override
  EventsState build() => const EventsState();

  void join(int id) => state = state.copyWith(joined: {...state.joined, id});
  void toggleReminder(int id) =>
      state = state.copyWith(reminders: state.reminders.contains(id) ? ({...state.reminders}..remove(id)) : {...state.reminders, id});

  /// Called for every gift sent: live, joined events that count this gift earn points.
  void onGiftSent(Gift gift, int qty) {
    final now = DateTime.now();
    final pts = {...state.points};
    for (final e in allEvents) {
      if (e.status(now) == 'live' && state.joined.contains(e.id) && e.giftIds.contains(gift.id)) {
        pts[e.id] = (pts[e.id] ?? 0) + gift.price * qty;
      }
    }
    state = state.copyWith(points: pts);
  }

  /// Claim a milestone reward. Returns a message.
  String claimTier(EventInfo e, int tier) {
    final key = '${e.id}:$tier';
    final (need, label, coins) = e.tiers[tier];
    if (state.claimed.contains(key)) return 'Already claimed';
    if ((state.points[e.id] ?? 0) < need) return 'Need $need points';
    state = state.copyWith(claimed: {...state.claimed, key});
    if (coins > 0) ref.read(sessionProvider.notifier).earn(coins, note: 'Event: ${e.title}');
    return 'Claimed $label';
  }

  void claimMission(Mission m) {
    if (!m.done || state.claimed.contains(m.id)) return;
    state = state.copyWith(claimed: {...state.claimed, m.id});
    ref.read(sessionProvider.notifier).earn(m.reward, note: 'Mission: ${m.name}');
  }
}

/// Event leaderboard (demo players + me).
List<(YoloUser, int)> eventBoard(EventInfo e, int myPoints, YoloUser me) {
  final rows = [
    (DemoUsers.zara, 5200 * e.id),
    (DemoUsers.omar, 3100 * e.id),
    (DemoUsers.kenji, 1800 * e.id),
    (DemoUsers.mia, 960 * e.id),
    (DemoUsers.leo, 240 * e.id),
    (me, myPoints),
  ]..sort((a, b) => b.$2.compareTo(a.$2));
  return rows;
}

String countdown(Duration d) {
  if (d.isNegative) return '00:00:00';
  final days = d.inDays;
  final h = (d.inHours % 24).toString().padLeft(2, '0');
  final m = (d.inMinutes % 60).toString().padLeft(2, '0');
  final s = (d.inSeconds % 60).toString().padLeft(2, '0');
  return days > 0 ? '${days}d $h:$m:$s' : '$h:$m:$s';
}
