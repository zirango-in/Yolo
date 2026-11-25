import 'dart:io';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../core/theme.dart';
import '../../data/cp_providers.dart';
import '../../data/demo_content.dart';
import '../../data/models.dart';
import '../../data/profile_providers.dart';
import '../../data/providers.dart';
import '../../data/room_levels.dart';
import '../../data/social_providers.dart';
import '../../widgets/avatar_figure.dart';
import '../../widgets/common.dart';
import '../../widgets/page_kit.dart';
import 'room_sheets.dart';

Color roleColor(String role) => switch (role) {
      'Owner' => YoloColors.gold,
      'Co-owner' => const Color(0xFFF472B6),
      'Admin' => const Color(0xFF60A5FA),
      'Member' => const Color(0xFF86EFAC),
      _ => YoloColors.textMuted,
    };

IconData roleIcon(String role) => switch (role) {
      'Owner' => Icons.workspace_premium_rounded,
      'Co-owner' => Icons.stars_rounded,
      'Admin' => Icons.shield_rounded,
      'Member' => Icons.person_rounded,
      _ => Icons.person_outline_rounded,
    };

/// Small role pill (Owner / Co-owner / Admin / Member).
class RolePill extends StatelessWidget {
  const RolePill(this.role, {super.key});
  final String role;

  @override
  Widget build(BuildContext context) {
    final c = roleColor(role);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(color: c.withValues(alpha: 0.18), borderRadius: BorderRadius.circular(8)),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(roleIcon(role), size: 11, color: c),
        const SizedBox(width: 3),
        Text(role, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: c)),
      ]),
    );
  }
}

/// Level crown + number.
class LevelCrown extends StatelessWidget {
  const LevelCrown(this.level, {super.key});
  final int level;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
        decoration: BoxDecoration(gradient: const LinearGradient(colors: [Color(0xFFFDE68A), Color(0xFFF59E0B)]), borderRadius: BorderRadius.circular(8)),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          const Icon(Icons.emoji_events_rounded, size: 11, color: Color(0xFF7C2D12)),
          Text('$level', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: Color(0xFF7C2D12))),
        ]),
      );
}

/// Member title badge (room name in caps) shown on members' chat lines.
class MemberTitle extends StatelessWidget {
  const MemberTitle(this.room, {super.key});
  final String room;

  @override
  Widget build(BuildContext context) {
    final t = room.split(' ').first.toUpperCase();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [Color(0xFF9F1239), Color(0xFFF59E0B)]),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFFDE68A), width: 0.8),
      ),
      child: Text(t.length > 10 ? t.substring(0, 10) : t, style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w900, letterSpacing: 0.8, color: Colors.white)),
    );
  }
}

YoloUser roomUser(WidgetRef ref, int id) {
  final me = ref.read(sessionProvider);
  if (me != null && me.id == id) return me;
  return userById(id);
}

String _lastActive(int id) => const ['today', 'today', '3 days ago', '8 days ago', '9 days ago'][id % 5];

