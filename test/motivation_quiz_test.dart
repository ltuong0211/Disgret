// 1.1 Unit test nội dung quiz và cách tính điểm.
import 'package:flutter_test/flutter_test.dart';
import 'package:focus_app/data/models/motivation_type.dart';
import 'package:focus_app/data/motivation_quiz.dart';

void main() {
  const money = MotivationType.money;
  const family = MotivationType.family;
  const career = MotivationType.career;
  const prove = MotivationType.proveYourself;
  const freedom = MotivationType.freedom;

  group('Nội dung quiz', () {
    test('11 questions: 7 in the core part, 4 in the extra part (spec 015)', () {
      expect(quizQuestions, hasLength(11));
      expect(coreQuestions.map((q) => q.id), ['q1', 'q2', 'q5', 'q7', 'q9', 'q10', 'q11']);
      expect(extraQuestions.map((q) => q.id), ['q3', 'q4', 'q6', 'q8']);
      expect(coreQuestions.every((q) => q.part == QuizPart.core), isTrue);
      expect(extraQuestions.every((q) => q.part == QuizPart.extra), isTrue);
    });

    test('Có đúng 4 câu về lý do học', () {
      expect(motivationQuestions, hasLength(4));
      expect(motivationQuestions.every((q) => q.isReason), isTrue);
    });

    test('Câu lý do nào cũng có đủ 7 loại động lực, mỗi loại một đáp án', () {
      for (final question in motivationQuestions) {
        final types = question.answers.map((answer) => answer.type);
        expect(types, unorderedEquals(MotivationType.values), reason: question.text);
      }
    });

    test('Thứ tự đáp án thay đổi giữa các câu để không lộ quy luật', () {
      final orders = motivationQuestions
          .map((question) => question.answers.map((answer) => answer.type!.name).join(','))
          .toSet();
      expect(orders, hasLength(motivationQuestions.length));
    });

    test('Question and answer ids are unique and prefixed by their question', () {
      final questionIds = quizQuestions.map((q) => q.id).toList();
      expect(questionIds.toSet(), hasLength(questionIds.length));
      final answerIds = [
        for (final question in quizQuestions)
          for (final answer in question.answers) answer.id,
      ];
      expect(answerIds.toSet(), hasLength(answerIds.length));
      for (final question in quizQuestions) {
        for (final answer in question.answers) {
          expect(answer.id, startsWith('${question.id}.'));
        }
      }
    });

    test('Every non-reason answer carries at least one label', () {
      for (final question in quizQuestions.where((q) => !q.isReason)) {
        for (final answer in question.answers) {
          final labels =
              answer.formats.length +
              answer.messengers.length +
              answer.themes.length +
              answer.flags.length +
              answer.languages.length +
              (answer.tone == null ? 0 : 1) +
              (answer.goal == null ? 0 : 1);
          expect(labels, greaterThan(0), reason: answer.id);
        }
      }
    });

    test('Choice limits follow the design: q5, q6, q9 up to 2; q11 all; others single', () {
      final limits = {for (final q in quizQuestions) q.id: q.maxChoices};
      expect(limits['q5'], 2);
      expect(limits['q6'], 2);
      expect(limits['q9'], 2);
      expect(limits['q11'], questionById('q11')!.answers.length);
      for (final id in ['q1', 'q2', 'q3', 'q4', 'q7', 'q8', 'q10']) {
        expect(limits[id], 1, reason: id);
      }
    });

    test('questionById: unknown id → null', () {
      expect(questionById('q5')?.id, 'q5');
      expect(questionById('q99'), isNull);
    });
  });

  group('Tính điểm', () {
    test('Lấy 2 loại có điểm cao nhất, xếp theo điểm', () {
      expect(topMotivationTypes([money, career, career, career]), [career, money]);
    });

    test('Hai loại mỗi loại 2 điểm', () {
      expect(topMotivationTypes([family, freedom, family, freedom]), [family, freedom]);
    });

    test('Bằng điểm thì ưu tiên loại được chọn sớm hơn', () {
      expect(topMotivationTypes([freedom, prove, money, career]), [freedom, prove]);
      expect(topMotivationTypes([career, freedom, freedom, career]), [career, freedom]);
    });

    test('Điểm cao hơn thắng dù được chọn sau', () {
      expect(topMotivationTypes([money, family, career, career]), [career, money]);
    });

    test('Cả 4 câu chọn cùng một loại thì chỉ có 1 loại', () {
      expect(topMotivationTypes([prove, prove, prove, prove]), [prove]);
    });
  });
}
