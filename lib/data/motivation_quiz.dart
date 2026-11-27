// 1.1 Hồ sơ động lực – nội dung quiz và cách tính điểm.
// Spec 015 (quiz-and-tags-design.md §4): 11 questions in two parts. The core part is asked in
// onboarding, the extra part ("Giúp app hiểu bạn hơn") later from Cài đặt. Every answer carries
// the reel labels it stands for, so the profile can be computed from the stored answer ids alone.
// Reason questions offer every motivation type once, so every type has the same chance.
import 'models/motivation_type.dart';
import 'models/reel_labels.dart';

/// Core = asked in onboarding; extra = asked later to sharpen the profile.
enum QuizPart { core, extra }

class QuizAnswer {
  const QuizAnswer(
    this.id,
    this.text, {
    this.hint,
    this.type,
    this.formats = const [],
    this.tone,
    this.messengers = const [],
    this.themes = const [],
    this.goal,
    this.flags = const [],
    this.languages = const [],
  });

  /// Stable id stored in the profile, e.g. `q5.journey`. Never reuse an id for another meaning.
  final String id;
  final String text;

  /// One short line under the answer, e.g. an example video.
  final String? hint;

  /// Chọn đáp án này thì loại động lực này được cộng 1 điểm.
  final MotivationType? type;
  final List<VideoFormat> formats;
  final VideoTone? tone;
  final List<Messenger> messengers;
  final List<ReelTheme> themes;
  final StudyGoal? goal;
  final List<ReelFlag> flags;
  final List<ReelLanguage> languages;
}

class QuizQuestion {
  const QuizQuestion(
    this.id,
    this.text,
    this.answers, {
    this.part = QuizPart.core,
    this.maxChoices = 1,
    this.skipText = 'Không chắc',
  });

  /// Stable id stored in the profile (q1–q11).
  final String id;
  final String text;
  final List<QuizAnswer> answers;
  final QuizPart part;

  /// 1 = single choice (a tap goes to the next question); more = multi choice with "Tiếp".
  final int maxChoices;

  /// The "no preference" button; choosing it stores no answer for this question.
  final String skipText;

  bool get isMultiChoice => maxChoices > 1;

  /// Câu hỏi về lý do học (q1–q4).
  bool get isReason => answers.every((answer) => answer.type != null);
}

const _q1 = QuizQuestion('q1', 'Điều gì khiến bạn muốn cố gắng nhất?', [
  QuizAnswer('q1.money', 'Có thu nhập tốt, không phải lo chuyện tiền', type: MotivationType.money),
  QuizAnswer('q1.family', 'Làm người thân tự hào và yên tâm', type: MotivationType.family),
  QuizAnswer('q1.career', 'Có công việc mình thật sự muốn làm', type: MotivationType.career),
  QuizAnswer('q1.prove', 'Chứng minh rằng mình làm được', type: MotivationType.proveYourself),
  QuizAnswer('q1.freedom', 'Được tự quyết định cuộc sống của mình', type: MotivationType.freedom),
  QuizAnswer('q1.growth', 'Hiểu sâu và giỏi lên mỗi ngày', type: MotivationType.growth),
  QuizAnswer(
    'q1.contribution',
    'Làm được điều có ích cho người khác',
    type: MotivationType.contribution,
  ),
]);

const _q2 = QuizQuestion('q2', 'Bạn hình dung mình 5 năm nữa thế nào?', [
  QuizAnswer('q2.freedom', 'Làm việc ở đâu, lúc nào là do mình chọn', type: MotivationType.freedom),
  QuizAnswer('q2.career', 'Đang ở đúng vị trí mình mơ ước', type: MotivationType.career),
  QuizAnswer('q2.growth', 'Giỏi thật sự một lĩnh vực mình thích', type: MotivationType.growth),
  QuizAnswer('q2.family', 'Lo được cho gia đình', type: MotivationType.family),
  QuizAnswer(
    'q2.prove',
    'Trở thành người mà trước đây ít ai tin',
    type: MotivationType.proveYourself,
  ),
  QuizAnswer(
    'q2.contribution',
    'Làm công việc giúp được nhiều người',
    type: MotivationType.contribution,
  ),
  QuizAnswer('q2.money', 'Tự chủ tài chính, có khoản tiết kiệm riêng', type: MotivationType.money),
]);

