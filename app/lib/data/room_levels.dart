import 'package:material_ui/material_ui.dart';

/// Room levels: EXP needed and what each level unlocks.
/// Laravel: GET /rooms/{id}/level, room EXP is added server-side (hourly).
class RoomLevel {
  final int level;
  final int exp; // EXP needed to reach this level
  final int maxMembers;
  final int admins;
  final int coOwners;
  final int recommendCards;
  final String? background; // background unlocked at this level
  final bool guestSeat;
  const RoomLevel(this.level, this.exp, this.maxMembers, this.admins, this.coOwners, this.recommendCards, this.background, this.guestSeat);
}

const roomLevels = [
  RoomLevel(1, 0, 1000, 3, 0, 2, null, false),
  RoomLevel(2, 8000, 2000, 4, 0, 2, 'Club', false),
  RoomLevel(3, 30000, 3000, 5, 0, 2, 'Golden Party', false),
  RoomLevel(4, 100000, 5000, 6, 0, 2, 'Diamond Party', false),
  RoomLevel(5, 300000, 7000, 7, 1, 3, null, false),
  RoomLevel(6, 800000, 10000, 8, 1, 3, 'Starfield', false),
  RoomLevel(7, 2000000, 20000, 9, 1, 4, null, true),
  RoomLevel(8, 4800000, 30000, 10, 2, 4, 'Future City', true),
  RoomLevel(9, 11000000, 40000, 12, 2, 5, null, true),
];

RoomLevel levelForExp(int exp) => roomLevels.lastWhere((l) => exp >= l.exp);
RoomLevel? nextLevel(RoomLevel l) => l.level < roomLevels.length ? roomLevels[l.level] : null;

/// Daily room EXP rules.
const roomExpPerFiveMinutes = 5; // double for VIP
const roomExpDailyCapPlay = 5000;
const roomExpDailyCapGifts = 80000;
const roomExpDailyMax = 85000;

/// Badge colours per level (1 grey … 9 gold).
List<Color> roomLevelColors(int level) => switch (level) {
      1 => const [Color(0xFF9CA3AF), Color(0xFF4B5563)],
      2 => const [Color(0xFF4ADE80), Color(0xFF15803D)],
      3 || 4 => const [Color(0xFF38BDF8), Color(0xFF0369A1)],
      5 || 6 => const [Color(0xFFC084FC), Color(0xFF7E22CE)],
      7 || 8 => const [Color(0xFFFB923C), Color(0xFFC2410C)],
      _ => const [Color(0xFFFDE68A), Color(0xFFB45309)],
    };

/// Pentagon-style room level badge.
class RoomLevelBadge extends StatelessWidget {
  const RoomLevelBadge(this.level, {super.key, this.size = 26});
  final int level;
  final double size;

  @override
  Widget build(BuildContext context) => Semantics(
        label: 'Room level $level',
        excludeSemantics: true,
        child: Container(
          width: size,
          height: size,
          decoration: ShapeDecoration(
            shape: const StarBorder.polygon(sides: 5, pointRounding: 0.4),
            gradient: LinearGradient(colors: roomLevelColors(level), begin: Alignment.topCenter, end: Alignment.bottomCenter),
            shadows: [BoxShadow(color: roomLevelColors(level).first.withValues(alpha: 0.5), blurRadius: size * 0.3)],
          ),
          alignment: Alignment.center,
          child: Text('$level', style: TextStyle(fontSize: size * 0.48, fontWeight: FontWeight.w900, color: Colors.white)),
        ),
      );
}
