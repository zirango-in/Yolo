import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:video_player/video_player.dart';

import '../../core/theme.dart';
import '../../data/models.dart';
import '../../data/providers.dart';
import '../../data/room_look.dart';
import '../../data/social_providers.dart';
import '../../widgets/common.dart';
import '../../widgets/page_kit.dart';
import 'room_sheets.dart';

/// Stage for the current room mode (auction, video, game). Normal and acquaint rooms have none.
class RoomModeStage extends ConsumerWidget {
  const RoomModeStage({super.key, required this.room});
  final Room room;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mode = ref.watch(roomProvider(room).select((s) => s.roomMode));
    return switch (mode) {
      'auction' => _AuctionStage(room: room),
      'video' => _VideoStage(room: room),
      'game' => _GameStage(room: room),
      _ => const SizedBox.shrink(),
    };
  }
}

/// Shared card shape for stages.
class _StageCard extends StatelessWidget {
  const _StageCard({required this.child, this.padding = const EdgeInsets.fromLTRB(10, 8, 8, 8)});
  final Widget child;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    final look = RoomLookScope.of(context);
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 2, 12, 4),
      padding: padding,
      decoration: BoxDecoration(
        color: look.panel,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: look.accent.withValues(alpha: 0.35)),
      ),
      child: child,
    );
  }
}

Widget _stageButton(BuildContext context, String label, VoidCallback onTap, {bool filled = true}) {
  final look = RoomLookScope.of(context);
  return SizedBox(
    height: 32,
    child: filled
        ? FilledButton(
            style: FilledButton.styleFrom(backgroundColor: look.accent, foregroundColor: look.onAccent, padding: const EdgeInsets.symmetric(horizontal: 14), visualDensity: VisualDensity.compact),
            onPressed: onTap,
            child: Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800)),
          )
        : OutlinedButton(
            style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 12), visualDensity: VisualDensity.compact),
            onPressed: onTap,
            child: Text(label, style: const TextStyle(fontSize: 12)),
          ),
  );
}

Future<String?> _askText(BuildContext context, String title, String hint, {Key? key}) {
  final c = TextEditingController();
  return showDialog<String>(
    context: context,
    builder: (d) => AlertDialog(
      backgroundColor: YoloColors.sheet,
      title: Text(title),
      content: TextField(key: key, controller: c, autofocus: true, decoration: InputDecoration(hintText: hint)),
      actions: [
        TextButton(onPressed: () => Navigator.pop(d), child: const Text('Cancel')),
        FilledButton(onPressed: () => Navigator.pop(d, c.text), child: const Text('OK')),
      ],
    ),
  );
}

// ---------------------------------------------------------------------------
class _AuctionStage extends ConsumerWidget {
  const _AuctionStage({required this.room});
  final Room room;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final (item, bids) = ref.watch(roomProvider(room).select((s) => (s.auctionItem, s.auctionBids)));
    final st = ref.read(roomProvider(room));
    final ctrl = ref.read(roomProvider(room).notifier);
    final look = RoomLookScope.of(context);
    final top = st.topBid;
    final me = ref.read(sessionProvider);
    final topUser = top == null ? null : (top.$1 == me?.id ? me : userById(top.$1));

    void toast(String m) {
      if (m.isNotEmpty) showYoloToast(context, m);
    }

    return _StageCard(
      child: Row(children: [
        Icon(Icons.gavel_rounded, color: look.accent, size: 22),
        const SizedBox(width: 8),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
            Text(item == null ? 'Auction room' : 'Auction: $item', maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800)),
            const SizedBox(height: 2),
            if (item == null)
              Text(ctrl.canManage ? 'Start an auction for your fans to bid on' : 'Waiting for the host to start an auction',
                  maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 11, color: YoloColors.textSoft))
            else if (topUser == null)
              const Text('No bids yet', style: TextStyle(fontSize: 11, color: YoloColors.textSoft))
            else
              Row(children: [
                YoloAvatar(user: topUser, size: 16, plain: true),
                const SizedBox(width: 4),
                Flexible(child: Text('${topUser.name} · ${formatCoins(top!.$2)} coins', maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 11, color: look.accent, fontWeight: FontWeight.w700))),
              ]),
          ]),
        ),
        const SizedBox(width: 6),
        if (item != null) _stageButton(context, 'Bid', () => _bid(context, ref)),
        if (item != null && ctrl.canManage) ...[const SizedBox(width: 6), _stageButton(context, 'End', () => toast(ctrl.endAuction()), filled: false)],
        if (item == null && ctrl.canManage)
          _stageButton(context, 'Start', () async {
            final v = await _askText(context, 'What are you auctioning?', 'e.g. 1 song request, CP for a day', key: const Key('auction-item'));
            if (v != null && context.mounted) toast(ctrl.startAuction(v));
          }),
      ]),
    );
  }

  void _bid(BuildContext context, WidgetRef ref) {
    final ctrl = ref.read(roomProvider(room).notifier);
    showRoomSheet<void>(
      context,
      (c) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 18, 16, 12),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Text('Place a bid', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
          const SizedBox(height: 4),
          const Text('Bids are paid in coins and count towards your Charms here.', style: TextStyle(fontSize: 12, color: YoloColors.textMuted)),
          const SizedBox(height: 12),
          Row(children: [
            for (final amount in [100, 500, 1000, 5000])
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: OutlinedButton(
                    onPressed: () {
                      Navigator.pop(c);
                      final m = ctrl.bid(amount);
                      showYoloToast(context, m.isEmpty ? 'You bid $amount coins' : m);
                    },
                    child: Text(formatCoins(amount)),
                  ),
                ),
              ),
          ]),
        ]),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
