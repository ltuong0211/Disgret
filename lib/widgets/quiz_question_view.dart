// 1.1 Hồ sơ động lực – một câu hỏi quiz dạng thẻ chọn, dùng ở onboarding và màn làm lại quiz.
// 5.3 (feature 003, FR-011): the question sits in Gret's thought bubble, answers are large cards
// with an icon, and Gret is happy for a moment after an answer before the next question. With
// "remove animations" on, the answer goes through at once.
// Spec 015: multi-choice questions toggle up to `maxChoices` cards and go on with "Tiếp"; every
// question has a "Không chắc" button that stores no answer.
import 'dart:async';

import 'package:material_ui/material_ui.dart';

import '../data/mascot_mood.dart';
import '../data/models/motivation_type.dart';
import '../data/motivation_quiz.dart';
import '../l10n/app_strings.dart';
import '../theme/app_theme.dart';
import 'mascot/mascot_bubbles.dart';
import 'mascot/mascot_view.dart';

class QuizQuestionView extends StatefulWidget {
  const QuizQuestionView({
    required this.question,
    required this.step,
    required this.total,
    required this.selected,
    required this.onAnswered,
    super.key,
  });

  final QuizQuestion question;

  /// Zero-based position of this question in the quiz being asked, and the number of questions.
  final int step;
  final int total;

  /// Answer ids chosen before, if the user came back to this question.
  final List<String> selected;

  /// The chosen answer ids; empty for "Không chắc".
  final ValueChanged<List<String>> onAnswered;

  @override
  State<QuizQuestionView> createState() => _QuizQuestionViewState();
}

class _QuizQuestionViewState extends State<QuizQuestionView> {
  /// Single choice: the answer Gret is reacting to; further taps wait until it has gone through.
  String? _picked;
  Timer? _reaction;

  /// Multi choice: the cards switched on so far.
  late List<String> _chosen = [...widget.selected];

