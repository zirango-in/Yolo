import 'dart:async';
import 'dart:math';

import 'package:file_picker/file_picker.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../core/theme.dart';
import '../../data/models.dart';
import '../../data/music_providers.dart';
import '../../data/providers.dart';
import '../../data/repository.dart';
import '../../widgets/common.dart';
import '../../widgets/page_kit.dart';
import '../room/room_sheets.dart';

String _plays(int n) => n >= 1000 ? '${(n / 1000).toStringAsFixed(1)}K plays' : '$n plays';

Widget _cover(Song s, double size) => Container(
      width: size,
      height: size,
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(size * 0.25), gradient: LinearGradient(colors: s.cover, begin: Alignment.topLeft, end: Alignment.bottomRight)),
      child: Icon(Icons.music_note_rounded, color: Colors.white70, size: size * 0.45),
    );

/// Music home: modes, search, popular / all / favorites / uploads, preview player.
class MusicScreen extends ConsumerStatefulWidget {
  const MusicScreen({super.key});

  @override
  ConsumerState<MusicScreen> createState() => _MusicScreenState();
}

class _MusicScreenState extends ConsumerState<MusicScreen> {
  int _tab = 0;
  String _q = '';

  @override
  Widget build(BuildContext context) {
    final m = ref.watch(musicProvider);
    final ctrl = ref.read(musicProvider.notifier);
    final q = _q.trim().toLowerCase();
    var list = switch (_tab) {
      0 => ([...demoSongs]..sort((a, b) => b.plays.compareTo(a.plays))),
      2 => ctrl.all.where((s) => m.favorites.contains(s.id)).toList(),
      3 => m.uploads,
      _ => ctrl.all,
    };
    if (q.isNotEmpty) list = ctrl.all.where((s) => '${s.title} ${s.artist} ${s.genre}'.toLowerCase().contains(q)).toList();
    final playing = ctrl.all.where((s) => s.id == m.playing).firstOrNull;

    Widget mode(IconData icon, String label, List<Color> colors, String route) => Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: GlassCard(
              padding: const EdgeInsets.symmetric(vertical: 14),
              gradient: LinearGradient(colors: colors),
              onTap: () => context.push(route),
              child: Column(children: [Icon(icon, color: Colors.white, size: 28), const SizedBox(height: 6), Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800))]),
            ),
          ),
        );

    return YoloPage(
      title: 'Music',
      actions: [IconButton(tooltip: 'Upload music', icon: const Icon(Icons.upload_rounded, color: YoloColors.gold), onPressed: () => context.push('/music/upload'))],
      body: Column(children: [
        Expanded(
          child: ListView(padding: const EdgeInsets.only(bottom: 16), children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 4, 12, 0),
              child: Row(children: [
                mode(Icons.mic_external_on_rounded, 'Karaoke', const [Color(0xFFEC4899), Color(0xFF8B5CF6)], '/music/karaoke'),
                mode(Icons.groups_rounded, 'Singing room', const [Color(0xFF0EA5E9), Color(0xFF6366F1)], '/music/room'),
                mode(Icons.sports_mma_rounded, 'Battle', const [Color(0xFFF97316), Color(0xFFDC2626)], '/music/battle'),
                mode(Icons.front_hand_rounded, 'Mic grab', const [Color(0xFF10B981), Color(0xFF0E7490)], '/music/micgrab'),
              ]),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
              child: TextField(
                onChanged: (v) => setState(() => _q = v),
                decoration: InputDecoration(
                  hintText: 'Search songs, artists, genres',
                  prefixIcon: const Icon(Icons.search_rounded),
                  filled: true,
                  fillColor: Colors.white.withValues(alpha: 0.07),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(24), borderSide: BorderSide.none),
                ),
              ),
            ),
            if (q.isEmpty) YoloTabs(tabs: const ['Popular', 'All songs', 'Favorites', 'My uploads'], index: _tab, onChanged: (i) => setState(() => _tab = i), padding: const EdgeInsets.fromLTRB(20, 14, 20, 6)),
            if (list.isEmpty) const Padding(padding: EdgeInsets.all(30), child: Center(child: Text('No songs here', style: TextStyle(color: YoloColors.textMuted)))),
            for (final (i, s) in list.indexed)
              ListTile(
                leading: Stack(alignment: Alignment.center, children: [
                  _cover(s, 52),
                  if (m.playing == s.id) const Icon(Icons.graphic_eq_rounded, color: Colors.white).animate(onPlay: (c) => c.repeat(reverse: true)).scaleY(begin: 0.6, end: 1, duration: 400.ms),
                ]),
                title: Row(children: [
                  if (_tab == 0 && q.isEmpty) Text('${i + 1}  ', style: TextStyle(fontWeight: FontWeight.w900, color: i < 3 ? YoloColors.gold : YoloColors.textMuted)),
                  Flexible(child: Text(s.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w700))),
                ]),
                subtitle: Text('${s.artist} · ${s.genre} · ${s.length}${s.uploaded ? ' · uploaded' : ' · ${_plays(s.plays)}'}', maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12, color: YoloColors.textMuted)),
                onTap: () => ctrl.play(s.id),
                trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                  IconButton(
                    tooltip: m.favorites.contains(s.id) ? 'Unfavorite ${s.title}' : 'Favorite ${s.title}',
                    icon: Icon(m.favorites.contains(s.id) ? Icons.favorite_rounded : Icons.favorite_border_rounded, color: m.favorites.contains(s.id) ? const Color(0xFFF43F5E) : YoloColors.textMuted),
                    onPressed: () => ctrl.toggleFavorite(s.id),
                  ),
                  IconButton(tooltip: 'Sing ${s.title}', icon: const Icon(Icons.mic_rounded, color: YoloColors.gold), onPressed: () => context.push('/music/karaoke', extra: s)),
                ]),
              ).entrance(i),
            if (m.history.isNotEmpty && q.isEmpty) ...[
              const SectionTitle('My performances'),
              for (final r in m.history.take(5))
                ListTile(
                  leading: Badge2(r.grade, bg: YoloColors.gold, fg: YoloColors.onGold),
                  title: Text(r.song.title),
                  subtitle: Text('Score ${r.score} · ${r.time}', style: const TextStyle(fontSize: 12, color: YoloColors.textMuted)),
                  trailing: Text('+${r.coins}', style: const TextStyle(color: YoloColors.gold, fontWeight: FontWeight.w800)),
                ),
            ],
          ]),
        ),
        if (playing != null)
          Container(
            decoration: BoxDecoration(color: YoloColors.sheet, border: Border(top: BorderSide(color: YoloColors.gold.withValues(alpha: 0.3)))),
            child: SafeArea(
              top: false,
              child: ListTile(
                leading: _cover(playing, 44).animate(onPlay: (c) => c.repeat()).rotate(duration: 8.seconds),
                title: Text(playing.title, style: const TextStyle(fontWeight: FontWeight.w800)),
                subtitle: const Text('Preview · demo audio', style: TextStyle(fontSize: 12, color: YoloColors.textMuted)),
                trailing: IconButton(tooltip: 'Stop preview', icon: const Icon(Icons.stop_circle_rounded, color: YoloColors.gold, size: 34), onPressed: () => ctrl.play(playing.id)),
              ),
            ),
          ),
      ]),
    );
  }
}

