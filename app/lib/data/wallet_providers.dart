import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'providers.dart';

/// Wallet extras: recharge orders, diamonds, check-in, tasks, invites, gift cards, monthly pack.
/// Laravel: /wallet, /wallet/packages, /wallet/iap/verify, /wallet/exchange, /rewards/*.

class RechargePackage {
  final String id;
  final int coins;
  final int bonus;
  final String price; // shown price (from Google Play in production)
  final bool popular;
  const RechargePackage(this.id, this.coins, this.bonus, this.price, {this.popular = false});
}

const rechargePackages = [
  RechargePackage('c60', 600, 0, '\$0.99'),
  RechargePackage('c300', 3000, 150, '\$4.99'),
  RechargePackage('c980', 9800, 800, '\$14.99', popular: true),
  RechargePackage('c1980', 19800, 2200, '\$29.99'),
  RechargePackage('c3280', 32800, 4200, '\$49.99'),
  RechargePackage('c6480', 64800, 10000, '\$99.99'),
];

class RechargeOrder {
  final String orderId;
  final RechargePackage pack;
  final String time;
  final bool firstBonus;
  const RechargeOrder(this.orderId, this.pack, this.time, {this.firstBonus = false});
}

class DailyTask {
  final String name;
  final int progress, target, reward;
  const DailyTask(this.name, this.progress, this.target, this.reward);
  bool get done => progress >= target;
}

const dailyTasks = [
  DailyTask('Stay in a voice room for 10 minutes', 10, 10, 50),
  DailyTask('Send 3 messages in rooms', 3, 3, 30),
  DailyTask('Send a gift', 1, 1, 40),
  DailyTask('Follow 2 new people', 1, 2, 30),
  DailyTask('Post a moment', 0, 1, 60),
];

const checkInRewards = [50, 60, 80, 100, 120, 150, 300]; // day 1..7
const eventRewards = [('Ludo Party Night · Top 100', 500), ('Gift King Week · Participation', 200)];
const giftCards = {'YOLO100': 100, 'WELCOME500': 500, 'PARTY2026': 1000};
const monthlyPackPrice = '\$4.99';
const monthlyPackDaily = 300;
const diamondsPerCoin = 10; // 10 diamonds -> 1 coin

class WalletState {
  final List<RechargeOrder> orders;
  final int diamonds; // earned from received gifts
  final int checkInDays; // days checked in this week (0..7)
  final bool checkedInToday;
  final Set<int> claimedTasks;
  final Set<int> claimedEvents;
  final Set<String> redeemed;
  final int monthlyDaysLeft;
  final bool monthlyClaimedToday;
  final List<String> invited;

  const WalletState({
    this.orders = const [],
    this.diamonds = 12600,
    this.checkInDays = 2,
    this.checkedInToday = false,
    this.claimedTasks = const {},
    this.claimedEvents = const {},
    this.redeemed = const {},
    this.monthlyDaysLeft = 0,
    this.monthlyClaimedToday = false,
    this.invited = const ['Kenji', 'Leo'],
  });

  WalletState copyWith({
    List<RechargeOrder>? orders,
    int? diamonds,
    int? checkInDays,
    bool? checkedInToday,
    Set<int>? claimedTasks,
    Set<int>? claimedEvents,
    Set<String>? redeemed,
    int? monthlyDaysLeft,
    bool? monthlyClaimedToday,
  }) =>
      WalletState(
        orders: orders ?? this.orders,
        diamonds: diamonds ?? this.diamonds,
        checkInDays: checkInDays ?? this.checkInDays,
        checkedInToday: checkedInToday ?? this.checkedInToday,
        claimedTasks: claimedTasks ?? this.claimedTasks,
        claimedEvents: claimedEvents ?? this.claimedEvents,
        redeemed: redeemed ?? this.redeemed,
        monthlyDaysLeft: monthlyDaysLeft ?? this.monthlyDaysLeft,
        monthlyClaimedToday: monthlyClaimedToday ?? this.monthlyClaimedToday,
        invited: invited,
      );

