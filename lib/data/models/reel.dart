// 1.2 Kho nội dung – một video reel tạo động lực, đọc từ assets/reels/reels.json.
import 'motivation_type.dart';
import 'reel_labels.dart';

/// Ngữ cảnh đề xuất reel, chính là giá trị trong trường "context" của reels.json.
class ReelContext {
  ReelContext._();

  /// Trước khi học.
  static const String start = 'start';

  /// Sau khi xao nhãng.
  static const String distracted = 'distracted';
}

class Reel {
  const Reel({
    required this.id,
    required this.assetPath,
    required this.title,
    required this.tags,
    required this.lengthSec,
    required this.context,
    this.pinFirst = const [],
    this.format = VideoFormat.other,
    this.tone = VideoTone.unknown,
    this.messenger = Messenger.none,
    this.origin = Origin.vietnamese,
    this.themes = const [],
    this.goals = const [],
    this.language = ReelLanguage.vi,
    this.flags = const [],
  });

  final String id;
  final String assetPath;
  final String title;

  /// 1.2 Lý do học mà reel nói tới (JSON `motivation`, or the older `tags`).
  final List<MotivationType> tags;
  final int lengthSec;

  /// Các ngữ cảnh phù hợp với reel này, xem [ReelContext].
  final List<String> context;

  /// 1.3 Ghim reel: mở Reels với một trong các ngữ cảnh này thì reel luôn đứng đầu,
  /// không cần xét điểm. Ví dụ "Get back to work!" ghim cho ngữ cảnh "distracted".
  final List<String> pinFirst;

  /// Spec 015 labels (quiz-and-tags-design.md §3). All optional in JSON, with defaults.
  final VideoFormat format;
  final VideoTone tone;
  final Messenger messenger;
  final Origin origin;
  final List<ReelTheme> themes;
  final List<StudyGoal> goals;
  final ReelLanguage language;
  final List<ReelFlag> flags;

  /// Các trường khác trong JSON (source, creditUrl) không dùng nên được bỏ qua.
  factory Reel.fromMap(Map<String, dynamic> map) => Reel(
    id: map['id'] as String,
    assetPath: map['assetPath'] as String,
    title: map['title'] as String,
    tags: namesToList(MotivationType.values, map['motivation'] ?? map['tags']),
    lengthSec: map['lengthSec'] as int,
    context: (map['context'] as List).cast<String>().toList(),
    // Trường không bắt buộc: reel không ghim thì không cần ghi.
    pinFirst: (map['pinFirst'] as List? ?? const []).cast<String>().toList(),
    format: VideoFormat.fromName(map['format'] as String?),
    tone: VideoTone.fromName(map['tone'] as String?),
    messenger: Messenger.fromName(map['messenger'] as String?),
    origin: Origin.fromName(map['origin'] as String?),
    themes: namesToList(ReelTheme.values, map['theme']),
    goals: namesToList(StudyGoal.values, map['goal']),
    language: ReelLanguage.fromName(map['language'] as String?),
    flags: namesToList(ReelFlag.values, map['flags']),
  );
}
