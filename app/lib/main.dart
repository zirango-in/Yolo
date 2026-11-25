import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import 'core/theme.dart';
import 'data/models.dart';
import 'data/events_providers.dart';
import 'data/providers.dart';
import 'data/settings_providers.dart';
import 'data/social_providers.dart';
import 'features/account/account_screen.dart';
import 'features/auth/email_login_screen.dart';
import 'features/auth/login_screen.dart';
import 'features/auth/phone_flow.dart';
import 'features/auth/register_screen.dart';
import 'features/auth/welcome_screen.dart';
import 'features/home/home_screen.dart';
import 'features/discover/discover_screen.dart';
import 'features/events/events_screen.dart';
import 'features/family/family_pages.dart';
import 'features/family/family_screen.dart';
import 'features/friends/friends_screen.dart';
import 'features/games/game_center_screen.dart';
import 'features/gifts/gift_pages.dart';
import 'features/messages/messages_screen.dart';
import 'features/moments/create_post_screen.dart';
import 'features/moments/moments_screen.dart';
import 'data/demo_content.dart';
import 'features/music/music_pages.dart';
import 'features/notifications/notifications_screen.dart';
import 'data/music_providers.dart';
import 'features/profile/avatar_studio_screen.dart';
import 'features/profile/edit_profile_screen.dart';
import 'features/profile/level_badges_screens.dart';
import 'features/profile/user_profile_screen.dart';
import 'features/rankings/rankings_screen.dart';
import 'features/room/create_room_screen.dart';
import 'features/room/room_screen.dart';
import 'features/settings/settings_pages.dart';
import 'features/settings/settings_screen.dart';
import 'features/shop/shop_screen.dart';
import 'features/support/support_pages.dart';
import 'features/vip/vip_pages.dart';
import 'features/wallet/wallet_pages.dart';

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
      final public = loc == '/welcome' || loc.startsWith('/login') || loc.startsWith('/legal') || loc.startsWith('/support');
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
      GoRoute(path: '/rankings', builder: (_, state) => RankingsScreen(initialTab: state.extra as int? ?? 0)),
      GoRoute(path: '/discover', builder: (_, _) => const DiscoverScreen()),
      GoRoute(path: '/games', builder: (_, _) => const GameCenterScreen()),
      GoRoute(path: '/friends', builder: (_, _) => const FriendsScreen()),
      GoRoute(
        path: '/chat',
        builder: (_, state) => state.extra is GroupChat ? ChatScreen(group: state.extra! as GroupChat) : ChatScreen(user: state.extra! as YoloUser),
      ),
      GoRoute(path: '/chat/new-group', builder: (_, _) => const CreateGroupScreen()),
      GoRoute(path: '/friends/requests', builder: (_, _) => const FriendRequestsScreen()),
      GoRoute(path: '/friends/add', builder: (_, _) => const AddFriendsScreen()),
      GoRoute(path: '/blocked', builder: (_, _) => const BlockedUsersScreen()),
      GoRoute(path: '/user', builder: (_, state) => UserProfileScreen(user: state.extra! as YoloUser)),
      GoRoute(path: '/moments', builder: (_, _) => const MomentsScreen()),
      GoRoute(path: '/moments/new', builder: (_, _) => const CreatePostScreen()),
      GoRoute(path: '/moments/post', builder: (_, state) => PostDetailsScreen(moment: state.extra! as Moment)),
      GoRoute(path: '/moments/topic', builder: (_, state) => MomentsScreen(topic: state.extra as String?)),
      GoRoute(path: '/family', builder: (_, _) => const FamilyScreen()),
      GoRoute(path: '/family/create', builder: (_, _) => const CreateFamilyScreen()),
      GoRoute(path: '/family/profile', builder: (_, state) => FamilyProfileScreen(family: state.extra! as FamilyInfo)),
      GoRoute(path: '/family/quests', builder: (_, _) => const FamilyQuestsScreen()),
      GoRoute(path: '/family/gacha', builder: (_, _) => const FamilyGachaScreen()),
      GoRoute(path: '/family/shop', builder: (_, _) => const FamilyShopScreen()),
      GoRoute(path: '/family/members', builder: (_, _) => const FamilyMembersScreen()),
      GoRoute(path: '/family/ranking', builder: (_, _) => const FamilyRankingScreen()),
      GoRoute(path: '/events', builder: (_, _) => const EventsScreen()),
      GoRoute(path: '/events/detail', builder: (_, state) => EventDetailScreen(event: state.extra! as EventInfo)),
      GoRoute(path: '/missions', builder: (_, _) => const MissionsScreen()),
      GoRoute(path: '/music', builder: (_, _) => const MusicScreen()),
      GoRoute(path: '/music/karaoke', builder: (_, state) => KaraokeScreen(song: state.extra as Song?)),
      GoRoute(path: '/music/result', builder: (_, state) => SingResultScreen(result: state.extra! as SingResult)),
      GoRoute(path: '/music/room', builder: (_, _) => const SingingRoomScreen()),
      GoRoute(path: '/music/battle', builder: (_, _) => const SingingBattleScreen()),
      GoRoute(path: '/music/micgrab', builder: (_, _) => const MicGrabScreen()),
      GoRoute(path: '/music/upload', builder: (_, _) => const UploadMusicScreen()),
      GoRoute(path: '/shop', builder: (_, _) => const ShopScreen()),
      GoRoute(path: '/gifts', builder: (_, _) => const GiftStoreScreen()),
      GoRoute(path: '/gifts/history', builder: (_, _) => const GiftHistoryScreen()),
      GoRoute(path: '/gifts/ranking', builder: (_, _) => const GiftRankingScreen()),
      GoRoute(path: '/backpack', builder: (_, _) => const BackpackScreen()),
      GoRoute(path: '/wallet', builder: (_, _) => const WalletScreen()),
      GoRoute(path: '/vip', builder: (_, _) => const VipCenterScreen()),
      GoRoute(path: '/vip/manage', builder: (_, _) => const VipManageScreen()),
      GoRoute(path: '/vip/history', builder: (_, _) => const VipHistoryScreen()),
      GoRoute(path: '/wallet/transactions', builder: (_, _) => const TransactionsScreen()),
      GoRoute(path: '/wallet/purchases', builder: (_, _) => const PurchaseHistoryScreen()),
      GoRoute(path: '/rewards', builder: (_, _) => const RewardsScreen()),
      GoRoute(path: '/rewards/invite', builder: (_, _) => const InviteScreen()),
      GoRoute(path: '/notifications', builder: (_, _) => const NotificationsScreen()),
      GoRoute(path: '/settings', builder: (_, _) => const SettingsScreen()),
      GoRoute(path: '/settings/privacy', builder: (_, _) => const PrivacySettingsScreen()),
      GoRoute(path: '/settings/notifications', builder: (_, _) => const NotificationSettingsScreen()),
      GoRoute(path: '/settings/sound', builder: (_, _) => const SoundSettingsScreen()),
      GoRoute(path: '/settings/language', builder: (_, _) => const LanguageSettingsScreen()),
      GoRoute(path: '/settings/display', builder: (_, _) => const DisplaySettingsScreen()),
      GoRoute(path: '/settings/permissions', builder: (_, _) => const PermissionsScreen()),
      GoRoute(path: '/settings/storage', builder: (_, _) => const StorageScreen()),
      GoRoute(path: '/support', builder: (_, _) => const HelpCenterScreen()),
      GoRoute(path: '/support/chat', builder: (_, _) => const CustomerServiceScreen()),
      GoRoute(path: '/support/feedback', builder: (_, _) => const FeedbackScreen()),
      GoRoute(path: '/support/bug', builder: (_, _) => const BugReportScreen()),
      GoRoute(path: '/support/report', builder: (_, _) => const ReportIssueScreen()),
      GoRoute(path: '/support/tickets', builder: (_, _) => const TicketsScreen()),
      GoRoute(path: '/legal/:page', builder: (_, state) => LegalScreen(page: state.pathParameters['page']!)),
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
      // Apply text size, right-to-left languages and reduced motion app-wide.
      builder: (context, child) {
        final s = ref.watch(settingsProvider);
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(textScaler: TextScaler.linear(s.textScale), disableAnimations: s.reduceMotion),
          child: Directionality(textDirection: s.isRtl ? TextDirection.rtl : TextDirection.ltr, child: child!),
        );
      },
    );
  }
}
