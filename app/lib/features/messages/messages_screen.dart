import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:material_ui/material_ui.dart';

import '../../core/theme.dart';
import '../../data/demo_content.dart';
import '../../data/models.dart';
import '../../data/social_providers.dart';
import '../../widgets/common.dart';
import '../../widgets/page_kit.dart';
import '../room/room_sheets.dart';

/// Inbox tab: shortcuts, groups and conversations.
class MessagesScreen extends ConsumerWidget {
  const MessagesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final read = ref.watch(readNotificationsProvider);
    final blocked = ref.watch(blockedProvider);
    final requests = ref.watch(incomingRequestsProvider);
    final groups = ref.watch(groupsProvider);
    final unreadNotes = [for (final (i, n) in demoNotifications.indexed) if (n.unread && !read.contains(i)) i].length;
    final convos = demoConversations.where((c) => !blocked.contains(c.user.id)).toList();

    Widget shortcut(IconData icon, String label, Color color, String route, {int badge = 0}) => Expanded(
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () => context.push(route),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Column(children: [
                Badge(isLabelVisible: badge > 0, label: Text('$badge'), child: TintIcon(icon, color: color, size: 48)),
                const SizedBox(height: 6),
                Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
              ]),
            ),
          ),
        );

    Widget dot(int id) => onlineIds.contains(id)
        ? Positioned(
            right: 2,
            bottom: 2,
            child: Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(color: YoloColors.online, shape: BoxShape.circle, border: Border.all(color: YoloColors.bg, width: 2)),
            ),
          )
        : const SizedBox.shrink();

    return SafeArea(
      bottom: false,
      child: ListView(padding: const EdgeInsets.only(bottom: 120), children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 14, 12, 8),
          child: Row(children: [
            const Expanded(child: Text('Messages', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800))),
            IconButton(tooltip: 'New group', icon: const Icon(Icons.group_add_rounded), onPressed: () => context.push('/chat/new-group')),
            IconButton(tooltip: 'Add friends', icon: const Icon(Icons.person_add_alt_1_rounded), onPressed: () => context.push('/friends/add')),
          ]),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Row(children: [
            shortcut(Icons.notifications_rounded, 'Notices', const Color(0xFFF5C451), '/notifications', badge: unreadNotes),
            shortcut(Icons.person_add_rounded, 'Requests', const Color(0xFF7DD3FC), '/friends/requests', badge: requests.length),
            shortcut(Icons.people_alt_rounded, 'Friends', const Color(0xFF86EFAC), '/friends'),
            shortcut(Icons.groups_rounded, 'Family', const Color(0xFFC4B5FD), '/family'),
          ]),
        ),
        if (groups.isNotEmpty) const SectionTitle('Groups'),
        for (final g in groups)
          ListTile(
            onTap: () => context.push('/chat', extra: g),
            leading: Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(borderRadius: BorderRadius.circular(16), gradient: const LinearGradient(colors: [Color(0xFF6366F1), Color(0xFFEC4899)])),
              child: const Icon(Icons.groups_rounded, color: Colors.white),
            ),
            title: Text(g.name, style: const TextStyle(fontWeight: FontWeight.w700)),
            subtitle: Text('${g.members.length + 1} members', style: const TextStyle(color: YoloColors.textMuted)),
          ),
        const SectionTitle('Chats'),
        for (final (i, c) in convos.indexed)
          ListTile(
            onTap: () => context.push('/chat', extra: c.user),
            leading: Stack(children: [YoloAvatar(user: c.user, size: 52), dot(c.user.id)]),
            title: Text(c.user.name, style: const TextStyle(fontWeight: FontWeight.w700)),
            subtitle: Text(c.last, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: YoloColors.textMuted)),
            trailing: Column(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.end, children: [
              Text(c.time, style: const TextStyle(fontSize: 11, color: YoloColors.textMuted)),
              const SizedBox(height: 4),
              if (c.unread > 0)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                  decoration: BoxDecoration(color: const Color(0xFFEF4444), borderRadius: BorderRadius.circular(10)),
                  child: Text('${c.unread}', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800)),
                ),
            ]),
          ).entrance(i),
      ]),
    );
  }
}

/// 1-to-1 chat (pass a [YoloUser]) or group chat (pass a [GroupChat]).
class ChatScreen extends ConsumerStatefulWidget {
  const ChatScreen({super.key, this.user, this.group}) : assert(user != null || group != null);
  final YoloUser? user;
  final GroupChat? group;

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final _input = TextEditingController();
  DateTime? _recordStart;
  Timer? _recordTimer;
  int _recordSecs = 0;

  String get _key => widget.group != null ? 'g:${widget.group!.id}' : 'u:${widget.user!.id}';
  ChatController get _chat => ref.read(chatProvider(_key).notifier);

  @override
  void dispose() {
    _input.dispose();
    _recordTimer?.cancel();
    super.dispose();
  }

  void _send() {
    _chat.send(_input.text);
    _input.clear();
    setState(() {});
  }