/// Mic & effect picker sheet.
void showMicSheet(BuildContext context, WidgetRef ref) {
  showRoomSheet<void>(
    context,
    (c) => Consumer(builder: (c, ref, _) {
      final m = ref.watch(musicProvider);
      final ctrl = ref.read(musicProvider.notifier);
      return Padding(
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 16),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Microphone', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
          const SizedBox(height: 8),
          for (final (v, label, icon) in [('phone', 'Phone mic', Icons.smartphone_rounded), ('headset', 'Wired headset', Icons.headset_mic_rounded), ('bluetooth', 'Bluetooth', Icons.bluetooth_audio_rounded)])
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(icon, color: YoloColors.gold),
              title: Text(label),
              trailing: m.mic == v ? const Icon(Icons.check_circle_rounded, color: YoloColors.gold) : null,
              onTap: () => ctrl.setMic(v),
            ),
          const SizedBox(height: 6),
          const Text('Voice effect', style: TextStyle(fontWeight: FontWeight.w800)),
          const SizedBox(height: 8),
          Wrap(spacing: 8, children: [
            for (final e in ['none', 'echo', 'reverb', 'studio'])
              ChoiceChip(
                label: Text(e[0].toUpperCase() + e.substring(1)),
                selected: m.effect == e,
                onSelected: (_) => ctrl.setEffect(e),
                selectedColor: YoloColors.gold,
                showCheckmark: false,
                labelStyle: TextStyle(color: m.effect == e ? YoloColors.onGold : YoloColors.text, fontWeight: FontWeight.w700),
              ),
          ]),
        ]),
      );
    }),
  );
}

