import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import 'demo_content.dart';
import 'social_providers.dart';

/// Layered 2D avatar settings (upgradeable to 3D later).
class AvatarConfig {
  final int skin, hair, hairColor, outfit, outfitColor, accessory, eyes;
  const AvatarConfig({this.skin = 1, this.hair = 1, this.hairColor = 0, this.outfit = 0, this.outfitColor = 0, this.accessory = 0, this.eyes = 0});

  AvatarConfig copyWith({int? skin, int? hair, int? hairColor, int? outfit, int? outfitColor, int? accessory, int? eyes}) => AvatarConfig(
        skin: skin ?? this.skin,
        hair: hair ?? this.hair,
        hairColor: hairColor ?? this.hairColor,
        outfit: outfit ?? this.outfit,
        outfitColor: outfitColor ?? this.outfitColor,
        accessory: accessory ?? this.accessory,
        eyes: eyes ?? this.eyes,
      );

  static const skins = [Color(0xFFFFE0C7), Color(0xFFF5C6A0), Color(0xFFD9A07A), Color(0xFFA9714B), Color(0xFF6E4630)];
  static const hairColors = [Color(0xFF1F1B24), Color(0xFF6B3E26), Color(0xFFE8C26A), Color(0xFFE85D9E), Color(0xFF7C5CFF), Color(0xFFE5E7EB)];
  static const outfitColors = [Color(0xFF8B5CF6), Color(0xFFF5C451), Color(0xFFEC4899), Color(0xFF0EA5E9), Color(0xFF10B981), Color(0xFF1F2937)];
  static const hairNames = ['Bald', 'Short', 'Long', 'Bun', 'Spiky', 'Bob'];
  static const outfitNames = ['Hoodie', 'Suit', 'Dress', 'Jersey'];
  static const accessoryNames = ['None', 'Glasses', 'Shades', 'Crown', 'Headphones', 'Cap'];
  static const eyeNames = ['Happy', 'Wink', 'Cool', 'Star'];
}

class ProfileExtras {
  final String bio;
  final String? photoPath; // picked from gallery
  final int photoColor; // fallback gradient avatar
  final int cover;
  final bool useAvatarFigure;
  final AvatarConfig avatar;
  final DateTime birthday;

  const ProfileExtras({
    this.bio = 'Night owl. Music, Ludo and good vibes.',
    this.photoPath,
    this.photoColor = 0,
    this.cover = 0,
    this.useAvatarFigure = false,
    this.avatar = const AvatarConfig(),
    required this.birthday,
  });

  ProfileExtras copyWith({String? bio, String? photoPath, bool clearPhoto = false, int? photoColor, int? cover, bool? useAvatarFigure, AvatarConfig? avatar, DateTime? birthday}) =>
      ProfileExtras(
        bio: bio ?? this.bio,
        photoPath: clearPhoto ? null : (photoPath ?? this.photoPath),
        photoColor: photoColor ?? this.photoColor,
        cover: cover ?? this.cover,
        useAvatarFigure: useAvatarFigure ?? this.useAvatarFigure,
        avatar: avatar ?? this.avatar,
        birthday: birthday ?? this.birthday,
      );

  static const photoColors = [
    [Color(0xFFEC4899), Color(0xFF8B5CF6)],
    [Color(0xFFF59E0B), Color(0xFFEA580C)],
    [Color(0xFF0EA5E9), Color(0xFF6366F1)],
    [Color(0xFF10B981), Color(0xFF0EA5E9)],
    [Color(0xFFEF4444), Color(0xFFF59E0B)],
    [Color(0xFF6366F1), Color(0xFFA855F7)],
  ];
  static const covers = [
    [Color(0xFF5B21B6), Color(0xFF9D174D)],
    [Color(0xFF0F172A), Color(0xFF6366F1)],
    [Color(0xFFB45309), Color(0xFFF59E0B)],
    [Color(0xFF0E7490), Color(0xFF10B981)],
    [Color(0xFF9D174D), Color(0xFFF472B6)],
    [Color(0xFF111827), Color(0xFF374151)],
  ];
  static const coverNames = ['Royal Night', 'Deep Space', 'Golden Hour', 'Ocean', 'Sakura', 'Midnight'];
}

final profileExtrasProvider = NotifierProvider<ProfileExtrasController, ProfileExtras>(ProfileExtrasController.new);

class ProfileExtrasController extends Notifier<ProfileExtras> {
  @override
  ProfileExtras build() => ProfileExtras(birthday: DateTime(2004, 3, 12));

  void update(ProfileExtras Function(ProfileExtras) f) => state = f(state);
}

/// The frame currently equipped from the shop (null = default gold ring).
final equippedFrameProvider = Provider<ShopItem?>((ref) {
  final equipped = ref.watch(equippedItemsProvider);
  return demoShopItems.where((s) => s.category == 'frame' && equipped.contains(s.id)).firstOrNull;
});

class BadgeInfo {
  final String name;
  final String how;
  final IconData icon;
  final Color color;
  final bool owned;
  const BadgeInfo(this.name, this.how, this.icon, this.color, this.owned);
}

const demoBadges = [
  BadgeInfo('Newcomer', 'Create your account', Icons.waving_hand_rounded, Color(0xFF86EFAC), true),
  BadgeInfo('Chatterbox', 'Send 100 room messages', Icons.forum_rounded, Color(0xFF7DD3FC), true),
  BadgeInfo('Generous', 'Send gifts worth 10,000 coins', Icons.volunteer_activism_rounded, Color(0xFFF5C451), true),
  BadgeInfo('Mic Star', 'Spend 10 hours on mic', Icons.mic_rounded, Color(0xFFF9A8D4), false),
  BadgeInfo('Family Hero', 'Donate 5,000 to your family', Icons.shield_rounded, Color(0xFFC4B5FD), false),
  BadgeInfo('Night Owl', 'Be online after midnight 7 days', Icons.nightlight_round, Color(0xFFA5B4FC), true),
  BadgeInfo('Trendsetter', 'Get 1,000 likes on moments', Icons.local_fire_department_rounded, Color(0xFFFDBA74), false),
  BadgeInfo('VIP', 'Become a VIP member', Icons.workspace_premium_rounded, Color(0xFFFDE68A), true),
];

class Achievement {
  final String name;
  final String goal;
  final int progress, target, reward;
  const Achievement(this.name, this.goal, this.progress, this.target, this.reward);
  bool get done => progress >= target;
}

const demoAchievements = [
  Achievement('First steps', 'Join 5 voice rooms', 5, 5, 50),
  Achievement('Social butterfly', 'Follow 20 people', 12, 20, 100),
  Achievement('Gift giver', 'Send 50 gifts', 50, 50, 200),
  Achievement('On the mic', 'Talk on mic for 60 minutes', 38, 60, 150),
  Achievement('Moment maker', 'Post 10 moments', 3, 10, 120),
  Achievement('Family member', 'Join a family', 0, 1, 80),
];
