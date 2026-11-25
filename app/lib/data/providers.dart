import 'dart:async';
import 'dart:math';
import 'dart:ui' show Color;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'gift_providers.dart';
import 'room_levels.dart';
import 'social_providers.dart' show userById;
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

  void earn(int coins, {String note = 'Reward'}) {
    final me = state;
    if (me == null) return;
    state = me.copyWith(coins: me.coins + coins);
    ref.read(ledgerProvider.notifier).add(coins, note);
  }

  void updateProfile({String? name, String? gender, int? age}) {
    final me = state;
    if (me != null) state = me.copyWith(name: name, gender: gender, age: age);
  }

  void setVip(int level) {
    final me = state;
    if (me != null) state = me.copyWith(vipLevel: level);
  }

  void changeId(int id) {
    final me = state;
    if (me != null) state = me.copyWith(id: id);
  }

  void logout() {
    ref.read(activeRoomProvider.notifier).exit();
    state = null;
  }

  /// Returns false when the balance is too low. Every change is written to the wallet ledger.
  bool spend(int coins, {String note = 'Spent'}) {
    final me = state;
    if (me == null || me.coins < coins) return false;
    state = me.copyWith(coins: me.coins - coins);
    ref.read(ledgerProvider.notifier).add(-coins, note);
    return true;
  }
}

/// Coin transaction record. Laravel: GET /wallet/transactions.
class CoinTx {
  final int amount; // + income, - spent
  final String note;
  final String time;
  const CoinTx(this.amount, this.note, this.time);
}

final ledgerProvider = NotifierProvider<LedgerController, List<CoinTx>>(LedgerController.new);

class LedgerController extends Notifier<List<CoinTx>> {
  @override
  List<CoinTx> build() => const [
        CoinTx(5000, 'Recharge 5,000 coins', 'Mon 18:20'),
        CoinTx(-520, 'Gift: Crown', 'Mon 21:05'),
        CoinTx(100, 'Daily check-in', 'Sun 09:12'),
      ];

  void add(int amount, String note) {
    final n = DateTime.now();
    state = [CoinTx(amount, note, 'Today ${n.hour.toString().padLeft(2, '0')}:${n.minute.toString().padLeft(2, '0')}'), ...state];
  }
}

final roomsProvider = FutureProvider.family<List<Room>, String>(
  (ref, tab) => ref.read(repositoryProvider).rooms(tab: tab),
);

final giftsProvider = FutureProvider<List<Gift>>((ref) => ref.read(repositoryProvider).gifts());

// ---------------------------------------------------------------------------
// Live room state
// ---------------------------------------------------------------------------

/// A short effect shown on a seat (dice result, sticker…).
class SeatFx {
  final String kind; // dice, rps, coin, lottery, light, sticker
  final String label;
  final int serial;
  const SeatFx(this.kind, this.label, this.serial);
}

class RedPacket {
  final int id;
  final YoloUser from;
  final int total;
  final List<int> left; // remaining shares
  final Map<int, int> grabbed; // userId -> coins
  const RedPacket(this.id, this.from, this.total, this.left, this.grabbed);
  bool get empty => left.isEmpty;
}

/// Treasure boxes: minutes in the room needed to open each box (last two are VIP only).
const treasureMinutes = [1, 3, 5, 10, 20, 30];
const treasureVipOnly = {2, 5};
const treasureCoins = [10, 20, 40, 60, 100, 200];

class RoomState {
  final String name;
  final String announcement;
  final String password;
  final String tag;
  final String? coverPath;
  final int theme;
  final String mode; // normal, intimacy
  final bool applyMode; // users must request to join mic
  final List<Seat> seats;
  final List<RoomMessage> messages;
  final bool micOn;
  final bool speakerOn;
  final Set<int> admins;
  final Set<int> coOwners;
  final Set<int> banned;
  final Set<int> members; // room members (joined)
  final int memberBase; // members not in the demo list
  final int fans;
  final Map<int, int> contributions; // userId -> coins gifted today
  final int exp;
  final bool highQuality, banText, noImages, banRedPacket, manageEvent;
  final int fee; // membership fee in coins (0 = free)
  final int? groupId; // associated group chat
  final List<String> records;
  final int? track;
  final bool musicPlaying;
  final GiftEvent? lastGift;
  final Map<int, SeatFx> seatFx; // userId -> effect
  final List<RedPacket> redPackets;
  final String? entryBanner;
  final bool sentGift, sentMessage;
  final int watchSecs;
  final Set<int> claimedBoxes;
  final Set<int> onlineIds; // named users currently in the room
  final int listeners; // other listeners (no profile loaded)

