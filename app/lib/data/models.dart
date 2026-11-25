import 'package:material_ui/material_ui.dart';

/// Data models. Field names match the Laravel API JSON (snake_case).

class YoloUser {
  final int id;
  final String name;
  final String gender; // 'male' | 'female'
  final int age;
  final int level;
  final int vipLevel;
  final int coins;
  final String bio;
  final int following;
  final int followers;
  final int friends;
  final List<Color> avatarColors;

  const YoloUser({
    required this.id,
    required this.name,
    this.gender = 'female',
    this.age = 22,
    this.level = 1,
    this.vipLevel = 0,
    this.coins = 0,
    this.bio = '',
    this.following = 0,
    this.followers = 0,
    this.friends = 0,
    this.avatarColors = const [Color(0xFFEC4899), Color(0xFF8B5CF6)],
  });

  String get initial => name.isEmpty ? '?' : name[0].toUpperCase();

  YoloUser copyWith({int? coins}) => YoloUser(
        id: id,
        name: name,
        gender: gender,
        age: age,
        level: level,
        vipLevel: vipLevel,
        coins: coins ?? this.coins,
        bio: bio,
        following: following,
        followers: followers,
        friends: friends,
        avatarColors: avatarColors,
      );

  factory YoloUser.fromJson(Map<String, dynamic> j) => YoloUser(
        id: j['id'] as int,
        name: j['nickname'] as String? ?? '',
        gender: j['gender'] as String? ?? 'female',
        age: j['age'] as int? ?? 0,
        level: j['level'] as int? ?? 1,
        vipLevel: j['vip_level'] as int? ?? 0,
        coins: j['coins'] as int? ?? 0,
        bio: j['bio'] as String? ?? '',
        following: j['following_count'] as int? ?? 0,
        followers: j['followers_count'] as int? ?? 0,
        friends: j['friends_count'] as int? ?? 0,
      );
}

class Room {
  final int id;
  final String name;
  final String tag;
  final String announcement;
  final int online;
  final YoloUser owner;
  final List<Color> cover;

  const Room({
    required this.id,
    required this.name,
    required this.tag,
    required this.owner,
    this.announcement = '',
    this.online = 0,
    this.cover = const [Color(0xFF7C3AED), Color(0xFFDB2777)],
  });
}

class Seat {
  final int index;
  final YoloUser? user;
  final bool locked;
  final bool muted;
  final bool speaking;

  const Seat({
    required this.index,
    this.user,
    this.locked = false,
    this.muted = false,
    this.speaking = false,
  });

  bool get isEmpty => user == null;

  Seat copyWith({YoloUser? user, bool clearUser = false, bool? locked, bool? muted, bool? speaking}) => Seat(
        index: index,
        user: clearUser ? null : (user ?? this.user),
        locked: locked ?? this.locked,
        muted: muted ?? this.muted,
        speaking: speaking ?? this.speaking,
      );
}

enum MessageKind { chat, system, gift }

class RoomMessage {
  final MessageKind kind;
  final String sender;
  final String text;
  final Color color;

  const RoomMessage({
    required this.kind,
    required this.text,
    this.sender = '',
    this.color = const Color(0xFFC4B5FD),
  });
}

class Gift {
  final int id;
  final String name;
  final int price;
  final IconData icon;
  final Color tint;
  final bool fullScreen;

  const Gift({
    required this.id,
    required this.name,
    required this.price,
    required this.icon,
    required this.tint,
    this.fullScreen = false,
  });
}