class _VideoStage extends ConsumerStatefulWidget {
  const _VideoStage({required this.room});
  final Room room;

  @override
  ConsumerState<_VideoStage> createState() => _VideoStageState();
}

class _VideoStageState extends ConsumerState<_VideoStage> {
  VideoPlayerController? _player;
  String? _url;
  bool _failed = false;

  @override
  void dispose() {
    _player?.dispose();
    super.dispose();
  }

  /// One player per video link; reused while the link stays the same (no reloads on rebuilds).
  void _sync(String? url, bool playing) {
    if (url != _url) {
      _player?.dispose();
      _player = null;
      _failed = false;
      _url = url;
      if (url != null) {
        final p = VideoPlayerController.networkUrl(Uri.parse(url));
        _player = p;
        p.initialize().then((_) {
          if (!mounted || _player != p) return;
          p.setLooping(true);
          playing ? p.play() : p.pause();
          setState(() {});
        }).catchError((Object _) {
          if (mounted && _player == p) setState(() => _failed = true);
        });
      }
    } else if (_player?.value.isInitialized ?? false) {
      playing ? _player!.play() : _player!.pause();
    }
  }

  @override
  Widget build(BuildContext context) {
    final room = widget.room;
    final (url, title, playing) = ref.watch(roomProvider(room).select((s) => (s.videoUrl, s.videoTitle, s.videoPlaying)));
    final ctrl = ref.read(roomProvider(room).notifier);
    final look = RoomLookScope.of(context);
    _sync(url, playing);

    if (url == null) {
      return _StageCard(
        child: Row(children: [
          Icon(Icons.smart_display_rounded, color: look.accent),
          const SizedBox(width: 8),
          Expanded(
            child: Text(ctrl.canManage ? 'Pick a video to watch together' : 'Waiting for the host to pick a video',
                style: const TextStyle(fontSize: 12, color: YoloColors.textSoft)),
          ),
          if (ctrl.canManage)
            _stageButton(context, 'Choose', () async {
              final link = await _askText(context, 'Video link', 'https://…/video.mp4', key: const Key('video-url'));
              if (link == null || !context.mounted) return;
              final m = ctrl.setVideo(link, Uri.tryParse(link)?.pathSegments.lastOrNull ?? 'Video');
              if (m.isNotEmpty) showYoloToast(context, m);
            }),
        ]),
      );
    }
    final p = _player;
    final ready = p != null && p.value.isInitialized;
    return _StageCard(
      padding: const EdgeInsets.all(6),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: SizedBox(
            height: 140,
            width: double.infinity,
            child: ColoredBox(
              color: Colors.black,
              child: Center(
                child: _failed
                    ? const Text("Can't play this video", style: TextStyle(color: YoloColors.textSoft))
                    : ready
                        ? AspectRatio(aspectRatio: p.value.aspectRatio, child: VideoPlayer(p))
                        : const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2)),
              ),
            ),
          ),
        ),
        Row(children: [
          const SizedBox(width: 4),
          Expanded(child: Text(title, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700))),
          if (ctrl.canManage) ...[
            IconButton(
              tooltip: playing ? 'Pause video' : 'Play video',
              visualDensity: VisualDensity.compact,
              icon: Icon(playing ? Icons.pause_rounded : Icons.play_arrow_rounded),
              onPressed: ctrl.toggleVideo,
            ),
            IconButton(tooltip: 'Stop video', visualDensity: VisualDensity.compact, icon: const Icon(Icons.stop_rounded), onPressed: ctrl.stopVideo),
          ],
        ]),
      ]),
    );
  }
}

// ---------------------------------------------------------------------------
class _GameStage extends ConsumerWidget {
  const _GameStage({required this.room});
  final Room room;

  /// Games that already work in the app (more arrive with the Games step).
  static const games = [('Mic Grab', Icons.mic_external_on_rounded, '/music/micgrab')];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final game = ref.watch(roomProvider(room).select((s) => s.roomGame));
    final ctrl = ref.read(roomProvider(room).notifier);
    final look = RoomLookScope.of(context);
    final current = games.where((g) => g.$1 == game).firstOrNull;
    return _StageCard(
      child: Row(children: [
        Icon(current?.$2 ?? Icons.sports_esports_rounded, color: look.accent),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            current != null ? 'Playing ${current.$1}' : (ctrl.canManage ? 'Choose a game for the room' : 'Waiting for the host to start a game'),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(fontSize: 12, fontWeight: current != null ? FontWeight.w800 : FontWeight.w500, color: current != null ? YoloColors.text : YoloColors.textSoft),
          ),
        ),
        if (current != null) ...[
          _stageButton(context, 'Join', () => context.push(current.$3)),
          if (ctrl.canManage) ...[const SizedBox(width: 6), _stageButton(context, 'End', () => ctrl.setGame(null), filled: false)],
        ] else if (ctrl.canManage)
          for (final g in games) _stageButton(context, g.$1, () => ctrl.setGame(g.$1)),
      ]),
    );
  }
}
