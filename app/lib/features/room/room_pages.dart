import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:material_ui/material_ui.dart';

import '../../core/theme.dart';
import '../../data/models.dart';
import '../../data/providers.dart';
import '../../data/room_levels.dart';
import '../../data/social_providers.dart';
import '../../widgets/common.dart';
import '../../widgets/page_kit.dart';
import 'room_panels.dart';
import 'room_sheets.dart';
import 'room_theme_sheet.dart';

/// Room level: badge, EXP progress, today's tasks and the level explanation table.
class RoomLevelScreen extends ConsumerStatefulWidget {
  const RoomLevelScreen({super.key, required this.room});
  final Room room;

  @override
  ConsumerState<RoomLevelScreen> createState() => _RoomLevelScreenState();
}

class _RoomLevelScreenState extends ConsumerState<RoomLevelScreen> {
  int _tab = 0;

  @override
  Widget build(BuildContext context) {
    final st = ref.watch(roomProvider(widget.room));
    final me = ref.watch(sessionProvider)!;
    final lvl = levelForExp(st.exp);
    final next = nextLevel(lvl);
    final playExp = (st.watchSecs ~/ 300) * roomExpPerFiveMinutes * (me.vipLevel > 0 ? 2 : 1) + 10;
    final giftExp = ((st.contributions[me.id] ?? 0) / 10).ceil();

    Widget cell(String t, {bool head = false}) => Container(
          width: 108,
          height: head ? 44 : 50,
          alignment: Alignment.center,
          decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: Color(0x14FFFFFF)), right: BorderSide(color: Color(0x14FFFFFF)))),
          child: Text(t, textAlign: TextAlign.center, style: TextStyle(fontSize: head ? 11 : 13, color: head ? YoloColors.textMuted : YoloColors.text, fontWeight: head ? FontWeight.w600 : FontWeight.w700)),
        );

    return YoloPage(
      title: 'Room level',
      body: ListView(padding: const EdgeInsets.fromLTRB(16, 4, 16, 40), children: [
        GlassCard(
          padding: const EdgeInsets.all(20),
          gradient: LinearGradient(colors: [roomLevelColors(lvl.level).last.withValues(alpha: 0.5), YoloColors.surface]),
          child: Column(children: [
            RoomLevelBadge(lvl.level, size: 92),
            const SizedBox(height: 16),
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(
                value: next == null ? 1 : ((st.exp - lvl.exp) / (next.exp - lvl.exp)).clamp(0.0, 1.0),
                minHeight: 10,
                color: roomLevelColors(lvl.level).first,
                backgroundColor: const Color(0x22FFFFFF),
              ),
            ),
            const SizedBox(height: 6),
            Row(children: [
              Text('Lv${lvl.level}', style: const TextStyle(fontWeight: FontWeight.w800)),
              const Spacer(),
              Text(next == null ? formatCoins(st.exp) : '${formatCoins(st.exp)} / ${formatCoins(next.exp)}', style: TextStyle(color: roomLevelColors(lvl.level).first, fontWeight: FontWeight.w700)),
              const Spacer(),
              Text(next == null ? 'MAX' : 'Lv${next.level}', style: const TextStyle(fontWeight: FontWeight.w800)),
            ]),
          ]),
        ),
        const SizedBox(height: 14),
        Center(
          child: SegmentedButton<int>(
            showSelectedIcon: false,
            segments: const [ButtonSegment(value: 0, label: Text('Tasks today')), ButtonSegment(value: 1, label: Text('Level explanation'))],
            selected: {_tab},
            onSelectionChanged: (v) => setState(() => _tab = v.first),
          ),
        ),
        const SizedBox(height: 14),
        if (_tab == 0) ...[
          for (final (title, rule, mine, cap) in [
            ('Stay in the voice room', '5 minutes = $roomExpPerFiveMinutes EXP (double for VIP)', playExp, roomExpDailyCapPlay),
            ('Send gifts or red packets', '10 coins = 1 EXP', giftExp, roomExpDailyCapGifts),
          ])
            GlassCard(
              margin: const EdgeInsets.only(bottom: 10),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  Expanded(child: Text(title, style: const TextStyle(fontWeight: FontWeight.w800))),
                  Text('My contribution: $mine', style: const TextStyle(fontSize: 12, color: YoloColors.textMuted)),
                ]),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(value: (mine / cap).clamp(0.0, 1.0), minHeight: 6, color: YoloColors.gold, backgroundColor: const Color(0x22FFFFFF)),
                ),
                const SizedBox(height: 6),
                Row(children: [
                  Expanded(child: Text(rule, style: const TextStyle(fontSize: 12, color: YoloColors.textMuted))),
                  Text('$mine/${formatCoins(cap)}', style: const TextStyle(fontSize: 12, color: YoloColors.textMuted)),
                ]),
              ]),
            ),
          const SizedBox(height: 6),
          const Text(
            '1. Room EXP updates once per hour. EXP is not counted while the room is locked with a password.\n'
            '2. Each room can earn up to 85,000 EXP per day.',
            style: TextStyle(fontSize: 12, color: YoloColors.textMuted, height: 1.6),
          ),
        ] else
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Container(
              decoration: BoxDecoration(borderRadius: BorderRadius.circular(14), border: Border.all(color: const Color(0x14FFFFFF))),
              child: Column(children: [
                Row(children: [for (final h in ['Level', 'EXP', 'Members', 'Admins', 'Co-owners', 'Promo cards', 'Background', 'Guest seat']) cell(h, head: true)]),
                for (final l in roomLevels)
                  Container(
                    color: l.level == lvl.level ? YoloColors.gold.withValues(alpha: 0.08) : null,
                    child: Row(children: [
                      SizedBox(width: 108, height: 50, child: Center(child: RoomLevelBadge(l.level, size: 30))),
                      cell(l.exp == 0 ? '-' : '${formatCoins(l.exp ~/ 1000)}k'),
                      cell('${l.maxMembers ~/ 1000}k'),
                      cell('${l.admins}'),
                      cell(l.coOwners == 0 ? '-' : '${l.coOwners}'),
                      cell('${l.recommendCards}'),
                      cell(l.background ?? '-'),
                      SizedBox(
                        width: 108,
                        height: 50,
                        child: Icon(l.guestSeat ? Icons.check_circle_rounded : Icons.cancel_rounded, color: l.guestSeat ? YoloColors.online : const Color(0xFFF87171)),
                      ),
                    ]),
                  ),
              ]),
            ),
          ),
      ]),
    );
  }
}