/// Karaoke: synced lyrics, live pitch meter, finish → results.
class KaraokeScreen extends ConsumerStatefulWidget {
  const KaraokeScreen({super.key, this.song});
  final Song? song;

  @override
  ConsumerState<KaraokeScreen> createState() => _KaraokeScreenState();
}

class _KaraokeScreenState extends ConsumerState<KaraokeScreen> {
  static const _lineMs = 3000;
  late Song _song = widget.song ?? demoSongs.first;
  Timer? _timer;
  int _ms = 0;
  bool _singing = false;
  double _pitch = 0.5;
  final _accuracy = <double>[];
  final _rand = Random();

  int get _total => _song.lyrics.length * _lineMs;
  int get _line => (_ms ~/ _lineMs).clamp(0, _song.lyrics.length - 1);

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _toggle() {
    if (_singing) {
      _timer?.cancel();
      setState(() => _singing = false);
      return;
    }
    setState(() => _singing = true);
    _timer = Timer.periodic(const Duration(milliseconds: 100), (_) {
      setState(() {
        _ms += 100;
        _pitch = (0.35 + _rand.nextDouble() * 0.65);
        _accuracy.add(_pitch);
      });
      if (_ms >= _total) _finish();
    });
  }

  void _finish() {
    _timer?.cancel();
    final acc = _accuracy.isEmpty ? ref.read(musicProvider.notifier).simulatedAccuracy() : _accuracy.reduce((a, b) => a + b) / _accuracy.length;
    final result = ref.read(musicProvider.notifier).finish(_song, acc);
    context.pushReplacement('/music/result', extra: result);
  }