  const RoomState({
    required this.name,
    required this.announcement,
    required this.password,
    required this.seats,
    required this.messages,
    this.tag = 'Chat',
    this.coverPath,
    this.theme = 0,
    this.mode = 'normal',
    this.applyMode = false,
    this.micOn = true,
    this.speakerOn = true,
    this.admins = const {},
    this.coOwners = const {},
    this.banned = const {},
    this.members = const {},
    this.memberBase = 0,
    this.fans = 0,
    this.contributions = const {},
    this.exp = 0,
    this.highQuality = false,
    this.banText = false,
    this.noImages = false,
    this.banRedPacket = false,
    this.manageEvent = false,
    this.fee = 0,
    this.groupId,
    this.records = const [],
    this.track,
    this.musicPlaying = false,
    this.lastGift,
    this.seatFx = const {},
    this.redPackets = const [],
    this.entryBanner,
    this.sentGift = false,
    this.sentMessage = false,
    this.watchSecs = 0,
    this.claimedBoxes = const {},
    this.onlineIds = const {},
    this.listeners = 0,
  });

  RoomState copyWith({
    String? name,
    String? announcement,
    String? password,
    String? tag,
    String? coverPath,
    int? theme,
    String? mode,
    bool? applyMode,
    List<Seat>? seats,
    List<RoomMessage>? messages,
    bool? micOn,
    bool? speakerOn,
    Set<int>? admins,
    Set<int>? coOwners,
    Set<int>? banned,
    Set<int>? members,
    int? fans,
    Map<int, int>? contributions,
    int? exp,
    bool? highQuality,
    bool? banText,
    bool? noImages,
    bool? banRedPacket,
    bool? manageEvent,
    int? fee,
    int? groupId,
    List<String>? records,
    int? track,
    bool? musicPlaying,
    GiftEvent? lastGift,
    Map<int, SeatFx>? seatFx,
    List<RedPacket>? redPackets,
    String? entryBanner,
    bool clearEntry = false,
    bool? sentGift,
    bool? sentMessage,
    int? watchSecs,
    Set<int>? claimedBoxes,
    Set<int>? onlineIds,
    int? listeners,
  }) =>
      RoomState(
        name: name ?? this.name,
        announcement: announcement ?? this.announcement,
        password: password ?? this.password,
        tag: tag ?? this.tag,
        coverPath: coverPath ?? this.coverPath,
        theme: theme ?? this.theme,
        mode: mode ?? this.mode,
        applyMode: applyMode ?? this.applyMode,
        seats: seats ?? this.seats,
        messages: messages ?? this.messages,
        micOn: micOn ?? this.micOn,
        speakerOn: speakerOn ?? this.speakerOn,
        admins: admins ?? this.admins,
        coOwners: coOwners ?? this.coOwners,
        banned: banned ?? this.banned,
        members: members ?? this.members,
        memberBase: memberBase,
        fans: fans ?? this.fans,
        contributions: contributions ?? this.contributions,
        exp: exp ?? this.exp,
        highQuality: highQuality ?? this.highQuality,
        banText: banText ?? this.banText,
        noImages: noImages ?? this.noImages,
        banRedPacket: banRedPacket ?? this.banRedPacket,
        manageEvent: manageEvent ?? this.manageEvent,
        fee: fee ?? this.fee,
        groupId: groupId ?? this.groupId,
        records: records ?? this.records,
        track: track ?? this.track,
        musicPlaying: musicPlaying ?? this.musicPlaying,
        lastGift: lastGift ?? this.lastGift,
        seatFx: seatFx ?? this.seatFx,
        redPackets: redPackets ?? this.redPackets,
        entryBanner: clearEntry ? null : (entryBanner ?? this.entryBanner),
        sentGift: sentGift ?? this.sentGift,
        sentMessage: sentMessage ?? this.sentMessage,
        watchSecs: watchSecs ?? this.watchSecs,
        claimedBoxes: claimedBoxes ?? this.claimedBoxes,
        onlineIds: onlineIds ?? this.onlineIds,
        listeners: listeners ?? this.listeners,
      );

