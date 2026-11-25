import 'dart:async';
import 'dart:math';
import 'dart:ui' show Color;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'gift_providers.dart';
import 'room_levels.dart';
import 'room_look.dart';
import 'settings_providers.dart';
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
  final bool sentGift, sentMessage;
  final int watchSecs;
  final Set<int> claimedBoxes;
  final Set<int> onlineIds; // named users currently in the room
  final int listeners; // other listeners (no profile loaded)
  final String? bgPath; // custom background photo (room-wide)
  final int? bgAccent; // main colour of that photo (ARGB), drives the room colours
  final double bgAlignY; // crop position of the photo, -1 top … 1 bottom
  final String roomMode; // normal, acquaint, auction, video, game
  final String? auctionItem; // what is being auctioned (auction room)
  final Map<int, int> auctionBids; // userId -> total coins bid
  final String? videoUrl; // video being watched together (video room)
  final String videoTitle;
  final bool videoPlaying;
  final String? roomGame; // game the room is playing together (game room)
  final DateTime? promotedUntil; // recommendation card active until
  final int promoUsed; // recommendation cards used today
  final DateTime? lastRallyAt; // last "rally fans" call
  final List<PresenceEvent> presence; // enter / leave events, newest last

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
    this.sentGift = false,
    this.sentMessage = false,
    this.watchSecs = 0,
    this.claimedBoxes = const {},
    this.onlineIds = const {},
    this.bgPath,
    this.bgAccent,
    this.bgAlignY = 0,
    this.roomMode = 'normal',
    this.auctionItem,
    this.auctionBids = const {},
    this.videoUrl,
    this.videoTitle = '',
    this.videoPlaying = false,
    this.roomGame,
    this.promotedUntil,
    this.promoUsed = 0,
    this.lastRallyAt,
    this.presence = const [],
    this.listeners = 0,
  });

  RoomState copyWith({
    String? name,
    String? announcement,
    String? password,
    String? tag,
    String? coverPath,
    int? theme,
    String? bgPath,
    int? bgAccent,
    double? bgAlignY,
    bool clearBg = false,
    String? roomMode,
    String? auctionItem,
    Map<int, int>? auctionBids,
    bool clearAuction = false,
    String? videoUrl,
    String? videoTitle,
    bool? videoPlaying,
    bool clearVideo = false,
    String? roomGame,
    bool clearGame = false,
    DateTime? promotedUntil,
    int? promoUsed,
    DateTime? lastRallyAt,
    List<PresenceEvent>? presence,
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
        bgPath: clearBg ? null : (bgPath ?? this.bgPath),
        bgAccent: clearBg ? null : (bgAccent ?? this.bgAccent),
        bgAlignY: bgAlignY ?? this.bgAlignY,
        roomMode: roomMode ?? this.roomMode,
        auctionItem: clearAuction ? null : (auctionItem ?? this.auctionItem),
        auctionBids: clearAuction ? const {} : (auctionBids ?? this.auctionBids),
        videoUrl: clearVideo ? null : (videoUrl ?? this.videoUrl),
        videoTitle: clearVideo ? '' : (videoTitle ?? this.videoTitle),
        videoPlaying: clearVideo ? false : (videoPlaying ?? this.videoPlaying),
        roomGame: clearGame ? null : (roomGame ?? this.roomGame),
        promotedUntil: promotedUntil ?? this.promotedUntil,
        promoUsed: promoUsed ?? this.promoUsed,
        lastRallyAt: lastRallyAt ?? this.lastRallyAt,
        presence: presence ?? this.presence,
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
        sentGift: sentGift ?? this.sentGift,
        sentMessage: sentMessage ?? this.sentMessage,
        watchSecs: watchSecs ?? this.watchSecs,
        claimedBoxes: claimedBoxes ?? this.claimedBoxes,
        onlineIds: onlineIds ?? this.onlineIds,
        listeners: listeners ?? this.listeners,
      );

  /// How the room looks right now: the custom photo if one is set, else the chosen theme.
  RoomLook get look => bgPath != null && bgAccent != null ? RoomLook.photo(bgPath!, Color(bgAccent!), alignY: bgAlignY) : RoomLook.theme(theme);

  bool get promoted => promotedUntil != null && promotedUntil!.isAfter(DateTime.now());

  /// Highest bid in the auction (user, coins), or null.
  (int, int)? get topBid {
    if (auctionBids.isEmpty) return null;
    final e = auctionBids.entries.reduce((a, b) => b.value > a.value ? b : a);
    return (e.key, e.value);
  }

  static const roomModes = ['normal', 'acquaint', 'auction', 'video', 'game'];
  static const roomModeNames = {'normal': 'Normal Room', 'acquaint': 'Acquaint Room', 'auction': 'Auction Room', 'video': 'Video Room', 'game': 'Game Room'};

  /// Room categories shown in the room menu → stored room tag.
  static const categories = [('Friends', 'Friends'), ('Music', 'Music'), ('Game', 'Games'), ('Chats', 'Chat')];

  /// Everyone in the room right now (named users + other listeners).
  int get onlineCount => onlineIds.length + listeners;

  int get memberCount => memberBase + members.length;

  /// Treasure-box progress: watched time plus 60 s per completed task.
  int get treasureSecs => watchSecs + 60 * [sentGift, sentMessage].where((x) => x).length;

  static final themeNames = [for (final t in RoomLook.themes) t.name];
  static const themeUnlock = [1, 1, 1, 1, 1, 1, 2, 3, 4, 6, 8]; // room level needed
  static const tracks = ['Midnight Drive', 'Golden Hour', 'Neon Dreams', 'Lo-fi Chill', 'Party Starter', 'Slow Love'];
  static const tags = ['Chat', 'Music', 'Games', 'Friends', 'Dating', 'Poetry', 'Family', 'Private'];
}

