// 6.2 Mô hình dữ liệu – hồ sơ người dùng (chỉ có một, lưu local).
import 'motivation_type.dart';
import 'reel_labels.dart';
import 'reel_preferences.dart';

class UserProfile {
  const UserProfile({
    required this.motivationTypes,
    required this.preferredReelLength,
    this.demoMode = false,
    this.displayName = '',
    this.quizAnswers = const {},
  });

  static const int defaultReelLength = 30;

  /// 5.1 Longest name kept, in Unicode code points (spec 007 FR-002).
  static const int maxNameLength = 20;

  /// Trims, collapses inner spaces and keeps the first [maxNameLength] code points, so accented
  /// letters typed on a phone and emoji are never cut in half.
  static String cleanName(String raw) {
    final words = raw.trim().split(RegExp(r'\s+')).where((word) => word.isNotEmpty);
    final joined = words.join(' ');
    return String.fromCharCodes(joined.runes.take(maxNameLength)).trimRight();
  }

  /// 1.1 Hai loại động lực có điểm quiz cao nhất.
  final List<MotivationType> motivationTypes;

  /// Độ dài reel ưa thích, tính bằng giây.
  final int preferredReelLength;

  /// Chế độ demo: đồng hồ phiên học và giờ nghỉ chạy nhanh hơn (xem
  /// FocusSessionTimer.demoTimeScale), để test và trình bày nhanh.
  final bool demoMode;

  /// 5.1 Tên gọi (spec 007, ADR-0012): only for the greeting on Hôm nay; empty means none. Kept on
  /// the phone, never in events or exports.
  final String displayName;

  /// 1.1 Quiz answers (spec 015): question id → answer ids. Profiles from before spec 015 have
  /// none; their [motivationTypes] are kept.
  final QuizAnswers quizAnswers;

  /// What the answers say about the reels this user likes (quiz-and-tags-design.md §5.1).
  ReelPreferences get preferences =>
      ReelPreferences.fromAnswers(quizAnswers, legacyTypes: motivationTypes);

  UserProfile copyWith({
    List<MotivationType>? motivationTypes,
    bool? demoMode,
    String? displayName,
    QuizAnswers? quizAnswers,
  }) => UserProfile(
    motivationTypes: motivationTypes ?? this.motivationTypes,
    preferredReelLength: preferredReelLength,
    demoMode: demoMode ?? this.demoMode,
    displayName: displayName ?? this.displayName,
    quizAnswers: quizAnswers ?? this.quizAnswers,
  );

  Map<String, dynamic> toMap() => {
    'motivationTypes': motivationTypes.map((type) => type.name).toList(),
    'preferredReelLength': preferredReelLength,
    'demoMode': demoMode,
    'displayName': displayName,
    'quizAnswers': quizAnswers,
  };

  factory UserProfile.fromMap(Map<String, dynamic> map) => UserProfile(
    // Unknown names (from a later version) are dropped instead of failing the whole profile.
    motivationTypes: namesToList(MotivationType.values, map['motivationTypes']),
    preferredReelLength: map['preferredReelLength'] as int,
    // Hồ sơ lưu từ trước khi có trường này thì coi như chưa bật.
    demoMode: map['demoMode'] as bool? ?? false,
    // Profiles saved before the name existed have none.
    displayName: map['displayName'] as String? ?? '',
    quizAnswers: ReelPreferences.answersFromMap(map['quizAnswers']),
  );
}