  /// Everyone in the room right now (named users + other listeners).
  int get onlineCount => onlineIds.length + listeners;

  int get memberCount => memberBase + members.length;

  /// Treasure-box progress: watched time plus 60 s per completed task.
  int get treasureSecs => watchSecs + 60 * [sentGift, sentMessage].where((x) => x).length;

  static const themes = [
    [Color(0xFF3B1D78), Color(0xFF160C33)],
    [Color(0xFF0C4A6E), Color(0xFF0B1026)],
    [Color(0xFF831843), Color(0xFF1A0B1F)],
    [Color(0xFF14532D), Color(0xFF071A12)],
    [Color(0xFF78350F), Color(0xFF1C1206)],
    [Color(0xFF1E293B), Color(0xFF020617)],
    [Color(0xFF581C87), Color(0xFF0F0A1F)], // Club
    [Color(0xFF92400E), Color(0xFF2A1503)], // Golden Party
    [Color(0xFF155E75), Color(0xFF0B1220)], // Diamond Party
    [Color(0xFF1E1B4B), Color(0xFF030014)], // Starfield
    [Color(0xFF0E7490), Color(0xFF111827)], // Future City
  ];
  static const themeNames = ['Royal', 'Ocean', 'Rose', 'Forest', 'Sunset', 'Midnight', 'Club', 'Golden Party', 'Diamond Party', 'Starfield', 'Future City'];
  static const themeUnlock = [1, 1, 1, 1, 1, 1, 2, 3, 4, 6, 8]; // room level needed
  static const tracks = ['Midnight Drive', 'Golden Hour', 'Neon Dreams', 'Lo-fi Chill', 'Party Starter', 'Slow Love'];
  static const tags = ['Chat', 'Music', 'Games', 'Friends', 'Dating', 'Poetry', 'Family', 'Private'];
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

/// The room the user is currently in (kept alive while minimized). null = not in a room.
/// Entering another room replaces it, so there is never more than one live room session.
final activeRoomProvider = NotifierProvider<ActiveRoomController, Room?>(ActiveRoomController.new);

class ActiveRoomController extends Notifier<Room?> {
  @override
  Room? build() => null;

  /// The canonical Room instance for [r] (reuses the live one when the id matches).
  Room canonical(Room r) {
    final cur = state;
    return cur != null && cur.id == r.id ? cur : r;
  }

  void enter(Room r) {
    if (state?.id != r.id) state = r;
  }

  void exit() => state = null;
}

/// How many voice-room screens are on screen (the floating mini room hides while > 0).
final roomScreenOpenProvider = NotifierProvider<RoomScreenOpen, int>(RoomScreenOpen.new);

class RoomScreenOpen extends Notifier<int> {
  @override
  int build() => 0;
  void opened() => state++;
  void closed() {
    if (ref.mounted) state = state > 0 ? state - 1 : 0;
  }
}

/// Room logic. In demo mode it simulates other users; with the Laravel
/// backend these updates arrive over the `presence-room.{id}` channel.
class RoomController extends Notifier<RoomState> {
  RoomController(this.room);
  final Room room;
  final _rand = Random();
  int _serial = 0;