/// Room details (tap the room image or name): cover, name, Room ID, level, follow, settings,
/// share, owner / partner (co-owner) / admins, online & members, group and announcement.
void showRoomInfoSheet(BuildContext context, WidgetRef ref, Room room) {
  showRoomSheet<void>(
    context,
    (c) => Consumer(builder: (c, ref, _) {
      final st = ref.watch(roomProvider(room));
      final ctrl = ref.read(roomProvider(room).notifier);
      final look = st.look;
      final lvl = levelForExp(st.exp);
      final next = nextLevel(lvl);
      final staff = <int>{room.owner.id, ...st.coOwners, ...st.admins}.toList();
      final isOwner = ctrl.roleOf(ref.read(sessionProvider)!.id) == 'Owner';
      final group = ref.watch(groupsProvider).where((g) => g.id == st.groupId).firstOrNull;
      final levelColor = roomLevelColors(lvl.level).first;

      Widget countCard(String label, String value, Color color, VoidCallback onTap) => Expanded(
            child: Semantics(
              button: true,
              excludeSemantics: true,
              label: '$label $value',
              child: InkWell(
                borderRadius: BorderRadius.circular(14),
                onTap: onTap,
                child: Container(
                  height: 54,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: color.withValues(alpha: 0.35)),
                  ),
                  child: Row(children: [
                    Expanded(
                      child: Column(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(label, style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.w700)),
                        Text(value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: color, height: 1.15)),
                      ]),
                    ),
                    Icon(Icons.chevron_right_rounded, size: 18, color: color),
                  ]),
                ),
              ),
            ),
          );

      return SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: SizedBox(
                width: 64,
                height: 64,
                child: st.coverPath != null && !kIsWeb
                    ? Image.file(File(st.coverPath!), fit: BoxFit.cover)
                    : DecoratedBox(
                        decoration: BoxDecoration(gradient: LinearGradient(colors: room.cover)),
                        child: Center(child: Text(st.name[0], style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w900))),
                      ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(st.name, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, height: 1.2)),
                const SizedBox(height: 5),
                Wrap(spacing: 6, runSpacing: 4, crossAxisAlignment: WrapCrossAlignment.center, children: [
                  Container(
                    padding: const EdgeInsets.fromLTRB(2, 1, 6, 1),
                    decoration: BoxDecoration(color: levelColor.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(8)),
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      RoomLevelBadge(lvl.level, size: 14),
                      const SizedBox(width: 3),
                      Text('Level ${lvl.level}', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: levelColor)),
                    ]),
                  ),
                  Badge2(st.tag, bg: look.accent.withValues(alpha: 0.18), fg: look.accent),
                  InkWell(
                    onTap: () {
                      Clipboard.setData(ClipboardData(text: '${room.id}'));
                      showYoloToast(context, 'Room ID copied');
                    },
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      Text('Room ID: ${room.id}', style: const TextStyle(fontSize: 12, color: YoloColors.textMuted)),
                      const SizedBox(width: 3),
                      const Icon(Icons.copy_rounded, size: 12, color: YoloColors.textMuted),
                    ]),
                  ),
                ]),
              ]),
            ),
            IconButton(
              tooltip: 'Room settings',
              visualDensity: VisualDensity.compact,
              onPressed: () {
                if (!ctrl.canManage) {
                  showYoloToast(c, 'Only the owner and admins can open room settings');
                  return;
                }
                Navigator.pop(c);
                context.push('/room/settings', extra: room);
              },
              icon: const Icon(Icons.settings_rounded),
            ),
            IconButton(
              tooltip: 'Share room',
              visualDensity: VisualDensity.compact,
              onPressed: () {
                Navigator.pop(c);
                showInviteSheet(context, ref, room);
              },
              icon: const Icon(Icons.ios_share_rounded),
            ),
          ]),
          // Follow / unfollow lives here (not on the main room screen).
          if (!isOwner) ...[
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              height: 38,
              child: ctrl.isMember
                  ? OutlinedButton.icon(
                      onPressed: () {
                        ctrl.leaveMembership();
                        showYoloToast(context, 'Unfollowed ${st.name}');
                      },
                      icon: const Icon(Icons.check_rounded, size: 16),
                      label: const Text('Following'),
                      style: OutlinedButton.styleFrom(foregroundColor: YoloColors.textSoft),
                    )
                  : FilledButton.icon(
                      onPressed: () => showYoloToast(context, ctrl.join()),
                      icon: const Icon(Icons.add_rounded, size: 16),
                      label: const Text('Follow'),
                      style: FilledButton.styleFrom(backgroundColor: look.accent, foregroundColor: look.onAccent),
                    ),
            ),
          ],
          const SizedBox(height: 10),
          GlassCard(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
            onTap: () {
              Navigator.pop(c);
              context.push('/room/level', extra: room);
            },
            child: Row(children: [
              RoomLevelBadge(lvl.level, size: 30),
              const SizedBox(width: 10),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('Room level ${lvl.level}', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13)),
                  const SizedBox(height: 4),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: next == null ? 1 : ((st.exp - lvl.exp) / (next.exp - lvl.exp)).clamp(0.0, 1.0),
                      minHeight: 5,
                      color: levelColor,
                      backgroundColor: const Color(0x22FFFFFF),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(next == null ? 'Max level' : 'EXP ${formatCoins(st.exp)} / ${formatCoins(next.exp)}', style: const TextStyle(fontSize: 10.5, color: YoloColors.textMuted)),
                ]),
              ),
              const Icon(Icons.chevron_right_rounded),
            ]),
          ),
          const SizedBox(height: 12),
          const Text('Owner, partner & admins', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: YoloColors.textMuted)),
          const SizedBox(height: 6),
          SizedBox(
            height: 92,
            child: ListView(scrollDirection: Axis.horizontal, children: [
              for (final id in staff)
                Padding(
                  padding: const EdgeInsets.only(right: 12),
                  child: GestureDetector(
                    onTap: () {
                      Navigator.pop(c);
                      showUserCard(context, ref, room, roomUser(ref, id));
                    },
                    child: Column(mainAxisSize: MainAxisSize.min, children: [
                      YoloAvatar(user: roomUser(ref, id), size: 44, plain: true),
                      const SizedBox(height: 3),
                      SizedBox(width: 60, child: Text(roomUser(ref, id).name, maxLines: 1, overflow: TextOverflow.ellipsis, textAlign: TextAlign.center, style: const TextStyle(fontSize: 11))),
                      const SizedBox(height: 2),
                      RolePill(ctrl.roleOf(id) == 'Co-owner' ? 'Co-owner' : ctrl.roleOf(id)),
                    ]),
                  ),
                ),
            ]),
          ),
          const SizedBox(height: 8),
          Row(children: [
            countCard('Online', formatCoins(st.onlineCount), YoloColors.online, () {
              Navigator.pop(c);
              showMembersSheet(context, ref, room);
            }),
            const SizedBox(width: 10),
            countCard('Members', formatCoins(st.memberCount), look.accent, () {
              Navigator.pop(c);
              showMembersSheet(context, ref, room, tab: 1);
            }),
          ]),
          if (group != null) ...[
            const SizedBox(height: 8),
            ListTile(
              dense: true,
              contentPadding: EdgeInsets.zero,
              leading: Icon(Icons.forum_rounded, color: look.accent),
              title: Text('Group: ${group.name}', style: const TextStyle(fontWeight: FontWeight.w700)),
              trailing: const Icon(Icons.chevron_right_rounded),
              onTap: () {
                Navigator.pop(c);
                context.push('/chat', extra: group);
              },
            ),
          ],
          const SizedBox(height: 8),
          Row(children: [
            Text('Fans ${formatCoins(st.fans)}', style: const TextStyle(fontSize: 12, color: YoloColors.textMuted)),
            const SizedBox(width: 14),
            Text('Max members ${formatCoins(lvl.maxMembers)}', style: const TextStyle(fontSize: 12, color: YoloColors.textMuted)),
          ]),
          const SizedBox(height: 10),
          Text('Announcement', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: look.accent)),
          const SizedBox(height: 3),
          Text(st.announcement.isEmpty ? 'No announcement yet' : st.announcement, style: const TextStyle(fontSize: 13, height: 1.4)),
        ]),
      );
    }),
    scroll: true,
  );
}