  Future<void> _pickImage() async {
    try {
      final img = await ImagePicker().pickImage(source: ImageSource.gallery, maxWidth: 1600, imageQuality: 85);
      if (img != null) _chat.sendImage(img.path);
    } catch (_) {
      if (mounted) showYoloToast(context, 'Could not open gallery');
    }
  }

  void _startRecord() {
    setState(() {
      _recordStart = DateTime.now();
      _recordSecs = 0;
    });
    _recordTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() => _recordSecs++);
    });
  }

  void _stopRecord({bool cancel = false}) {
    _recordTimer?.cancel();
    final start = _recordStart;
    setState(() => _recordStart = null);
    if (start == null || cancel) return;
    _chat.sendVoice(DateTime.now().difference(start).inSeconds);
  }

  void _menu() {
    final u = widget.user;
    final blocked = u != null && ref.read(blockedProvider).contains(u.id);
    showRoomSheet<void>(
      context,
      (c) => Column(mainAxisSize: MainAxisSize.min, children: [
        if (u != null) ListTile(leading: const Icon(Icons.person_rounded), title: const Text('View profile'), onTap: () {
          Navigator.pop(c);
          context.push('/user', extra: u);
        }),
        if (widget.group != null)
          ListTile(
            leading: const Icon(Icons.groups_rounded),
            title: Text('Members: ${widget.group!.members.map((id) => userById(id).name).join(', ')}'),
          ),
        ListTile(
          leading: const Icon(Icons.delete_sweep_rounded),
          title: const Text('Clear chat history'),
          onTap: () {
            Navigator.pop(c);
            _chat.clear();
            showYoloToast(context, 'Chat history cleared');
          },
        ),
        if (u != null)
          ListTile(
            leading: Icon(blocked ? Icons.lock_open_rounded : Icons.block_rounded, color: const Color(0xFFF87171)),
            title: Text(blocked ? 'Unblock ${u.name}' : 'Block ${u.name}', style: const TextStyle(color: Color(0xFFF87171))),
            onTap: () {
              Navigator.pop(c);
              ref.read(blockedProvider.notifier).toggle(u.id);
              showYoloToast(context, blocked ? '${u.name} unblocked' : '${u.name} blocked');
            },
          ),
        if (u != null)
          ListTile(leading: const Icon(Icons.flag_rounded), title: const Text('Report user'), onTap: () {
            Navigator.pop(c);
            showReportSheet(context, 'user');
          }),
        const SizedBox(height: 8),
      ]),
    );
  }

  @override
  Widget build(BuildContext context) {
    final messages = ref.watch(chatProvider(_key));
    final u = widget.user;
    final blocked = u != null && ref.watch(blockedProvider).contains(u.id);
    final title = widget.group?.name ?? u!.name;
    final subtitle = widget.group != null ? '${widget.group!.members.length + 1} members' : presence(u!.id);

    return YoloPage(
      title: title,
      actions: [IconButton(tooltip: 'Chat options', icon: const Icon(Icons.more_vert_rounded), onPressed: _menu)],
      body: Column(children: [
        Text(subtitle, style: TextStyle(fontSize: 12, color: subtitle == 'Online' ? YoloColors.online : YoloColors.textMuted)),
        Expanded(
          child: messages.isEmpty
              ? const EmptyState(icon: Icons.chat_bubble_outline_rounded, title: 'No messages yet', subtitle: 'Say hello!')
              : ListView.builder(
                  reverse: true,
                  padding: const EdgeInsets.all(16),
                  itemCount: messages.length,
                  itemBuilder: (_, i) => _Bubble(m: messages[messages.length - 1 - i], showSender: widget.group != null),
                ),
        ),
        if (blocked)
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(children: [
                Expanded(child: Text('You blocked ${u.name}.', style: const TextStyle(color: YoloColors.textMuted))),
                TextButton(onPressed: () => ref.read(blockedProvider.notifier).remove(u.id), child: const Text('Unblock', style: TextStyle(color: YoloColors.gold))),
              ]),
            ),
          )
        else
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(8, 4, 8, 10),
              // The mic button stays mounted while recording so releasing it sends the message.
              child: Row(children: [
                if (_recordStart != null)
                  Expanded(
                    child: Container(
                      height: 52,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(color: const Color(0x33EF4444), borderRadius: BorderRadius.circular(26)),
                      child: Row(children: [
                        const Icon(Icons.fiber_manual_record_rounded, color: Color(0xFFEF4444))
                            .animate(onPlay: (c) => c.repeat(reverse: true))
                            .fade(begin: 0.3, end: 1, duration: 500.ms),
                        const SizedBox(width: 8),
                        Text('Recording… 0:${_recordSecs.toString().padLeft(2, '0')}', style: const TextStyle(fontWeight: FontWeight.w700)),
                        const Spacer(),
                        const Flexible(child: Text('Release to send', overflow: TextOverflow.ellipsis, style: TextStyle(color: YoloColors.textMuted, fontSize: 12))),
                      ]),
                    ),
                  )
                else ...[
                  IconButton(tooltip: 'Send photo', icon: const Icon(Icons.image_outlined), onPressed: _pickImage),
                  Expanded(
                    child: TextField(
                      controller: _input,
                      onChanged: (_) => setState(() {}),
                      onSubmitted: (_) => _send(),
                      textInputAction: TextInputAction.send,
                      decoration: InputDecoration(
                        hintText: 'Message',
                        filled: true,
                        fillColor: Colors.white.withValues(alpha: 0.08),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(24), borderSide: BorderSide.none),
                      ),
                    ),
                  ),
                ],
                if (_recordStart == null && _input.text.trim().isNotEmpty)
                  IconButton(tooltip: 'Send', icon: const Icon(Icons.send_rounded, color: YoloColors.gold), onPressed: _send)
                else
                  Semantics(
                    button: true,
                    label: 'Hold to record voice message',
                    child: GestureDetector(
                      onLongPressStart: (_) => _startRecord(),
                      onLongPressEnd: (_) => _stopRecord(),
                      onLongPressCancel: () => _stopRecord(cancel: true),
                      onTap: () => showYoloToast(context, 'Hold the mic to record'),
                      child: AnimatedScale(
                        scale: _recordStart != null ? 1.3 : 1,
                        duration: 150.ms,
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Icon(Icons.mic_rounded, color: _recordStart != null ? const Color(0xFFEF4444) : YoloColors.gold),
                        ),
                      ),
                    ),
                  ),
                    ]),
            ),
          ),
      ]),
    );
  }
}