  @override
  RoomState build() {
    // Stay alive while this is the active room (also when minimized); dispose once the user exits
    // or enters another room.
    final link = ref.keepAlive();
    final active = ref.read(activeRoomProvider);
    if (active != null && active.id != room.id) link.close();
    ref.listen(activeRoomProvider, (_, next) {
      if (next?.id != room.id) link.close();
    });
    final speak = Timer.periodic(const Duration(milliseconds: 1400), (_) => _simulateSpeaking());
    final watch = Timer.periodic(const Duration(seconds: 1), (_) => _tickWatch());
    final presence = Timer.periodic(const Duration(seconds: 8), (_) => _simulatePresence());
    final entry = Timer(const Duration(seconds: 3), () => state = state.copyWith(clearEntry: true));
    ref.onDispose(() {
      speak.cancel();
      watch.cancel();
      presence.cancel();
      entry.cancel();
    });
    final others = [DemoUsers.zara, DemoUsers.kenji, DemoUsers.mia, null, DemoUsers.omar]
        .map((u) => u?.id == room.owner.id ? null : u)
        .toList();
    final me = _me;
    return RoomState(
      name: room.name,
      announcement: room.announcement,
      password: room.password,
      tag: room.tag,
      seats: [
        for (var i = 0; i < room.seatCount; i++)
          Seat(index: i, user: i < others.length ? others[i] : null, locked: i == 6, speaking: i == 0 && others[0] != null),
      ],
      admins: {DemoUsers.kenji.id, DemoUsers.omar.id},
      members: {DemoUsers.zara.id, DemoUsers.kenji.id, DemoUsers.mia.id, DemoUsers.omar.id, DemoUsers.leo.id, if (room.owner.id == me.id) me.id},
      memberBase: room.online * 12,
      fans: room.online * 19,
      exp: room.id == 884216 ? 475694 : (room.id % 97) * 4100,
      groupId: room.owner.id == me.id ? 1 : null,
      contributions: {DemoUsers.zara.id: 5200, DemoUsers.omar.id: 1999, DemoUsers.kenji.id: 520},
      entryBanner: '${me.name} entered the room',
      onlineIds: {room.owner.id, me.id, for (final u in others) if (u != null) u.id},
      listeners: max(0, room.online - 5),
      messages: [
        const RoomMessage(
            kind: MessageKind.system,
            text: 'Welcome to Yolo! Please be kind. Sexual content, hate, scams and illegal content are not allowed. '
                'Moderators review rooms 24/7 — report anything that breaks the Safety guidelines.'),
        if (room.isFamily) const RoomMessage(kind: MessageKind.system, text: 'This is your family voice room.'),
        RoomMessage(kind: MessageKind.chat, sender: 'Kenji', senderId: DemoUsers.kenji.id, text: 'Good evening everyone!', color: const Color(0xFF7DD3FC)),
        RoomMessage(kind: MessageKind.chat, sender: 'Mia', senderId: DemoUsers.mia.id, text: 'Who wants to play Ludo after this?', color: const Color(0xFF86EFAC)),
      ],
    );
  }

  YoloUser get _me => ref.read(sessionProvider) ?? DemoUsers.me;

  bool get isOwner => room.owner.id == _me.id;
  bool get isCoOwner => state.coOwners.contains(_me.id);
  bool get canManage => isOwner || isCoOwner || state.admins.contains(_me.id);
  int get mySeat => state.seats.indexWhere((s) => s.user?.id == _me.id);
  RoomLevel get level => levelForExp(state.exp);

  String roleOf(int userId) => userId == room.owner.id
      ? 'Owner'
      : (state.coOwners.contains(userId) ? 'Co-owner' : (state.admins.contains(userId) ? 'Admin' : (state.members.contains(userId) ? 'Member' : 'Guest')));

  String _time() {
    final n = DateTime.now();
    return '${n.hour.toString().padLeft(2, '0')}:${n.minute.toString().padLeft(2, '0')}';
  }

  void _record(String text) => state = state.copyWith(records: ['${_time()}  ${_me.name}: $text', ...state.records]);
  void _system(String text) => state = state.copyWith(messages: [...state.messages, RoomMessage(kind: MessageKind.system, text: text)]);

  void _simulateSpeaking() {
    final seats = [
      for (final s in state.seats)
        s.isEmpty
            ? s
            : s.copyWith(speaking: !s.muted && (s.user!.id == _me.id ? (state.micOn && _rand.nextBool()) : _rand.nextInt(3) == 0)),
    ];
    state = state.copyWith(seats: seats);
  }

  void _tickWatch() {
    final secs = state.watchSecs + 1;
    state = state.copyWith(watchSecs: secs);
    if (secs % 300 == 0) addExp(roomExpPerFiveMinutes * (_me.vipLevel > 0 ? 2 : 1));
  }

