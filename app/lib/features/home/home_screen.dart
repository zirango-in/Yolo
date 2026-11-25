import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../core/theme.dart';
import '../../data/models.dart';
import '../../data/providers.dart';
import '../../widgets/common.dart';
import '../games/game_center_screen.dart';
import '../messages/messages_screen.dart';
import '../profile/profile_screen.dart';
import '../room/room_sheets.dart';

/// Main shell with the premium bottom navigation.
class HomeShell extends ConsumerStatefulWidget {
  const HomeShell({super.key});

  @override
  ConsumerState<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends ConsumerState<HomeShell> {
  int _tab = 0;

  void _openMyRoom() => context.push('/room/create');

  @override
  Widget build(BuildContext context) {
    final pages = const [
      _RoomsTab(),
      GameCenterScreen(embedded: true),
      SizedBox.shrink(),
      MessagesScreen(),
      ProfileScreen(),
    ];
    return Scaffold(
      extendBody: true,
      body: AnimatedSwitcher(duration: 250.ms, child: KeyedSubtree(key: ValueKey(_tab), child: pages[_tab])),
      bottomNavigationBar: _BottomBar(
        index: _tab,
        onTap: (i) => i == 2 ? _openMyRoom() : setState(() => _tab = i),
      ),
    );
  }
}

class _BottomBar extends StatelessWidget {
  const _BottomBar({required this.index, required this.onTap});
  final int index;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    Widget item(int i, IconData icon, String label) {
      final active = i == index;
      return Expanded(
        child: InkResponse(
          onTap: () => onTap(i),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            AnimatedScale(
              scale: active ? 1.12 : 1,
              duration: 200.ms,
              child: Icon(icon, color: active ? YoloColors.gold : YoloColors.textMuted),
            ),
            const SizedBox(height: 4),
            Text(label,
                style: TextStyle(
                    fontSize: 11,
                    fontWeight: active ? FontWeight.w700 : FontWeight.w600,
                    color: active ? YoloColors.gold : YoloColors.textMuted)),
          ]),
        ),
      );
    }

    return Container(
      padding: EdgeInsets.only(bottom: MediaQuery.paddingOf(context).bottom + 8, top: 10),
      decoration: BoxDecoration(
        color: const Color(0xEB140D2A),
        border: Border(top: BorderSide(color: Colors.white.withValues(alpha: 0.06))),
      ),
      child: Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
        item(0, Icons.home_rounded, 'Home'),
        item(1, Icons.sports_esports_rounded, 'Games'),
        Expanded(
          child: Semantics(
            button: true,
            label: 'Open my room',
            child: GestureDetector(
              onTap: () => onTap(2),
              child: Transform.translate(
                offset: const Offset(0, -10),
                child: Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: YoloColors.goldGradient,
                    boxShadow: [BoxShadow(color: YoloColors.gold.withValues(alpha: 0.45), blurRadius: 24, offset: const Offset(0, 8))],
                  ),
                  child: const Icon(Icons.add_rounded, size: 30, color: YoloColors.onGold),
                ),
              ),
            ),
          ),
        ),
        item(3, Icons.chat_bubble_outline_rounded, 'Messages'),
        item(4, Icons.person_outline_rounded, 'Me'),
      ]),
    );
  }
}

class _RoomsTab extends ConsumerStatefulWidget {
  const _RoomsTab();

  @override
  ConsumerState<_RoomsTab> createState() => _RoomsTabState();
}

class _RoomsTabState extends ConsumerState<_RoomsTab> {
  static const _tabs = ['Popular', 'Following', 'New', 'Games'];
  int _tab = 0;