  @override
  Widget build(BuildContext context) {
    final m = ref.watch(musicProvider);
    return YoloPage(
      title: 'Karaoke',
      actions: [IconButton(tooltip: 'Mic & effects', icon: const Icon(Icons.tune_rounded), onPressed: () => showMicSheet(context, ref))],
      body: Container(
        decoration: BoxDecoration(gradient: LinearGradient(colors: [_song.cover.last.withValues(alpha: 0.35), YoloColors.bg], begin: Alignment.topCenter, end: Alignment.bottomCenter)),
        child: Column(children: [
          const SizedBox(height: 8),
          _cover(_song, 110).animate(target: _singing ? 1 : 0).scaleXY(end: 1.06, duration: 300.ms),
          const SizedBox(height: 10),
          Text(_song.title, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900)),
          Text('${_song.artist} · mic: ${m.mic} · effect: ${m.effect}', style: const TextStyle(color: YoloColors.textMuted, fontSize: 12)),
          if (widget.song == null)
            TextButton(
              onPressed: () => showRoomSheet<void>(
                context,
                (c) => ListView(shrinkWrap: true, children: [
                  for (final s in demoSongs)
                    ListTile(leading: _cover(s, 40), title: Text(s.title), onTap: () {
                      Navigator.pop(c);
                      setState(() {
                        _song = s;
                        _ms = 0;
                        _accuracy.clear();
                      });
                    }),
                ]),
                scroll: true,
              ),
              child: const Text('Change song', style: TextStyle(color: YoloColors.gold)),
            ),
          Expanded(
            child: ListView(padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12), children: [
              for (var i = 0; i < _song.lyrics.length; i++)
                AnimatedDefaultTextStyle(
                  duration: 250.ms,
                  style: TextStyle(
                    fontSize: i == _line ? 22 : 16,
                    height: 2,
                    fontWeight: i == _line ? FontWeight.w900 : FontWeight.w500,
                    color: i < _line ? YoloColors.textMuted : (i == _line ? YoloColors.gold : YoloColors.textSoft),
                    fontFamily: DefaultTextStyle.of(context).style.fontFamily,
                  ),
                  textAlign: TextAlign.center,
                  child: Text(_song.lyrics[i], textAlign: TextAlign.center),
                ),
            ]),
          ),
          // Pitch meter
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(children: [
              const Icon(Icons.graphic_eq_rounded, color: YoloColors.gold),
              const SizedBox(width: 8),
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LinearProgressIndicator(value: _singing ? _pitch : 0, minHeight: 10, color: _pitch > 0.75 ? YoloColors.online : YoloColors.gold, backgroundColor: const Color(0x22FFFFFF)),
                ),
              ),
            ]),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(children: [
              Text(_fmt(_ms), style: const TextStyle(fontSize: 12, color: YoloColors.textMuted)),
              Expanded(child: Slider(value: (_ms / _total).clamp(0, 1), onChanged: null)),
              Text(_fmt(_total), style: const TextStyle(fontSize: 12, color: YoloColors.textMuted)),
            ]),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
              child: Row(children: [
                Expanded(child: GoldButton(label: _singing ? 'Pause' : (_ms == 0 ? 'Start singing' : 'Resume'), icon: _singing ? Icons.pause_rounded : Icons.mic_rounded, onPressed: _toggle)),
                const SizedBox(width: 12),
                OutlinedButton(
                  onPressed: _ms > 0 ? _finish : null,
                  style: OutlinedButton.styleFrom(minimumSize: const Size(96, 54), shape: const StadiumBorder(), foregroundColor: YoloColors.gold),
                  child: const Text('Finish'),
                ),
              ]),
            ),
          ),
        ]),
      ),
    );
  }

  String _fmt(int ms) => '${ms ~/ 60000}:${((ms ~/ 1000) % 60).toString().padLeft(2, '0')}';
}

/// Singing results: score, grade, coins.
class SingResultScreen extends StatelessWidget {
  const SingResultScreen({super.key, required this.result});
  final SingResult result;

  @override
  Widget build(BuildContext context) {
    final r = result;
    return YoloPage(
      title: 'Results',
      body: ListView(padding: const EdgeInsets.all(24), children: [
        const SizedBox(height: 10),
        Center(
          child: Container(
            width: 150,
            height: 150,
            decoration: BoxDecoration(shape: BoxShape.circle, gradient: YoloColors.goldGradient, boxShadow: [BoxShadow(color: YoloColors.gold.withValues(alpha: 0.5), blurRadius: 40)]),
            alignment: Alignment.center,
            child: Text(r.grade, style: const TextStyle(fontSize: 72, fontWeight: FontWeight.w900, color: YoloColors.onGold)),
          ).animate().scale(begin: const Offset(0.3, 0.3), duration: 700.ms, curve: Curves.elasticOut),
        ),
        const SizedBox(height: 20),
        Center(child: Text('Score ${r.score}', style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w900))),
        Center(child: Text(r.song.title, style: const TextStyle(color: YoloColors.textMuted))),
        const SizedBox(height: 10),
        Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          for (var i = 0; i < 5; i++)
            Icon(i < (r.score / 20).round() ? Icons.star_rounded : Icons.star_outline_rounded, color: YoloColors.gold, size: 32).animate().fadeIn(delay: (200 + i * 120).ms).scaleXY(begin: 0.5, end: 1),
        ]),
        const SizedBox(height: 16),
        Center(
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            const CoinIcon(size: 20),
            Text('  +${r.coins} coins', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: YoloColors.gold)),
          ]),
        ),
        const SizedBox(height: 30),
        GoldButton(label: 'Sing again', icon: Icons.replay_rounded, onPressed: () => context.pushReplacement('/music/karaoke', extra: r.song)),
        const SizedBox(height: 12),
        OutlinedButton(
          onPressed: () => showYoloToast(context, 'Shared to your moments draft'),
          style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(50), shape: const StadiumBorder()),
          child: const Text('Share result'),
        ),
      ]),
    );
  }
}