  /// Demo presence: listeners come and go; Leo drops in and out. With Laravel these are presence-channel events.
  void _simulatePresence() {
    final ids = {...state.onlineIds};
    String? banner;
    if (!ids.contains(DemoUsers.leo.id) && _rand.nextInt(3) == 0 && !state.banned.contains(DemoUsers.leo.id)) {
      ids.add(DemoUsers.leo.id);
      banner = 'Leo entered the room';
    } else if (ids.contains(DemoUsers.leo.id) && _rand.nextInt(4) == 0 && !state.seats.any((s) => s.user?.id == DemoUsers.leo.id)) {
      ids.remove(DemoUsers.leo.id);
    }
    final delta = _rand.nextInt(3) - 1; // -1, 0, +1
    state = state.copyWith(onlineIds: ids, listeners: max(0, state.listeners + delta), entryBanner: banner);
    if (banner != null) {
      Timer(const Duration(seconds: 3), () {
        if (ref.mounted && state.entryBanner == banner) state = state.copyWith(clearEntry: true);
      });
    }
  }

  /// Top gift senders in this room (highest first), with real profiles.
  List<(YoloUser, int)> topGifters([int n = 3]) {
    final me = _me;
    final rows = [
      for (final e in state.contributions.entries)
        if (e.value > 0) (e.key == me.id ? me : userById(e.key), e.value),
    ]..sort((a, b) => b.$2.compareTo(a.$2));
    return rows.take(n).toList();
  }

  void addExp(int exp) => state = state.copyWith(exp: state.exp + exp);

  void _setSeat(int index, Seat seat) {
    final seats = [...state.seats];
    seats[index] = seat;
    state = state.copyWith(seats: seats);
  }

  // --- Seats ---------------------------------------------------------------
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

  /// Takes the first free unlocked seat. Returns a message.
  String takeAnySeat() {
    final i = state.seats.indexWhere((s) => s.isEmpty && !s.locked);
    return i < 0 ? 'No free seat' : takeSeat(i);
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
    _record('${s.locked ? 'unlocked' : 'locked'} seat ${index + 1}');
  }

  void toggleMute(int index) {
    final s = state.seats[index];
    _setSeat(index, s.copyWith(muted: !s.muted, speaking: false));
    if (s.user != null) {
      _system('${s.user!.name} was ${s.muted ? 'unmuted' : 'muted'} by an admin');
      _record('${s.muted ? 'unmuted' : 'muted'} ${s.user!.name}');
    }
  }

  void kickFromSeat(int index) {
    final s = state.seats[index];
    if (s.user == null) return;
    _system('${s.user!.name} was removed from the mic');
    _record('removed ${s.user!.name} from the mic');
    _setSeat(index, s.copyWith(clearUser: true, speaking: false, muted: false));
  }

  /// Returns '' or an error (admin limit from room level).
  String toggleAdmin(YoloUser u) {
    final on = state.admins.contains(u.id);
    if (!on && state.admins.length >= level.admins) return 'Admin limit reached (${level.admins}) — level up the room';
    state = state.copyWith(admins: on ? ({...state.admins}..remove(u.id)) : {...state.admins, u.id});
    _system(on ? '${u.name} is no longer an admin' : '${u.name} is now an admin');
    _record(on ? 'removed admin ${u.name}' : 'made ${u.name} admin');
    return '';
  }

  /// Returns '' or an error (co-owner limit from room level).
  String toggleCoOwner(YoloUser u) {
    final on = state.coOwners.contains(u.id);
    if (!on && state.coOwners.length >= level.coOwners) return 'Co-owners: ${state.coOwners.length}/${level.coOwners} — unlocks at room level 5';
    state = state.copyWith(coOwners: on ? ({...state.coOwners}..remove(u.id)) : {...state.coOwners, u.id});
    _system(on ? '${u.name} is no longer a co-owner' : '${u.name} is now a co-owner');
    _record(on ? 'removed co-owner ${u.name}' : 'made ${u.name} co-owner');
    return '';
  }

  void removeMember(YoloUser u) {
    state = state.copyWith(
      members: {...state.members}..remove(u.id),
      admins: {...state.admins}..remove(u.id),
      coOwners: {...state.coOwners}..remove(u.id),
    );
    _record('removed member ${u.name}');
  }

  void ban(YoloUser u) {
    final i = state.seats.indexWhere((s) => s.user?.id == u.id);
    if (i >= 0) _setSeat(i, state.seats[i].copyWith(clearUser: true, speaking: false));
    state = state.copyWith(banned: {...state.banned, u.id}, onlineIds: {...state.onlineIds}..remove(u.id));
    _system('${u.name} was banned from the room');
    _record('banned ${u.name}');
  }

  void unban(int userId) {
    state = state.copyWith(banned: {...state.banned}..remove(userId));
    _record('unbanned user $userId');
  }

