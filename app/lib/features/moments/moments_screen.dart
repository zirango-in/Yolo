import 'dart:io';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../core/theme.dart';
import '../../data/demo_content.dart';
import '../../data/moments_providers.dart';
import '../../data/providers.dart';
import '../../data/social_providers.dart';
import '../../widgets/common.dart';
import '../../widgets/page_kit.dart';
import '../room/room_sheets.dart';

class MomentsScreen extends ConsumerStatefulWidget {
  const MomentsScreen({super.key, this.topic});
  final String? topic;

  @override
  ConsumerState<MomentsScreen> createState() => _MomentsScreenState();
}

class _MomentsScreenState extends ConsumerState<MomentsScreen> {
  late int _tab = widget.topic != null ? 2 : 0;
  late String _topic = widget.topic ?? allTopics.first;

  @override
  Widget build(BuildContext context) {
    final all = ref.watch(momentsProvider);
    final following = ref.watch(followingProvider);
    final topics = ref.watch(followedTopicsProvider);
    final blocked = ref.watch(blockedProvider);
    final list = feedFor(all, _tab, following, topics, _topic, blocked, meId: ref.watch(sessionProvider)?.id);

    return YoloPage(
      title: 'Moments',
      actions: [
        IconButton(tooltip: 'New post', icon: const Icon(Icons.add_circle_rounded, color: YoloColors.gold, size: 30), onPressed: () => context.push('/moments/new')),
      ],
      bottom: Column(children: [
        YoloTabs(tabs: const ['Trending', 'Following', 'Topics'], index: _tab, onChanged: (i) => setState(() => _tab = i)),
        if (_tab == 2)
          SizedBox(
            height: 44,
            child: ListView(scrollDirection: Axis.horizontal, padding: const EdgeInsets.symmetric(horizontal: 16), children: [
              for (final t in allTopics)
                Padding(
                  padding: const EdgeInsets.only(right: 8, bottom: 6),
                  child: ChoiceChip(
                    label: Text(t),
                    selected: _topic == t,
                    onSelected: (_) => setState(() => _topic = t),
                    selectedColor: YoloColors.gold,
                    showCheckmark: false,
                    labelStyle: TextStyle(color: _topic == t ? YoloColors.onGold : YoloColors.text, fontWeight: FontWeight.w700),
                  ),
                ),
            ]),
          ),
        if (_tab == 2)
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
            child: Row(children: [
              Expanded(child: Text('$_topic · ${list.length} posts', style: const TextStyle(color: YoloColors.textMuted))),
              OutlinedButton(
                onPressed: () => ref.read(followedTopicsProvider.notifier).toggle(_topic),
                style: OutlinedButton.styleFrom(shape: const StadiumBorder(), foregroundColor: YoloColors.gold),
                child: Text(topics.contains(_topic) ? 'Following topic' : 'Follow topic'),
              ),
            ]),
          ),
      ]),
      body: list.isEmpty
          ? EmptyState(
              icon: Icons.photo_library_rounded,
              title: 'No posts yet',
              subtitle: _tab == 1 ? 'Follow people or topics to see their moments here.' : 'Be the first to post!',
            )
          : ListView.builder(
              padding: const EdgeInsets.only(bottom: 40),
              itemCount: list.length,
              itemBuilder: (_, i) => MomentCard(moment: list[i]).entrance(i),
            ),
    );
  }
}

/// Shows the post media: real photos / video, or the demo gradient image.
class MomentMedia extends StatelessWidget {
  const MomentMedia({super.key, required this.m, this.height = 180});
  final Moment m;
  final double height;

  Widget _file(String path) => !kIsWeb
      ? Image.file(File(path), fit: BoxFit.cover, errorBuilder: (_, _, _) => const ColoredBox(color: Colors.black26, child: Icon(Icons.broken_image_rounded)))
      : const ColoredBox(color: Colors.black26, child: Icon(Icons.image_rounded));

