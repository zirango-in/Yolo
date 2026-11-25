import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'demo_content.dart';
import 'models.dart';
import 'repository.dart';

/// Moments feed. With Laravel: GET/POST /moments, DELETE /moments/{id}.
final momentsProvider = NotifierProvider<MomentsController, List<Moment>>(MomentsController.new);

class MomentsController extends Notifier<List<Moment>> {
  @override
  List<Moment> build() => [...demoMoments];

  Moment post(YoloUser me, {required String text, required String topic, List<String> images = const [], String? video}) {
    final m = Moment(DateTime.now().microsecondsSinceEpoch, me, text, topic, 'Just now', 0, 0, images: images, video: video);
    state = [m, ...state];
    return m;
  }

  void delete(int id) => state = state.where((m) => m.id != id).toList();
}

const allTopics = ['#Ludo', '#Music', '#Life', '#Family', '#Gaming', '#Poetry', '#Friends', '#Selfie'];

final followedTopicsProvider = NotifierProvider<TopicsController, Set<String>>(TopicsController.new);

class TopicsController extends Notifier<Set<String>> {
  @override
  Set<String> build() => {'#Music'};
  void toggle(String t) => state = state.contains(t) ? ({...state}..remove(t)) : {...state, t};
}

class MomentComment {
  final YoloUser author;
  final String text;
  final String time;
  const MomentComment(this.author, this.text, this.time);
}

/// Comments per moment. With Laravel: GET/POST /moments/{id}/comments.
final commentsProvider = NotifierProvider.family<CommentsController, List<MomentComment>, int>(CommentsController.new);

class CommentsController extends Notifier<List<MomentComment>> {
  CommentsController(this.momentId);
  final int momentId;

  @override
  List<MomentComment> build() => momentId < 1000
      ? const [
          MomentComment(DemoUsers.kenji, 'This is amazing!', '3m'),
          MomentComment(DemoUsers.mia, 'Count me in next time', '1m'),
        ]
      : const [];

  void add(YoloUser me, String text) {
    final t = text.trim();
    if (t.isEmpty) return;
    state = [...state, MomentComment(me, t, 'now')];
  }
}

/// Like count shown for a moment (base likes + mine).
int likeCount(Moment m, Set<int> liked) => m.likes + (liked.contains(m.id) ? 1 : 0);

/// Feed for a tab: 0 trending (most liked), 1 following (people + topics), 2 one topic.
List<Moment> feedFor(List<Moment> all, int tab, Set<int> following, Set<String> topics, String? topic, Set<int> blocked, {int? meId}) {
  final visible = all.where((m) => !blocked.contains(m.author.id));
  return switch (tab) {
    1 => visible.where((m) => following.contains(m.author.id) || topics.contains(m.topic) || m.author.id == meId).toList(),
    2 => visible.where((m) => m.topic == topic).toList(),
    _ => visible.toList(),
  };
}