/// Online / Members / Contribution sheet with search and member management.
void showMembersSheet(BuildContext context, WidgetRef ref, Room room, {int tab = 0}) {
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: YoloColors.sheet,
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
    builder: (c) => SizedBox(height: MediaQuery.sizeOf(context).height * 0.72, child: _MembersSheet(room: room, initialTab: tab, parent: context)),
  );
}

class _MembersSheet extends ConsumerStatefulWidget {
  const _MembersSheet({required this.room, required this.initialTab, required this.parent});
  final Room room;
  final int initialTab;
  final BuildContext parent;

  @override
  ConsumerState<_MembersSheet> createState() => _MembersSheetState();
}

class _MembersSheetState extends ConsumerState<_MembersSheet> {
  late int _tab = widget.initialTab;
  int _period = 0;
  String _q = '';

  void _manage(YoloUser u) {
    final ctrl = ref.read(roomProvider(widget.room).notifier);
    final st = ref.read(roomProvider(widget.room));
    final lvl = levelForExp(st.exp);
    showRoomSheet<void>(
      context,
      (c) => Column(mainAxisSize: MainAxisSize.min, children: [
        ListTile(leading: YoloAvatar(user: u, size: 40), title: Text(u.name, style: const TextStyle(fontWeight: FontWeight.w800))),
        if (ctrl.isOwner)
          ListTile(
            title: Center(child: Text(st.coOwners.contains(u.id) ? 'Remove co-owner' : 'Set as co-owner (${st.coOwners.length}/${lvl.coOwners})')),
            onTap: () {
              Navigator.pop(c);
              final err = ctrl.toggleCoOwner(u);
              if (err.isNotEmpty) showYoloToast(context, err);
            },
          ),
        ListTile(
          title: Center(
            child: Text(st.admins.contains(u.id) ? 'Remove admin' : 'Set as admin (${st.admins.length}/${lvl.admins})',
                style: TextStyle(color: st.admins.contains(u.id) ? const Color(0xFFF87171) : YoloColors.text)),
          ),
          onTap: () {
            Navigator.pop(c);
            final err = ctrl.toggleAdmin(u);
            if (err.isNotEmpty) showYoloToast(context, err);
          },
        ),
        ListTile(
          title: const Center(child: Text('Remove the member', style: TextStyle(color: Color(0xFFF87171)))),
          onTap: () {
            Navigator.pop(c);
            ctrl.removeMember(u);
            showYoloToast(context, '${u.name} removed from members');
          },
        ),
        ListTile(title: const Center(child: Text('Cancel', style: TextStyle(color: YoloColors.textMuted))), onTap: () => Navigator.pop(c)),
      ]),
    );
  }

