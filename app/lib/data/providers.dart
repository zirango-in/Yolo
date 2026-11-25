import 'dart:async';
import 'dart:math';
import 'dart:ui' show Color;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'models.dart';
import 'repository.dart';

final repositoryProvider = Provider<YoloRepository>((ref) => createRepository());

/// Logged-in user (null = logged out).
final sessionProvider = NotifierProvider<SessionController, YoloUser?>(SessionController.new);

class SessionController extends Notifier<YoloUser?> {
  @override
  YoloUser? build() => null;

  Future<void> login(String method) async {
    state = await ref.read(repositoryProvider).login(method: method);
  }

  void loginAs(YoloUser user) => state = user;

  void updateProfile({String? name, String? gender, int? age}) {
    final me = state;
    if (me != null) state = me.copyWith(name: name, gender: gender, age: age);
  }

  void changeId(int id) {
    final me = state;
    if (me != null) state = me.copyWith(id: id);
  }

  void logout() => state = null;

  /// Returns false when the balance is too low.
  bool spend(int coins) {
    final me = state;
    if (me == null || me.coins < coins) return false;
    state = me.copyWith(coins: me.coins - coins);
    return true;
  }
}

final roomsProvider = FutureProvider.family<List<Room>, String>(
  (ref, tab) => ref.read(repositoryProvider).rooms(tab: tab),
);

final giftsProvider = FutureProvider<List<Gift>>((ref) => ref.read(repositoryProvider).gifts());

// ---------------------------------------------------------------------------
// Live room state
// ---------------------------------------------------------------------------

class RoomState {
  final List<Seat> seats;
  final List<RoomMessage> messages;
  final bool micOn;
  final GiftEvent? lastGift;

  const RoomState({required this.seats, required this.messages, this.micOn = true, this.lastGift});

  RoomState copyWith({List<Seat>? seats, List<RoomMessage>? messages, bool? micOn, GiftEvent? lastGift}) =>
      RoomState(
        seats: seats ?? this.seats,
        messages: messages ?? this.messages,
        micOn: micOn ?? this.micOn,
        lastGift: lastGift ?? this.lastGift,
      );
}

class GiftEvent {
  final Gift gift;
  final String from;
  final String to;
  final int qty;
  final int serial; // changes every send so the animation replays
  const GiftEvent(this.gift, this.from, this.to, this.qty, this.serial);
}

final roomProvider =
    NotifierProvider.autoDispose.family<RoomController, RoomState, Room>(RoomController.new);

/// Room logic. In demo mode it simulates other users; with the Laravel
/// backend these updates arrive over the `presence-room.{id}` channel.
class RoomController extends Notifier<RoomState> {
  RoomController(this.room);
  final Room room;
  final _rand = Random();
  int _giftSerial = 0;

  @override
  RoomState build() {
    final timer = Timer.periodic(const Duration(milliseconds: 1400), (_) => _simulateSpeaking());
    ref.onDispose(timer.cancel);
    return RoomState(
      seats: [
        Seat(index: 0, user: DemoUsers.zara, speaking: true),
        const Seat(index: 1, user: DemoUsers.kenji),
        const Seat(index: 2, user: DemoUsers.mia),
        const Seat(index: 3),
        const Seat(index: 4, user: DemoUsers.omar),
        const Seat(index: 5),
        const Seat(index: 6, locked: true),
        const Seat(index: 7),
      ],
      messages: const [
        RoomMessage(kind: MessageKind.system, text: 'Welcome to the room! Please be kind and respectful.'),
        RoomMessage(kind: MessageKind.chat, sender: 'Kenji', text: 'Good evening everyone!', color: Color(0xFF7DD3FC)),
        RoomMessage(kind: MessageKind.chat, sender: 'Mia', text: 'Who wants to play Ludo after this?', color: Color(0xFF86EFAC)),
        RoomMessage(kind: MessageKind.chat, sender: 'Omar', text: 'Count me in', color: Color(0xFFC4B5FD)),
      ],
    );
  }

  YoloUser get _me => ref.read(sessionProvider) ?? DemoUsers.me;

  int get mySeat => state.seats.indexWhere((s) => s.user?.id == _me.id);

  void _simulateSpeaking() {
    final seats = [
      for (final s in state.seats)
        s.isEmpty
            ? s
            : s.copyWith(
                speaking: s.user!.id == _me.id ? (state.micOn && _rand.nextBool()) : _rand.nextInt(3) == 0,
              ),
    ];
    state = state.copyWith(seats: seats);
  }

  void takeSeat(int index) {
    final seat = state.seats[index];
    if (!seat.isEmpty || seat.locked) return;
    final seats = [...state.seats];
    final current = mySeat;
    if (current >= 0) seats[current] = seats[current].copyWith(clearUser: true, speaking: false);
    seats[index] = seat.copyWith(user: _me);
    state = state.copyWith(seats: seats);
  }

  void leaveSeat() {
    final current = mySeat;
    if (current < 0) return;
    final seats = [...state.seats];
    seats[current] = seats[current].copyWith(clearUser: true, speaking: false);
    state = state.copyWith(seats: seats);
  }

  void toggleMic() => state = state.copyWith(micOn: !state.micOn);

  void sendChat(String text) {
    final t = text.trim();
    if (t.isEmpty) return;
    state = state.copyWith(messages: [
      ...state.messages,
      RoomMessage(kind: MessageKind.chat, sender: _me.name, text: t, color: const Color(0xFFF5C451)),
    ]);
  }

  /// Returns false when coins are not enough.
  bool sendGift(Gift gift, YoloUser to, int qty) {
    if (!ref.read(sessionProvider.notifier).spend(gift.price * qty)) return false;
    _giftSerial++;
    state = state.copyWith(
      lastGift: GiftEvent(gift, _me.name, to.name, qty, _giftSerial),
      messages: [
        ...state.messages,
        RoomMessage(kind: MessageKind.gift, text: '${_me.name} sent ${gift.name} ×$qty to ${to.name}'),
      ],
    );
    return true;
  }
}
