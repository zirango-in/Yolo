import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'models.dart';
import 'providers.dart';
import 'repository.dart';

/// One gift transaction (sent or received). Laravel: GET /me/gift-history.
class GiftRecord {
  final Gift gift;
  final YoloUser from;
  final YoloUser to;
  final int qty;
  final String time;
  const GiftRecord(this.gift, this.from, this.to, this.qty, this.time);
  int get total => gift.price * qty;
}

class GiftCenterState {
  final List<GiftRecord> records;
  final Map<int, int> backpack; // giftId -> count (free gifts from rewards / purchases)
  const GiftCenterState({this.records = const [], this.backpack = const {}});
}

class SendResult {
  final bool ok;
  final String message;
  final int luckyWin; // coins won back from a lucky gift
  const SendResult(this.ok, this.message, {this.luckyWin = 0});
}

Gift giftById(int id) => demoGiftCatalog.firstWhere((g) => g.id == id);

final giftCenterProvider = NotifierProvider<GiftCenter, GiftCenterState>(GiftCenter.new);

class GiftCenter extends Notifier<GiftCenterState> {
  final _rand = Random();

  @override
  GiftCenterState build() => GiftCenterState(
        backpack: const {1: 10, 2: 3, 11: 2},
        records: [
          GiftRecord(giftById(3), DemoUsers.zara, DemoUsers.me, 1, 'Today 20:14'),
          GiftRecord(giftById(1), DemoUsers.kenji, DemoUsers.me, 99, 'Today 19:02'),
          GiftRecord(giftById(4), DemoUsers.omar, DemoUsers.me, 1, 'Yesterday'),
          GiftRecord(giftById(2), DemoUsers.me, DemoUsers.mia, 10, 'Yesterday'),
        ],
      );

  String _now() {
    final n = DateTime.now();
    return 'Today ${n.hour.toString().padLeft(2, '0')}:${n.minute.toString().padLeft(2, '0')}';
  }

  /// Sends a gift (paid with coins, or free from the backpack).
  SendResult send(Gift gift, YoloUser to, int qty, {bool fromBackpack = false}) {
    final me = ref.read(sessionProvider);
    if (me == null) return const SendResult(false, 'Please log in');
    if (gift.vipLevel > me.vipLevel) return SendResult(false, 'Needs VIP ${gift.vipLevel}');
    if (fromBackpack) {
      final have = state.backpack[gift.id] ?? 0;
      if (have < qty) return const SendResult(false, 'Not enough in your backpack');
      final bp = {...state.backpack, gift.id: have - qty}..removeWhere((_, v) => v <= 0);
      state = GiftCenterState(records: state.records, backpack: bp);
    } else if (!ref.read(sessionProvider.notifier).spend(gift.price * qty)) {
      return const SendResult(false, 'Not enough coins. Recharge to send this gift.');
    }
    var win = 0;
    if (gift.category == 'lucky' && _rand.nextInt(100) < 30) {
      win = gift.price * qty * [2, 5, 10][_rand.nextInt(3)];
      ref.read(sessionProvider.notifier).earn(win);
    }
    state = GiftCenterState(records: [GiftRecord(gift, me, to, qty, _now()), ...state.records], backpack: state.backpack);
    return SendResult(true, win > 0 ? 'Lucky! You won $win coins back' : 'Sent ${gift.name} ×$qty to ${to.name}', luckyWin: win);
  }

  /// Buy gifts into the backpack to send later.
  bool buyToBackpack(Gift gift, int qty) {
    if (!ref.read(sessionProvider.notifier).spend(gift.price * qty)) return false;
    state = GiftCenterState(records: state.records, backpack: {...state.backpack, gift.id: (state.backpack[gift.id] ?? 0) + qty});
    return true;
  }
}

/// Gift ranking rows: (user, total coins). [senders] = who sent most; otherwise who received most.
List<(YoloUser, int)> giftRanking(List<GiftRecord> records, {required bool senders}) {
  final base = <int, (YoloUser, int)>{
    DemoUsers.zara.id: (DemoUsers.zara, senders ? 86000 : 42000),
    DemoUsers.omar.id: (DemoUsers.omar, senders ? 51000 : 18000),
    DemoUsers.kenji.id: (DemoUsers.kenji, senders ? 23000 : 64000),
    DemoUsers.mia.id: (DemoUsers.mia, senders ? 9000 : 77000),
    DemoUsers.leo.id: (DemoUsers.leo, senders ? 4000 : 12000),
  };
  for (final r in records) {
    final u = senders ? r.from : r.to;
    final cur = base[u.id];
    base[u.id] = (u, (cur?.$2 ?? 0) + r.total);
  }
  return base.values.toList()..sort((a, b) => b.$2.compareTo(a.$2));
}