  @override
  Widget build(BuildContext context) {
    final st = ref.watch(roomProvider(widget.room));
    final ctrl = ref.read(roomProvider(widget.room).notifier);
    final me = ref.watch(sessionProvider)!;
    final q = _q.trim().toLowerCase();
    bool match(YoloUser u) => q.isEmpty || u.name.toLowerCase().contains(q) || '${u.id}' == q;

    // People currently in the room (live: updates as users enter or leave).
    final onlineUsers = [for (final id in st.onlineIds) if (!st.banned.contains(id)) roomUser(ref, id)].where(match).toList();
    final memberUsers = <YoloUser>{if (st.members.contains(me.id)) me, ...demoAllUsers.where((u) => st.members.contains(u.id))}.where(match).toList()
      ..sort((a, b) => ['Owner', 'Co-owner', 'Admin', 'Member'].indexOf(ctrl.roleOf(a.id)).compareTo(['Owner', 'Co-owner', 'Admin', 'Member'].indexOf(ctrl.roleOf(b.id))));
    // Charms recorded in this room session (weekly / total history comes from the server:
    // GET /rooms/{id}/contributions?period=…).
    final contrib = [
      for (final e in st.contributions.entries) if (e.value > 0) (roomUser(ref, e.key), e.value),
    ]..sort((a, b) => b.$2.compareTo(a.$2));
    final myIndex = contrib.indexWhere((r) => r.$1.id == me.id);

    Widget row(YoloUser u, {Widget? trailing}) {
      final role = ctrl.roleOf(u.id);
      return ListTile(
        onTap: () {
          Navigator.pop(context);
          showUserCard(widget.parent, ref, widget.room, u);
        },
        leading: YoloAvatar(user: u, size: 46),
        title: Wrap(spacing: 6, crossAxisAlignment: WrapCrossAlignment.center, children: [
          if (role != 'Guest') RolePill(role),
          Text(u.id == me.id ? '${u.name} (you)' : u.name, style: const TextStyle(fontWeight: FontWeight.w700)),
          Icon(u.gender == 'female' ? Icons.female_rounded : Icons.male_rounded, size: 16, color: u.gender == 'female' ? const Color(0xFFF9A8D4) : const Color(0xFF60A5FA)),
        ]),
        subtitle: Padding(padding: const EdgeInsets.only(top: 4), child: Row(children: [LevelCrown(u.level + 7)])),
        trailing: trailing,
      );
    }

    final tabs = ['Online ${compactCount(st.onlineCount)}', 'Members ${formatCoins(st.memberCount)}', 'Contribution'];
    return Column(children: [
      const SizedBox(height: 10),
      Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2))),
      Row(children: [
        Expanded(child: YoloTabs(tabs: tabs, index: _tab, onChanged: (i) => setState(() => _tab = i), padding: const EdgeInsets.fromLTRB(16, 12, 0, 8))),
        if (ctrl.canManage)
          IconButton(
            tooltip: 'Room settings',
            icon: const Icon(Icons.manage_accounts_rounded),
            onPressed: () {
              Navigator.pop(context);
              widget.parent.push('/room/settings', extra: widget.room);
            },
          ),
      ]),
      if (_tab < 2)
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 6),
          child: TextField(
            onChanged: (v) => setState(() => _q = v),
            decoration: InputDecoration(
              hintText: 'Search nickname or ID',
              prefixIcon: const Icon(Icons.search_rounded),
              isDense: true,
              filled: true,
              fillColor: Colors.white.withValues(alpha: 0.07),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(24), borderSide: BorderSide.none),
            ),
          ),
        )
      else
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 6),
          child: Row(children: [
            for (final (i, p) in ['Daily', 'Weekly', 'Total'].indexed)
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: ChoiceChip(
                  label: Text(p),
                  selected: _period == i,
                  onSelected: (_) => setState(() => _period = i),
                  selectedColor: YoloColors.gold,
                  showCheckmark: false,
                  labelStyle: TextStyle(color: _period == i ? YoloColors.onGold : YoloColors.text, fontWeight: FontWeight.w700),
                ),
              ),
          ]),
        ),
      Expanded(
        child: switch (_tab) {
          0 => ListView(children: [
              for (final u in onlineUsers) row(u),
              if (st.listeners > 0 && q.isEmpty)
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text('+ ${formatCoins(st.listeners)} more listening', textAlign: TextAlign.center, style: const TextStyle(color: YoloColors.textMuted)),
                ),
            ]),
          1 => ListView(children: [
              for (final u in memberUsers)
                row(
                  u,
                  trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                    Text('Active\n${_lastActive(u.id)}', textAlign: TextAlign.right, style: const TextStyle(fontSize: 11, color: YoloColors.textMuted)),
                    if (ctrl.canManage && u.id != widget.room.owner.id && u.id != me.id)
                      IconButton(tooltip: 'Manage ${u.name}', icon: const Icon(Icons.more_vert_rounded), onPressed: () => _manage(u)),
                  ]),
                ),
            ]),
          _ => ListView(children: [
              for (final (i, (u, coins)) in contrib.indexed)
                row(u, trailing: Text('${formatCoins(coins)}\nCharms', textAlign: TextAlign.right, style: TextStyle(fontWeight: FontWeight.w800, color: i == 0 ? const Color(0xFFF0ABFC) : YoloColors.text))),
            ]),
        },
      ),
      if (_tab == 2)
        Container(
          color: Colors.white.withValues(alpha: 0.04),
          child: SafeArea(
            top: false,
            child: ListTile(
              leading: YoloAvatar(user: me, size: 42),
              title: Text(myIndex >= 0 ? 'My rank #${myIndex + 1}' : 'Not ranked yet', style: const TextStyle(fontWeight: FontWeight.w800)),
              trailing: Text(myIndex >= 0 ? '${formatCoins(contrib[myIndex].$2)} Charms' : 'Send a gift to rank', style: const TextStyle(color: Color(0xFFF0ABFC), fontWeight: FontWeight.w700)),
            ),
          ),
        ),
    ]);
  }
}