  @override
  void didUpdateWidget(QuizQuestionView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.question.id != widget.question.id) {
      _reaction?.cancel();
      _picked = null;
      _chosen = [...widget.selected];
    }
  }

  @override
  void dispose() {
    _reaction?.cancel();
    super.dispose();
  }

  void _pick(String answerId) {
    if (_picked != null) return;
    if (MediaQuery.disableAnimationsOf(context)) {
      widget.onAnswered([answerId]);
      return;
    }
    setState(() => _picked = answerId);
    _reaction = Timer(AppMotion.reaction, () {
      if (mounted) widget.onAnswered([answerId]);
    });
  }

  /// Taps past the limit are ignored: the user unticks a card first.
  void _toggle(String answerId) {
    setState(() {
      if (_chosen.contains(answerId)) {
        _chosen.remove(answerId);
      } else if (_chosen.length < widget.question.maxChoices) {
        _chosen.add(answerId);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final question = widget.question;
    final multi = question.isMultiChoice;
    final reacting = _picked != null;

    bool isSelected(String id) =>
        multi ? _chosen.contains(id) : (_picked ?? widget.selected.firstOrNull) == id;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            _StepDots(
              key: const ValueKey('quiz-step-dots'),
              current: widget.step,
              total: widget.total,
            ),
            const Spacer(),
            Text(
              AppStrings.quizStep(widget.step + 1, widget.total),
              style: theme.textTheme.labelLarge?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.lg),
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            AnimatedScale(
              scale: reacting ? AppMascot.reactionScale : 1,
              duration: AppMotion.entrance,
              curve: Curves.easeOutBack,
              child: MascotView(
                mood: reacting ? MascotMood.happy : MascotMood.neutral,
                size: AppMascot.small,
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: ThoughtBubble(text: question.text, style: theme.textTheme.titleMedium),
            ),
          ],
        ),
        if (multi) ...[
          const SizedBox(height: AppSpacing.sm),
          Text(
            AppStrings.quizChooseUpTo(question.maxChoices, question.answers.length),
            style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
          ),
        ],
        const SizedBox(height: AppSpacing.lg),
        for (final answer in question.answers) ...[
          _AnswerCard(
            answer: answer,
            icon: _iconFor(question, answer),
            isSelected: isSelected(answer.id),
            onTap: () => multi ? _toggle(answer.id) : _pick(answer.id),
          ),
          const SizedBox(height: AppSpacing.sm),
        ],
        const SizedBox(height: AppSpacing.xs),
        Row(
          children: [
            Expanded(
              child: TextButton(
                key: const ValueKey('quiz-unsure'),
                onPressed: reacting ? null : () => widget.onAnswered(const []),
                child: Text(question.skipText),
              ),
            ),
            if (multi) ...[
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: FilledButton(
                  key: const ValueKey('quiz-next'),
                  onPressed: _chosen.isEmpty ? null : () => widget.onAnswered([..._chosen]),
                  child: const Text(AppStrings.quizNext),
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }

  static IconData _iconFor(QuizQuestion question, QuizAnswer answer) {
    final type = answer.type;
    if (type != null) {
      return switch (type) {
        MotivationType.money => AppIcons.motivationMoney,
        MotivationType.family => AppIcons.motivationFamily,
        MotivationType.career => AppIcons.motivationCareer,
        MotivationType.proveYourself => AppIcons.motivationProveYourself,
        MotivationType.freedom => AppIcons.motivationFreedom,
        MotivationType.growth => AppIcons.motivationGrowth,
        MotivationType.contribution => AppIcons.motivationContribution,
      };
    }
    return switch (question.id) {
      'q5' => AppIcons.quizFormat,
      'q6' => AppIcons.quizMessenger,
      'q7' => AppIcons.quizTone,
      'q8' => AppIcons.quizScenario,
      'q9' => AppIcons.quizBlocker,
      'q10' => AppIcons.quizGoal,
      'q11' => AppIcons.quizAvoid,
      _ => AppIcons.quizUnsure,
    };
  }
}

/// One dot per question: done and current in the primary colour, the current one wider.
class _StepDots extends StatelessWidget {
  const _StepDots({required this.current, required this.total, super.key});

  final int current;
  final int total;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    // The "Câu n/N" text next to the dots already tells screen readers the step.
    return ExcludeSemantics(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var i = 0; i < total; i++)
            Padding(
              padding: const EdgeInsets.only(right: AppSpacing.xs),
              child: Container(
                width: i == current ? AppSpacing.lg : AppSpacing.sm,
                height: AppSpacing.sm,
                decoration: BoxDecoration(
                  color: i <= current ? scheme.primary : scheme.outlineVariant,
                  borderRadius: AppRadius.pillBorder,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _AnswerCard extends StatelessWidget {
  const _AnswerCard({
    required this.answer,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  final QuizAnswer answer;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final accent = scheme.secondary;

    // One node per answer: label, tap and "selected" together for screen readers.
    return MergeSemantics(
      child: Semantics(
        button: true,
        selected: isSelected,
        child: Card(
          clipBehavior: Clip.antiAlias,
          color: isSelected ? scheme.secondaryContainer : null,
          // Đáp án đang chọn được làm nổi bằng viền màu nhấn.
          shape: isSelected
              ? RoundedRectangleBorder(
                  borderRadius: AppRadius.cardBorder,
                  side: BorderSide(color: accent, width: 1.5),
                )
              : null,
          child: InkWell(
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Row(
                children: [
                  Container(
                    width: AppStatCard.badge,
                    height: AppStatCard.badge,
                    decoration: BoxDecoration(
                      color: isSelected ? accent : scheme.primaryContainer,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      icon,
                      size: AppStatCard.icon,
                      color: isSelected ? scheme.onSecondary : scheme.onPrimaryContainer,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(answer.text, style: theme.textTheme.bodyLarge),
                        if (answer.hint case final hint?)
                          Text(
                            hint,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: scheme.onSurfaceVariant,
                            ),
                          ),
                      ],
                    ),
                  ),
                  if (isSelected) ...[
                    const SizedBox(width: AppSpacing.sm),
                    Icon(AppIcons.check, color: accent),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