const _q3 = QuizQuestion('q3', 'Khi sắp bỏ cuộc, điều gì kéo bạn quay lại?', part: QuizPart.extra, [
  QuizAnswer('q3.prove', 'Không muốn thua chính mình', type: MotivationType.proveYourself),
  QuizAnswer('q3.money', 'Nghĩ tới mức sống mình muốn có', type: MotivationType.money),
  QuizAnswer('q3.growth', 'Tò mò muốn hiểu cho bằng được', type: MotivationType.growth),
  QuizAnswer('q3.freedom', 'Không muốn cả đời làm theo ý người khác', type: MotivationType.freedom),
  QuizAnswer('q3.family', 'Nhớ tới những người đang tin mình', type: MotivationType.family),
  QuizAnswer(
    'q3.contribution',
    'Nghĩ tới những người mình muốn giúp',
    type: MotivationType.contribution,
  ),
  QuizAnswer('q3.career', 'Nghĩ tới nghề mình đang theo đuổi', type: MotivationType.career),
]);

const _q4 = QuizQuestion('q4', 'Học tốt hơn sẽ mang lại cho bạn điều gì?', part: QuizPart.extra, [
  QuizAnswer('q4.career', 'Một bước tiến trong sự nghiệp', type: MotivationType.career),
  QuizAnswer('q4.contribution', 'Khả năng giúp đỡ người khác', type: MotivationType.contribution),
  QuizAnswer('q4.freedom', 'Nhiều lựa chọn hơn cho tương lai', type: MotivationType.freedom),
  QuizAnswer('q4.money', 'Cơ hội có mức lương cao hơn', type: MotivationType.money),
  QuizAnswer('q4.growth', 'Cảm giác hiểu được điều khó', type: MotivationType.growth),
  QuizAnswer('q4.prove', 'Niềm tin rằng mình làm được', type: MotivationType.proveYourself),
  QuizAnswer('q4.family', 'Bớt gánh nặng cho gia đình', type: MotivationType.family),
]);

const _q5 = QuizQuestion(
  'q5',
  'Bạn thường thấy có động lực sau khi xem kiểu video nào?',
  maxChoices: 2,
  [
    QuizAnswer(
      'q5.interview',
      'Phỏng vấn người nổi tiếng, người thành công',
      hint: 'Họ kể lại chặng đường của mình',
      formats: [VideoFormat.interview],
    ),
    QuizAnswer(
      'q5.speech',
      'Bài phát biểu truyền cảm hứng',
      hint: 'Một người nói trước khán giả',
      formats: [VideoFormat.speech],
    ),
    QuizAnswer(
      'q5.edit',
      'Video edit có nhạc và câu nói mạnh',
      hint: 'Cắt ghép nhanh, chữ lớn',
      formats: [VideoFormat.edit, VideoFormat.quote],
    ),
    QuizAnswer(
      'q5.journey',
      'Hành trình từ con số 0 đến thành công',
      hint: 'Trước và sau, từng bước một',
      formats: [VideoFormat.journey],
    ),
    QuizAnswer(
      'q5.studyWithMe',
      'Học cùng mình, một ngày của người học giỏi',
      hint: 'Bàn học, đồng hồ, vlog',
      formats: [VideoFormat.studyWithMe, VideoFormat.dayInLife],
    ),
    QuizAnswer(
      'q5.story',
      'Câu chuyện ngắn, phim ngắn, hoạt hình',
      hint: 'Có nhân vật và cốt truyện',
      formats: [VideoFormat.story],
    ),
    QuizAnswer(
      'q5.tips',
      'Mẹo học ngắn gọn, làm được ngay',
      hint: 'Pomodoro, cách lập kế hoạch…',
      formats: [VideoFormat.tips],
    ),
  ],
);

