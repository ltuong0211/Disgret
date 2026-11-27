// 1.1 Hồ sơ động lực – what the quiz answers say about the reels a user likes (spec 015,
// quiz-and-tags-design.md §5.1). Pure: the same stored answers always give the same preferences.
import '../motivation_quiz.dart';
import 'motivation_type.dart';
import 'reel_labels.dart';

/// Stored quiz answers: question id → chosen answer ids. A missing key or an empty list means
/// "Không chắc" (no preference).
typedef QuizAnswers = Map<String, List<String>>;

class ReelPreferences {
  const ReelPreferences({
    this.motivationTypes = const [],
    this.formatScores = const {},
    this.tone = VideoTone.unknown,
    this.messengers = const [],
    this.themes = const {},
    this.goal,
    this.avoidFlags = const {},
    this.avoidLanguages = const {},
  });

  /// No answers at all: every dimension is "no preference".
  static const ReelPreferences none = ReelPreferences();

  /// Top 2 reasons.
  final List<MotivationType> motivationTypes;

  /// Format → points (q5 +2 per chosen format, q8 +1). Read through [formatBonus].
  final Map<VideoFormat, int> formatScores;
  final VideoTone tone;
  final List<Messenger> messengers;

  /// The themes that answer the user's blockers (q9).
  final Set<ReelTheme> themes;
  final StudyGoal? goal;
  final Set<ReelFlag> avoidFlags;
  final Set<ReelLanguage> avoidLanguages;

  /// Formats with points, highest first (ties: first seen).
  List<VideoFormat> get formats {
    final firstSeen = formatScores.keys.toList();
    return [...firstSeen]..sort((a, b) {
      final byScore = formatScores[b]!.compareTo(formatScores[a]!);
      return byScore != 0 ? byScore : firstSeen.indexOf(a).compareTo(firstSeen.indexOf(b));
    });
  }

  /// §5.3: +2 for a favourite format (the highest points), +1 for a liked one, else 0.
  int formatBonus(VideoFormat format) {
    final points = formatScores[format];
    if (points == null || format == VideoFormat.other) return 0;
    final best = formatScores.values.reduce((a, b) => a > b ? a : b);
    return points == best ? 2 : 1;
  }

  /// §5.1. [legacyTypes] are the reasons stored by a version without answers: they are kept when
  /// q1 and q2 are unanswered and count as earlier answers when only q3/q4 are answered.
  factory ReelPreferences.fromAnswers(
    QuizAnswers answers, {
    List<MotivationType> legacyTypes = const [],
  }) {
    List<QuizAnswer> chosen(String questionId) {
      final question = questionById(questionId);
      final ids = answers[questionId] ?? const [];
      if (question == null) return const [];
      return [
        for (final answer in question.answers)
          if (ids.contains(answer.id)) answer,
      ];
    }

    final coreReasonsAnswered = chosen('q1').isNotEmpty || chosen('q2').isNotEmpty;
    final reasons = [
      if (!coreReasonsAnswered) ...legacyTypes,
      for (final id in ['q1', 'q2', 'q3', 'q4'])
        for (final answer in chosen(id)) answer.type!,
    ];

    final formatScores = <VideoFormat, int>{};
    void addFormats(String questionId, int points) {
      for (final answer in chosen(questionId)) {
        for (final format in answer.formats) {
          formatScores[format] = (formatScores[format] ?? 0) + points;
        }
      }
    }

    addFormats('q5', 2);
    addFormats('q8', 1);

    final toneAnswer = [...chosen('q7'), ...chosen('q8')].where((a) => a.tone != null);
    final goalAnswer = chosen('q10').where((a) => a.goal != null);

    return ReelPreferences(
      motivationTypes: topMotivationTypes(reasons),
      formatScores: formatScores,
      tone: toneAnswer.isEmpty ? VideoTone.unknown : toneAnswer.first.tone!,
      messengers: [for (final answer in chosen('q6')) ...answer.messengers].take(2).toList(),
      themes: {for (final answer in chosen('q9')) ...answer.themes},
      goal: goalAnswer.isEmpty ? null : goalAnswer.first.goal,
      avoidFlags: {for (final answer in chosen('q11')) ...answer.flags},
      avoidLanguages: {for (final answer in chosen('q11')) ...answer.languages},
    );
  }

  /// Reads stored answers, keeping only string lists.
  static QuizAnswers answersFromMap(Object? raw) {
    if (raw is! Map) return const {};
    return {
      for (final entry in raw.entries)
        if (entry.key is String && entry.value is List)
          entry.key as String: (entry.value as List).whereType<String>().toList(),
    };
  }
}
