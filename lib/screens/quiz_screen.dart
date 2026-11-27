// 1.1 Hồ sơ động lực – màn "Làm lại quiz động lực" và "Giúp app hiểu bạn hơn", mở từ Cài đặt.
// Spec 015 FR-012: the full retake asks all 11 questions and replaces the stored answers; the
// extra part asks 4 and merges them. Leaving early changes nothing.
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../data/models/reel_preferences.dart';
import '../data/motivation_quiz.dart';
import '../l10n/app_strings.dart';
import '../providers/app_providers.dart';
import '../theme/app_theme.dart';
import '../widgets/quiz_question_view.dart';

class QuizScreen extends ConsumerStatefulWidget {
  const QuizScreen({this.extraOnly = false, super.key});

  /// True for "Giúp app hiểu bạn hơn" (only the extra part, merged into the profile).
  final bool extraOnly;

  @override
  ConsumerState<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends ConsumerState<QuizScreen> {
  late final List<QuizQuestion> _questions = widget.extraOnly ? extraQuestions : quizQuestions;
  final QuizAnswers _answers = {};
  int _index = 0;
  bool _saving = false;

  Future<void> _answer(List<String> answerIds) async {
    if (_saving) return; // Bấm đúp ở câu cuối không được lưu và đóng màn hai lần.
    _answers[_questions[_index].id] = answerIds;

    if (_index < _questions.length - 1) {
      setState(() => _index++);
      return;
    }

    _saving = true;
    final notifier = ref.read(profileProvider.notifier);
    await notifier.saveQuizAnswers(_answers, merge: widget.extraOnly);
    if (!mounted) return;

    final reasons = (ref.read(profileProvider)?.motivationTypes ?? const [])
        .map((type) => type.label)
        .join(', ');
    final message = widget.extraOnly ? AppStrings.quizExtraSaved : AppStrings.quizSaved(reasons);
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
    context.pop();
  }

  @override
  Widget build(BuildContext context) {
    final question = _questions[_index];
    // Từ câu thứ hai trở đi, nút quay lại về câu trước thay vì thoát khỏi quiz.
    return PopScope(
      canPop: _index == 0,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) setState(() => _index--);
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(widget.extraOnly ? AppStrings.quizExtra : AppStrings.quizRetakeTitle),
        ),
        body: SingleChildScrollView(
          // Mỗi câu một khoá riêng để câu mới luôn hiện từ trên cùng.
          key: ValueKey(_index),
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: QuizQuestionView(
            question: question,
            step: _index,
            total: _questions.length,
            selected: _answers[question.id] ?? const [],
            onAnswered: _answer,
          ),
        ),
      ),
    );
  }
}