/// Singing room: current singer + queue, join/leave, next.
class SingingRoomScreen extends ConsumerWidget {
  const SingingRoomScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final m = ref.watch(musicProvider);
    final me = ref.watch(sessionProvider)!;
    final ctrl = ref.read(musicProvider.notifier);
    final inQueue = m.queue.any((e) => e.$1.id == me.id);
    final now = m.queue.isEmpty ? null : m.queue.first;

    return YoloPage(
      title: 'Singing room',
      body: ListView(padding: const EdgeInsets.fromLTRB(16, 4, 16, 40), children: [
        GlassCard(
          gradient: const LinearGradient(colors: [Color(0xFF0EA5E9), Color(0xFF6366F1)]),
          child: now == null
              ? const Padding(padding: EdgeInsets.all(20), child: Center(child: Text('Nobody is singing. Join the queue!', style: TextStyle(fontWeight: FontWeight.w700))))
              : Column(children: [
                  const Text('NOW SINGING', style: TextStyle(fontSize: 11, letterSpacing: 1.4, fontWeight: FontWeight.w800, color: Color(0xFFE0F2FE))),
                  const SizedBox(height: 10),
                  YoloAvatar(user: now.$1, size: 80, speaking: true, goldFrame: true),
                  const SizedBox(height: 8),
                  Text(now.$1.id == me.id ? '${now.$1.name} (you)' : now.$1.name, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
                  Text(now.$2.title, style: const TextStyle(color: Color(0xFFE0F2FE))),
                  const SizedBox(height: 8),
                  Text('"${now.$2.lyrics.first}"', textAlign: TextAlign.center, style: const TextStyle(fontStyle: FontStyle.italic, color: YoloColors.goldLight)),
                  const SizedBox(height: 10),
                  Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                    if (now.$1.id == me.id)
                      GoldButton(label: 'Open karaoke', height: 40, onPressed: () => context.push('/music/karaoke', extra: now.$2))
                    else
                      OutlinedButton.icon(
                        onPressed: () => showYoloToast(context, 'You cheered for ${now.$1.name}!'),
                        icon: const Icon(Icons.celebration_rounded),
                        label: const Text('Cheer'),
                      ),
                    const SizedBox(width: 10),
                    TextButton(onPressed: ctrl.nextSinger, child: const Text('Next singer')),
                  ]),
                ]),
        ),
        SectionTitle('Singer queue (${m.queue.length > 1 ? m.queue.length - 1 : 0})'),
        for (final (i, (u, s)) in m.queue.skip(1).indexed)
          ListTile(
            leading: SizedBox(width: 80, child: Row(children: [SizedBox(width: 28, child: Text('${i + 1}', style: const TextStyle(fontWeight: FontWeight.w800))), YoloAvatar(user: u, size: 40)])),
            title: Text(u.id == me.id ? '${u.name} (you)' : u.name, style: const TextStyle(fontWeight: FontWeight.w700)),
            subtitle: Text(s.title, style: const TextStyle(fontSize: 12, color: YoloColors.textMuted)),
            trailing: u.id == me.id ? TextButton(onPressed: () => ctrl.leaveQueue(me.id), child: const Text('Leave')) : null,
          ),
        const SizedBox(height: 16),
        if (!inQueue)
          GoldButton(
            label: 'Join the queue',
            icon: Icons.queue_music_rounded,
            onPressed: () => showRoomSheet<void>(
              context,
              (c) => ListView(shrinkWrap: true, children: [
                const Padding(padding: EdgeInsets.all(16), child: Text('Pick your song', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800))),
                for (final s in demoSongs)
                  ListTile(leading: _cover(s, 40), title: Text(s.title), subtitle: Text(s.artist), onTap: () {
                    Navigator.pop(c);
                    ctrl.joinQueue(me, s);
                    showYoloToast(context, 'You are in the queue with ${s.title}');
                  }),
              ]),
              scroll: true,
            ),
          ),
      ]),
    );
  }
}