const _q6 = QuizQuestion(
  'q6',
  'Ai nói thì bạn dễ nghe nhất?',
  part: QuizPart.extra,
  maxChoices: 2,
  skipText: 'Không quan trọng',
  [
    QuizAnswer(
      'q6.celebrity',
      'Người nổi tiếng, thần tượng của mình',
      messengers: [Messenger.celebrity],
    ),
    QuizAnswer(
      'q6.achiever',
      'Doanh nhân, người giỏi trong nghề',
      messengers: [Messenger.achiever],
    ),
    QuizAnswer('q6.athlete', 'Vận động viên', messengers: [Messenger.athlete]),
    QuizAnswer('q6.expert', 'Thầy cô, chuyên gia', messengers: [Messenger.expert]),
    QuizAnswer('q6.peer', 'Bạn cùng tuổi đang học như mình', messengers: [Messenger.peer]),
    QuizAnswer(
      'q6.ordinary',
      'Người bình thường với câu chuyện thật',
      messengers: [Messenger.ordinary],
    ),
  ],
);

const _q7 = QuizQuestion('q7', 'Lúc lười học, kiểu "cú hích" nào hợp với bạn nhất?', [
  QuizAnswer('q7.hype', 'Nhạc mạnh, lời hô hào làm mình sôi máu', tone: VideoTone.hype),
  QuizAnswer('q7.toughLove', 'Ai đó nói thẳng, hơi "phũ" cũng được', tone: VideoTone.toughLove),
  QuizAnswer('q7.calm', 'Nhẹ nhàng, ấm áp, không áp lực', tone: VideoTone.calm),
  QuizAnswer('q7.emotional', 'Một câu chuyện chạm tới cảm xúc', tone: VideoTone.emotional),
  QuizAnswer('q7.funny', 'Chút hài hước cho nhẹ đầu', tone: VideoTone.funny),
  QuizAnswer('q7.practical', 'Chỉ cần ai đó chỉ việc cụ thể', tone: VideoTone.practical),
]);

const _q8 = QuizQuestion(
  'q8',
  'Bạn đang lướt mạng và thấy 5 video. Bạn bấm vào cái nào trước?',
  part: QuizPart.extra,
  [
    QuizAnswer(
      'q8.interview',
      'Một ca sĩ nổi tiếng kể về 5 năm bị từ chối',
      formats: [VideoFormat.interview],
      tone: VideoTone.emotional,
    ),
    QuizAnswer(
      'q8.edit',
      '60 giây: nhạc dồn dập + "Không ai học thay bạn"',
      formats: [VideoFormat.edit],
      tone: VideoTone.hype,
    ),
    QuizAnswer(
      'q8.dayInLife',
      'Vlog: 1 ngày ôn thi của thủ khoa',
      formats: [VideoFormat.dayInLife],
      tone: VideoTone.practical,
    ),
    QuizAnswer(
      'q8.journey',
      'Từ mất gốc đến 8.0 IELTS trong 1 năm',
      formats: [VideoFormat.journey],
      tone: VideoTone.emotional,
    ),
    QuizAnswer(
      'q8.story',
      'Hoạt hình 1 phút: con ốc sên chậm mà chắc',
      formats: [VideoFormat.story],
      tone: VideoTone.calm,
    ),
  ],
);