  void inviteToSeat(YoloUser u) => _system('Invitation sent to ${u.name}');

  // --- Membership ----------------------------------------------------------
  bool get isMember => state.members.contains(_me.id);

  /// Join the room as a member (pays the membership fee if set). Returns a message.
  String join() {
    if (isMember) return 'Already a member';
    if (state.memberCount >= level.maxMembers) return 'Room is full';
    if (state.fee > 0 && !ref.read(sessionProvider.notifier).spend(state.fee, note: 'Join room ${state.name}')) return 'Membership costs ${state.fee} coins';
    state = state.copyWith(members: {...state.members, _me.id}, fans: state.fans + 1);
    _system('${_me.name} joined the room as a member');
    return 'Welcome to ${state.name}!';
  }

  void leaveMembership() => state = state.copyWith(members: {...state.members}..remove(_me.id));

  // --- Settings ------------------------------------------------------------
  void updateSettings({
    String? name,
    String? announcement,
    String? password,
    String? tag,
    String? coverPath,
    int? theme,
    String? mode,
    bool? applyMode,
    bool? highQuality,
    bool? banText,
    bool? noImages,
    bool? banRedPacket,
    bool? manageEvent,
    int? fee,
    int? groupId,
  }) {
    final wasMode = state.mode;
    state = state.copyWith(
      name: name,
      announcement: announcement,
      password: password,
      tag: tag,
      coverPath: coverPath,
      theme: theme,
      mode: mode,
      applyMode: applyMode,
      highQuality: highQuality,
      banText: banText,
      noImages: noImages,
      banRedPacket: banRedPacket,
      manageEvent: manageEvent,
      fee: fee,
      groupId: groupId,
    );
    if (mode != null && mode != wasMode) _system(mode == 'intimacy' ? 'Owner enabled the Intimacy Seat' : 'Owner switched to normal seats');
    _record('updated room settings');
  }

  // --- Music ---------------------------------------------------------------
  void playTrack(int i) => state = state.copyWith(track: i, musicPlaying: true);
  void toggleMusic() => state = state.copyWith(musicPlaying: !state.musicPlaying);

  // --- Chat, interactions & gifts ------------------------------------------
  /// Returns false when text chat is banned for this user.
  bool sendChat(String text) {
    final t = text.trim();
    if (t.isEmpty) return true;
    if (state.banText && !canManage) return false;
    state = state.copyWith(
      sentMessage: true,
      messages: [...state.messages, RoomMessage(kind: MessageKind.chat, sender: _me.name, senderId: _me.id, text: t, color: const Color(0xFFF5C451))],
    );
    addExp(1);
    return true;
  }

  /// Interaction: dice, rock-paper-scissors, coin, lottery, light burst, or a sticker name.
  void interact(String kind, {String? sticker}) {
    final label = switch (kind) {
      'dice' => '${1 + _rand.nextInt(6)}',
      'rps' => ['Rock', 'Paper', 'Scissors'][_rand.nextInt(3)],
      'coin' => _rand.nextBool() ? 'Heads' : 'Tails',
      'lottery' => '${_rand.nextInt(10)}${_rand.nextInt(10)}${_rand.nextInt(10)}',
      'light' => 'Light burst',
      _ => sticker ?? 'Wave',
    };
    _serial++;
    state = state.copyWith(
      seatFx: {...state.seatFx, _me.id: SeatFx(kind, label, _serial)},
      messages: [
        ...state.messages,
        RoomMessage(
          kind: MessageKind.chat,
          sender: _me.name,
          senderId: _me.id,
          color: const Color(0xFFF5C451),
          text: switch (kind) {
            'dice' => 'rolled a dice: $label',
            'rps' => 'played rock-paper-scissors: $label',
            'coin' => 'tossed a coin: $label',
            'lottery' => 'drew a lottery number: $label',
            'light' => 'sent a light burst',
            _ => '[$label]',
          },
        ),
      ],
    );
  }