/// Tap a person in the room: avatar banner with CP, badges, ID, @mention and gift.
void showUserCard(BuildContext context, WidgetRef ref, Room room, YoloUser u, {ValueChanged<String>? onMention, VoidCallback? onGift}) {
  final ctrl = ref.read(roomProvider(room).notifier);
  final st = ref.read(roomProvider(room));
  final me = ref.read(sessionProvider);
  final role = ctrl.roleOf(u.id);
  final isMe = me?.id == u.id;
  final cp = ref.read(cpProvider.notifier).coupleOf(u.id);
  final cfg = isMe
      ? ref.read(profileExtrasProvider).avatar
      : AvatarConfig(skin: u.id % 5, hair: 1 + u.id % 5, hairColor: u.id % 6, outfit: u.id % 4, outfitColor: (u.id ~/ 3) % 6, accessory: u.id % 6);
  showDialog<void>(
    context: context,
    builder: (c) => Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Container(
          height: 150,
          decoration: const BoxDecoration(
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            gradient: LinearGradient(colors: [Color(0xFF4C1D95), Color(0xFF9D174D)], begin: Alignment.topLeft, end: Alignment.bottomRight),
          ),
          child: Stack(children: [
            Center(child: AvatarFigure(config: cfg, size: 130, background: const [Color(0x00000000), Color(0x00000000)]).animate().scale(curve: Curves.easeOutBack)),
            if (cp != null)
            Positioned(
              right: 10,
              bottom: 12,
              child: Container(
                padding: const EdgeInsets.fromLTRB(10, 4, 4, 4),
                decoration: BoxDecoration(color: Colors.black38, borderRadius: BorderRadius.circular(20)),
                child: Row(children: [
                  const Text('CP ', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: Color(0xFFF9A8D4))),
                  YoloAvatar(user: cp, size: 28),
                ]),
              ),
            ),
          ]),
        ),
        Container(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
          decoration: const BoxDecoration(color: YoloColors.sheet, borderRadius: BorderRadius.vertical(bottom: Radius.circular(24))),
          child: Column(children: [
            Row(children: [
              YoloAvatar(user: u, size: 64, goldFrame: role == 'Owner'),
              const SizedBox(width: 12),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Wrap(spacing: 6, crossAxisAlignment: WrapCrossAlignment.center, children: [
                    if (role != 'Guest') RolePill(role),
                    Text(u.name, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
                  ]),
                  const SizedBox(height: 4),
                  Wrap(spacing: 6, children: [LevelCrown(u.level + 7), if (st.members.contains(u.id)) MemberTitle(st.name)]),
                  const SizedBox(height: 4),
                  InkWell(
                    onTap: () {
                      Clipboard.setData(ClipboardData(text: '${u.id}'));
                      showYoloToast(context, 'ID copied');
                    },
                    child: Text('ID: ${u.id}', style: const TextStyle(color: YoloColors.textMuted, fontSize: 12)),
                  ),
                ]),
              ),
            ]),
            const SizedBox(height: 18),
            Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
              Column(children: [
                IconButton.filled(
                  tooltip: 'Mention ${u.name}',
                  style: IconButton.styleFrom(backgroundColor: const Color(0xFF3B82F6), minimumSize: const Size(60, 60)),
                  icon: const Icon(Icons.alternate_email_rounded, color: Colors.white),
                  onPressed: () {
                    Navigator.pop(c);
                    onMention?.call('@${u.name} ');
                  },
                ),
                const SizedBox(height: 4),
                const Text('Mention', style: TextStyle(fontSize: 12)),
              ]),
              Column(children: [
                IconButton.filled(
                  tooltip: 'Profile of ${u.name}',
                  style: IconButton.styleFrom(backgroundColor: const Color(0xFF8B5CF6), minimumSize: const Size(60, 60)),
                  icon: const Icon(Icons.person_rounded, color: Colors.white),
                  onPressed: () {
                    Navigator.pop(c);
                    if (!isMe) context.push('/user', extra: u);
                  },
                ),
                const SizedBox(height: 4),
                const Text('Profile', style: TextStyle(fontSize: 12)),
              ]),
              if (!isMe)
                Column(children: [
                  IconButton.filled(
                    tooltip: 'Gift ${u.name}',
                    style: IconButton.styleFrom(backgroundColor: const Color(0xFFF43F5E), minimumSize: const Size(60, 60)),
                    icon: const Icon(Icons.card_giftcard_rounded, color: Colors.white),
                    onPressed: () {
                      Navigator.pop(c);
                      onGift?.call();
                    },
                  ),
                  const SizedBox(height: 4),
                  const Text('Gift', style: TextStyle(fontSize: 12)),
                ]),
            ]),
          ]),
        ),
      ]),
    ),
  );
}