/// Someone entered or left the room (shown in the fixed notice strip under the seats).
class PresenceEvent {
  final int serial;
  final YoloUser user;
  final bool entered;
  const PresenceEvent(this.serial, this.user, this.entered);
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
/// Room settings saved per room id (theme, background, mode, category…), so they come back
/// when the room is reopened. With Laravel these come from GET /rooms/{id}.
final roomSavedProvider = NotifierProvider<RoomSaved, Map<int, Map<String, Object?>>>(RoomSaved.new);

class RoomSaved extends Notifier<Map<int, Map<String, Object?>>> {
  @override
  Map<int, Map<String, Object?>> build() => const {};
  void save(int roomId, Map<String, Object?> data) => state = {...state, roomId: data};
}

/// Rooms boosted with a recommendation card (room id → until). Home shows them first.
final promotedRoomsProvider = NotifierProvider<PromotedRooms, Map<int, DateTime>>(PromotedRooms.new);

class PromotedRooms extends Notifier<Map<int, DateTime>> {
  @override
  Map<int, DateTime> build() => const {};
  void promote(int roomId, DateTime until) => state = {...state, roomId: until};
  bool isPromoted(int roomId) => state[roomId]?.isAfter(DateTime.now()) ?? false;
}

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
    ref.onDispose(() {
      speak.cancel();
      watch.cancel();
      presence.cancel();
    });
    final others = [DemoUsers.zara, DemoUsers.kenji, DemoUsers.mia, null, DemoUsers.omar]
        .map((u) => u?.id == room.owner.id ? null : u)
        .toList();
    final me = _me;
    final fresh = RoomState(
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
    // Restore the room's saved settings (theme, background, mode, category…) and show my entry.
    return _restore(fresh).copyWith(presence: [PresenceEvent(++_serial, me, true)]);
  }

  RoomState _restore(RoomState s) {
    final saved = ref.read(roomSavedProvider)[room.id];
    if (saved == null) return s;
    return s.copyWith(
      name: saved['name'] as String?,
      announcement: saved['announcement'] as String?,
      tag: saved['tag'] as String?,
      theme: saved['theme'] as int?,
      bgPath: saved['bgPath'] as String?,
      bgAccent: saved['bgAccent'] as int?,
      bgAlignY: saved['bgAlignY'] as double?,
      roomMode: saved['roomMode'] as String?,
      mode: saved['mode'] as String?,
      coverPath: saved['coverPath'] as String?,
      groupId: saved['groupId'] as int?,
      promotedUntil: saved['promotedUntil'] as DateTime?,
      promoUsed: saved['promoUsed'] as int?,
      lastRallyAt: saved['lastRallyAt'] as DateTime?,
    );
  }

