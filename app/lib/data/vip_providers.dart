import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import 'providers.dart';

/// VIP tiers. Laravel: GET /vip/tiers, POST /vip/purchase, PUT /vip/subscription.
class VipTier {
  final int level;
  final String name;
  final int monthlyCoins; // price per 30 days
  final int dailyCoins; // free coins per day while active
  final List<Color> colors;
  final IconData icon;
  const VipTier(this.level, this.name, this.monthlyCoins, this.dailyCoins, this.colors, this.icon);
}

const vipTiers = [
  VipTier(1, 'Knight', 3000, 50, [Color(0xFF64748B), Color(0xFF94A3B8)], Icons.shield_rounded),
  VipTier(2, 'Baron', 8000, 120, [Color(0xFF0E7490), Color(0xFF22D3EE)], Icons.verified_rounded),
  VipTier(3, 'Viscount', 20000, 300, [Color(0xFF15803D), Color(0xFF4ADE80)], Icons.military_tech_rounded),
  VipTier(4, 'Earl', 50000, 700, [Color(0xFF6D28D9), Color(0xFFA78BFA)], Icons.stars_rounded),
  VipTier(5, 'Marquis', 100000, 1500, [Color(0xFFB45309), Color(0xFFF5C451)], Icons.workspace_premium_rounded),
  VipTier(6, 'Duke', 300000, 4500, [Color(0xFFBE123C), Color(0xFFFB7185)], Icons.diamond_rounded),
  VipTier(7, 'King', 800000, 12000, [Color(0xFF111827), Color(0xFFFFD97A)], Icons.emoji_events_rounded),
];

/// (privilege, icon, minimum VIP level)
const vipPrivileges = [
  ('VIP badge', Icons.verified_rounded, 1),
  ('Daily free coins', Icons.toll_rounded, 1),
  ('Colored nickname', Icons.format_color_text_rounded, 2),
  ('VIP chat bubble', Icons.chat_bubble_rounded, 2),
  ('Exclusive avatar frame', Icons.account_circle_rounded, 3),
  ('VIP gifts', Icons.card_giftcard_rounded, 1),
  ('Entry effect', Icons.auto_awesome_rounded, 4),
  ('VIP ring', Icons.radio_button_checked_rounded, 4),
  ('Hide visitors', Icons.visibility_off_rounded, 5),
  ('Anti-kick in rooms', Icons.gpp_good_rounded, 5),
  ('Top of member list', Icons.vertical_align_top_rounded, 6),
  ('Mystery visitor mode', Icons.theater_comedy_rounded, 7),
];

VipTier tierOf(int level) => vipTiers[(level.clamp(1, 7)) - 1];

class VipPurchase {
  final String what;
  final int coins;
  final String time;
  const VipPurchase(this.what, this.coins, this.time);
}

class VipState {
  final int daysLeft; // 0 = not active
  final bool autoRenew;
  final bool dailyClaimed;
  final bool ringEquipped;
  final List<VipPurchase> history;
  const VipState({this.daysLeft = 18, this.autoRenew = true, this.dailyClaimed = false, this.ringEquipped = false, this.history = const [VipPurchase('VIP 5 Marquis · 30 days', 100000, '8/11')]});

  VipState copyWith({int? daysLeft, bool? autoRenew, bool? dailyClaimed, bool? ringEquipped, List<VipPurchase>? history}) => VipState(
        daysLeft: daysLeft ?? this.daysLeft,
        autoRenew: autoRenew ?? this.autoRenew,
        dailyClaimed: dailyClaimed ?? this.dailyClaimed,
        ringEquipped: ringEquipped ?? this.ringEquipped,
        history: history ?? this.history,
      );
}

final vipProvider = NotifierProvider<VipController, VipState>(VipController.new);

class VipController extends Notifier<VipState> {
  @override
  VipState build() => const VipState();

  int get _level => ref.read(sessionProvider)?.vipLevel ?? 0;

  String _now() {
    final n = DateTime.now();
    return '${n.day}/${n.month}';
  }

  /// Buy / renew / upgrade. Upgrading credits unused days of the current tier. Returns a message.
  String purchase(int level) {
    final tier = tierOf(level);
    final current = _level;
    var price = tier.monthlyCoins;
    if (current > 0 && level > current && state.daysLeft > 0) {
      price -= (tierOf(current).monthlyCoins * state.daysLeft / 30).round(); // credit for unused days
    }
    if (current > level && state.daysLeft > 0) return 'You already have a higher VIP level';
    if (!ref.read(sessionProvider.notifier).spend(price, note: 'VIP $level ${tier.name}')) return 'Not enough coins';
    final renew = current == level && state.daysLeft > 0;
    ref.read(sessionProvider.notifier).setVip(level);
    state = state.copyWith(
      daysLeft: renew ? state.daysLeft + 30 : 30,
      history: [VipPurchase('VIP $level ${tier.name} · ${renew ? 'renew' : (current > 0 && level > current ? 'upgrade' : '30 days')}', price, _now()), ...state.history],
    );
    return renew ? 'VIP renewed for 30 more days' : 'Welcome, VIP $level ${tier.name}!';
  }

  int claimDaily() {
    if (state.dailyClaimed || state.daysLeft <= 0 || _level == 0) return 0;
    final coins = tierOf(_level).dailyCoins;
    state = state.copyWith(dailyClaimed: true);
    ref.read(sessionProvider.notifier).earn(coins, note: 'VIP daily coins');
    return coins;
  }

  void setAutoRenew(bool v) => state = state.copyWith(autoRenew: v);

  /// Cancel = stop auto-renew; VIP stays active until it expires.
  void cancel() => state = state.copyWith(autoRenew: false);

  String toggleRing() {
    if (_level < 4) return 'VIP rings unlock at VIP 4';
    state = state.copyWith(ringEquipped: !state.ringEquipped);
    return state.ringEquipped ? 'VIP ring equipped' : 'VIP ring removed';
  }
}