  bool get firstRecharge => orders.isEmpty;
}

final walletProvider = NotifierProvider<WalletController, WalletState>(WalletController.new);

class WalletController extends Notifier<WalletState> {
  @override
  WalletState build() => const WalletState();

  SessionController get _session => ref.read(sessionProvider.notifier);

  String _now() {
    final n = DateTime.now();
    return '${n.day}/${n.month} ${n.hour.toString().padLeft(2, '0')}:${n.minute.toString().padLeft(2, '0')}';
  }

  /// Demo purchase. In production: Google Play Billing → Laravel verifies the receipt → coins added.
  RechargeOrder recharge(RechargePackage p) {
    final first = state.firstRecharge;
    final total = p.coins + p.bonus + (first ? p.coins : 0); // first recharge: double coins
    _session.earn(total, note: 'Recharge ${p.price}${first ? ' (first-recharge double)' : ''}');
    final order = RechargeOrder('YO${DateTime.now().millisecondsSinceEpoch % 100000000}', p, _now(), firstBonus: first);
    state = state.copyWith(orders: [order, ...state.orders]);
    return order;
  }

  /// Exchange diamonds to coins. Returns coins received (0 if not enough).
  int exchange(int diamonds) {
    if (diamonds <= 0 || diamonds > state.diamonds) return 0;
    final coins = diamonds ~/ diamondsPerCoin;
    state = state.copyWith(diamonds: state.diamonds - coins * diamondsPerCoin);
    _session.earn(coins, note: 'Exchanged ${coins * diamondsPerCoin} diamonds');
    return coins;
  }

  int checkIn() {
    if (state.checkedInToday || state.checkInDays >= 7) return 0;
    final reward = checkInRewards[state.checkInDays];
    state = state.copyWith(checkedInToday: true, checkInDays: state.checkInDays + 1);
    _session.earn(reward, note: 'Daily check-in day ${state.checkInDays}');
    return reward;
  }

  void claimTask(int i) {
    final t = dailyTasks[i];
    if (!t.done || state.claimedTasks.contains(i)) return;
    state = state.copyWith(claimedTasks: {...state.claimedTasks, i});
    _session.earn(t.reward, note: 'Task: ${t.name}');
  }

  void claimEvent(int i) {
    if (state.claimedEvents.contains(i)) return;
    state = state.copyWith(claimedEvents: {...state.claimedEvents, i});
    _session.earn(eventRewards[i].$2, note: 'Event: ${eventRewards[i].$1}');
  }

  /// Returns a message.
  String redeem(String code) {
    final c = code.trim().toUpperCase();
    if (state.redeemed.contains(c)) return 'This code was already used';
    final coins = giftCards[c];
    if (coins == null) return 'Invalid gift card code';
    state = state.copyWith(redeemed: {...state.redeemed, c});
    _session.earn(coins, note: 'Gift card $c');
    return 'Redeemed $coins coins!';
  }

  /// Buys the monthly pack (demo purchase) — 30 days of daily coins.
  void buyMonthly() {
    state = state.copyWith(monthlyDaysLeft: 30, monthlyClaimedToday: false);
    final order = RechargeOrder('YO${DateTime.now().millisecondsSinceEpoch % 100000000}', const RechargePackage('monthly', 0, 0, monthlyPackPrice), _now());
    state = state.copyWith(orders: [order, ...state.orders]);
  }

  bool claimMonthly() {
    if (state.monthlyDaysLeft <= 0 || state.monthlyClaimedToday) return false;
    state = state.copyWith(monthlyClaimedToday: true, monthlyDaysLeft: state.monthlyDaysLeft - 1);
    _session.earn(monthlyPackDaily, note: 'Monthly pack daily coins');
    return true;
  }
}

String inviteCodeFor(int userId) => 'YOLO${userId.toRadixString(36).toUpperCase()}';