const _q9 = QuizQuestion('q9', 'Điều gì hay cản bạn bắt đầu học nhất?', maxChoices: 2, [
  QuizAnswer('q9.phone', 'Cứ cầm điện thoại là trôi', themes: [ReelTheme.digitalDetox]),
  QuizAnswer(
    'q9.tooMuch',
    'Việc nhiều quá, không biết bắt đầu từ đâu',
    themes: [ReelTheme.startSmall],
  ),
  QuizAnswer('q9.fear', 'Sợ làm không tốt nên né', themes: [ReelTheme.fearCourage]),
  QuizAnswer(
    'q9.noPoint',
    'Thấy học chẳng để làm gì',
    themes: [ReelTheme.futureSelf, ReelTheme.timeMatters],
  ),
  QuizAnswer('q9.tired', 'Mệt, hết năng lượng', themes: [ReelTheme.selfCompassion]),
  QuizAnswer('q9.compare', 'Hay so sánh với người khác rồi nản', themes: [ReelTheme.ownPath]),
  QuizAnswer(
    'q9.giveUp',
    'Làm được vài hôm rồi bỏ',
    themes: [ReelTheme.consistency, ReelTheme.discipline, ReelTheme.comeback],
  ),
]);

const _q10 = QuizQuestion(
  'q10',
  'Bạn đang học cho mục tiêu gần nhất nào?',
  skipText: 'Chưa có mục tiêu rõ',
  [
    QuizAnswer('q10.exam', 'Một kỳ thi sắp tới', goal: StudyGoal.exam),
    QuizAnswer('q10.language', 'Ngoại ngữ, chứng chỉ', goal: StudyGoal.language),
    QuizAnswer('q10.grades', 'Điểm số trên lớp', goal: StudyGoal.grades),
    QuizAnswer('q10.skill', 'Một kỹ năng, một nghề mình thích', goal: StudyGoal.skill),
  ],
);

const _q11 = QuizQuestion(
  'q11',
  'Có kiểu video nào bạn KHÔNG muốn thấy?',
  maxChoices: 5,
  skipText: 'Không có',
  [
    QuizAnswer('q11.loud', 'La hét, nhạc quá to', flags: [ReelFlag.loud]),
    QuizAnswer('q11.sad', 'Nhạc buồn, dễ chùng xuống', flags: [ReelFlag.sad]),
    QuizAnswer('q11.wealth', 'Khoe tiền, xe, nhà', flags: [ReelFlag.wealthDisplay]),
    QuizAnswer('q11.fastCuts', 'Cắt cảnh nhanh, nhấp nháy', flags: [ReelFlag.fastCuts]),
    QuizAnswer('q11.en', 'Tiếng Anh không có phụ đề', languages: [ReelLanguage.en]),
  ],
);

/// All 11 questions in design order (asked in this order by "Làm lại quiz động lực").
const List<QuizQuestion> quizQuestions = [_q1, _q2, _q3, _q4, _q5, _q6, _q7, _q8, _q9, _q10, _q11];

/// Onboarding: the questions that carry the most weight, reasons first.
const List<QuizQuestion> coreQuestions = [_q1, _q2, _q5, _q7, _q9, _q10, _q11];

/// "Giúp app hiểu bạn hơn".
const List<QuizQuestion> extraQuestions = [_q3, _q4, _q6, _q8];

/// The four reason questions, in question order.
const List<QuizQuestion> motivationQuestions = [_q1, _q2, _q3, _q4];

/// Finds a question by its stored id; null for an id from another version.
QuizQuestion? questionById(String id) {
  for (final question in quizQuestions) {
    if (question.id == id) return question;
  }
  return null;
}

/// Lấy 2 loại động lực điểm cao nhất từ các đáp án đã chọn.
/// Bằng điểm thì ưu tiên loại được chọn sớm hơn, vì câu đầu hỏi trực tiếp nhất.
List<MotivationType> topMotivationTypes(List<MotivationType> answers) {
  final scores = <MotivationType, int>{}; // Map của Dart giữ thứ tự thêm vào.
  for (final type in answers) {
    scores[type] = (scores[type] ?? 0) + 1;
  }

  final firstChosen = scores.keys.toList();
  final ranked = [...firstChosen]
    ..sort((a, b) {
      final byScore = scores[b]!.compareTo(scores[a]!);
      return byScore != 0 ? byScore : firstChosen.indexOf(a).compareTo(firstChosen.indexOf(b));
    });
  return ranked.take(2).toList();
}