/// Full room settings page (owner, co-owners and admins).
class RoomSettingsScreen extends ConsumerWidget {
  const RoomSettingsScreen({super.key, required this.room});
  final Room room;

  Future<String?> _text(BuildContext context, String title, String initial, {int max = 30, int lines = 1, bool digits = false}) {
    final ctrl = TextEditingController(text: initial);
    return showDialog<String>(
      context: context,
      builder: (c) => AlertDialog(
        backgroundColor: YoloColors.sheet,
        title: Text(title),
        content: TextField(
          key: Key('room-setting-$title'),
          controller: ctrl,
          autofocus: true,
          maxLength: max,
          maxLines: lines,
          keyboardType: digits ? TextInputType.number : null,
          inputFormatters: digits ? [FilteringTextInputFormatter.digitsOnly] : null,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c), child: const Text('Cancel')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: YoloColors.gold, foregroundColor: YoloColors.onGold),
            onPressed: () => Navigator.pop(c, ctrl.text.trim()),
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  Future<T?> _choose<T>(BuildContext context, String title, List<(T, String)> options, T current) => showRoomSheet<T>(
        context,
        (c) => SingleChildScrollView(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Padding(padding: const EdgeInsets.all(16), child: Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800))),
            for (final (v, label) in options)
              ListTile(
                title: Text(label),
                trailing: v == current ? const Icon(Icons.check_circle_rounded, color: YoloColors.gold) : null,
                onTap: () => Navigator.pop(c, v),
              ),
            const SizedBox(height: 8),
          ]),
        ),
        scroll: true,
      );

  void _people(BuildContext context, WidgetRef ref, String title, Set<int> ids, String empty, void Function(int) onRemove, {String action = 'Remove'}) {
    showRoomSheet<void>(
      context,
      (c) => Consumer(builder: (c, ref, _) {
        ref.watch(roomProvider(room));
        return Column(mainAxisSize: MainAxisSize.min, children: [
          Padding(padding: const EdgeInsets.all(16), child: Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800))),
          if (ids.isEmpty) Padding(padding: const EdgeInsets.all(20), child: Text(empty, style: const TextStyle(color: YoloColors.textMuted))),
          for (final id in ids)
            ListTile(
              leading: YoloAvatar(user: roomUser(ref, id), size: 40),
              title: Text(roomUser(ref, id).name),
              trailing: TextButton(
                onPressed: () {
                  onRemove(id);
                  Navigator.pop(c);
                },
                child: Text(action, style: const TextStyle(color: Color(0xFFF87171))),
              ),
            ),
          const SizedBox(height: 8),
        ]);
      }),
      scroll: true,
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final st = ref.watch(roomProvider(room));
    final ctrl = ref.read(roomProvider(room).notifier);
    final lvl = levelForExp(st.exp);
    final groups = ref.watch(groupsProvider);

    Widget row(String label, String value, VoidCallback onTap, {Widget? lead}) => ListTile(
          title: Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
          trailing: Row(mainAxisSize: MainAxisSize.min, children: [
            ?lead,
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 150),
              child: Text(value, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: YoloColors.textMuted)),
            ),
            const Icon(Icons.chevron_right_rounded, color: YoloColors.textMuted),
          ]),
          onTap: onTap,
        );
    Widget toggle(String label, bool value, ValueChanged<bool> onChanged, {String? subtitle}) => SwitchListTile(
          title: Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
          subtitle: subtitle == null ? null : Text(subtitle, style: const TextStyle(fontSize: 12, color: YoloColors.textMuted)),
          value: value,
          activeThumbColor: YoloColors.gold,
          onChanged: onChanged,
        );
    Widget card(List<Widget> children) => GlassCard(margin: const EdgeInsets.fromLTRB(16, 0, 16, 12), padding: EdgeInsets.zero, child: Column(children: children));

    return YoloPage(
      title: 'Room settings',
      body: ListView(padding: const EdgeInsets.only(top: 4, bottom: 40), children: [
        card([
          row('Title', st.name, () async {
            final v = await _text(context, 'Title', st.name);
            if (v != null && v.length >= 2) ctrl.updateSettings(name: v);
          }),
          row('Cover', st.coverPath == null ? 'Default' : 'Photo', () async {
            try {
              final img = await ImagePicker().pickImage(source: ImageSource.gallery, maxWidth: 800, imageQuality: 85);
              if (img != null) ctrl.updateSettings(coverPath: img.path);
            } catch (_) {
              if (context.mounted) showYoloToast(context, 'Could not open gallery');
            }
          }),
          row('Announcement', st.announcement.isEmpty ? 'Not set' : st.announcement, () async {
            final v = await _text(context, 'Announcement', st.announcement, max: 200, lines: 3);
            if (v != null) ctrl.updateSettings(announcement: v);
          }),
          row('Room mode', RoomState.roomModeNames[st.roomMode]!, () async {
            final v = await _choose(context, 'Room mode', [for (final m in RoomState.roomModes) (m, RoomState.roomModeNames[m]!)], st.roomMode);
            if (v != null) {
              final msg = ctrl.setRoomMode(v);
              if (msg.isNotEmpty && context.mounted) showYoloToast(context, msg);
            }
          }),
          row('Tag', st.tag, () async {
            final v = await _choose(context, 'Tag', [for (final t in RoomState.tags) (t, t)], st.tag);
            if (v != null) ctrl.updateSettings(tag: v);
          }),
          row('Theme & background', st.bgPath != null ? 'My photo' : RoomState.themeNames[st.theme], () => showRoomThemeSheet(context, ref, room)),
          row('Mic mode', st.applyMode ? 'Request to join' : 'Free', () async {
            final v = await _choose(context, 'Mic mode', const [(false, 'Free — anyone can take a seat'), (true, 'Request — host approves')], st.applyMode);
            if (v != null) ctrl.updateSettings(applyMode: v);
          }),
        ]),
        card([
          toggle('Partner seat', st.mode == 'intimacy', (v) => ctrl.updateSettings(mode: v ? 'intimacy' : 'normal'), subtitle: 'Seat next to the host, works in any room mode'),
          toggle('High quality mode', st.highQuality, (v) => ctrl.updateSettings(highQuality: v), subtitle: 'Better voice, uses more data'),
          toggle('Ban text chatting', st.banText, (v) => ctrl.updateSettings(banText: v), subtitle: 'Only admins can chat'),
          toggle('No images', st.noImages, (v) => ctrl.updateSettings(noImages: v)),
          toggle('Ban red packet', st.banRedPacket, (v) => ctrl.updateSettings(banRedPacket: v)),
        ]),
        card([
          toggle('Password', st.password.isNotEmpty, (v) async {
            if (!v) {
              ctrl.updateSettings(password: '');
              return;
            }
            final p = await _text(context, 'Room password (4–6 digits)', '', max: 6, digits: true);
            if (p != null && p.length >= 4) {
              ctrl.updateSettings(password: p);
            } else if (context.mounted) {
              showYoloToast(context, 'Password must be 4–6 digits');
            }
          }),
          toggle('Manage events', st.manageEvent, (v) => ctrl.updateSettings(manageEvent: v), subtitle: 'Admins can create and delete room events in the Event Center'),
        ]),
        card([
          row('Membership fee', st.fee == 0 ? 'Free' : '${st.fee} coins', () async {
            final v = await _choose(context, 'Membership fee', const [(0, 'Free'), (100, '100 coins'), (500, '500 coins'), (1000, '1,000 coins')], st.fee);
            if (v != null) ctrl.updateSettings(fee: v);
          }),
          row('Co-owner', '${st.coOwners.length}/${lvl.coOwners}', () => _people(context, ref, 'Co-owners', st.coOwners, 'Set co-owners from the members list (unlocks at room level 5).', (id) => ctrl.toggleCoOwner(roomUser(ref, id)))),
          row('Admin', '${st.admins.length}/${lvl.admins}', () => _people(context, ref, 'Admins', st.admins, 'No admins yet.', (id) => ctrl.toggleAdmin(roomUser(ref, id)))),
          row('Blacklist', '${st.banned.length}', () => _people(context, ref, 'Blacklist', st.banned, 'Nobody is banned.', ctrl.unban, action: 'Unban')),
          row('Records', '${st.records.length}', () {
            showRoomSheet<void>(
              context,
              (c) => SizedBox(
                height: 360,
                child: Column(children: [
                  const Padding(padding: EdgeInsets.all(16), child: Text('Room records', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800))),
                  Expanded(
                    child: st.records.isEmpty
                        ? const Center(child: Text('No records yet', style: TextStyle(color: YoloColors.textMuted)))
                        : ListView(children: [for (final r in st.records) ListTile(dense: true, title: Text(r, style: const TextStyle(fontSize: 13)))]),
                  ),
                ]),
              ),
              scroll: true,
            );
          }),
        ]),
        card([
          row('Associated group', groups.where((g) => g.id == st.groupId).firstOrNull?.name ?? 'None', () async {
            final v = await _choose<int>(context, 'Associated group', [(0, 'None'), for (final g in groups) (g.id, g.name)], st.groupId ?? 0);
            if (v != null) ctrl.updateSettings(groupId: v);
          }),
          row('Room ID', '${room.id}', () {
            Clipboard.setData(ClipboardData(text: '${room.id}'));
            showYoloToast(context, 'Room ID copied');
          }),
        ]),
      ]),
    );
  }
}
