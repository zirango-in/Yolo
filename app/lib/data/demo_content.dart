import 'package:material_ui/material_ui.dart';

import 'models.dart';
import 'repository.dart';

/// Demo content for pages until the Laravel API serves it.
/// Each list maps to an API endpoint listed in docs/FEATURES.md.

class GameInfo {
  final String id;
  final String name;
  final String players;
  final IconData icon;
  final List<Color> colors;
  final bool hot;
  const GameInfo(this.id, this.name, this.players, this.icon, this.colors, {this.hot = false});
}

const demoGames = [
  GameInfo('ludo', 'Ludo', '2–4', Icons.casino_rounded, [Color(0xFFF59E0B), Color(0xFFEA580C)], hot: true),
  GameInfo('draw', 'Draw & Guess', '2–8', Icons.brush_rounded, [Color(0xFFEC4899), Color(0xFF8B5CF6)], hot: true),
  GameInfo('spy', 'Who Is Spy', '4–8', Icons.visibility_rounded, [Color(0xFF6366F1), Color(0xFF0EA5E9)], hot: true),
  GameInfo('werewolf', 'Werewolf', '6–12', Icons.nightlight_round, [Color(0xFF312E81), Color(0xFF7C3AED)]),
  GameInfo('impostor', 'Star Impostor', '5–10', Icons.rocket_launch_rounded, [Color(0xFF0F766E), Color(0xFF6366F1)]),
  GameInfo('micgrab', 'Mic Grab', '2–6', Icons.mic_rounded, [Color(0xFFDB2777), Color(0xFFF59E0B)]),
  GameInfo('reversi', 'Reversi', '2', Icons.blur_circular_rounded, [Color(0xFF16A34A), Color(0xFF065F46)]),
  GameInfo('bingo', 'Bingo', '2–6', Icons.grid_on_rounded, [Color(0xFF0EA5E9), Color(0xFF14B8A6)]),
  GameInfo('wildcards', 'Wild Cards', '2–6', Icons.style_rounded, [Color(0xFFEF4444), Color(0xFFF59E0B)]),
  GameInfo('bluff', 'Bluff Party', '3–6', Icons.theater_comedy_rounded, [Color(0xFF9333EA), Color(0xFFEC4899)]),
  GameInfo('colorhide', 'Color Hide', '4–8', Icons.format_paint_rounded, [Color(0xFF06B6D4), Color(0xFFA855F7)]),
  GameInfo('llama', 'Llama Dash', '2–6', Icons.pets_rounded, [Color(0xFFF97316), Color(0xFFFACC15)]),
  GameInfo('trickcafe', 'Trick Café', '3–6', Icons.local_cafe_rounded, [Color(0xFF92400E), Color(0xFFD97706)]),
  GameInfo('jackaroo', 'Jackaroo', '4', Icons.extension_rounded, [Color(0xFF1D4ED8), Color(0xFF9333EA)]),
];

class Moment {
  final int id;
  final YoloUser author;
  final String text;
  final String topic;
  final String time;
  final int likes;
  final int comments;
  final List<Color>? photo; // demo placeholder image
  final List<String> images; // real picked photos
  final String? video; // real picked video
  const Moment(this.id, this.author, this.text, this.topic, this.time, this.likes, this.comments, {this.photo, this.images = const [], this.video});
}

const demoMoments = [
  Moment(1, DemoUsers.zara, 'Won 3 Ludo games in a row tonight. Who wants a rematch?', '#Ludo', '5m', 128, 24,
      photo: [Color(0xFFF59E0B), Color(0xFFEA580C)]),
  Moment(2, DemoUsers.kenji, 'New song cover in my room at 10pm. Come sing with me!', '#Music', '22m', 86, 12),
  Moment(3, DemoUsers.mia, 'Sunset from my balcony. Good vibes only.', '#Life', '1h', 342, 51,
      photo: [Color(0xFFF472B6), Color(0xFF7C3AED)]),
  Moment(4, DemoUsers.omar, 'Our family just reached level 10! Thanks everyone for the donations.', '#Family', '3h', 210, 33),
];

class Conversation {
  final YoloUser user;
  final String last;
  final String time;
  final int unread;
  final bool online;
  const Conversation(this.user, this.last, this.time, {this.unread = 0, this.online = false});
}

const demoConversations = [
  Conversation(DemoUsers.zara, 'See you in the room tonight!', '21:04', unread: 2, online: true),
  Conversation(DemoUsers.kenji, 'Thanks for the gift', '20:41', online: true),
  Conversation(DemoUsers.mia, 'Haha that was so funny', 'Yesterday', unread: 1),
  Conversation(DemoUsers.omar, 'Join our family?', 'Mon'),
  Conversation(DemoUsers.leo, 'GG! Rematch tomorrow', 'Sun'),
];

class YoloNotification {
  final String type; // friend, message, gift, room, game, family, system, event, reward
  final String title;
  final String body;
  final String time;
  final bool unread;
  const YoloNotification(this.type, this.title, this.body, this.time, {this.unread = false});
}