class _Bubble extends StatefulWidget {
  const _Bubble({required this.m, required this.showSender});
  final ChatMessage m;
  final bool showSender;

  @override
  State<_Bubble> createState() => _BubbleState();
}

class _BubbleState extends State<_Bubble> {
  bool _playing = false;

  @override
  Widget build(BuildContext context) {
    final m = widget.m;
    final fg = m.mine ? YoloColors.onGold : YoloColors.text;
    Widget content;
    switch (m.kind) {
      case ChatKind.image:
        content = ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: m.imagePath != null && !kIsWeb
              ? Image.file(File(m.imagePath!), width: 200, height: 200, fit: BoxFit.cover,
                  errorBuilder: (_, _, _) => const SizedBox(width: 200, height: 200, child: Icon(Icons.broken_image_rounded)))
              : Container(width: 200, height: 160, color: Colors.black26, child: const Icon(Icons.image_rounded, size: 48)),
        );
      case ChatKind.voice:
        content = InkWell(
          onTap: () async {
            setState(() => _playing = true);
            await Future<void>.delayed(Duration(seconds: m.seconds));
            if (mounted) setState(() => _playing = false);
          },
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Icon(_playing ? Icons.pause_rounded : Icons.play_arrow_rounded, color: fg),
            const SizedBox(width: 6),
            for (var i = 0; i < 12; i++)
              Container(
                width: 3,
                height: 6.0 + (i * 7 % 14),
                margin: const EdgeInsets.symmetric(horizontal: 1.5),
                decoration: BoxDecoration(color: fg.withValues(alpha: 0.8), borderRadius: BorderRadius.circular(2)),
              ).animate(target: _playing ? 1 : 0, onPlay: (c) => c.repeat(reverse: true)).scaleY(begin: 1, end: 0.4, duration: (200 + i * 30).ms),
            const SizedBox(width: 8),
            Text('${m.seconds}"', style: TextStyle(color: fg, fontWeight: FontWeight.w700)),
          ]),
        );
      case ChatKind.text:
        content = Text(m.text, style: TextStyle(color: fg, fontSize: 14));
    }

    return Align(
      alignment: m.mine ? Alignment.centerRight : Alignment.centerLeft,
      child: Column(crossAxisAlignment: m.mine ? CrossAxisAlignment.end : CrossAxisAlignment.start, children: [
        if (widget.showSender && !m.mine && m.sender.isNotEmpty)
          Padding(padding: const EdgeInsets.only(left: 8, bottom: 2), child: Text(m.sender, style: const TextStyle(fontSize: 11, color: YoloColors.textMuted))),
        Container(
          margin: const EdgeInsets.only(bottom: 10),
          constraints: const BoxConstraints(maxWidth: 280),
          padding: m.kind == ChatKind.image ? const EdgeInsets.all(4) : const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            gradient: m.mine ? YoloColors.goldGradient : null,
            color: m.mine ? null : YoloColors.surface,
            borderRadius: BorderRadius.only(
              topLeft: const Radius.circular(18),
              topRight: const Radius.circular(18),
              bottomLeft: Radius.circular(m.mine ? 18 : 4),
              bottomRight: Radius.circular(m.mine ? 4 : 18),
            ),
          ),
          child: Column(crossAxisAlignment: CrossAxisAlignment.end, mainAxisSize: MainAxisSize.min, children: [
            content,
            const SizedBox(height: 2),
            Text(m.time, style: TextStyle(fontSize: 10, color: m.mine ? const Color(0x991A1200) : YoloColors.textMuted)),
          ]),
        ),
      ]),
    ).animate().fadeIn(duration: 200.ms).slideY(begin: 0.2, end: 0);
  }
}
