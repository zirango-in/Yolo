import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import 'demo_content.dart';
import 'models.dart';
import 'providers.dart';
import 'repository.dart';

/// Everything about "my family". Laravel endpoints: /families, /families/{id}/join, /family/sign-in,
/// /family/donate, /family/quests/{id}/claim, /family/chests/{n}/claim, /family/gacha, /family/shop.
class FamilyState {
  final int? familyId;
  final String role; // leader, deputy, admin, member
  final int level;
  final int funds; // family treasury (from donations)
  final int activeness; // this week's activeness
  final int familyCoins; // my personal family coins
  final bool signedIn;
  final bool freeRollUsed;
  final Set<int> claimedQuests;
  final Set<int> claimedChests;
  final Set<String> ownedItems;
  final String? title;
  final String? frame;
  final Map<int, String> memberRoles; // userId -> role
  final List<FamilyInfo> created;

  const FamilyState({
    this.familyId,
    this.role = 'member',
    this.level = 1,
    this.funds = 0,
    this.activeness = 0,
    this.familyCoins = 0,
    this.signedIn = false,
    this.freeRollUsed = false,
    this.claimedQuests = const {},
    this.claimedChests = const {},
    this.ownedItems = const {},
    this.title,
    this.frame,
    this.memberRoles = const {},
    this.created = const [],
  });

  FamilyState copyWith({
    int? familyId,
    bool clearFamily = false,
    String? role,
    int? level,
    int? funds,
    int? activeness,
    int? familyCoins,
    bool? signedIn,
    bool? freeRollUsed,
    Set<int>? claimedQuests,
    Set<int>? claimedChests,
    Set<String>? ownedItems,
    String? title,
    String? frame,
    Map<int, String>? memberRoles,
    List<FamilyInfo>? created,
  }) =>
      FamilyState(
        familyId: clearFamily ? null : (familyId ?? this.familyId),
        role: role ?? this.role,
        level: level ?? this.level,
        funds: funds ?? this.funds,
        activeness: activeness ?? this.activeness,
        familyCoins: familyCoins ?? this.familyCoins,
        signedIn: signedIn ?? this.signedIn,
        freeRollUsed: freeRollUsed ?? this.freeRollUsed,
        claimedQuests: claimedQuests ?? this.claimedQuests,
        claimedChests: claimedChests ?? this.claimedChests,
        ownedItems: ownedItems ?? this.ownedItems,
        title: title ?? this.title,
        frame: frame ?? this.frame,
        memberRoles: memberRoles ?? this.memberRoles,
        created: created ?? this.created,
      );

  bool get canManage => role == 'leader' || role == 'deputy';
  int get upgradeCost => level * 5000;
  int get maxMembers => 40 + level * 10;
}

class FamilyQuest {
  final String name;
  final int progress, target, activeness, coins;
  const FamilyQuest(this.name, this.progress, this.target, this.activeness, this.coins);
  bool get done => progress >= target;
}

const familyQuests = [
  FamilyQuest('Sign in to the family', 1, 1, 10, 20),
  FamilyQuest('Chat in the family room', 5, 5, 15, 30),
  FamilyQuest('Stay on mic for 10 minutes', 10, 10, 20, 40),
  FamilyQuest('Send 3 gifts to members', 1, 3, 25, 60),
  FamilyQuest('Donate to the family', 0, 1, 30, 80),
];

const chestMilestones = [(20, 100), (60, 300), (120, 800)]; // (activeness needed, coins reward)

class FamilyShopItem {
  final String id, name, kind; // kind: title / frame
  final int price;
  final IconData icon;
  final Color color;
  const FamilyShopItem(this.id, this.name, this.kind, this.price, this.icon, this.color);
}

const familyShop = [
  FamilyShopItem('t-guardian', 'Guardian', 'title', 50, Icons.shield_rounded, Color(0xFF7DD3FC)),
  FamilyShopItem('t-star', 'Rising Star', 'title', 80, Icons.star_rounded, Color(0xFFFDE68A)),
  FamilyShopItem('t-legend', 'Family Legend', 'title', 200, Icons.military_tech_rounded, Color(0xFFF5C451)),
  FamilyShopItem('f-moon', 'Moon Frame', 'frame', 120, Icons.nightlight_round, Color(0xFFC4B5FD)),
  FamilyShopItem('f-flame', 'Flame Frame', 'frame', 160, Icons.local_fire_department_rounded, Color(0xFFFDBA74)),
  FamilyShopItem('f-crown', 'Crown Frame', 'frame', 300, Icons.workspace_premium_rounded, Color(0xFFF5C451)),
];

const gachaPrizes = [('20 family coins', 20, 0), ('50 family coins', 50, 0), ('100 coins', 0, 100), ('300 coins', 0, 300), ('10 family coins', 10, 0), ('Jackpot 1,000 coins', 0, 1000)];