  /// Saves room-wide settings so they come back when the room is reopened, and sends them to
  /// the server (Laravel: PATCH /rooms/{id}/settings → broadcast to everyone in the room).
  void _save() {
    final st = state;
    final data = <String, Object?>{
      'name': st.name,
      'announcement': st.announcement,
      'tag': st.tag,
      'theme': st.theme,
      'bgPath': st.bgPath,
      'bgAccent': st.bgAccent,
      'bgAlignY': st.bgAlignY,
      'roomMode': st.roomMode,
      'mode': st.mode,
      'coverPath': st.coverPath,
      'groupId': st.groupId,
      'promotedUntil': st.promotedUntil,
      'promoUsed': st.promoUsed,
      'lastRallyAt': st.lastRallyAt,
    };
    ref.read(roomSavedProvider.notifier).save(room.id, data);
    ref.read(repositoryProvider).saveRoomSettings(room.id, {
      for (final e in data.entries)
        if (e.key != 'coverPath' && e.key != 'bgPath') e.key: e.value is DateTime ? (e.value! as DateTime).toIso8601String() : e.value,
    }).ignore();
  }

  /// Applies settings another participant changed (called by the realtime room channel).
  void applyRemoteSettings(Map<String, Object?> data) {
    state = state.copyWith(
      name: data['name'] as String?,
      announcement: data['announcement'] as String?,
      tag: data['tag'] as String?,
      theme: data['theme'] as int?,
      bgPath: data['bgPath'] as String?,
      bgAccent: data['bgAccent'] as int?,
      bgAlignY: (data['bgAlignY'] as num?)?.toDouble(),
      clearBg: data.containsKey('bgPath') && data['bgPath'] == null,
      roomMode: data['roomMode'] as String?,
      mode: data['mode'] as String?,
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
    final leo = DemoUsers.leo;
    final delta = _rand.nextInt(3) - 1; // -1, 0, +1
    state = state.copyWith(listeners: max(0, state.listeners + delta));
    if (!ids.contains(leo.id) && _rand.nextInt(3) == 0 && !state.banned.contains(leo.id)) {
      userEntered(leo);
    } else if (ids.contains(leo.id) && _rand.nextInt(4) == 0 && !state.seats.any((s) => s.user?.id == leo.id)) {
      userLeft(leo);
    }
  }

  /// Someone joined: add them to the online list and queue an "entered" notice.
  /// Laravel: presence channel `joining` event.
  void userEntered(YoloUser u) => _presence(u, true);

  /// Someone left: remove them and queue a "left" notice. Laravel: presence channel `leaving` event.
  void userLeft(YoloUser u) => _presence(u, false);

  void _presence(YoloUser u, bool entered) {
    final online = state.onlineIds.contains(u.id);
    if (online == entered) return; // already in / already gone → no duplicate notice
    final ids = {...state.onlineIds};
    entered ? ids.add(u.id) : ids.remove(u.id);
    final log = [...state.presence, PresenceEvent(++_serial, u, entered)];
    state = state.copyWith(onlineIds: ids, presence: log.length > 30 ? log.sublist(log.length - 30) : log);
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
    String? bgPath,
    int? bgAccent,
    double? bgAlignY,
    bool clearBg = false,
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
      bgPath: bgPath,
      bgAccent: bgAccent,
      bgAlignY: bgAlignY,
      clearBg: clearBg,
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
    _save();
  }

  /// Picking a predefined theme replaces any custom photo.
  void setTheme(int i) => updateSettings(theme: i, clearBg: true);

  // --- Room mode & category (room menu) ------------------------------------
  /// Returns an error message, or '' when the mode changed.
  String setRoomMode(String m) {
    if (!canManage) return 'Only the owner and admins can change the room mode';
    if (m == state.roomMode) return '';
    state = state.copyWith(
      roomMode: m,
      mode: m == 'acquaint' ? 'intimacy' : 'normal', // acquaint = host + partner seats
      clearAuction: m != 'auction',
      clearVideo: m != 'video',
      clearGame: m != 'game',
    );
    _system('${_me.name} switched to ${RoomState.roomModeNames[m]}');
    _record('switched to ${RoomState.roomModeNames[m]}');
    _save();
    return '';
  }

  String setCategory(String tag) {
    if (!canManage) return 'Only the owner and admins can change the category';
    if (tag != state.tag) updateSettings(tag: tag);
    return '';
  }

  // --- Auction room ----------------------------------------------------------
  String startAuction(String item) {
    if (!canManage) return 'Only the owner and admins can start an auction';
    final t = item.trim();
    if (t.isEmpty) return 'Enter what you are auctioning';
    state = state.copyWith(auctionItem: t, auctionBids: const {});
    _system('Auction started: $t. Bid with coins!');
    return '';
  }

  /// Bids are paid in coins (they also count as Charms contribution to the room).
  String bid(int coins) {
    if (state.auctionItem == null) return 'No auction is running';
    if (!ref.read(sessionProvider.notifier).spend(coins, note: 'Auction bid in ${state.name}')) return 'Not enough coins';
    final total = (state.auctionBids[_me.id] ?? 0) + coins;
    state = state.copyWith(
      auctionBids: {...state.auctionBids, _me.id: total},
      contributions: {...state.contributions, _me.id: (state.contributions[_me.id] ?? 0) + coins},
    );
    _system('${_me.name} bid $total coins');
    return '';
  }

  String endAuction() {
    if (!canManage) return 'Only the owner and admins can end the auction';
    final top = state.topBid;
    final item = state.auctionItem;
    state = state.copyWith(clearAuction: true);
    _system(top == null ? 'Auction for $item ended with no bids' : 'SOLD! ${top.$1 == _me.id ? _me.name : userById(top.$1).name} won $item for ${top.$2} coins');
    return '';
  }

  // --- Video room ------------------------------------------------------------
  String setVideo(String url, String title) {
    if (!canManage) return 'Only the owner and admins can choose the video';
    final u = Uri.tryParse(url.trim());
    if (u == null || !(u.scheme == 'https' || u.scheme == 'http')) return 'Enter a video link (https://…)';
    state = state.copyWith(videoUrl: url.trim(), videoTitle: title.trim().isEmpty ? 'Video' : title.trim(), videoPlaying: true);
    _system('${_me.name} is playing "${state.videoTitle}" for everyone');
    return '';
  }

  void toggleVideo() {
    if (canManage && state.videoUrl != null) state = state.copyWith(videoPlaying: !state.videoPlaying);
  }

  void stopVideo() {
    if (canManage) state = state.copyWith(clearVideo: true);
  }

  // --- Game room -------------------------------------------------------------
  String setGame(String? game) {
    if (!canManage) return 'Only the owner and admins can choose the game';
    state = game == null ? state.copyWith(clearGame: true) : state.copyWith(roomGame: game);
    if (game != null) _system('${_me.name} started $game — join from the game stage');
    return '';
  }

  // --- Recommendation card & rally fans ---------------------------------------
  int get recommendCardsLeft => max(0, levelForExp(state.exp).recommendCards - state.promoUsed);

  /// Puts the room at the top of Home → Popular for 30 minutes.
  String useRecommendCard() {
    if (!canManage) return 'Only the owner and admins can use recommendation cards';
    if (state.promoted) return 'The room is already recommended';
    if (recommendCardsLeft == 0) return 'No recommendation cards left today';
    final until = DateTime.now().add(const Duration(minutes: 30));
    state = state.copyWith(promotedUntil: until, promoUsed: state.promoUsed + 1);
    ref.read(promotedRoomsProvider.notifier).promote(room.id, until);
    _system('${state.name} is now recommended on Home for 30 minutes');
    _save();
    return '';
  }

  /// Notifies the room's members and fans to come in (30-minute cooldown).
  /// Laravel: POST /rooms/{id}/rally → push notification to members & fans.
  String rallyFans(String message) {
    if (!canManage) return 'Only the owner and admins can rally fans';
    final last = state.lastRallyAt;
    if (last != null && DateTime.now().difference(last) < const Duration(minutes: 30)) {
      final left = 30 - DateTime.now().difference(last).inMinutes;
      return 'You can rally again in $left min';
    }
    final text = message.trim().isEmpty ? 'Come join ${state.name}!' : message.trim();
    state = state.copyWith(lastRallyAt: DateTime.now());
    _system('${_me.name} rallied fans: $text');
    ref.read(repositoryProvider).rallyFans(room.id, text).ignore();
    _save();
    return '';
  }

  /// Gift sound is a personal setting (same switch as Settings → Sound).
  void toggleGiftSound() => ref.read(settingsProvider.notifier).update((s) => s.copyWith(giftSounds: !s.giftSounds));

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