  /// Sends a gift in the room (coins or backpack) and plays the animation.
  SendResult sendGift(Gift gift, YoloUser to, int qty, {bool fromBackpack = false}) {
    final res = ref.read(giftCenterProvider.notifier).send(gift, to, qty, fromBackpack: fromBackpack);
    if (!res.ok) return res;
    _serial++;
    final total = gift.price * qty;
    state = state.copyWith(
      sentGift: true,
      lastGift: GiftEvent(gift, _me.name, to.name, qty, _serial),
      contributions: {...state.contributions, _me.id: (state.contributions[_me.id] ?? 0) + total},
      messages: [
        ...state.messages,
        RoomMessage(kind: MessageKind.gift, text: '${_me.name} sent ${gift.name} ×$qty to ${to.name}'),
        if (res.luckyWin > 0) RoomMessage(kind: MessageKind.gift, text: 'Lucky! ${_me.name} won ${res.luckyWin} coins'),
      ],
    );
    addExp((total / 10).ceil()); // 10 coins (diamonds) = 1 EXP
    return res;
  }

  // --- Red packets ---------------------------------------------------------
  /// Sends a red packet of [total] coins split into [count] shares. Returns '' or an error.
  String sendRedPacket(int total, int count) {
    if (state.banRedPacket) return 'Red packets are turned off in this room';
    if (count < 1 || total < count) return 'Each share needs at least 1 coin';
    if (!ref.read(sessionProvider.notifier).spend(total, note: 'Red packet in ${state.name}')) return 'Not enough coins';
    // Random split that adds up to total.
    final cuts = List.generate(count - 1, (_) => 1 + _rand.nextInt(total - 1))..sort();
    final shares = <int>[];
    var prev = 0;
    for (final c in [...cuts, total]) {
      shares.add(max(1, c - prev));
      prev = c;
    }
    final fix = total - shares.fold<int>(0, (a, b) => a + b);
    shares[0] += fix;
    _serial++;
    final p = RedPacket(_serial, _me, total, shares, const {});
    state = state.copyWith(
      redPackets: [...state.redPackets, p],
      messages: [...state.messages, RoomMessage(kind: MessageKind.gift, text: '${_me.name} sent a red packet of $total coins! Tap the envelope to grab.')],
    );
    addExp((total / 10).ceil());
    // Others grab some shares a moment later (demo).
    Timer(const Duration(seconds: 2), () {
      if (!ref.mounted) return;
      for (final u in [DemoUsers.zara, DemoUsers.kenji]) {
        _grab(p.id, u);
      }
    });
    return '';
  }

  int _grab(int id, YoloUser u) {
    final i = state.redPackets.indexWhere((p) => p.id == id);
    if (i < 0) return 0;
    final p = state.redPackets[i];
    if (p.empty || p.grabbed.containsKey(u.id)) return 0;
    final amount = p.left.first;
    final np = RedPacket(p.id, p.from, p.total, p.left.sublist(1), {...p.grabbed, u.id: amount});
    final list = [...state.redPackets]..[i] = np;
    state = state.copyWith(redPackets: list);
    return amount;
  }

  /// Grab a share for me. Returns coins won (0 = none left / already grabbed).
  int grabRedPacket(int id) {
    final amount = _grab(id, _me);
    if (amount > 0) {
      ref.read(sessionProvider.notifier).earn(amount, note: 'Red packet');
      _system('${_me.name} grabbed $amount coins from a red packet');
    }
    return amount;
  }

  // --- Treasure boxes ------------------------------------------------------
  /// Watched seconds + 60 s per completed task (join, gift, message).
  int get treasureProgress => state.treasureSecs + (isMember ? 60 : 0);

  /// Claim box [i]. Returns coins or an error message via negative codes: -1 not ready, -2 VIP only, -3 claimed.
  int claimBox(int i) {
    if (state.claimedBoxes.contains(i)) return -3;
    if (treasureVipOnly.contains(i) && _me.vipLevel == 0) return -2;
    if (treasureProgress < treasureMinutes[i] * 60) return -1;
    state = state.copyWith(claimedBoxes: {...state.claimedBoxes, i});
    ref.read(sessionProvider.notifier).earn(treasureCoins[i], note: 'Room treasure box');
    return treasureCoins[i];
  }
}

/// Rooms the user created in this session (shown first on Home).
final createdRoomsProvider = NotifierProvider<CreatedRooms, List<Room>>(CreatedRooms.new);

class CreatedRooms extends Notifier<List<Room>> {
  @override
  List<Room> build() => const [];
  void add(Room r) => state = [r, ...state];
}