const demoNotifications = [
  YoloNotification('friend', 'New friend request', 'Leo wants to be your friend', '2m', unread: true),
  YoloNotification('gift', 'You received a gift', 'Zara sent you a Crown ×1', '10m', unread: true),
  YoloNotification('room', 'Room invitation', 'Kenji invited you to "Sing With Me"', '25m', unread: true),
  YoloNotification('game', 'Game invitation', 'Mia invited you to play Ludo', '1h'),
  YoloNotification('family', 'Family', 'Moonlight family reached level 10', '3h'),
  YoloNotification('reward', 'Reward ready', 'Your daily check-in reward is waiting', '5h'),
  YoloNotification('event', 'Event started', 'Ludo Party Night has begun', '6h'),
  YoloNotification('system', 'System', 'Welcome to Yolo! Read our community rules to stay safe.', '1d'),
];

class YoloEvent {
  final String title;
  final String subtitle;
  final String when;
  final bool live;
  final List<Color> colors;
  final IconData icon;
  const YoloEvent(this.title, this.subtitle, this.when, this.live, this.colors, this.icon);
}

const demoEvents = [
  YoloEvent('Ludo Party Night', 'Win up to 5,000 coins', 'Ends in 4h', true, [Color(0xFF6D28D9), Color(0xFFA21CAF)], Icons.casino_rounded),
  YoloEvent('Gift King Week', 'Top senders win exclusive frames', 'Ends in 3d', true, [Color(0xFFB45309), Color(0xFFF59E0B)], Icons.workspace_premium_rounded),
  YoloEvent('Singing Star', 'Karaoke battle with live voting', 'Starts Fri 20:00', false, [Color(0xFF0E7490), Color(0xFF6366F1)], Icons.mic_rounded),
  YoloEvent('Family Clash', 'Families compete for the crown', 'Starts Mon', false, [Color(0xFF9D174D), Color(0xFF7C3AED)], Icons.groups_rounded),
];

class ShopItem {
  final int id;
  final String name;
  final String category; // frame, entry, bubble, theme
  final int price;
  final String duration;
  final List<Color> colors;
  final IconData icon;
  const ShopItem(this.id, this.name, this.category, this.price, this.duration, this.colors, this.icon);
}

const demoShopItems = [
  ShopItem(1, 'Golden Crown', 'frame', 3000, '7 days', [Color(0xFFFFD97A), Color(0xFFE0A82E)], Icons.workspace_premium_rounded),
  ShopItem(2, 'Neon Love', 'frame', 1500, '7 days', [Color(0xFFEC4899), Color(0xFF8B5CF6)], Icons.favorite_rounded),
  ShopItem(3, 'Ice Crystal', 'frame', 2200, '7 days', [Color(0xFF7DD3FC), Color(0xFF6366F1)], Icons.ac_unit_rounded),
  ShopItem(4, 'Royal Wings', 'frame', 8800, '30 days', [Color(0xFFFDE68A), Color(0xFFF59E0B)], Icons.flight_rounded),
  ShopItem(5, 'Sports Car Entry', 'entry', 5200, '7 days', [Color(0xFFEF4444), Color(0xFFF97316)], Icons.directions_car_rounded),
  ShopItem(6, 'Dragon Entry', 'entry', 12000, '7 days', [Color(0xFF16A34A), Color(0xFF0EA5E9)], Icons.local_fire_department_rounded),
  ShopItem(7, 'Galaxy Bubble', 'bubble', 900, '7 days', [Color(0xFF312E81), Color(0xFF9333EA)], Icons.chat_bubble_rounded),
  ShopItem(8, 'Gold Bubble', 'bubble', 1200, '7 days', [Color(0xFFFFD97A), Color(0xFFE0A82E)], Icons.chat_rounded),
  ShopItem(9, 'Night City', 'theme', 2500, '30 days', [Color(0xFF0F172A), Color(0xFF6366F1)], Icons.location_city_rounded),
  ShopItem(10, 'Sakura Garden', 'theme', 2500, '30 days', [Color(0xFFF9A8D4), Color(0xFFDB2777)], Icons.local_florist_rounded),
];

class FamilyInfo {
  final int id;
  final String name;
  final String slogan;
  final int level;
  final int members;
  final int maxMembers;
  final List<Color> colors;
  const FamilyInfo(this.id, this.name, this.slogan, this.level, this.members, this.maxMembers, this.colors);
}

const demoFamilies = [
  FamilyInfo(1, 'Moonlight', 'Night owls who love music', 10, 86, 100, [Color(0xFF6366F1), Color(0xFFA855F7)]),
  FamilyInfo(2, 'Golden Lions', 'Play hard, gift harder', 14, 120, 150, [Color(0xFFF59E0B), Color(0xFFEA580C)]),
  FamilyInfo(3, 'Ocean Breeze', 'Chill talks every day', 6, 42, 60, [Color(0xFF0EA5E9), Color(0xFF14B8A6)]),
  FamilyInfo(4, 'Rose Garden', 'Friends forever', 8, 58, 80, [Color(0xFFEC4899), Color(0xFFF43F5E)]),
];

const demoAllUsers = [DemoUsers.zara, DemoUsers.kenji, DemoUsers.mia, DemoUsers.omar, DemoUsers.leo];