  @override
  Widget build(BuildContext context) {
    if (m.video != null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: Container(
          height: height,
          color: Colors.black54,
          alignment: Alignment.center,
          child: const Column(mainAxisSize: MainAxisSize.min, children: [
            Icon(Icons.play_circle_fill_rounded, size: 56, color: Colors.white),
            SizedBox(height: 6),
            Text('Video', style: TextStyle(color: Colors.white70)),
          ]),
        ),
      );
    }
    if (m.images.isNotEmpty) {
      if (m.images.length == 1) {
        return ClipRRect(borderRadius: BorderRadius.circular(14), child: SizedBox(height: height, width: double.infinity, child: _file(m.images.first)));
      }
      return GridView.count(
        crossAxisCount: 3,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        mainAxisSpacing: 4,
        crossAxisSpacing: 4,
        children: [for (final p in m.images) ClipRRect(borderRadius: BorderRadius.circular(8), child: _file(p))],
      );
    }
    if (m.photo != null) {
      return Container(
        height: height,
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(14), gradient: LinearGradient(colors: m.photo!)),
        alignment: Alignment.center,
        child: const Icon(Icons.image_rounded, size: 48, color: Colors.white54),
      );
    }
    return const SizedBox.shrink();
  }
}

/// A post in the feed with like / comment / share / more.
class MomentCard extends ConsumerWidget {
  const MomentCard({super.key, required this.moment, this.inDetails = false});
  final Moment moment;
  final bool inDetails;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final m = moment;
    final liked = ref.watch(likedMomentsProvider);
    final isLiked = liked.contains(m.id);
    final comments = ref.watch(commentsProvider(m.id)).length;
    final isMine = m.author.id == ref.watch(sessionProvider)?.id;

    void more() {
      showRoomSheet<void>(
        context,
        (c) => Column(mainAxisSize: MainAxisSize.min, children: [
          ListTile(
            leading: const Icon(Icons.link_rounded),
            title: const Text('Copy link'),
            onTap: () {
              Clipboard.setData(ClipboardData(text: 'https://yolo.app/moment/${m.id}'));
              Navigator.pop(c);
              showYoloToast(context, 'Link copied');
            },
          ),
          if (isMine)
            ListTile(
              leading: const Icon(Icons.delete_rounded, color: Color(0xFFF87171)),
              title: const Text('Delete post', style: TextStyle(color: Color(0xFFF87171))),
              onTap: () {
                Navigator.pop(c);
                ref.read(momentsProvider.notifier).delete(m.id);
                showYoloToast(context, 'Post deleted');
                if (inDetails) context.pop();
              },
            )
          else
            ListTile(
              leading: const Icon(Icons.flag_rounded),
              title: const Text('Report post'),
              onTap: () {
                Navigator.pop(c);
                showReportSheet(context, 'post');
              },
            ),
          const SizedBox(height: 8),
        ]),
      );
    }

