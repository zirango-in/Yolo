import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import 'core/theme.dart';
import 'data/models.dart';
import 'data/providers.dart';
import 'features/account/account_screen.dart';
import 'features/auth/email_login_screen.dart';
import 'features/auth/login_screen.dart';
import 'features/auth/phone_flow.dart';
import 'features/auth/register_screen.dart';
import 'features/auth/welcome_screen.dart';
import 'features/home/home_screen.dart';
import 'features/discover/discover_screen.dart';
import 'features/events/events_screen.dart';
import 'features/family/family_screen.dart';
import 'features/friends/friends_screen.dart';
import 'features/games/game_center_screen.dart';
import 'features/messages/messages_screen.dart';
import 'features/moments/moments_screen.dart';
import 'features/notifications/notifications_screen.dart';
import 'features/profile/avatar_studio_screen.dart';
import 'features/profile/edit_profile_screen.dart';
import 'features/profile/level_badges_screens.dart';
import 'features/profile/user_profile_screen.dart';
import 'features/room/create_room_screen.dart';
import 'features/room/room_screen.dart';
import 'features/settings/settings_screen.dart';
import 'features/shop/shop_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
    systemNavigationBarColor: YoloColors.bg,
  ));
  runApp(const ProviderScope(child: YoloApp()));
}

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/welcome',
    redirect: (context, state) {
      final loggedIn = ref.read(sessionProvider) != null;
      final loc = state.matchedLocation;
      final public = loc == '/welcome' || loc.startsWith('/login');
      if (!loggedIn && !public) return '/welcome';
      return null;
    },
    routes: [
      GoRoute(path: '/welcome', builder: (_, _) => const WelcomeScreen()),
      GoRoute(path: '/login', builder: (_, _) => const LoginScreen()),
      GoRoute(path: '/login/phone', builder: (_, state) => PhoneEntryScreen(purpose: state.extra as PhonePurpose? ?? PhonePurpose.login)),
      GoRoute(path: '/login/otp', builder: (_, state) {
        final (phone, purpose) = state.extra! as (String, PhonePurpose);
        return OtpScreen(phone: phone, purpose: purpose);
      }),
      GoRoute(path: '/login/register', builder: (_, _) => const RegisterScreen()),
      GoRoute(path: '/login/email', builder: (_, _) => const EmailLoginScreen()),
      GoRoute(path: '/login/recover', builder: (_, _) => const RecoveryScreen()),
      GoRoute(path: '/account', builder: (_, _) => const AccountScreen()),
      GoRoute(path: '/profile/edit', builder: (_, _) => const EditProfileScreen()),
      GoRoute(path: '/profile/avatar', builder: (_, _) => const AvatarStudioScreen()),
      GoRoute(path: '/profile/levels', builder: (_, _) => const LevelScreen()),
      GoRoute(path: '/profile/badges', builder: (_, _) => const BadgesScreen()),
      GoRoute(path: '/profile/achievements', builder: (_, _) => const BadgesScreen(initialTab: 1)),
      GoRoute(path: '/home', builder: (_, _) => const HomeShell()),
      GoRoute(path: '/room', builder: (_, state) => RoomScreen(room: state.extra! as Room)),
      GoRoute(path: '/room/create', builder: (_, _) => const CreateRoomScreen()),
      GoRoute(path: '/discover', builder: (_, _) => const DiscoverScreen()),
      GoRoute(path: '/games', builder: (_, _) => const GameCenterScreen()),
      GoRoute(path: '/friends', builder: (_, _) => const FriendsScreen()),
      GoRoute(path: '/chat', builder: (_, state) => ChatScreen(user: state.extra! as YoloUser)),
      GoRoute(path: '/user', builder: (_, state) => UserProfileScreen(user: state.extra! as YoloUser)),
      GoRoute(path: '/moments', builder: (_, _) => const MomentsScreen()),
      GoRoute(path: '/family', builder: (_, _) => const FamilyScreen()),
      GoRoute(path: '/events', builder: (_, _) => const EventsScreen()),
      GoRoute(path: '/shop', builder: (_, _) => const ShopScreen()),
      GoRoute(path: '/notifications', builder: (_, _) => const NotificationsScreen()),
      GoRoute(path: '/settings', builder: (_, _) => const SettingsScreen()),
    ],
  );
});

class YoloApp extends ConsumerWidget {
  const YoloApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp.router(
      title: 'Yolo',
      debugShowCheckedModeBanner: false,
      theme: buildYoloTheme(),
      routerConfig: ref.watch(routerProvider),
    );
  }
}
