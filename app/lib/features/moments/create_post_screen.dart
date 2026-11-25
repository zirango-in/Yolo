import 'dart:io';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:material_ui/material_ui.dart';

import '../../core/theme.dart';
import '../../data/moments_providers.dart';
import '../../data/providers.dart';
import '../../widgets/common.dart';
import '../../widgets/page_kit.dart';

class CreatePostScreen extends ConsumerStatefulWidget {
  const CreatePostScreen({super.key});

  @override
  ConsumerState<CreatePostScreen> createState() => _CreatePostScreenState();
}

class _CreatePostScreenState extends ConsumerState<CreatePostScreen> {
  final _text = TextEditingController();
  final _images = <String>[];
  String? _video;
  String _topic = allTopics[2];

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  bool get _canPost => _text.text.trim().isNotEmpty || _images.isNotEmpty || _video != null;

  Future<void> _addPhotos() async {
    try {
      final picked = await ImagePicker().pickMultiImage(maxWidth: 1600, imageQuality: 85, limit: 9 - _images.length);
      setState(() {
        _video = null;
        _images.addAll(picked.map((x) => x.path).take(9 - _images.length));
      });
    } catch (_) {
      if (mounted) showYoloToast(context, 'Could not open gallery');
    }
  }

  Future<void> _addVideo() async {
    try {
      final v = await ImagePicker().pickVideo(source: ImageSource.gallery, maxDuration: const Duration(seconds: 60));
      if (v != null) {
        setState(() {
          _images.clear();
          _video = v.path;
        });
      }
    } catch (_) {
      if (mounted) showYoloToast(context, 'Could not open gallery');
    }
  }

  void _post() {
    final me = ref.read(sessionProvider);
    if (me == null || !_canPost) return;
    ref.read(momentsProvider.notifier).post(me, text: _text.text.trim(), topic: _topic, images: [..._images], video: _video);
    showYoloToast(context, 'Posted!');
    context.pop();
  }

  @override
  Widget build(BuildContext context) {
    return YoloPage(
      title: 'New moment',
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 4),
          child: SizedBox(
            width: 84,
            child: Opacity(opacity: _canPost ? 1 : 0.5, child: GoldButton(label: 'Post', height: 36, onPressed: _canPost ? _post : null)),
          ),
        ),
      ],
      body: ListView(padding: const EdgeInsets.all(20), children: [
        TextField(
          controller: _text,
          maxLength: 500,
          maxLines: 6,
          minLines: 4,
          autofocus: true,
          onChanged: (_) => setState(() {}),
          decoration: InputDecoration(
            hintText: "What's happening?",
            filled: true,
            fillColor: Colors.white.withValues(alpha: 0.06),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(18), borderSide: BorderSide.none),
          ),
        ),
        const SizedBox(height: 8),
        if (_images.isNotEmpty)
          GridView.count(
            crossAxisCount: 3,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 6,
            crossAxisSpacing: 6,
            children: [
              for (final (i, p) in _images.indexed)
                Stack(fit: StackFit.expand, children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: kIsWeb ? const ColoredBox(color: Colors.black26) : Image.file(File(p), fit: BoxFit.cover),
                  ),
                  Positioned(
                    top: 2,
                    right: 2,
                    child: IconButton.filled(
                      tooltip: 'Remove photo',
                      iconSize: 16,
                      style: IconButton.styleFrom(backgroundColor: Colors.black54, minimumSize: const Size(28, 28)),
                      icon: const Icon(Icons.close_rounded),
                      onPressed: () => setState(() => _images.removeAt(i)),
                    ),
                  ),
                ]),
            ],
          ),
        if (_video != null)
          GlassCard(
            child: Row(children: [
              const Icon(Icons.movie_rounded, color: YoloColors.gold),
              const SizedBox(width: 10),
              const Expanded(child: Text('Video attached')),
              IconButton(tooltip: 'Remove video', icon: const Icon(Icons.close_rounded), onPressed: () => setState(() => _video = null)),
            ]),
          ),
        const SizedBox(height: 12),
        Row(children: [
          Expanded(
            child: OutlinedButton.icon(
              onPressed: _images.length >= 9 ? null : _addPhotos,
              style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(48), shape: const StadiumBorder(), foregroundColor: YoloColors.gold),
              icon: const Icon(Icons.photo_library_rounded),
              label: Text('Photos ${_images.length}/9'),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: OutlinedButton.icon(
              onPressed: _addVideo,
              style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(48), shape: const StadiumBorder(), foregroundColor: YoloColors.gold),
              icon: const Icon(Icons.videocam_rounded),
              label: const Text('Video'),
            ),
          ),
        ]),
        const SectionTitle('Topic'),
        Wrap(spacing: 8, runSpacing: 8, children: [
          for (final t in allTopics)
            ChoiceChip(
              label: Text(t),
              selected: _topic == t,
              onSelected: (_) => setState(() => _topic = t),
              selectedColor: YoloColors.gold,
              showCheckmark: false,
              labelStyle: TextStyle(color: _topic == t ? YoloColors.onGold : YoloColors.text, fontWeight: FontWeight.w700),
            ),
        ]),
      ]),
    );
  }
}
