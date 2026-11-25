import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'providers.dart';

/// In-app notification. Laravel: GET /notifications, POST /notifications/read, DELETE /notifications/{id};
/// push delivery through Firebase Cloud Messaging later.
class AppNotification {
  final int id;
  final String type; // friend, message, gift, room, game, family, system, event, reward
  final String title;
  final String body;
  final String time;
  final int ref; // user / room / event id the action uses
  final bool read;
  final bool done; // action completed (accepted, claimed...)

  const AppNotification(this.id, this.type, this.title, this.body, this.time, {this.ref = 0, this.read = false, this.done = false});

  AppNotification copyWith({bool? read, bool? done}) => AppNotification(id, type, title, body, time, ref: ref, read: read ?? this.read, done: done ?? this.done);
}

const notificationTypes = ['cp', 'friend', 'message', 'gift', 'room', 'game', 'family', 'system', 'event', 'reward'];

final notificationsProvider = NotifierProvider<NotificationsController, List<AppNotification>>(NotificationsController.new);

class NotificationsController extends Notifier<List<AppNotification>> {
  @override
  List<AppNotification> build() => const [
        AppNotification(1, 'friend', 'New friend request', 'Leo wants to be your friend', '2m', ref: 2005),
        AppNotification(10, 'cp', 'CP request', 'Leo wants to be your Couple', '3m', ref: 2005),
        AppNotification(2, 'message', 'New message', 'Zara: See you in the room tonight!', '4m', ref: 2001),
        AppNotification(3, 'gift', 'You received a gift', 'Zara sent you a Crown ×1', '10m', ref: 2001),
        AppNotification(4, 'room', 'Room invitation', 'Kenji invited you to "Sing With Me"', '25m', ref: 884217),
        AppNotification(5, 'game', 'Game invitation', 'Mia invited you to play Ludo', '1h', ref: 2003),
        AppNotification(6, 'family', 'Family', 'Moonlight family reached level 10', '3h', read: true),
        AppNotification(7, 'reward', 'Reward ready', 'Your weekly login reward: 200 coins', '5h', ref: 200),
        AppNotification(8, 'event', 'Event started', 'Ludo Party Night has begun', '6h', ref: 1, read: true),
        AppNotification(9, 'system', 'Welcome to Yolo!', 'Please read our community rules to stay safe. Never share passwords or pay anyone outside the app.', '1d', read: true),
      ];

  int get unread => state.where((n) => !n.read).length;

  /// Add a new notification at the top.
  void push(String type, String title, String body, {int ref = 0}) {
    final id = state.fold<int>(0, (m, n) => n.id > m ? n.id : m) + 1;
    state = [AppNotification(id, type, title, body, 'now', ref: ref), ...state];
  }

  void markRead(int id) => state = [for (final n in state) n.id == id ? n.copyWith(read: true) : n];
  void markAllRead() => state = [for (final n in state) n.copyWith(read: true)];
  void markDone(int id) => state = [for (final n in state) n.id == id ? n.copyWith(read: true, done: true) : n];
  void delete(int id) => state = state.where((n) => n.id != id).toList();
  void clearAll() => state = const [];

  /// Claim a reward notification (coins in [ref]).
  bool claim(AppNotification n) {
    if (n.type != 'reward' || n.done) return false;
    ref.read(sessionProvider.notifier).earn(n.ref, note: 'Notification reward');
    markDone(n.id);
    return true;
  }
}

final unreadNotificationsProvider = Provider<int>((ref) => ref.watch(notificationsProvider).where((n) => !n.read).length);
