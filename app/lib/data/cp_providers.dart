import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import 'gift_providers.dart';
import 'models.dart';
import 'notifications_providers.dart';
import 'providers.dart';
import 'repository.dart';
import 'social_providers.dart';

/// CP (couple pair) & relationships.
/// Laravel: GET /me/relationships, POST /relationships/requests {type, user_id}, POST /relationships/requests/{id}/accept|decline,
/// DELETE /relationships/{id}, GET /rankings/cp. Intimacy is added server-side when partners gift each other.
class RelationType {
  final String id;
  final String name;
  final int slots;
  final int giftId; // gift sent with the request
  final IconData icon;
  final List<Color> colors;
  const RelationType(this.id, this.name, this.slots, this.giftId, this.icon, this.colors);
}

const relationTypes = [
  RelationType('couple', 'Couple', 1, 7, Icons.favorite_rounded, [Color(0xFFF472B6), Color(0xFFE11D48)]),
  RelationType('bestie', 'Best friend', 2, 3, Icons.diversity_1_rounded, [Color(0xFFFDE68A), Color(0xFFF59E0B)]),
  RelationType('brother', 'Brother', 2, 4, Icons.sports_handball_rounded, [Color(0xFF7DD3FC), Color(0xFF2563EB)]),
  RelationType('sister', 'Sister', 2, 4, Icons.spa_rounded, [Color(0xFFC4B5FD), Color(0xFF7C3AED)]),
];

RelationType relationType(String id) => relationTypes.firstWhere((t) => t.id == id);

/// Intimacy needed for each CP level, and what it unlocks.
const cpLevels = [
  (1, 0, 'Relationship badge on both profiles'),
  (2, 520, 'Pair name tag in rooms'),
  (3, 1314, 'Matching avatar frame'),
  (4, 5200, 'Pair entry effect in voice rooms'),
  (5, 13140, 'Heartbeat seat glow when on mic together'),
  (6, 52000, 'Legendary pair frame + ranking crown'),
];

int cpLevel(int intimacy) => cpLevels.lastWhere((l) => intimacy >= l.$2).$1;
int? nextCpLevelAt(int intimacy) {
  for (final l in cpLevels) {
    if (l.$2 > intimacy) return l.$2;
  }
  return null;
}

class Relationship {
  final int id;
  final String type;
  final YoloUser partner;
  final DateTime since;
  final int intimacy;
  const Relationship(this.id, this.type, this.partner, this.since, this.intimacy);
  Relationship withIntimacy(int v) => Relationship(id, type, partner, since, v);
  int get days => DateTime.now().difference(since).inDays + 1;
}

class CpRequest {
  final int id;
  final String type;
  final YoloUser user; // the other person
  final bool incoming;
  const CpRequest(this.id, this.type, this.user, this.incoming);
}

class CpState {
  final List<Relationship> relations;
  final List<CpRequest> requests;
  const CpState({this.relations = const [], this.requests = const []});
  Relationship? get couple => relations.where((r) => r.type == 'couple').firstOrNull;
  int used(String type) => relations.where((r) => r.type == type).length;
  bool hasRelationWith(int userId) => relations.any((r) => r.partner.id == userId);
}

/// Other users' couples (demo) so profiles and room cards show a real partner.
const demoCouples = {2001: 2004, 2004: 2001, 2002: 2003, 2003: 2002};

final cpProvider = NotifierProvider<CpController, CpState>(CpController.new);

class CpController extends Notifier<CpState> {
  int _nextId = 100;

  @override
  CpState build() => CpState(
        relations: [Relationship(1, 'bestie', DemoUsers.mia, DateTime.now().subtract(const Duration(days: 41)), 820)],
        requests: const [CpRequest(2, 'couple', DemoUsers.leo, true)],
      );

  /// Partner shown for any user: me → my couple; others → demo couples.
  YoloUser? coupleOf(int userId) {
    final me = ref.read(sessionProvider);
    if (me != null && userId == me.id) return state.couple?.partner;
    if (state.couple?.partner.id == userId) return me;
    final p = demoCouples[userId];
    return p == null ? null : userById(p);
  }

  /// Send a request with the type's gift. Returns '' or an error.
  String sendRequest(String typeId, YoloUser to) {
    final t = relationType(typeId);
    if (state.used(typeId) >= t.slots) return 'Your ${t.name} slots are full';
    if (state.hasRelationWith(to.id)) return 'You already have a relationship with ${to.name}';
    if (state.requests.any((r) => r.user.id == to.id && !r.incoming)) return 'Request already sent to ${to.name}';
    if (typeId == 'couple' && demoCouples.containsKey(to.id)) return '${to.name} already has a CP';
    final res = ref.read(giftCenterProvider.notifier).send(giftById(t.giftId), to, 1);
    if (!res.ok) return res.message;
    final req = CpRequest(_nextId++, typeId, to, false);
    state = CpState(relations: state.relations, requests: [...state.requests, req]);
    // Demo: the other person accepts a few seconds later.
    Timer(const Duration(seconds: 3), () {
      if (!ref.mounted || !state.requests.any((r) => r.id == req.id)) return;
      _accept(req);
      ref.read(notificationsProvider.notifier).push('cp', '${t.name} accepted', '${to.name} accepted your ${t.name} request', ref: to.id);
    });
    return '';
  }

  void _accept(CpRequest r) {
    final rel = Relationship(_nextId++, r.type, r.user, DateTime.now(), giftById(relationType(r.type).giftId).price ~/ 10);
    state = CpState(relations: [...state.relations, rel], requests: state.requests.where((x) => x.id != r.id).toList());
  }

  /// Accept an incoming request. Returns '' or an error.
  String accept(int requestId) {
    final r = state.requests.firstWhere((x) => x.id == requestId);
    final t = relationType(r.type);
    if (state.used(r.type) >= t.slots) return 'Your ${t.name} slots are full — end one first';
    _accept(r);
    return '';
  }

  void decline(int requestId) => state = CpState(relations: state.relations, requests: state.requests.where((x) => x.id != requestId).toList());

  void breakUp(int relationId) => state = CpState(relations: state.relations.where((r) => r.id != relationId).toList(), requests: state.requests);

  /// Called for every gift: gifts to a partner add intimacy (10 coins = 1 point).
  void onGift(int toUserId, int coins) {
    if (!state.hasRelationWith(toUserId)) return;
    state = CpState(
      relations: [for (final r in state.relations) r.partner.id == toUserId ? r.withIntimacy(r.intimacy + (coins / 10).ceil()) : r],
      requests: state.requests,
    );
  }
}

/// CP ranking (demo pairs + my couple).
List<(YoloUser, YoloUser, int)> cpRanking(CpState s, YoloUser me) {
  final rows = <(YoloUser, YoloUser, int)>[
    (DemoUsers.zara, DemoUsers.omar, 64200),
    (DemoUsers.kenji, DemoUsers.mia, 28700),
    (const YoloUser(id: 3001, name: 'Nova', avatarColors: [Color(0xFF22D3EE), Color(0xFF6366F1)]),
        const YoloUser(id: 3002, name: 'Rio', gender: 'male', avatarColors: [Color(0xFFF97316), Color(0xFFDC2626)]), 9100),
    if (s.couple != null) (me, s.couple!.partner, s.couple!.intimacy),
  ]..sort((a, b) => b.$3.compareTo(a.$3));
  return rows;
}
