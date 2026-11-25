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

// ---------------------------------------------------------------------------
// Chat
// ---------------------------------------------------------------------------

class ChatMessage {
  final bool mine;
  final String text;
  final String time;
  const ChatMessage(this.mine, this.text, this.time);
}

final chatProvider = NotifierProvider.family<ChatController, List<ChatMessage>, int>(ChatController.new);

class ChatController extends Notifier<List<ChatMessage>> {
  ChatController(this.userId);
  final int userId;

  @override
  List<ChatMessage> build() {
    final convo = demoConversations.where((c) => c.user.id == userId).firstOrNull;
    return [
      const ChatMessage(false, 'Hey! Are you coming to the room tonight?', '20:30'),
      const ChatMessage(true, 'Yes! What time?', '20:31'),
      if (convo != null) ChatMessage(false, convo.last, convo.time),
    ];
  }

  void send(String text) {
    final t = text.trim();
    if (t.isEmpty) return;
    final now = DateTime.now();
    state = [...state, ChatMessage(true, t, '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}')];
  }
}

YoloUser userById(int id) => demoAllUsers.firstWhere((u) => u.id == id, orElse: () => demoAllUsers.first);
