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

  void earn(int coins) {
    final me = state;
    if (me != null) state = me.copyWith(coins: me.coins + coins);
  }

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
  final String name;
  final String announcement;
  final String password;
  final int theme;
  final bool applyMode; // true = users must request to join mic
  final List<Seat> seats;
  final List<RoomMessage> messages;
  final bool micOn;
  final bool speakerOn;
  final Set<int> admins;
  final Set<int> banned;
  final Map<int, int> contributions; // userId -> coins gifted in this room
  final int? track; // playing music track index
  final bool musicPlaying;
  final GiftEvent? lastGift;

  const RoomState({
    required this.name,
    required this.announcement,
    required this.password,
    required this.seats,
    required this.messages,
    this.theme = 0,
    this.applyMode = false,
    this.micOn = true,
    this.speakerOn = true,
    this.admins = const {},
    this.banned = const {},
    this.contributions = const {},
    this.track,
    this.musicPlaying = false,
    this.lastGift,
  });

  RoomState copyWith({
    String? name,
    String? announcement,
    String? password,
    int? theme,
    bool? applyMode,
    List<Seat>? seats,
    List<RoomMessage>? messages,
    bool? micOn,
    bool? speakerOn,
    Set<int>? admins,
    Set<int>? banned,
    Map<int, int>? contributions,
    int? track,
    bool? musicPlaying,
    GiftEvent? lastGift,
  }) =>
      RoomState(
        name: name ?? this.name,
        announcement: announcement ?? this.announcement,
        password: password ?? this.password,
        theme: theme ?? this.theme,
        applyMode: applyMode ?? this.applyMode,
        seats: seats ?? this.seats,
        messages: messages ?? this.messages,
        micOn: micOn ?? this.micOn,
        speakerOn: speakerOn ?? this.speakerOn,
        admins: admins ?? this.admins,
        banned: banned ?? this.banned,
        contributions: contributions ?? this.contributions,
        track: track ?? this.track,
        musicPlaying: musicPlaying ?? this.musicPlaying,
        lastGift: lastGift ?? this.lastGift,
      );

  static const themes = [
    [Color(0xFF3B1D78), Color(0xFF160C33)],
    [Color(0xFF0C4A6E), Color(0xFF0B1026)],
    [Color(0xFF831843), Color(0xFF1A0B1F)],
    [Color(0xFF14532D), Color(0xFF071A12)],
    [Color(0xFF78350F), Color(0xFF1C1206)],
    [Color(0xFF1E293B), Color(0xFF020617)],
  ];
  static const themeNames = ['Royal', 'Ocean', 'Rose', 'Forest', 'Sunset', 'Midnight'];
  static const tracks = ['Midnight Drive', 'Golden Hour', 'Neon Dreams', 'Lo-fi Chill', 'Party Starter', 'Slow Love'];
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
    final others = [DemoUsers.zara, DemoUsers.kenji, DemoUsers.mia, null, DemoUsers.omar]
        .map((u) => u?.id == room.owner.id ? null : u)
        .toList();
    return RoomState(
      name: room.name,
      announcement: room.announcement,
      password: room.password,
      seats: [
        for (var i = 0; i < room.seatCount; i++)
          Seat(index: i, user: i < others.length ? others[i] : null, locked: i == 6, speaking: i == 0 && others[0] != null),
      ],
      admins: {DemoUsers.kenji.id},
      contributions: {DemoUsers.zara.id: 5200, DemoUsers.omar.id: 1999, DemoUsers.kenji.id: 520},
      messages: [
        const RoomMessage(kind: MessageKind.system, text: 'Welcome to the room! Please be kind and respectful.'),
        if (room.isFamily) const RoomMessage(kind: MessageKind.system, text: 'This is your family voice room.'),
        const RoomMessage(kind: MessageKind.chat, sender: 'Kenji', text: 'Good evening everyone!', color: Color(0xFF7DD3FC)),
        const RoomMessage(kind: MessageKind.chat, sender: 'Mia', text: 'Who wants to play Ludo after this?', color: Color(0xFF86EFAC)),
      ],
    );
  }

  YoloUser get _me => ref.read(sessionProvider) ?? DemoUsers.me;

  bool get isOwner => room.owner.id == _me.id;
  bool get canManage => isOwner || state.admins.contains(_me.id);
  int get mySeat => state.seats.indexWhere((s) => s.user?.id == _me.id);

  void _system(String text) => state = state.copyWith(messages: [...state.messages, RoomMessage(kind: MessageKind.system, text: text)]);

  void _simulateSpeaking() {
    final seats = [
      for (final s in state.seats)
        s.isEmpty
            ? s
            : s.copyWith(
                speaking: !s.muted && (s.user!.id == _me.id ? (state.micOn && _rand.nextBool()) : _rand.nextInt(3) == 0),
              ),
    ];
    state = state.copyWith(seats: seats);
  }

  void _setSeat(int index, Seat seat) {
    final seats = [...state.seats];
    seats[index] = seat;
    state = state.copyWith(seats: seats);
  }

  /// Returns a message for the UI ('' = success).
  String takeSeat(int index) {
    final seat = state.seats[index];
    if (!seat.isEmpty) return 'Seat taken';
    if (seat.locked && !canManage) return 'This seat is locked';
    if (state.applyMode && !canManage) return 'Request sent to the host';
    final seats = [...state.seats];
    final current = mySeat;
    if (current >= 0) seats[current] = seats[current].copyWith(clearUser: true, speaking: false);
    seats[index] = seat.copyWith(user: _me, locked: false);
    state = state.copyWith(seats: seats);
    return '';
  }

  void leaveSeat() {
    final current = mySeat;
    if (current >= 0) _setSeat(current, state.seats[current].copyWith(clearUser: true, speaking: false, muted: false));
  }

  void toggleMic() => state = state.copyWith(micOn: !state.micOn);
  void toggleSpeaker() => state = state.copyWith(speakerOn: !state.speakerOn);

  // --- Admin actions -------------------------------------------------------
  void toggleLock(int index) {
    final s = state.seats[index];
    _setSeat(index, s.copyWith(locked: !s.locked));
  }

  void toggleMute(int index) {
    final s = state.seats[index];
    _setSeat(index, s.copyWith(muted: !s.muted, speaking: false));
    if (s.user != null) _system('${s.user!.name} was ${s.muted ? 'unmuted' : 'muted'} by an admin');
  }

  void kickFromSeat(int index) {
    final s = state.seats[index];
    if (s.user == null) return;
    _system('${s.user!.name} was removed from the mic');
    _setSeat(index, s.copyWith(clearUser: true, speaking: false, muted: false));
  }

  void toggleAdmin(YoloUser u) {
    final on = state.admins.contains(u.id);
    state = state.copyWith(admins: on ? ({...state.admins}..remove(u.id)) : {...state.admins, u.id});
    _system(on ? '${u.name} is no longer an admin' : '${u.name} is now an admin');
  }

  void ban(YoloUser u) {
    final i = state.seats.indexWhere((s) => s.user?.id == u.id);
    if (i >= 0) _setSeat(i, state.seats[i].copyWith(clearUser: true, speaking: false));
    state = state.copyWith(banned: {...state.banned, u.id});
    _system('${u.name} was banned from the room');
  }

  void inviteToSeat(YoloUser u) => _system('Invitation sent to ${u.name}');

  // --- Settings ------------------------------------------------------------
  void updateSettings({String? name, String? announcement, String? password, int? theme, bool? applyMode}) {
    state = state.copyWith(name: name, announcement: announcement, password: password, theme: theme, applyMode: applyMode);
    _system('Room settings updated');
  }

  // --- Music ---------------------------------------------------------------
  void playTrack(int i) => state = state.copyWith(track: i, musicPlaying: true);
  void toggleMusic() => state = state.copyWith(musicPlaying: !state.musicPlaying);

  // --- Chat & gifts --------------------------------------------------------
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
    final total = gift.price * qty;
    state = state.copyWith(
      lastGift: GiftEvent(gift, _me.name, to.name, qty, _giftSerial),
      contributions: {...state.contributions, _me.id: (state.contributions[_me.id] ?? 0) + total},
      messages: [
        ...state.messages,
        RoomMessage(kind: MessageKind.gift, text: '${_me.name} sent ${gift.name} ×$qty to ${to.name}'),
      ],
    );
    return true;
  }
}

/// Rooms the user created in this session (shown first on Home).
final createdRoomsProvider = NotifierProvider<CreatedRooms, List<Room>>(CreatedRooms.new);

class CreatedRooms extends Notifier<List<Room>> {
  @override
  List<Room> build() => const [];
  void add(Room r) => state = [r, ...state];
}