    void share() {
      final friends = ref.read(friendsProvider);
      showRoomSheet<void>(
        context,
        (c) => Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Padding(padding: EdgeInsets.fromLTRB(20, 18, 20, 8), child: Text('Share to', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800))),
          SizedBox(
            height: 96,
            child: ListView(scrollDirection: Axis.horizontal, padding: const EdgeInsets.symmetric(horizontal: 16), children: [
              for (final u in friends)
                InkWell(
                  onTap: () {
                    ref.read(chatProvider('u:${u.id}').notifier).send('Check out this moment: https://yolo.app/moment/${m.id}');
                    Navigator.pop(c);
                    showYoloToast(context, 'Shared with ${u.name}');
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Column(children: [YoloAvatar(user: u, size: 52), const SizedBox(height: 4), Text(u.name, style: const TextStyle(fontSize: 12))]),
                  ),
                ),
            ]),
          ),
          ListTile(
            leading: const Icon(Icons.link_rounded, color: YoloColors.gold),
            title: const Text('Copy link'),
            onTap: () {
              Clipboard.setData(ClipboardData(text: 'https://yolo.app/moment/${m.id}'));
              Navigator.pop(c);
              showYoloToast(context, 'Link copied');
            },
          ),
          const SizedBox(height: 8),
        ]),
      );
    }

    return GlassCard(
      margin: EdgeInsets.fromLTRB(16, 0, 16, inDetails ? 0 : 12),
      onTap: inDetails ? null : () => context.push('/moments/post', extra: m),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          GestureDetector(onTap: () => isMine ? null : context.push('/user', extra: m.author), child: YoloAvatar(user: m.author, size: 42)),
          const SizedBox(width: 10),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(m.author.name, style: const TextStyle(fontWeight: FontWeight.w700)),
              Text(m.time, style: const TextStyle(fontSize: 11, color: YoloColors.textMuted)),
            ]),
          ),
          IconButton(tooltip: 'Post options', icon: const Icon(Icons.more_horiz_rounded), onPressed: more),
        ]),
        if (m.text.isNotEmpty) ...[
          const SizedBox(height: 10),
          Text(m.text, style: const TextStyle(fontSize: 14, height: 1.45)),
        ],
        if (m.photo != null || m.images.isNotEmpty || m.video != null) ...[const SizedBox(height: 10), MomentMedia(m: m)],
        const SizedBox(height: 8),
        GestureDetector(
          onTap: () => context.push('/moments/topic', extra: m.topic),
          child: Text(m.topic, style: const TextStyle(color: YoloColors.gold, fontWeight: FontWeight.w700, fontSize: 12)),
        ),
        const SizedBox(height: 4),
        Row(children: [
          TextButton.icon(
            onPressed: () => ref.read(likedMomentsProvider.notifier).toggle(m.id),
            icon: Icon(isLiked ? Icons.favorite_rounded : Icons.favorite_border_rounded, color: isLiked ? const Color(0xFFF43F5E) : YoloColors.textMuted)
                .animate(target: isLiked ? 1 : 0)
                .scaleXY(end: 1.25, duration: 150.ms)
                .then()
                .scaleXY(end: 0.8, duration: 150.ms),
            label: Text('${likeCount(m, liked)}', style: const TextStyle(color: YoloColors.textSoft)),
          ),
          TextButton.icon(
            onPressed: inDetails ? null : () => context.push('/moments/post', extra: m),
            icon: const Icon(Icons.mode_comment_outlined, color: YoloColors.textMuted),
            label: Text('${m.comments + comments}', style: const TextStyle(color: YoloColors.textSoft)),
          ),
          const Spacer(),
          IconButton(tooltip: 'Share', icon: const Icon(Icons.share_outlined, color: YoloColors.textMuted), onPressed: share),
        ]),
      ]),
    );
  }
}

/// Post details with comments.
class PostDetailsScreen extends ConsumerStatefulWidget {
  const PostDetailsScreen({super.key, required this.moment});
  final Moment moment;

  @override
  ConsumerState<PostDetailsScreen> createState() => _PostDetailsScreenState();
}

class _PostDetailsScreenState extends ConsumerState<PostDetailsScreen> {
  final _input = TextEditingController();

  @override
  void dispose() {
    _input.dispose();
    super.dispose();
  }

  void _send() {
    final me = ref.read(sessionProvider);
    if (me == null) return;
    ref.read(commentsProvider(widget.moment.id).notifier).add(me, _input.text);
    _input.clear();
    FocusScope.of(context).unfocus();
  }

  @override
  Widget build(BuildContext context) {
    final comments = ref.watch(commentsProvider(widget.moment.id));
    return YoloPage(
      title: 'Post',
      body: Column(children: [
        Expanded(
          child: ListView(padding: const EdgeInsets.only(bottom: 20), children: [
            MomentCard(moment: widget.moment, inDetails: true),
            SectionTitle('Comments (${comments.length})'),
            if (comments.isEmpty) const Padding(padding: EdgeInsets.symmetric(horizontal: 20), child: Text('No comments yet. Say something nice!', style: TextStyle(color: YoloColors.textMuted))),
            for (final (i, c) in comments.indexed)
              ListTile(
                leading: YoloAvatar(user: c.author, size: 38),
                title: Text(c.author.name, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                subtitle: Text(c.text, style: const TextStyle(color: YoloColors.text)),
                trailing: Text(c.time, style: const TextStyle(fontSize: 11, color: YoloColors.textMuted)),
              ).entrance(i),
          ]),
        ),
        SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 4, 12, 10),
            child: Row(children: [
              Expanded(
                child: TextField(
                  controller: _input,
                  onSubmitted: (_) => _send(),
                  textInputAction: TextInputAction.send,
                  decoration: InputDecoration(
                    hintText: 'Add a comment…',
                    filled: true,
                    fillColor: Colors.white.withValues(alpha: 0.08),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(24), borderSide: BorderSide.none),
                  ),
                ),
              ),
              IconButton(tooltip: 'Post comment', icon: const Icon(Icons.send_rounded, color: YoloColors.gold), onPressed: _send),
            ]),
          ),
        ),
      ]),
    );
  }
}