/// Singing battle: two singers, vote with a countdown, winner screen.
class SingingBattleScreen extends ConsumerStatefulWidget {
  const SingingBattleScreen({super.key});

  @override
  ConsumerState<SingingBattleScreen> createState() => _SingingBattleScreenState();
}

class _SingingBattleScreenState extends ConsumerState<SingingBattleScreen> {
  static const _duration = 10;
  final _rand = Random();
  Timer? _timer;
  int _left = _duration;
  int _a = 120, _b = 110;
  int? _myVote;
  bool _over = false;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      setState(() {
        _left--;
        _a += _rand.nextInt(25);
        _b += _rand.nextInt(25);
        if (_left <= 0) {
          _over = true;
          t.cancel();
        }
      });
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _vote(int side) {
    if (_myVote != null || _over) return;
    setState(() {
      _myVote = side;
      if (side == 0) {
        _a += 50;
      } else {
        _b += 50;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    const left = DemoUsers.zara, right = DemoUsers.kenji;
    final total = _a + _b;
    final winner = _a >= _b ? left : right;

    Widget side(YoloUser u, int votes, int idx, Color color) => Expanded(
          child: Column(children: [
            YoloAvatar(user: u, size: 84, speaking: !_over, goldFrame: _over && winner.id == u.id),
            const SizedBox(height: 8),
            Text(u.name, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
            Text('$votes votes', style: TextStyle(color: color, fontWeight: FontWeight.w800)),
            const SizedBox(height: 10),
            if (!_over)
              SizedBox(
                width: 120,
                child: Opacity(
                  opacity: _myVote == null || _myVote == idx ? 1 : 0.4,
                  child: GoldButton(label: _myVote == idx ? 'Voted' : 'Vote ${u.name}', height: 40, onPressed: _myVote == null ? () => _vote(idx) : null),
                ),
              ),
          ]),
        );

    return YoloPage(
      title: 'Singing battle',
      body: ListView(padding: const EdgeInsets.all(16), children: [
        Center(child: Text(_over ? 'Battle over!' : 'Voting ends in ${_left}s', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: YoloColors.gold))),
        const SizedBox(height: 4),
        const Center(child: Text('Song: Starlight Duet', style: TextStyle(color: YoloColors.textMuted))),
        const SizedBox(height: 20),
        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          side(left, _a, 0, const Color(0xFFF9A8D4)),
          const Padding(padding: EdgeInsets.only(top: 30), child: Text('VS', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: YoloColors.gold))),
          side(right, _b, 1, const Color(0xFF7DD3FC)),
        ]),
        const SizedBox(height: 20),
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Row(children: [
            Expanded(flex: _a, child: AnimatedContainer(duration: 400.ms, height: 14, color: const Color(0xFFF9A8D4))),
            Expanded(flex: _b, child: AnimatedContainer(duration: 400.ms, height: 14, color: const Color(0xFF7DD3FC))),
          ]),
        ),
        const SizedBox(height: 6),
        Center(child: Text('${(_a * 100 / total).round()}% · ${(_b * 100 / total).round()}%', style: const TextStyle(color: YoloColors.textMuted))),
        if (_over) ...[
          const SizedBox(height: 24),
          GlassCard(
            gradient: const LinearGradient(colors: [Color(0xFF4A3410), Color(0xFF2A1A05)]),
            border: YoloColors.gold,
            child: Column(children: [
              const Icon(Icons.emoji_events_rounded, color: YoloColors.gold, size: 54),
              Text('${winner.name} wins!', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900)),
              if (_myVote != null) Text(_myVote == (winner.id == left.id ? 0 : 1) ? 'You picked the winner!' : 'Better luck next time', style: const TextStyle(color: YoloColors.textSoft)),
            ]),
          ).animate().scale(curve: Curves.elasticOut, duration: 700.ms),
          const SizedBox(height: 14),
          GoldButton(label: 'Challenge the winner', icon: Icons.mic_rounded, onPressed: () => context.pushReplacement('/music/karaoke', extra: demoSongs[7])),
        ],
      ]),
    );
  }
}

