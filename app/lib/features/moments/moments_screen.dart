import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../core/theme.dart';
import '../../data/demo_content.dart';
import '../../data/social_providers.dart';
import '../../widgets/common.dart';
import '../../widgets/page_kit.dart';

class MomentsScreen extends ConsumerStatefulWidget {
  const MomentsScreen({super.key});

  @override
  ConsumerState<MomentsScreen> createState() => _MomentsScreenState();
}

class _MomentsScreenState extends ConsumerState<MomentsScreen> {
  int _tab = 0;

  @override
  Widget build(BuildContext context) {
    final liked = ref.watch(likedMomentsProvider);
    final following = ref.watch(followingProvider);
    final list = _tab == 1 ? demoMoments.where((m) => following.contains(m.author.id)).toList() : demoMoments;

    return YoloPage(
      title: 'Moments',
      actions: [
        IconButton(tooltip: 'New post', icon: const Icon(Icons.add_circle_rounded, color: YoloColors.gold), onPressed: () => showYoloToast(context, 'Creating posts arrives in Step 6')),
      ],
      bottom: YoloTabs(tabs: const ['Trending', 'Following'], index: _tab, onChanged: (i) => setState(() => _tab = i)),
      body: list.isEmpty
          ? const EmptyState(icon: Icons.photo_library_rounded, title: 'No posts yet', subtitle: 'Follow people to see their moments here.')
          : ListView.builder(
              padding: const EdgeInsets.only(bottom: 40),
              itemCount: list.length,
              itemBuilder: (_, i) {
                final m = list[i];
                final isLiked = liked.contains(m.id);
                return GlassCard(
                  margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Row(children: [
                      GestureDetector(onTap: () => context.push('/user', extra: m.author), child: YoloAvatar(user: m.author, size: 42)),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text(m.author.name, style: const TextStyle(fontWeight: FontWeight.w700)),
                          Text(m.time, style: const TextStyle(fontSize: 11, color: YoloColors.textMuted)),
                        ]),
                      ),
                      IconButton(tooltip: 'More', icon: const Icon(Icons.more_horiz_rounded), onPressed: () => showYoloToast(context, 'Report and delete arrive in Step 6')),
                    ]),
                    const SizedBox(height: 10),
                    Text(m.text, style: const TextStyle(fontSize: 14, height: 1.45)),
                    if (m.photo != null) ...[
                      const SizedBox(height: 10),
                      Container(
                        height: 180,
                        decoration: BoxDecoration(borderRadius: BorderRadius.circular(14), gradient: LinearGradient(colors: m.photo!)),
                        alignment: Alignment.center,
                        child: const Icon(Icons.image_rounded, size: 48, color: Colors.white54),
                      ),
                    ],
                    const SizedBox(height: 8),
                    Text(m.topic, style: const TextStyle(color: YoloColors.gold, fontWeight: FontWeight.w700, fontSize: 12)),
                    const SizedBox(height: 4),
                    Row(children: [
                      TextButton.icon(
                        onPressed: () => ref.read(likedMomentsProvider.notifier).toggle(m.id),
                        icon: Icon(isLiked ? Icons.favorite_rounded : Icons.favorite_border_rounded, color: isLiked ? const Color(0xFFF43F5E) : YoloColors.textMuted)
                            .animate(target: isLiked ? 1 : 0)
                            .scaleXY(end: 1.25, duration: 150.ms)
                            .then()
                            .scaleXY(end: 0.8, duration: 150.ms),
                        label: Text('${m.likes + (isLiked ? 1 : 0)}', style: const TextStyle(color: YoloColors.textSoft)),
                      ),
                      TextButton.icon(
                        onPressed: () => showYoloToast(context, 'Comments arrive in Step 6'),
                        icon: const Icon(Icons.mode_comment_outlined, color: YoloColors.textMuted),
                        label: Text('${m.comments}', style: const TextStyle(color: YoloColors.textSoft)),
                      ),
                      const Spacer(),
                      IconButton(tooltip: 'Share', icon: const Icon(Icons.share_outlined, color: YoloColors.textMuted), onPressed: () => showYoloToast(context, 'Share link copied')),
                    ]),
                  ]),
                ).entrance(i);
              },
            ),
    );
  }
}