/// Emoji button: mini interactions + animated stickers (shown on your seat).
void showInteractionPanel(BuildContext context, WidgetRef ref, Room room) {
  const games = [
    ('lottery', 'Lottery', Icons.confirmation_number_rounded, Color(0xFFF59E0B)),
    ('rps', 'Rock paper scissors', Icons.back_hand_rounded, Color(0xFFFDBA74)),
    ('dice', 'Dice', Icons.casino_rounded, Color(0xFFEF4444)),
    ('light', 'Light burst', Icons.flare_rounded, Color(0xFFF472B6)),
    ('coin', 'Toss a coin', Icons.toll_rounded, Color(0xFFFDE68A)),
  ];
  const stickers = [
    ('Wave', Icons.waving_hand_rounded), ('Thanks', Icons.volunteer_activism_rounded), ('Tears of joy', Icons.sentiment_very_satisfied_rounded),
    ('Cheer up', Icons.celebration_rounded), ('Kiss', Icons.favorite_rounded), ('My love', Icons.favorite_border_rounded), ('DJ', Icons.headphones_rounded),
    ('Bow', Icons.self_improvement_rounded), ('Confused', Icons.help_rounded), ('Tongue', Icons.sentiment_satisfied_alt_rounded),
    ('Shocked', Icons.sentiment_neutral_rounded), ('Sob', Icons.sentiment_very_dissatisfied_rounded), ('Angry', Icons.mood_bad_rounded),
  ];
  showRoomSheet<void>(
    context,
    (c) {
      void pick(String kind, {String? sticker}) {
        Navigator.pop(c);
        final ctrl = ref.read(roomProvider(room).notifier);
        if (ctrl.mySeat < 0) showYoloToast(context, 'Tip: take a seat to show it on the mic');
        ctrl.interact(kind, sticker: sticker);
      }

      Widget tile(String label, IconData icon, Color color, VoidCallback onTap) => InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: onTap,
            child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              Icon(icon, size: 34, color: color),
              const SizedBox(height: 4),
              Text(label, maxLines: 1, overflow: TextOverflow.ellipsis, textAlign: TextAlign.center, style: const TextStyle(fontSize: 11)),
            ]),
          );

      return SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(12, 16, 12, 12),
        child: GridView.count(
          crossAxisCount: 5,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          childAspectRatio: 0.95,
          children: [
            for (final (k, label, icon, color) in games) tile(label, icon, color, () => pick(k)),
            for (final (label, icon) in stickers) tile(label, icon, const Color(0xFF7DD3FC), () => pick('sticker', sticker: label)),
          ],
        ),
      );
    },
    scroll: true,
  );
}