  @override
  Widget build(BuildContext context) {
    final me = ref.watch(sessionProvider);
    final rooms = ref.watch(roomsProvider(_tabs[_tab].toLowerCase())).whenData((l) => [...ref.watch(createdRoomsProvider), ...l]);

    return Stack(children: [
      Positioned(
        top: -120,
        right: -80,
        child: Container(
          width: 300,
          height: 300,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(colors: [YoloColors.purple.withValues(alpha: 0.35), YoloColors.purple.withValues(alpha: 0)]),
          ),
        ),
      ),
      SafeArea(
        bottom: false,
        child: RefreshIndicator(
          color: YoloColors.gold,
          onRefresh: () => ref.refresh(roomsProvider(_tabs[_tab].toLowerCase()).future),
          child: CustomScrollView(
            physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
                  child: Row(children: [
                    const Expanded(
                      child: Text('Yolo',
                          maxLines: 1,
                          overflow: TextOverflow.fade,
                          softWrap: false,
                          style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800, letterSpacing: -0.5, color: YoloColors.gold)),
                    ),
                    Flexible(child: FittedBox(fit: BoxFit.scaleDown, child: CoinPill(coins: me?.coins ?? 0))),
                    const SizedBox(width: 10),
                    GlassIconButton(icon: Icons.search_rounded, label: 'Search', onTap: () => context.push('/discover')),
                    const SizedBox(width: 10),
                    GlassIconButton(icon: Icons.notifications_none_rounded, label: 'Notifications', onTap: () => context.push('/notifications')),
                  ]),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 4, 20, 14),
                  child: Wrap(runSpacing: 8, children: [
                    for (var i = 0; i < _tabs.length; i++)
                      Padding(
                        padding: const EdgeInsets.only(right: 22),
                        child: GestureDetector(
                          onTap: () => setState(() => _tab = i),
                          child: AnimatedDefaultTextStyle(
                            duration: 200.ms,
                            style: TextStyle(
                              fontSize: i == _tab ? 17 : 15,
                              fontWeight: i == _tab ? FontWeight.w800 : FontWeight.w600,
                              color: i == _tab ? YoloColors.text : YoloColors.textMuted,
                              fontFamily: Theme.of(context).textTheme.bodyMedium?.fontFamily,
                            ),
                            child: Column(children: [
                              Text(_tabs[i]),
                              const SizedBox(height: 6),
                              AnimatedContainer(
                                duration: 200.ms,
                                height: 3,
                                width: i == _tab ? 28 : 0,
                                decoration: BoxDecoration(color: YoloColors.gold, borderRadius: BorderRadius.circular(2)),
                              ),
                            ]),
                          ),
                        ),
                      ),
                  ]),
                ),
              ),
              const SliverToBoxAdapter(child: _QuickEntries()),
              const SliverToBoxAdapter(child: _EventBanner()),
              const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(20, 18, 20, 12),
                  child: Text('Hot rooms', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
                ),
              ),
              rooms.when(
                loading: () => const SliverToBoxAdapter(
                  child: Padding(padding: EdgeInsets.all(40), child: Center(child: CircularProgressIndicator(color: YoloColors.gold))),
                ),
                error: (e, _) => SliverToBoxAdapter(
                  child: Padding(padding: const EdgeInsets.all(40), child: Center(child: Text('Could not load rooms\n$e', textAlign: TextAlign.center))),
                ),
                data: (list) => SliverPadding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 120),
                  sliver: SliverGrid.builder(
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      mainAxisSpacing: 12,
                      crossAxisSpacing: 12,
                      childAspectRatio: 0.92,
                    ),
                    itemCount: list.length,
                    itemBuilder: (_, i) => _RoomCard(room: list[i])
                        .animate()
                        .fadeIn(delay: (60 * i).ms, duration: 350.ms)
                        .slideY(begin: 0.15, end: 0, curve: Curves.easeOut),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    ]);
  }
}

/// Shortcut grid to the main sections.
class _QuickEntries extends StatelessWidget {
  const _QuickEntries();

