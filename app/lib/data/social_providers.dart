import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'demo_content.dart';
import 'models.dart';

/// Local social state (follows, likes, chats, notifications, purchases).
/// With the Laravel API each action becomes a POST and the state comes from the server.

final followingProvider = NotifierProvider<SetController, Set<int>>(() => SetController({2001, 2002}));
final likedMomentsProvider = NotifierProvider<SetController, Set<int>>(() => SetController({}));
final readNotificationsProvider = NotifierProvider<SetController, Set<int>>(() => SetController({}));
final ownedItemsProvider = NotifierProvider<SetController, Set<int>>(() => SetController({2}));
final equippedItemsProvider = NotifierProvider<SetController, Set<int>>(() => SetController({}));
final joinedFamilyProvider = NotifierProvider<FamilyController, int?>(FamilyController.new);

class SetController extends Notifier<Set<int>> {
  SetController(this._initial);
  final Set<int> _initial;

  @override
  Set<int> build() => {..._initial};

  void toggle(int id) => state = state.contains(id) ? ({...state}..remove(id)) : {...state, id};
  void add(int id) => state = {...state, id};
  void remove(int id) => state = {...state}..remove(id);
  void addAll(Iterable<int> ids) => state = {...state, ...ids};
}

class FamilyController extends Notifier<int?> {
  @override
  int? build() => null;
  void join(int id) => state = id;
  void leave() => state = null;
}

final followersProvider = NotifierProvider<SetController, Set<int>>(() => SetController({2001, 2002, 2003}));
final blockedProvider = NotifierProvider<SetController, Set<int>>(() => SetController({}));
final incomingRequestsProvider = NotifierProvider<SetController, Set<int>>(() => SetController({2005, 2004}));
final sentRequestsProvider = NotifierProvider<SetController, Set<int>>(() => SetController({}));

/// Friends = mutual follows (and not blocked).
final friendsProvider = Provider<List<YoloUser>>((ref) {
  final following = ref.watch(followingProvider);
  final followers = ref.watch(followersProvider);
  final blocked = ref.watch(blockedProvider);
  return demoAllUsers.where((u) => following.contains(u.id) && followers.contains(u.id) && !blocked.contains(u.id)).toList();
});

/// Accept a friend request: they follow me and I follow them back.
void acceptRequest(WidgetRef ref, int id) {
  ref.read(incomingRequestsProvider.notifier).remove(id);
  ref.read(followersProvider.notifier).add(id);
  ref.read(followingProvider.notifier).add(id);
}

const onlineIds = {2001, 2002, 2005};
String presence(int id) => onlineIds.contains(id) ? 'Online' : 'Last seen ${1 + id % 5}h ago';

// ---------------------------------------------------------------------------
// Chat (1-to-1 and groups). Key: 'u:<userId>' or 'g:<groupId>'.
// ---------------------------------------------------------------------------

enum ChatKind { text, voice, image }

class ChatMessage {
  final bool mine;
  final String sender;
  final String text;
  final String time;
  final ChatKind kind;
  final int seconds; // voice length
  final String? imagePath;
  const ChatMessage(this.mine, this.text, this.time, {this.sender = '', this.kind = ChatKind.text, this.seconds = 0, this.imagePath});
}

class GroupChat {
  final int id;
  final String name;
  final List<int> members;
  const GroupChat(this.id, this.name, this.members);
}

final groupsProvider = NotifierProvider<GroupsController, List<GroupChat>>(GroupsController.new);

class GroupsController extends Notifier<List<GroupChat>> {
  @override
  List<GroupChat> build() => const [GroupChat(1, 'Ludo Squad', [2001, 2002, 2003])];

  GroupChat create(String name, List<int> members) {
    final g = GroupChat(state.length + 1, name, members);
    state = [...state, g];
    return g;
  }
}

String _now() {
  final n = DateTime.now();
  return '${n.hour.toString().padLeft(2, '0')}:${n.minute.toString().padLeft(2, '0')}';
}

final chatProvider = NotifierProvider.family<ChatController, List<ChatMessage>, String>(ChatController.new);

class ChatController extends Notifier<List<ChatMessage>> {
  ChatController(this.key);
  final String key;

  @override
  List<ChatMessage> build() {
    if (key.startsWith('g:')) {
      return const [
        ChatMessage(false, 'Who is up for Ludo tonight?', '19:02', sender: 'Zara'),
        ChatMessage(false, 'Me! 9pm?', '19:05', sender: 'Kenji'),
      ];
    }
    final id = int.tryParse(key.substring(2)) ?? 0;
    final convo = demoConversations.where((c) => c.user.id == id).firstOrNull;
    return [
      const ChatMessage(false, 'Hey! Are you coming to the room tonight?', '20:30'),
      const ChatMessage(true, 'Yes! What time?', '20:31'),
      if (convo != null) ChatMessage(false, convo.last, convo.time),
    ];
  }

  void send(String text) {
    final t = text.trim();
    if (t.isEmpty) return;
    state = [...state, ChatMessage(true, t, _now())];
  }

  void sendVoice(int seconds) => state = [...state, ChatMessage(true, 'Voice message', _now(), kind: ChatKind.voice, seconds: seconds.clamp(1, 60))];

  void sendImage(String path) => state = [...state, ChatMessage(true, 'Photo', _now(), kind: ChatKind.image, imagePath: path)];

  void clear() => state = const [];
}

YoloUser userById(int id) => demoAllUsers.firstWhere((u) => u.id == id, orElse: () => demoAllUsers.first);
