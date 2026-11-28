// 5.1 Màn onboarding: chỉ hiện ở lần mở app đầu tiên. Tất cả chỉ được lưu vào Hive khi hoàn
// thành trang cuối.
// 5.3 (feature 003, FR-011, FR-011a): a story told by Gret. Four story pages explain the app, then
// one page per question: reel length, the motivation quiz (1.1), the apps that pull the user away
// (2.1, Android only), the first goal and habit (4.1). A first goal ends on "your sea is ready".
// Design: docs/superpowers/specs/2026-11-23-story-onboarding-design.md.
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../data/mascot_mood.dart';
import '../data/models/habit.dart';
import '../data/models/user_profile.dart';
import '../data/models/reel_preferences.dart';
import '../data/motivation_quiz.dart';
import '../data/repositories/blocked_apps_repository.dart';
import '../l10n/app_strings.dart';
import '../providers/account_providers.dart';
import '../providers/tour_providers.dart';
import '../providers/app_providers.dart';
import '../providers/sea_providers.dart';
import '../router/app_router.dart';
import '../theme/app_theme.dart';
import '../widgets/goal_form_fields.dart';
import '../widgets/gradient_pill_button.dart';
import '../widgets/habit_form_fields.dart';
import '../widgets/mascot/mascot_bubbles.dart';
import '../widgets/mascot/mascot_view.dart';
import '../widgets/motion/staggered_entrance.dart';
import '../widgets/quiz_question_view.dart';
import '../widgets/sticker_chip.dart';
import '../widgets/sea/sea_scene.dart';

/// What one onboarding page shows.
enum _PageKind { name, reelLength, quiz, apps, goal }

class _Page {
  const _Page(this.kind, [this.index = 0]);

  final _PageKind kind;

