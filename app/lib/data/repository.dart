import 'package:dio/dio.dart';
import 'package:material_ui/material_ui.dart';

import '../core/config.dart';
import 'models.dart';

/// Everything the app needs from the backend.
/// [DemoRepository] works offline now; [ApiRepository] talks to Laravel.
abstract class YoloRepository {
  Future<YoloUser> login({required String method, String? phone, String? otp});
  Future<List<Room>> rooms({String tab = 'popular'});
  Future<List<Gift>> gifts();

  /// Saves room-wide settings (theme, mode, category…). The server broadcasts them to the room.
  Future<void> saveRoomSettings(int roomId, Map<String, Object?> settings);

  /// Uploads a custom room background; returns its URL.
  Future<String> uploadRoomBackground(int roomId, String filePath);

  /// Sends a rally notification to the room's members and fans.
  Future<void> rallyFans(int roomId, String message);
}

YoloRepository createRepository() =>
    AppConfig.useDemoData ? DemoRepository() : ApiRepository();

// ---------------------------------------------------------------------------
// Demo data (offline)
// ---------------------------------------------------------------------------

class DemoUsers {
  static const me = YoloUser(
    id: 1048576,
    name: 'Aria',
    level: 28,
    vipLevel: 5,
    coins: 12480,
    bio: 'Night owl. Music, Ludo and good vibes.',
    following: 312,
    followers: 8400,
    friends: 96,
  );
  static const zara = YoloUser(id: 2001, name: 'Zara', avatarColors: [Color(0xFFF59E0B), Color(0xFFEA580C)]);
  static const kenji = YoloUser(id: 2002, name: 'Kenji', gender: 'male', avatarColors: [Color(0xFF0EA5E9), Color(0xFF6366F1)]);
  static const mia = YoloUser(id: 2003, name: 'Mia', avatarColors: [Color(0xFF10B981), Color(0xFF0EA5E9)]);
  static const omar = YoloUser(id: 2004, name: 'Omar', gender: 'male', avatarColors: [Color(0xFF6366F1), Color(0xFFA855F7)]);
  static const leo = YoloUser(id: 2005, name: 'Leo', gender: 'male', avatarColors: [Color(0xFFEF4444), Color(0xFFF59E0B)]);
}

const demoGiftCatalog = [
  Gift(id: 1, name: 'Rose', price: 1, icon: Icons.local_florist, tint: Color(0xFFFDA4AF)),
  Gift(id: 2, name: 'Heart', price: 10, icon: Icons.favorite, tint: Color(0xFFF9A8D4)),
  Gift(id: 9, name: 'Lollipop', price: 5, icon: Icons.cake, tint: Color(0xFFFBCFE8)),
  Gift(id: 10, name: 'Coffee', price: 20, icon: Icons.local_cafe, tint: Color(0xFFD6A77A)),
  Gift(id: 3, name: 'Crown', price: 520, icon: Icons.workspace_premium, tint: Color(0xFFFDE7A8), fullScreen: true),
  Gift(id: 4, name: 'Diamond', price: 999, icon: Icons.diamond, tint: Color(0xFF7DD3FC), fullScreen: true),
  Gift(id: 5, name: 'Rocket', price: 1999, icon: Icons.rocket_launch, tint: Color(0xFFD8B4FE), fullScreen: true),
  Gift(id: 6, name: 'Sports Car', price: 5200, icon: Icons.directions_car, tint: Color(0xFFFCA5A5), fullScreen: true),
  Gift(id: 11, name: 'Lucky Clover', price: 10, icon: Icons.eco, tint: Color(0xFF86EFAC), category: 'lucky'),
  Gift(id: 12, name: 'Lucky Star', price: 50, icon: Icons.star, tint: Color(0xFFFDE68A), category: 'lucky'),
  Gift(id: 13, name: 'Lucky Box', price: 100, icon: Icons.card_giftcard, tint: Color(0xFFFDBA74), category: 'lucky'),
  Gift(id: 14, name: 'VIP Rose', price: 99, icon: Icons.local_florist, tint: Color(0xFFF5C451), category: 'vip', vipLevel: 1),
  Gift(id: 15, name: 'VIP Throne', price: 8888, icon: Icons.chair, tint: Color(0xFFF5C451), category: 'vip', vipLevel: 5, fullScreen: true),
  Gift(id: 16, name: 'VIP Dragon', price: 18888, icon: Icons.local_fire_department, tint: Color(0xFFFB923C), category: 'vip', vipLevel: 7, fullScreen: true),
  Gift(id: 7, name: 'Ring', price: 9999, icon: Icons.radio_button_checked, tint: Color(0xFFFDE68A), fullScreen: true, category: 'special'),
  Gift(id: 8, name: 'Castle', price: 29999, icon: Icons.castle, tint: Color(0xFFC7D2FE), fullScreen: true, category: 'special'),
  Gift(id: 17, name: 'Galaxy', price: 52000, icon: Icons.auto_awesome, tint: Color(0xFFA5B4FC), fullScreen: true, category: 'special'),
];

