import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import 'models.dart';
import 'providers.dart';
import 'repository.dart';

/// Music & singing. Demo tracks with original placeholder lyrics.
/// Production needs licensed music (a karaoke catalogue provider) + Laravel /music endpoints.
class Song {
  final int id;
  final String title;
  final String artist;
  final String genre;
  final int seconds;
  final int plays;
  final List<Color> cover;
  final List<String> lyrics;
  final bool uploaded;
  const Song(this.id, this.title, this.artist, this.genre, this.seconds, this.plays, this.cover, this.lyrics, {this.uploaded = false});
  String get length => '${seconds ~/ 60}:${(seconds % 60).toString().padLeft(2, '0')}';
}

const _l1 = ['Lights are low, the night is young', 'Every voice becomes a song', 'Take my hand and sing along', 'Here with you is where I belong', 'Golden stars above the room', 'Dancing to a midnight tune'];
const _l2 = ['Rain on the window, coffee in hand', 'Nobody else could understand', 'Slow little moments, soft little sighs', 'Watching the city open its eyes', 'Stay a while, the morning can wait', 'Love is a song we hum, never late'];
const _l3 = ['Turn it up, turn it loud', 'We are shining in the crowd', 'Jump up high and touch the sky', 'Tonight we never say goodbye', 'Hands up if you feel it too', 'This party is made for you'];

const demoSongs = [
  Song(1, 'Midnight Golden', 'Yolo Studio', 'Pop', 196, 128400, [Color(0xFFF59E0B), Color(0xFF7C3AED)], _l1),
  Song(2, 'Coffee Rain', 'Luna Bay', 'Lo-fi', 172, 96200, [Color(0xFF0EA5E9), Color(0xFF1E293B)], _l2),
  Song(3, 'Hands Up Tonight', 'Neon Kids', 'Dance', 204, 210300, [Color(0xFFEC4899), Color(0xFFF97316)], _l3),
  Song(4, 'Paper Hearts', 'Aria & Co', 'Ballad', 231, 54100, [Color(0xFFF472B6), Color(0xFF9D174D)], _l2),
  Song(5, 'Desert Moon', 'Sahara Sound', 'World', 188, 73900, [Color(0xFFD97706), Color(0xFF78350F)], _l1),
  Song(6, 'Electric Smile', 'Volt Twins', 'EDM', 179, 182000, [Color(0xFF22D3EE), Color(0xFF6366F1)], _l3),
  Song(7, 'Old Town Letters', 'Kenji M', 'Acoustic', 214, 31800, [Color(0xFF65A30D), Color(0xFF14532D)], _l2),
  Song(8, 'Starlight Duet', 'Mia & Leo', 'Pop', 199, 88700, [Color(0xFFA855F7), Color(0xFF312E81)], _l1),
];

class SingResult {
  final Song song;
  final int score; // 0..100
  final int coins;
  final String time;
  const SingResult(this.song, this.score, this.coins, this.time);
  String get grade => score >= 90 ? 'S' : (score >= 80 ? 'A' : (score >= 65 ? 'B' : 'C'));
}

class MusicState {
  final Set<int> favorites;
  final List<Song> uploads;
  final List<SingResult> history;
  final List<(YoloUser, Song)> queue; // singing room queue (first = singing now)
  final String mic; // phone, headset, bluetooth
  final String effect; // none, echo, reverb, studio
  final int? playing; // preview song id
  const MusicState({
    this.favorites = const {1, 3},
    this.uploads = const [],
    this.history = const [],
    this.queue = const [],
    this.mic = 'phone',
    this.effect = 'studio',
    this.playing,
  });

  MusicState copyWith({Set<int>? favorites, List<Song>? uploads, List<SingResult>? history, List<(YoloUser, Song)>? queue, String? mic, String? effect, int? playing, bool stop = false}) => MusicState(
        favorites: favorites ?? this.favorites,
        uploads: uploads ?? this.uploads,
        history: history ?? this.history,
        queue: queue ?? this.queue,
        mic: mic ?? this.mic,
        effect: effect ?? this.effect,
        playing: stop ? null : (playing ?? this.playing),
      );
}

final musicProvider = NotifierProvider<MusicController, MusicState>(MusicController.new);

class MusicController extends Notifier<MusicState> {
  final _rand = Random();

  @override
  MusicState build() => MusicState(queue: [(DemoUsers.kenji, demoSongs[1]), (DemoUsers.mia, demoSongs[7])]);

  List<Song> get all => [...state.uploads, ...demoSongs];

  void toggleFavorite(int id) =>
      state = state.copyWith(favorites: state.favorites.contains(id) ? ({...state.favorites}..remove(id)) : {...state.favorites, id});

  void play(int id) => state = state.playing == id ? state.copyWith(stop: true) : state.copyWith(playing: id);
  void setMic(String m) => state = state.copyWith(mic: m);
  void setEffect(String e) => state = state.copyWith(effect: e);

  /// Score a performance. [accuracy] 0..1 comes from the pitch meter (simulated in demo).
  SingResult finish(Song song, double accuracy) {
    final score = (55 + accuracy * 45).round().clamp(0, 100);
    final coins = score >= 90 ? 100 : (score >= 80 ? 60 : (score >= 65 ? 30 : 10));
    ref.read(sessionProvider.notifier).earn(coins, note: 'Karaoke: ${song.title}');
    final n = DateTime.now();
    final r = SingResult(song, score, coins, '${n.hour.toString().padLeft(2, '0')}:${n.minute.toString().padLeft(2, '0')}');
    state = state.copyWith(history: [r, ...state.history]);
    return r;
  }

  double simulatedAccuracy() => 0.55 + _rand.nextDouble() * 0.45;

  // --- Singing room queue ---
  void joinQueue(YoloUser me, Song song) {
    if (state.queue.any((e) => e.$1.id == me.id)) return;
    state = state.copyWith(queue: [...state.queue, (me, song)]);
  }

  void leaveQueue(int userId) => state = state.copyWith(queue: state.queue.where((e) => e.$1.id != userId).toList());
  void nextSinger() => state = state.copyWith(queue: state.queue.length > 1 ? state.queue.sublist(1) : const []);

  // --- Upload ---
  Song upload(YoloUser me, String title, String genre) {
    final s = Song(1000 + state.uploads.length, title, me.name, genre, 180, 0, const [Color(0xFF6366F1), Color(0xFFEC4899)], _l1, uploaded: true);
    state = state.copyWith(uploads: [s, ...state.uploads]);
    return s;
  }
}