/// Mic grab: be the first to grab the mic when it appears (3 rounds vs bots).
class MicGrabScreen extends ConsumerStatefulWidget {
  const MicGrabScreen({super.key});

  @override
  ConsumerState<MicGrabScreen> createState() => _MicGrabScreenState();
}

class _MicGrabScreenState extends ConsumerState<MicGrabScreen> {
  final _rand = Random();
  Timer? _timer;
  int _round = 0; // 0 = not started
  bool _ready = false; // mic visible
  DateTime? _shownAt;
  int _wins = 0;
  String _message = 'Tap Start. When the mic appears, grab it first!';
  bool _done = false;

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _nextRound() {
    setState(() {
      _round++;
      _ready = false;
      _message = 'Round $_round of 3 — get ready…';
    });
    _timer = Timer(Duration(milliseconds: 1200 + _rand.nextInt(1500)), () {
      setState(() {
        _ready = true;
        _shownAt = DateTime.now();
        _message = 'GRAB!';
      });
      // Bot reaction time.
      _timer = Timer(Duration(milliseconds: 450 + _rand.nextInt(400)), () => _resolve(false));
    });
  }

  void _grab() {
    if (!_ready) {
      _timer?.cancel();
      setState(() => _message = 'Too early! Round lost.');
      _after();
      return;
    }
    _timer?.cancel();
    _resolve(true);
  }

  void _resolve(bool me) {
    final ms = _shownAt == null ? 0 : DateTime.now().difference(_shownAt!).inMilliseconds;
    setState(() {
      _ready = false;
      if (me) {
        _wins++;
        _message = 'You grabbed it in $ms ms!';
      } else {
        _message = 'Zara grabbed it first!';
      }
    });
    _after();
  }

  void _after() {
    if (_round >= 3) {
      setState(() => _done = true);
      if (_wins > 0) ref.read(sessionProvider.notifier).earn(_wins * 20, note: 'Mic grab wins');
    } else {
      _timer = Timer(const Duration(milliseconds: 1200), _nextRound);
    }
  }