class DemoRepository implements YoloRepository {
  @override
  Future<YoloUser> login({required String method, String? phone, String? otp}) async {
    await Future<void>.delayed(const Duration(milliseconds: 700));
    return DemoUsers.me;
  }

  @override
  Future<List<Room>> rooms({String tab = 'popular'}) async {
    await Future<void>.delayed(const Duration(milliseconds: 400));
    return const [
      Room(id: 884216, name: 'Late Night Talks', tag: 'Chat', online: 128, owner: DemoUsers.me,
          announcement: 'Welcome! Be kind, have fun. Mic requests are open.'),
      Room(id: 884217, name: 'Sing With Me', tag: 'Music', online: 96, owner: DemoUsers.kenji,
          cover: [Color(0xFF0EA5E9), Color(0xFF6366F1)]),
      Room(id: 884218, name: 'Ludo Champions', tag: 'Games', online: 74, owner: DemoUsers.zara,
          cover: [Color(0xFFF59E0B), Color(0xFFEA580C)]),
      Room(id: 884219, name: 'Friends Lounge', tag: 'Friends', online: 61, owner: DemoUsers.omar,
          cover: [Color(0xFF10B981), Color(0xFF0EA5E9)]),
      Room(id: 884220, name: 'Midnight Poetry', tag: 'Chat', online: 42, owner: DemoUsers.mia,
          cover: [Color(0xFFA855F7), Color(0xFFEC4899)]),
      Room(id: 884221, name: 'Who is the Spy?', tag: 'Games', online: 37, owner: DemoUsers.leo,
          cover: [Color(0xFFEF4444), Color(0xFF7C3AED)]),
      Room(id: 884222, name: 'VIP Lounge', tag: 'Private', online: 9, owner: DemoUsers.zara, password: '1234',
          cover: [Color(0xFF111827), Color(0xFFB45309)], seatCount: 12),
    ];
  }

  @override
  Future<List<Gift>> gifts() async => demoGiftCatalog;

  @override
  Future<void> saveRoomSettings(int roomId, Map<String, Object?> settings) async {}

  @override
  Future<String> uploadRoomBackground(int roomId, String filePath) async => filePath; // demo: the local file

  @override
  Future<void> rallyFans(int roomId, String message) async {}
}

// ---------------------------------------------------------------------------
// Laravel API (used when AppConfig.useDemoData == false)
// ---------------------------------------------------------------------------

class ApiRepository implements YoloRepository {
  ApiRepository()
      : _dio = Dio(BaseOptions(
          baseUrl: AppConfig.apiBaseUrl,
          connectTimeout: const Duration(seconds: 10),
          headers: {'Accept': 'application/json'},
        ));

  final Dio _dio;

  void setToken(String token) => _dio.options.headers['Authorization'] = 'Bearer $token';

  /// Unwraps the `{ success, data, message }` envelope.
  Future<dynamic> _data(Future<Response<dynamic>> call) async {
    final res = await call;
    final body = res.data as Map<String, dynamic>;
    if (body['success'] != true) throw Exception(body['message'] ?? 'Request failed');
    return body['data'];
  }

  @override
  Future<YoloUser> login({required String method, String? phone, String? otp}) async {
    final data = await _data(_dio.post('/auth/otp/verify', data: {'phone': phone, 'otp': otp}))
        as Map<String, dynamic>;
    setToken(data['token'] as String);
    return YoloUser.fromJson(data['user'] as Map<String, dynamic>);
  }

  @override
  Future<List<Room>> rooms({String tab = 'popular'}) async {
    final list = await _data(_dio.get('/rooms', queryParameters: {'tab': tab})) as List<dynamic>;
    return list.map((r) {
      final m = r as Map<String, dynamic>;
      return Room(
        id: m['id'] as int,
        name: m['name'] as String,
        tag: m['tag'] as String? ?? 'Chat',
        online: m['online_count'] as int? ?? 0,
        announcement: m['announcement'] as String? ?? '',
        owner: YoloUser.fromJson(m['owner'] as Map<String, dynamic>),
      );
    }).toList();
  }

  @override
  Future<void> saveRoomSettings(int roomId, Map<String, Object?> settings) => _data(_dio.patch('/rooms/$roomId/settings', data: settings));

  @override
  Future<String> uploadRoomBackground(int roomId, String filePath) async {
    final form = FormData.fromMap({'image': await MultipartFile.fromFile(filePath)});
    final data = await _data(_dio.post('/rooms/$roomId/background', data: form)) as Map<String, dynamic>;
    return data['url'] as String;
  }

  @override
  Future<void> rallyFans(int roomId, String message) => _data(_dio.post('/rooms/$roomId/rally', data: {'message': message}));

  @override
  Future<List<Gift>> gifts() async {
    final list = await _data(_dio.get('/gifts')) as List<dynamic>;
    return list.map((g) {
      final m = g as Map<String, dynamic>;
      return Gift(
        id: m['id'] as int,
        name: m['name'] as String,
        price: m['price'] as int,
        icon: Icons.card_giftcard,
        tint: const Color(0xFFFDE7A8),
        fullScreen: m['full_screen'] as bool? ?? false,
      );
    }).toList();
  }
}