  static const _items = [
    (Icons.explore_rounded, 'Discover', Color(0xFF7DD3FC), '/discover'),
    (Icons.celebration_rounded, 'Events', Color(0xFFFDA4AF), '/events'),
    (Icons.storefront_rounded, 'Shop', Color(0xFFF5C451), '/shop'),
    (Icons.groups_rounded, 'Family', Color(0xFFC4B5FD), '/family'),
    (Icons.photo_library_rounded, 'Moments', Color(0xFF86EFAC), '/moments'),
    (Icons.people_alt_rounded, 'Friends', Color(0xFF93C5FD), '/friends'),
    (Icons.sports_esports_rounded, 'Games', Color(0xFFFDBA74), '/games'),
    (Icons.settings_rounded, 'Settings', Color(0xFFD9D0F2), '/settings'),
  ];

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(12, 0, 12, 14),
        child: GridView.count(
          crossAxisCount: 4,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          childAspectRatio: 1.05,
          children: [
            for (final (i, (icon, label, color, route)) in _items.indexed)
              InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: () => context.push(route),
                child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                  Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(color: color.withValues(alpha: 0.16), borderRadius: BorderRadius.circular(15)),
                    child: Icon(icon, color: color, size: 24),
                  ),
                  const SizedBox(height: 6),
                  Text(label, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                ]),
              ).animate().fadeIn(delay: (30 * i).ms).scaleXY(begin: 0.85, end: 1, curve: Curves.easeOutBack),
          ],
        ),
      );
}

class _EventBanner extends StatelessWidget {
  const _EventBanner();

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            gradient: const LinearGradient(colors: [Color(0xFF6D28D9), Color(0xFFA21CAF)]),
            boxShadow: [BoxShadow(color: const Color(0xFF6D28D9).withValues(alpha: 0.35), blurRadius: 30, offset: const Offset(0, 12))],
          ),
          child: Row(children: [
            const Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('TONIGHT', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 1.2, color: Color(0xFFFDE7A8))),
                SizedBox(height: 4),
                Text('Ludo Party Night', style: TextStyle(fontSize: 19, fontWeight: FontWeight.w800)),
                SizedBox(height: 2),
                Text('Play with your room and win coins', style: TextStyle(fontSize: 13, color: Color(0xFFF1E6FF))),
              ]),
            ),
            GoldButton(label: 'Join', height: 40, onPressed: () {}),
          ]),
        ).animate(onPlay: (c) => c.repeat()).shimmer(delay: 3.seconds, duration: 1500.ms, color: Colors.white24),
      );
}

class _RoomCard extends ConsumerWidget {
  const _RoomCard({required this.room});
  final Room room;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Material(
      color: YoloColors.surface,
      borderRadius: BorderRadius.circular(20),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => openRoom(context, ref, room),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Expanded(
            child: Hero(
              tag: 'room-${room.id}',
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: room.cover, begin: Alignment.topLeft, end: Alignment.bottomRight),
                ),
                child: Stack(children: [
                  Center(
                    child: Text(room.name[0],
                        style: TextStyle(fontSize: 34, fontWeight: FontWeight.w800, color: Colors.white.withValues(alpha: 0.9))),
                  ),
                  Positioned(
                    top: 8,
                    left: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(color: YoloColors.bg.withValues(alpha: 0.6), borderRadius: BorderRadius.circular(11)),
                      child: Row(children: [
                        Container(
                          width: 6,
                          height: 6,
                          decoration: const BoxDecoration(color: YoloColors.online, shape: BoxShape.circle),
                        ).animate(onPlay: (c) => c.repeat(reverse: true)).fade(begin: 0.4, end: 1, duration: 800.ms),
                        const SizedBox(width: 5),
                        Text('${room.online}', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700)),
                      ]),
                    ),
                  ),
                  if (room.isPrivate)
                    const Positioned(top: 8, right: 8, child: Icon(Icons.lock_rounded, size: 18, color: YoloColors.gold)),
                ]),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(room.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
              const SizedBox(height: 4),
              Row(children: [
                Expanded(child: Text(room.owner.name, style: const TextStyle(fontSize: 12, color: YoloColors.textMuted))),
                Badge2(room.tag, fg: YoloColors.gold, bg: YoloColors.gold.withValues(alpha: 0.12)),
              ]),
            ]),
          ),
        ]),
      ),
    );
  }
}