  @override
  Widget build(BuildContext context) {
    return YoloPage(
      title: 'Mic grab',
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(children: [
          Text('Wins: $_wins / 3', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: YoloColors.gold)),
          const SizedBox(height: 12),
          Text(_message, key: const Key('micgrab-message'), textAlign: TextAlign.center, style: const TextStyle(fontSize: 16)),
          const Spacer(),
          Semantics(
            button: true,
            label: 'Grab the mic',
            child: GestureDetector(
              onTap: _round > 0 && !_done ? _grab : null,
              child: AnimatedContainer(
                duration: 150.ms,
                width: 200,
                height: 200,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: _ready ? YoloColors.goldGradient : null,
                  color: _ready ? null : Colors.white.withValues(alpha: 0.06),
                  boxShadow: _ready ? [BoxShadow(color: YoloColors.gold.withValues(alpha: 0.6), blurRadius: 40)] : null,
                ),
                child: Icon(Icons.mic_rounded, size: 96, color: _ready ? YoloColors.onGold : YoloColors.textMuted),
              ),
            ),
          ),
          const Spacer(),
          if (_round == 0) GoldButton(label: 'Start', onPressed: _nextRound),
          if (_done) ...[
            Text(_wins > 0 ? 'You won ${_wins * 20} coins!' : 'No wins this time', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
            const SizedBox(height: 12),
            GoldButton(label: 'Play again', onPressed: () {
              setState(() {
                _round = 0;
                _wins = 0;
                _done = false;
                _message = 'Tap Start. When the mic appears, grab it first!';
              });
            }),
          ],
        ]),
      ),
    );
  }
}

/// Upload your own track (title, genre, audio file). Goes to review before publishing.
class UploadMusicScreen extends ConsumerStatefulWidget {
  const UploadMusicScreen({super.key});

  @override
  ConsumerState<UploadMusicScreen> createState() => _UploadMusicScreenState();
}

class _UploadMusicScreenState extends ConsumerState<UploadMusicScreen> {
  final _title = TextEditingController();
  String _genre = 'Pop';
  String? _file;
  bool _rights = false;

  @override
  void dispose() {
    _title.dispose();
    super.dispose();
  }

  Future<void> _pick() async {
    try {
      final files = await FilePicker.pickFiles(type: FileType.audio);
      if (files.isNotEmpty) setState(() => _file = files.first.name);
    } catch (_) {
      if (mounted) showYoloToast(context, 'Could not open files');
    }
  }

  @override
  Widget build(BuildContext context) {
    final ok = _title.text.trim().length >= 2 && _rights;
    return YoloPage(
      title: 'Upload music',
      body: ListView(padding: const EdgeInsets.all(20), children: [
        GlassCard(
          onTap: _pick,
          child: Row(children: [
            const Icon(Icons.audio_file_rounded, color: YoloColors.gold, size: 36),
            const SizedBox(width: 12),
            Expanded(child: Text(_file ?? 'Choose an audio file (MP3, M4A)', style: const TextStyle(fontWeight: FontWeight.w600))),
          ]),
        ),
        const SizedBox(height: 14),
        TextField(controller: _title, maxLength: 40, onChanged: (_) => setState(() {}), decoration: const InputDecoration(labelText: 'Song title')),
        const SizedBox(height: 8),
        Wrap(spacing: 8, runSpacing: 8, children: [
          for (final g in ['Pop', 'Ballad', 'Dance', 'Lo-fi', 'Acoustic', 'Rap', 'Other'])
            ChoiceChip(
              label: Text(g),
              selected: _genre == g,
              onSelected: (_) => setState(() => _genre = g),
              selectedColor: YoloColors.gold,
              showCheckmark: false,
              labelStyle: TextStyle(color: _genre == g ? YoloColors.onGold : YoloColors.text, fontWeight: FontWeight.w700),
            ),
        ]),
        CheckboxListTile(
          contentPadding: EdgeInsets.zero,
          value: _rights,
          onChanged: (v) => setState(() => _rights = v ?? false),
          activeColor: YoloColors.gold,
          checkColor: YoloColors.onGold,
          title: const Text('I own the rights to this music or have permission to share it'),
        ),
        const SizedBox(height: 10),
        Opacity(
          opacity: ok ? 1 : 0.5,
          child: GoldButton(
            label: 'Upload',
            icon: Icons.upload_rounded,
            onPressed: ok
                ? () {
                    ref.read(musicProvider.notifier).upload(ref.read(sessionProvider)!, _title.text.trim(), _genre);
                    showYoloToast(context, 'Uploaded! It will be public after review.');
                    context.pop();
                  }
                : null,
          ),
        ),
      ]),
    );
  }
}