/// Send a red packet (coins split randomly among grabbers).
void showRedPacketSheet(BuildContext context, WidgetRef ref, Room room) {
  var total = 100;
  var count = 5;
  showRoomSheet<void>(
    context,
    (c) => StatefulBuilder(
      builder: (c, setState) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Row(children: [
            Icon(Icons.mail_rounded, color: Color(0xFFEF4444), size: 30),
            SizedBox(width: 10),
            Text('Send a red packet', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
          ]),
          const SizedBox(height: 6),
          const Text('Coins are split randomly. Everyone in the room can grab one share.', style: TextStyle(color: YoloColors.textMuted)),
          const SizedBox(height: 14),
          const Text('Total coins', style: TextStyle(fontWeight: FontWeight.w700)),
          Wrap(spacing: 8, children: [
            for (final t in [100, 500, 1000, 5000])
              ChoiceChip(
                label: Text(formatCoins(t)),
                selected: total == t,
                onSelected: (_) => setState(() => total = t),
                selectedColor: YoloColors.gold,
                showCheckmark: false,
                labelStyle: TextStyle(color: total == t ? YoloColors.onGold : YoloColors.text, fontWeight: FontWeight.w700),
              ),
          ]),
          const SizedBox(height: 10),
          const Text('Number of shares', style: TextStyle(fontWeight: FontWeight.w700)),
          Wrap(spacing: 8, children: [
            for (final n in [5, 10, 20])
              ChoiceChip(
                label: Text('$n'),
                selected: count == n,
                onSelected: (_) => setState(() => count = n),
                selectedColor: YoloColors.gold,
                showCheckmark: false,
                labelStyle: TextStyle(color: count == n ? YoloColors.onGold : YoloColors.text, fontWeight: FontWeight.w700),
              ),
          ]),
          const SizedBox(height: 16),
          GoldButton(
            label: 'Send $total coins',
            onPressed: () {
              Navigator.pop(c);
              final err = ref.read(roomProvider(room).notifier).sendRedPacket(total, count);
              showYoloToast(context, err.isEmpty ? 'Red packet sent!' : err);
            },
          ),
        ]),
      ),
    ),
  );
}

/// Open a red packet envelope.
void showGrabRedPacket(BuildContext context, WidgetRef ref, Room room, RedPacket p) {
  showDialog<void>(
    context: context,
    builder: (c) => Consumer(builder: (c, ref, _) {
      final live = ref.watch(roomProvider(room)).redPackets.firstWhere((x) => x.id == p.id, orElse: () => p);
      final meId = ref.read(sessionProvider)?.id;
      final mine = live.grabbed[meId];
      return Dialog(
        backgroundColor: const Color(0xFFB91C1C),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            YoloAvatar(user: live.from, size: 56),
            const SizedBox(height: 8),
            Text("${live.from.name}'s red packet", style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Color(0xFFFDE68A))),
            const SizedBox(height: 6),
            Text('${formatCoins(live.total)} coins · ${live.grabbed.length}/${live.grabbed.length + live.left.length} grabbed', style: const TextStyle(color: Color(0xFFFECACA))),
            const SizedBox(height: 18),
            if (mine != null)
              Text('You got $mine coins!', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Color(0xFFFDE68A))).animate().scale(curve: Curves.elasticOut)
            else if (live.empty)
              const Text('All shares are gone', style: TextStyle(color: Color(0xFFFECACA)))
            else
              GestureDetector(
                onTap: () => ref.read(roomProvider(room).notifier).grabRedPacket(p.id),
                child: Container(
                  width: 96,
                  height: 96,
                  decoration: const BoxDecoration(shape: BoxShape.circle, gradient: YoloColors.goldGradient),
                  alignment: Alignment.center,
                  child: const Text('OPEN', style: TextStyle(fontWeight: FontWeight.w900, color: Color(0xFF7C2D12), fontSize: 18)),
                ),
              ).animate(onPlay: (x) => x.repeat(reverse: true)).scaleXY(end: 1.08, duration: 600.ms),
            const SizedBox(height: 16),
            for (final e in live.grabbed.entries)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Row(children: [
                  Expanded(child: Text(roomUser(ref, e.key).name, style: const TextStyle(color: Colors.white))),
                  Text('${e.value}', style: const TextStyle(color: Color(0xFFFDE68A), fontWeight: FontWeight.w800)),
                ]),
              ),
          ]),
        ),
      );
    }),
  );
}