final familyProvider = NotifierProvider<FamilyController, FamilyState>(FamilyController.new);

class FamilyController extends Notifier<FamilyState> {
  final _rand = Random();

  @override
  FamilyState build() => const FamilyState();

  List<FamilyInfo> get allFamilies => [...state.created, ...demoFamilies];
  FamilyInfo? get current => allFamilies.where((f) => f.id == state.familyId).firstOrNull;

  void join(FamilyInfo f) => state = state.copyWith(
        familyId: f.id,
        role: 'member',
        level: f.level,
        funds: f.level * 3000,
        activeness: 0,
        memberRoles: {DemoUsers.omar.id: 'leader', DemoUsers.zara.id: 'deputy', DemoUsers.kenji.id: 'admin', DemoUsers.mia.id: 'member', DemoUsers.leo.id: 'member'},
      );

  /// Returns '' on success or an error message.
  String create(YoloUser me, String name, String slogan, List<Color> colors) {
    if (!ref.read(sessionProvider.notifier).spend(5000)) return 'Creating a family costs 5,000 coins';
    final f = FamilyInfo(800000 + state.created.length, name, slogan, 1, 1, 50, colors);
    state = state.copyWith(created: [f, ...state.created], familyId: f.id, role: 'leader', level: 1, funds: 0, activeness: 0, memberRoles: {});
    return '';
  }

  void leave() => state = state.copyWith(clearFamily: true, role: 'member', activeness: 0, title: null, frame: null);

  void signIn() {
    if (state.signedIn) return;
    state = state.copyWith(signedIn: true, activeness: state.activeness + 10, familyCoins: state.familyCoins + 20);
  }

  /// Returns false when coins are not enough.
  bool donate(int coins) {
    if (!ref.read(sessionProvider.notifier).spend(coins)) return false;
    state = state.copyWith(funds: state.funds + coins, activeness: state.activeness + coins ~/ 20, familyCoins: state.familyCoins + coins ~/ 10);
    return true;
  }

  void claimQuest(int i) {
    final q = familyQuests[i];
    if (!q.done || state.claimedQuests.contains(i)) return;
    state = state.copyWith(
      claimedQuests: {...state.claimedQuests, i},
      activeness: state.activeness + q.activeness,
      familyCoins: state.familyCoins + q.coins,
    );
  }

  void claimChest(int i) {
    final (need, reward) = chestMilestones[i];
    if (state.activeness < need || state.claimedChests.contains(i)) return;
    state = state.copyWith(claimedChests: {...state.claimedChests, i});
    ref.read(sessionProvider.notifier).earn(reward);
  }

  /// Daily free roll, then 30 family coins per roll. Returns prize index or -1.
  int roll() {
    if (state.freeRollUsed) {
      if (state.familyCoins < 30) return -1;
      state = state.copyWith(familyCoins: state.familyCoins - 30);
    } else {
      state = state.copyWith(freeRollUsed: true);
    }
    final i = _rand.nextInt(100) < 3 ? 5 : _rand.nextInt(5);
    final (_, fc, c) = gachaPrizes[i];
    state = state.copyWith(familyCoins: state.familyCoins + fc);
    if (c > 0) ref.read(sessionProvider.notifier).earn(c);
    return i;
  }

  /// Buy or equip a family shop item. Returns a message.
  String shop(FamilyShopItem item) {
    if (!state.ownedItems.contains(item.id)) {
      if (state.familyCoins < item.price) return 'Not enough family coins';
      state = state.copyWith(familyCoins: state.familyCoins - item.price, ownedItems: {...state.ownedItems, item.id});
    }
    state = item.kind == 'title' ? state.copyWith(title: item.name) : state.copyWith(frame: item.name);
    return '${item.name} equipped';
  }

  /// Returns '' on success or an error.
  String upgrade() {
    if (!state.canManage) return 'Only the leader or deputy can upgrade';
    if (state.funds < state.upgradeCost) return 'Need ${state.upgradeCost} family funds';
    state = state.copyWith(funds: state.funds - state.upgradeCost, level: state.level + 1);
    return '';
  }

  void setRole(int userId, String role) => state = state.copyWith(memberRoles: {...state.memberRoles, userId: role});
  void removeMember(int userId) => state = state.copyWith(memberRoles: {...state.memberRoles}..remove(userId));

  void setMyRole(String role) => state = state.copyWith(role: role);
}

/// Weekly family ranking (demo families + mine).
List<(FamilyInfo, int)> familyRanking(FamilyState s, List<FamilyInfo> all) {
  final rows = [
    for (final f in all) (f, f.id == s.familyId ? s.activeness + f.level * 100 : f.level * 120 + f.members * 3),
  ]..sort((a, b) => b.$2.compareTo(a.$2));
  return rows;
}