  /// Quiz question number.
  final int index;
}

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  static const List<int> _reelLengths = [15, 30, 60];

  final _formKey = GlobalKey<FormState>();
  final _goalTitle = TextEditingController();
  final _goalReason = TextEditingController();
  final _habitName = TextEditingController();
  final _habitMinutes = TextEditingController(text: '${HabitFormFields.defaultMinutes}');

  /// 4.1 Spec 024: the first habit gets a start time too.
  TimeOfDay _habitTime = _parseTime(Habit.defaultReminderTime);

  static TimeOfDay _parseTime(String text) {
    final parts = text.split(':');
    return TimeOfDay(hour: int.parse(parts.first), minute: int.parse(parts.last));
  }

  static String _formatTime(TimeOfDay time) =>
      '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';

  /// 5.1 Tên gọi (spec 007); replaying the introduction starts from the current name.
  final _name = TextEditingController();

  /// 1.1 Core quiz answers (spec 015): question id → answer ids, saved with the profile at the end.
  final QuizAnswers _answers = {};

  late int _reelLength;

  /// The reminder list being edited on the app page; saved only at the end.
  late final Set<String> _blockedApps;

  /// Xem lại onboarding từ Cài đặt khi đã có mục tiêu thì không hỏi lại mục tiêu.
  late final bool _needsFirstGoal;
  late final List<_Page> _pages;

  int _step = 0;
  bool _animationsOff = false;
  bool _saving = false;

  /// Everything is saved; the "your sea is ready" moment is showing.
  bool _seaReady = false;

  _Page get _page => _pages[_step];
  bool get _isLastPage => _step == _pages.length - 1;

  @override
  void initState() {
    super.initState();
    _reelLength = ref.read(profileProvider)?.preferredReelLength ?? UserProfile.defaultReelLength;
    _name.text = ref.read(profileProvider)?.displayName ?? '';
    _needsFirstGoal = ref.read(goalsProvider).isEmpty;
    _blockedApps = {...ref.read(blockedAppsProvider)};
    // The story pages are gone: how the app works is shown on Hôm nay itself by the guided tour
    // after these questions (spec 022). Gret asks the student's name first (spec 007).
    _pages = [
      const _Page(_PageKind.name),
      const _Page(_PageKind.reelLength),
      for (var i = 0; i < coreQuestions.length; i++) _Page(_PageKind.quiz, i),
      // Reminders when a distracting app opens only exist on Android (spec 003 FR-011a).
      if (ref.read(nativeBridgeProvider).isSupported) const _Page(_PageKind.apps),
      if (_needsFirstGoal) const _Page(_PageKind.goal),
    ];
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _animationsOff = MediaQuery.disableAnimationsOf(context);
  }

  @override
  void dispose() {
    _goalTitle.dispose();
    _goalReason.dispose();
    _habitName.dispose();
    _habitMinutes.dispose();
    _name.dispose();
    super.dispose();
  }

  void _goTo(int step) => setState(() => _step = step);

  void _goNext() {
    if (_saving) return;
    if (_isLastPage) {
      _finish();
    } else {
      _goTo(_step + 1);
    }
  }

  void _goBack() {
    if (_saving || _step == 0) return;
    _goTo(_step - 1);
  }

  void _selectAnswer(List<String> answerIds) {
    if (_saving) return;
    _answers[coreQuestions[_page.index].id] = answerIds;
    _goNext();
  }

  void _toggleApp(Set<String> packages, bool selected) {
    setState(() => selected ? _blockedApps.addAll(packages) : _blockedApps.removeAll(packages));
  }

  Future<void> _finish() async {
    if (_saving) return;
    if (_page.kind == _PageKind.goal && !_formKey.currentState!.validate()) return;
    setState(() => _saving = true); // Khoá nút để bấm hai lần không tạo trùng mục tiêu.

    if (_needsFirstGoal) {
      final goal = await ref
          .read(goalsProvider.notifier)
          .add(title: _goalTitle.text.trim(), reason: _goalReason.text.trim());
      await ref
          .read(habitsProvider.notifier)
          .add(
            goalId: goal.id,
            name: _habitName.text.trim(),
            minMinutesPerDay: int.parse(_habitMinutes.text),
            startTime: _formatTime(_habitTime),
          );
    }
    if (_pages.any((page) => page.kind == _PageKind.apps)) {
      await ref.read(blockedAppsProvider.notifier).replaceAll(_blockedApps);
    }
    // Đánh dấu xong sau cùng: lỡ tắt app giữa chừng thì lần sau vẫn vào lại onboarding.
    await ref
        .read(profileProvider.notifier)
        .completeOnboarding(
          UserProfile(
            motivationTypes: ReelPreferences.fromAnswers(_answers).motivationTypes,
            quizAnswers: Map.of(_answers),
            preferredReelLength: _reelLength,
            // Xem lại onboarding không được tắt chế độ demo đang bật.
            demoMode: ref.read(profileProvider)?.demoMode ?? false,
            displayName: UserProfile.cleanName(_name.text),
          ),
        );
    // 5.7 How the app works is shown next, on Hôm nay itself (spec 022).
    await ref.read(guidedTourProvider.notifier).schedule();
    if (!mounted) return;
    if (_needsFirstGoal && !_animationsOff) {
      setState(() => _seaReady = true);
      await Future<void>.delayed(AppMotion.seaReady);
      if (!mounted) return;
    }
    context.go(AppRoutes.today);
  }

  @override
  Widget build(BuildContext context) {
    // Từ trang thứ hai trở đi, nút Back của hệ thống về trang trước thay vì thoát app.
    return PopScope(
      canPop: _step == 0,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) _goBack();
      },
      child: Scaffold(
        body: SafeArea(
          child: _seaReady
              ? const _SeaReadyView()
              : Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(
                        AppSpacing.lg,
                        AppSpacing.sm,
                        AppSpacing.lg,
                        0,
                      ),
                      child: _StoryProgress(
                        key: const ValueKey('story-progress'),
                        count: _pages.length,
                        current: _step,
                      ),
                    ),
                    SizedBox(
                      height: AppSpacing.xxl,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
                        child: Align(
                          alignment: Alignment.centerRight,
                          // 6.3 A secondary link for students who already have an account
                          // (spec 016 FR-002), on the first page only.
                          child: _step == 0 && ref.watch(accountsAvailableProvider)
                              ? TextButton(
                                  onPressed: () => context.push(AppRoutes.accountSignIn),
                                  child: const Text(AppStrings.accountHaveAccount),
                                )
                              : null,
                        ),
                      ),
                    ),
                    Expanded(child: _buildQuestion(context)),
                    Padding(padding: const EdgeInsets.all(AppSpacing.lg), child: _buildButtons()),
                  ],
                ),
        ),
      ),
    );
  }

  Widget _buildQuestion(BuildContext context) {
    // Dùng SingleChildScrollView: ô nhập luôn được dựng nên Form kiểm tra đủ mọi ô.
    // Mỗi trang một khoá riêng để trang mới luôn hiện từ trên cùng.
    return SingleChildScrollView(
      key: ValueKey(_step),
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      child: switch (_page.kind) {
        _PageKind.name => _buildName(),
        _PageKind.reelLength => _buildReelLength(),
        _PageKind.quiz => QuizQuestionView(
          question: coreQuestions[_page.index],
          step: _page.index,
          total: coreQuestions.length,
          selected: _answers[coreQuestions[_page.index].id] ?? const [],
          onAnswered: _selectAnswer,
        ),
        _PageKind.apps => _buildApps(context),
        _PageKind.goal => _buildFirstGoal(context),
      },
    );
  }

  /// 5.1 Gret asks what to call the student; leaving it empty is fine (spec 007).
  Widget _buildName() {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const _GretAsks(text: AppStrings.nameQuestion),
        const SizedBox(height: AppSpacing.lg),
        TextField(
          controller: _name,
          textCapitalization: TextCapitalization.words,
          maxLength: UserProfile.maxNameLength,
          decoration: const InputDecoration(
            labelText: AppStrings.nameLabel,
            hintText: AppStrings.nameHint,
          ),
        ),
        Text(
          AppStrings.namePrivacy,
          style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
        ),
      ],
    );
  }

  Widget _buildReelLength() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const _GretAsks(text: AppStrings.reelLengthQuestion),
        const SizedBox(height: AppSpacing.lg),
        Wrap(
          alignment: WrapAlignment.center,
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: [
            for (var i = 0; i < _reelLengths.length; i++)
              StickerChip(
                label: AppStrings.reelSeconds(_reelLengths[i]),
                icon: AppIcons.reels,
                colour: const [3, 0, 9][i],
                large: true,
                selected: _reelLengths[i] == _reelLength,
                onSelected: (_) => setState(() => _reelLength = _reelLengths[i]),
              ),
          ],
        ),
      ],
    );
  }

  Widget _buildApps(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const _GretAsks(text: AppStrings.appsQuestion),
        const SizedBox(height: AppSpacing.md),
        Text(
          AppStrings.appsHint,
          style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
        ),
        const SizedBox(height: AppSpacing.lg),
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: [
            for (final (i, MapEntry(key: name, value: packages))
                in BlockedAppsRepository.onboardingApps.entries.indexed)
              StickerChip(
                label: name,
                colour: const [8, 7, 9, 0, 5][i % 5],
                large: true,
                selected: _blockedApps.containsAll(packages),
                onSelected: (selected) => _toggleApp(packages, selected),
              ),
          ],
        ),
      ],
    );
  }

  Widget _buildFirstGoal(BuildContext context) {
    final theme = Theme.of(context);

    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SpeechBubble(text: AppStrings.gretGoalPrompt),
          const Center(
            child: MascotView(mood: MascotMood.happy, size: AppMascot.small),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(AppStrings.firstGoalTitle, style: theme.textTheme.headlineSmall),
          const SizedBox(height: AppSpacing.xs),
          Text(
            AppStrings.firstGoalMessage,
            style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
          ),
          const SizedBox(height: AppSpacing.lg),
          GoalFormFields(titleController: _goalTitle, reasonController: _goalReason),
          const SizedBox(height: AppSpacing.md),
          HabitFormFields(nameController: _habitName, minutesController: _habitMinutes),
          const SizedBox(height: AppSpacing.sm),
          // 4.1 Spec 024: when to study, reminded at that time; repetition is edited later.
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(AppIcons.alarm),
            title: const Text(AppStrings.firstHabitTime),
            trailing: Text(_formatTime(_habitTime), style: theme.textTheme.titleMedium),
            onTap: () async {
              final picked = await showTimePicker(context: context, initialTime: _habitTime);
              if (picked != null) setState(() => _habitTime = picked);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildButtons() {
    // Ở trang quiz, chọn thẻ là tự sang câu tiếp nên không cần nút đi tiếp.
    final nextLabel = switch (_page.kind) {
      _PageKind.quiz => null,
      _PageKind.goal => AppStrings.enterApp,
      _ => _isLastPage ? AppStrings.enterApp : AppStrings.continueLabel,
    };
    return Row(
      children: [
        if (_step > 0)
          OutlinedButton(onPressed: _saving ? null : _goBack, child: const Text(AppStrings.back)),
        if (nextLabel != null) ...[
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: GradientPillButton(
              label: nextLabel,
              height: AppButton.compact,
              onPressed: _saving ? null : _goNext,
            ),
          ),
        ],
      ],
    );
  }
}

/// One segment per page; the current and past pages are full.
class _StoryProgress extends StatelessWidget {
  const _StoryProgress({required this.count, required this.current, super.key});

  final int count;
  final int current;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Semantics(
      label: AppStrings.storyProgress(current + 1, count),
      child: ExcludeSemantics(
        child: Row(
          children: [
            for (var i = 0; i < count; i++) ...[
              if (i > 0) const SizedBox(width: AppStory.segmentGap),
              Expanded(
                child: ClipRRect(
                  borderRadius: AppRadius.pillBorder,
                  child: Container(
                    height: AppStory.segmentHeight,
                    color: i <= current ? scheme.primary : scheme.outlineVariant,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Gret asking a question in a thought bubble, as on the quiz pages.
class _GretAsks extends StatelessWidget {
  const _GretAsks({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        const MascotView(mood: MascotMood.neutral, size: AppMascot.small),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: ThoughtBubble(text: text, style: Theme.of(context).textTheme.titleMedium),
        ),
      ],
    );
  }
}

/// "Biển của bạn đã sẵn sàng": the user's sea with a happy Gret, shown for about 1.2 s after
/// the first goal is saved (spec 003 FR-011).
class _SeaReadyView extends ConsumerWidget {
  const _SeaReadyView();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final clarity = ref.watch(seaStateProvider).clarity;

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: StaggeredEntrance(
          children: [
            SeaScene(clarity: clarity, mood: MascotMood.happy, variant: SeaSceneVariant.compact),
            const SizedBox(height: AppSpacing.lg),
            Text(
              AppStrings.seaReady,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.headlineSmall,
            ),
          ],
        ),
      ),
    );
  }
}