/// Daily treasure boxes: time in the room opens boxes; tasks cut 1 minute each.
void showTreasureSheet(BuildContext context, WidgetRef ref, Room room) {
  showRoomSheet<void>(
    context,
    (c) => Consumer(builder: (c, ref, _) {
      final st = ref.watch(roomProvider(room));
      final ctrl = ref.read(roomProvider(room).notifier);
      final vip = (ref.watch(sessionProvider)?.vipLevel ?? 0) > 0;
      final secs = ctrl.treasureProgress;
      return SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            const Expanded(child: Text('Daily treasure', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900))),
            IconButton(tooltip: 'Close', icon: const Icon(Icons.close_rounded), onPressed: () => Navigator.pop(c)),
          ]),
          const Text('Stay in the voice room to open the boxes.', style: TextStyle(color: YoloColors.textMuted)),
          const SizedBox(height: 14),
          GridView.count(
            crossAxisCount: 3,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            childAspectRatio: 0.9,
            children: [
              for (var i = 0; i < treasureMinutes.length; i++)
                Builder(builder: (_) {
                  final need = treasureMinutes[i] * 60;
                  final claimed = st.claimedBoxes.contains(i);
                  final ready = secs >= need;
                  final vipBox = treasureVipOnly.contains(i);
                  final label = claimed ? 'Claimed' : (vipBox && !vip ? 'VIP only' : (ready ? 'Open' : '${((need - secs) / 60).ceil()} min'));
                  return GlassCard(
                    padding: const EdgeInsets.all(8),
                    border: vipBox ? YoloColors.gold.withValues(alpha: 0.6) : null,
                    onTap: () {
                      final r = ctrl.claimBox(i);
                      showYoloToast(context, switch (r) { -1 => 'Not ready yet', -2 => 'VIP only box', -3 => 'Already claimed', _ => '+$r coins' });
                    },
                    child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                      Icon(claimed ? Icons.inventory_2_rounded : Icons.redeem_rounded, size: 36, color: vipBox ? YoloColors.gold : const Color(0xFF7DD3FC))
                          .animate(target: ready && !claimed ? 1 : 0, onPlay: (x) => x.repeat(reverse: true))
                          .scaleXY(end: 1.12, duration: 500.ms),
                      const SizedBox(height: 4),
                      Text(vipBox ? 'VIP · ${treasureCoins[i]}' : '${treasureCoins[i]} coins', style: const TextStyle(fontSize: 11, color: YoloColors.textMuted)),
                      Text(label, style: TextStyle(fontWeight: FontWeight.w800, color: claimed ? YoloColors.textMuted : (ready ? YoloColors.online : YoloColors.text))),
                    ]),
                  );
                }),
            ],
          ),
          const SizedBox(height: 16),
          const Text('Every task you complete cuts 1 minute off the countdown', style: TextStyle(fontWeight: FontWeight.w800)),
          const SizedBox(height: 8),
          for (final (label, icon, done, action) in [
            ('Join this voice room', Icons.add_home_rounded, ctrl.isMember, 'join'),
            ('Send a gift once', Icons.card_giftcard_rounded, st.sentGift, 'gift'),
            ('Send a message once', Icons.chat_bubble_rounded, st.sentMessage, 'chat'),
          ])
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(icon, color: YoloColors.gold),
              title: Text(label),
              trailing: done
                  ? const Text('Done', style: TextStyle(color: YoloColors.textMuted, fontWeight: FontWeight.w700))
                  : OutlinedButton(
                      onPressed: () {
                        Navigator.pop(c);
                        if (action == 'join') showYoloToast(context, ctrl.join());
                      },
                      child: const Text('Go'),
                    ),
            ),
        ]),
      );
    }),
    scroll: true,
  );
}
