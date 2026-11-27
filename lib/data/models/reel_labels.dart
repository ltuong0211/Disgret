// 1.2 Kho nội dung – bộ nhãn dán cho reel (spec 015, quiz-and-tags-design.md §3).
// Every list is fixed: the team never invents a value. A missing or unknown value in reels.json
// falls back to the default, so a later catalogue edit never crashes an older app.

/// Looks up an enum value by its stored name; unknown or null gives [fallback].
T _byName<T extends Enum>(List<T> values, String? name, T fallback) {
  for (final value in values) {
    if (value.name == name) return value;
  }
  return fallback;
}

/// Reads a JSON list of names, dropping unknown ones and duplicates.
List<T> namesToList<T extends Enum>(List<T> values, Object? raw) {
  if (raw is! List) return const [];
  final result = <T>[];
  for (final name in raw) {
    for (final value in values) {
      if (value.name == name && !result.contains(value)) result.add(value);
    }
  }
  return result;
}

/// §3.2 Dạng video.
enum VideoFormat {
  interview('Phỏng vấn'),
  speech('Bài phát biểu'),
  edit('Video edit truyền động lực'),
  quote('Câu nói + nhạc nền'),
  journey('Hành trình chạm đến thành công'),
  studyWithMe('Học cùng mình'),
  dayInLife('Một ngày của người học giỏi'),
  story('Câu chuyện, phim ngắn, hoạt hình'),
  tips('Mẹo học'),
  other('Khác');

  const VideoFormat(this.label);
  final String label;

  static VideoFormat fromName(String? name) => _byName(values, name, other);
}

/// §3.3 Cảm xúc của video. [unknown] never matches a user's tone.
enum VideoTone {
  hype('Bùng nổ, hô hào'),
  toughLove('Nói thẳng'),
  calm('Nhẹ nhàng, ấm áp'),
  emotional('Chạm cảm xúc'),
  funny('Hài hước'),
  practical('Thực tế, chỉ việc'),
  unknown('Chưa rõ');

  const VideoTone(this.label);
  final String label;

  static VideoTone fromName(String? name) => _byName(values, name, unknown);
}

/// §3.4 Ai nói trong video. [none] never matches.
enum Messenger {
  celebrity('Người nổi tiếng'),
  achiever('Người giỏi trong nghề'),
  athlete('Vận động viên'),
  expert('Thầy cô, chuyên gia'),
  peer('Bạn cùng trang lứa'),
  ordinary('Người bình thường'),
  character('Nhân vật phim, hoạt hình'),
  none('Không có người nói');

  const Messenger(this.label);
  final String label;

  static Messenger fromName(String? name) => _byName(values, name, none);
}

/// §3.4 Người nói là người Việt hay nước ngoài (catalogue info, not scored yet).
enum Origin {
  vietnamese('Người Việt'),
  international('Người nước ngoài');

  const Origin(this.label);
  final String label;

  static Origin fromName(String? name) => _byName(values, name, vietnamese);
}

/// §3.5 Thông điệp chính.
enum ReelTheme {
  startSmall('Bắt đầu từ việc nhỏ'),
  digitalDetox('Bỏ điện thoại xuống'),
  fearCourage('Sợ thì vẫn làm'),
  futureSelf('Bản thân tương lai'),
  timeMatters('Thời gian không chờ ai'),
  ownPath('Đi đường của mình'),
  consistency('Đều đặn mỗi ngày'),
  discipline('Kỷ luật hơn cảm hứng'),
  comeback('Thất bại rồi đứng dậy'),
  selfCompassion('Nghỉ đúng cách'),
  examPressure('Vượt áp lực thi cử'),
  gratitude('Biết ơn');

  const ReelTheme(this.label);
  final String label;
}

/// §3.6 Mục tiêu học mà video hợp.
enum StudyGoal {
  exam('Kỳ thi'),
  language('Ngoại ngữ'),
  grades('Điểm số'),
  skill('Kỹ năng, nghề');

  const StudyGoal(this.label);
  final String label;
}

/// §3.7 Ngôn ngữ của video.
enum ReelLanguage {
  vi('Tiếng Việt'),
  enSub('Tiếng Anh có phụ đề'),
  en('Tiếng Anh không phụ đề');

  const ReelLanguage(this.label);
  final String label;

  static ReelLanguage fromName(String? name) => _byName(values, name, vi);
}

/// §3.7 Nội dung một số người không thích; dùng để lọc cứng.
enum ReelFlag {
  loud('La hét, nhạc rất to'),
  sad('Nhạc buồn'),
  wealthDisplay('Khoe tiền, xe, nhà'),
  fastCuts('Cắt cảnh nhanh');

  const ReelFlag(this.label);
  final String label;
}
