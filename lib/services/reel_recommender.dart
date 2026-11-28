// 1.3 Bộ đề xuất reel theo luật cố định, không dùng AI.
// Toàn bộ là hàm thuần: cùng dữ liệu vào luôn cho cùng kết quả, nên dễ giải thích và dễ test.
import 'dart:math';

import '../data/models/event.dart';
import '../data/models/motivation_type.dart';
import '../data/models/reel.dart';
import '../data/models/reel_labels.dart';
import '../data/models/reel_preferences.dart';
import '../data/models/user_profile.dart';

class ReelRecommender {
  const ReelRecommender(this.reels);

  /// At most this many reels per opening of the motivation step (before a session).
  static const int maxResults = 3;

  /// Playlist length per context (spec 002 FR-002): up to 3 before a session, 1 after a
  /// distraction.
  static int limitFor(String context) => context == ReelContext.distracted ? 1 : maxResults;

  /// Reel xem trong khoảng thời gian này được coi là "mới xem".
  static const Duration recentWindow = Duration(hours: 24);

  final List<Reel> reels;

  /// Score weights (spec 015, quiz-and-tags-design.md §5.3). The reason stays the largest weight.
  static const int reasonPoints = 3;
  static const int themePoints = 2;
  static const int tonePoints = 2;
  static const int messengerPoints = 1;
  static const int goalPoints = 1;
  static const int contextThemePoints = 2;
  static const int freshPoints = 1;
  static const int lastWatchedPenalty = 3;

  /// At most this many reason or theme matches count.
  static const int maxMatches = 2;

  /// §5.4: a reel of a new format may take the next slot if it is at most this far behind.
  static const int varietyMargin = 2;

  /// Themes that bring a user back after a distraction (§5.3 context bonus).
  static const Set<ReelTheme> distractedThemes = {ReelTheme.digitalDetox, ReelTheme.startSmall};

  /// §5.2: a reel with a flag or language the user never wants to see is never shown.
  static bool isAvoided(Reel reel, ReelPreferences preferences) =>
      reel.flags.any(preferences.avoidFlags.contains) ||
      preferences.avoidLanguages.contains(reel.language);

  /// §5.3. Every part is a whole number so the result can be explained ("vì bạn chọn …").
  static int score(
    Reel reel, {
    required List<MotivationType> motivationTypes,
    required Set<String> recentlyWatchedIds,
    required String? lastWatchedId,
    ReelPreferences preferences = ReelPreferences.none,
    String context = ReelContext.start,
  }) {
    final reasons = reel.tags.where(motivationTypes.contains).length;
    final themes = reel.themes.where(preferences.themes.contains).length;
    var points = reasonPoints * min<int>(reasons, maxMatches);
    points += themePoints * min<int>(themes, maxMatches);
    points += preferences.formatBonus(reel.format);
    if (reel.tone != VideoTone.unknown && reel.tone == preferences.tone) points += tonePoints;
    if (preferences.messengers.contains(reel.messenger)) points += messengerPoints;
    if (preferences.goal != null && reel.goals.contains(preferences.goal)) points += goalPoints;
    if (context == ReelContext.distracted && reel.themes.any(distractedThemes.contains)) {
      points += contextThemePoints;
    }
    if (!recentlyWatchedIds.contains(reel.id)) points += freshPoints;
    if (reel.id == lastWatchedId) points -= lastWatchedPenalty;
    return points;
  }

  /// Lọc theo ngữ cảnh rồi lấy các reel điểm cao nhất. Tag chỉ cộng điểm chứ không dùng để lọc,
  /// nên dù không reel nào trùng tag vẫn có reel phù hợp ngữ cảnh để xem.
  /// Điểm bằng nhau thì giữ thứ tự trong reels.json.
  /// Reel ghim cho ngữ cảnh này (trường pinFirst) luôn đứng đầu, bỏ qua điểm và luật
  /// "vừa xem gần nhất"; các chỗ còn lại vẫn xếp theo điểm.
  /// Spec 015: reels the user avoids are dropped first (pinned ones too), and the next slots
  /// prefer a format not shown yet (§5.4).
  /// Returns at most [limit] reels, by default [limitFor] the context.
  List<Reel> recommend(
    UserProfile? profile,
    String context,
    List<Event> history, {
    DateTime? now,
    int? limit,
  }) {
    final currentTime = now ?? DateTime.now();
    final watched = history
        .where(
          (event) =>
              event.type == EventType.reelWatched && event.meta[ReelWatchMeta.reelId] is String,
        )
        .toList();

    final recentlyWatchedIds = {
      for (final event in watched)
        if (currentTime.difference(event.time) < recentWindow) _reelIdOf(event),
    };
    final lastWatchedId = _lastWatchedId(watched);

    final motivationTypes = profile?.motivationTypes ?? const <MotivationType>[];
    final preferences = profile?.preferences ?? ReelPreferences.none;
    final allowed = reels.where((reel) => !isAvoided(reel, preferences)).toList();
    final pinned = allowed.where((reel) => reel.pinFirst.contains(context)).toList();
    final candidates = allowed
        .where((reel) => reel.context.contains(context) && !pinned.contains(reel))
        .toList();
    final points = {
      for (final reel in candidates)
        reel.id: score(
          reel,
          motivationTypes: motivationTypes,
          recentlyWatchedIds: recentlyWatchedIds,
          lastWatchedId: lastWatchedId,
          preferences: preferences,
          context: context,
        ),
    };

    final ranked = [...candidates]
      ..sort((a, b) {
        final byPoints = points[b.id]!.compareTo(points[a.id]!);
        // Hàm sort của Dart không đảm bảo giữ thứ tự cũ khi bằng điểm nên phải so thêm vị trí.
        return byPoints != 0 ? byPoints : candidates.indexOf(a).compareTo(candidates.indexOf(b));
      });

    final count = limit ?? limitFor(context);
    final playlist = [...pinned.take(count)];
    while (playlist.length < count && ranked.isNotEmpty) {
      final best = ranked.first;
      final shownFormats = {
        for (final reel in playlist)
          if (reel.format != VideoFormat.other) reel.format,
      };
      final fresh = ranked.where((reel) => !shownFormats.contains(reel.format)).firstOrNull;
      final next = fresh != null && points[fresh.id]! >= points[best.id]! - varietyMargin
          ? fresh
          : best;
      playlist.add(next);
      ranked.remove(next);
    }
    return playlist;
  }

  String _reelIdOf(Event event) => event.meta[ReelWatchMeta.reelId] as String;

  String? _lastWatchedId(List<Event> watched) {
    if (watched.isEmpty) return null;
    final latest = watched.reduce((a, b) => a.time.isAfter(b.time) ? a : b);
    return _reelIdOf(latest);
  }
}
