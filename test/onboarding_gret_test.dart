// 5.3 Gret và biển sống: onboarding as a story told by Gret (spec 003 US2, FR-011, FR-011a; tasks
// T018–T020, T029). The saved data are unchanged apart from the app choice; these tests cover what
// the redesign adds.
import 'package:flutter_test/flutter_test.dart';
import 'package:focus_app/data/mascot_mood.dart';
import 'package:focus_app/data/repositories/blocked_apps_repository.dart';
import 'package:focus_app/data/repositories/goal_repository.dart';
import 'package:focus_app/data/repositories/habit_repository.dart';
import 'package:focus_app/data/repositories/profile_repository.dart';
import 'package:focus_app/l10n/app_strings.dart';
import 'package:focus_app/theme/app_theme.dart';
import 'package:focus_app/widgets/mascot/mascot_bubbles.dart';
import 'package:focus_app/widgets/mascot/mascot_view.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive/hive.dart';
import 'package:material_ui/material_ui.dart';
import 'package:video_player_platform_interface/video_player_platform_interface.dart';

import 'test_helpers.dart';

const List<String> _storyLines = [
  AppStrings.storyHello,
  AppStrings.storyScroll,
  AppStrings.storyStudy,
  AppStrings.storyCallBack,
];

Future<void> _enterField(WidgetTester tester, String label, String text) async {
  await tester.enterText(find.widgetWithText(TextFormField, label), text);
  await tester.pump();
}

/// From the first page to the first quiz question (name left empty, reel length kept).
Future<void> _toQuiz(WidgetTester tester) async {
  await tapAndSettle(tester, find.text(AppStrings.continueLabel));
  await tapAndSettle(tester, find.text(AppStrings.continueLabel));
}

/// Gret's question about the name, in its thought bubble (spec 007).
Finder get _nameQuestion =>
    find.descendant(of: find.byType(ThoughtBubble), matching: find.text(AppStrings.nameQuestion));

/// The 7 core questions (spec 015).
Future<void> _answerQuiz(WidgetTester tester) => answerCoreQuiz(tester);

/// From the first page to the first-goal page, keeping the suggested apps.
Future<void> _toFirstGoal(WidgetTester tester) async {
  await _toQuiz(tester);
  await _answerQuiz(tester);
  await tapAndSettle(tester, find.text(AppStrings.continueLabel));
}

Future<void> _fillFirstGoal(WidgetTester tester) async {
  await _enterField(tester, 'Tên mục tiêu', 'Qua môn Toán');
  await _enterField(tester, 'Vì sao bạn muốn điều này?', 'Để ra trường đúng hạn');
  await _enterField(tester, 'Tên thói quen', 'Làm đề');
}

/// Turns the system "remove animations" setting off again (pumpApp turns it on).
Future<void> _animationsOn(WidgetTester tester) async {
  tester.platformDispatcher.accessibilityFeaturesTestValue = const FakeAccessibilityFeatures();
  await tester.pump();
}

MascotMood _gretMood(WidgetTester tester) =>
    tester.widget<MascotView>(find.byType(MascotView)).mood;

void main() {
  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  setUp(() async {
    await openMemoryBoxes();
    VideoPlayerPlatform.instance = FakeVideoPlayerPlatform();
  });

  tearDown(() async {
    await Hive.close();
  });

  group('First page (spec 022: the story pages are gone)', () {
    testWidgets('Onboarding opens on Gret asking the name, with progress and no Back', (
      tester,
    ) async {
      await pumpApp(tester);
      expect(_nameQuestion, findsOneWidget);
      expect(find.byKey(const ValueKey('story-progress')), findsOneWidget);
      expect(find.text(AppStrings.back), findsNothing);
      for (final line in _storyLines) {
        expect(find.text(line), findsNothing);
      }
    });
  });

  group('Questions', () {
    testWidgets('Gret asks for a name first; it is saved when onboarding ends', (tester) async {
      await pumpApp(tester);
      expect(_nameQuestion, findsOneWidget);

      await tester.enterText(find.byType(TextField), '  Khôi ');
      await tapAndSettle(tester, find.text(AppStrings.continueLabel));
      await tapAndSettle(tester, find.text(AppStrings.continueLabel));
      await _answerQuiz(tester);
      await tapAndSettle(tester, find.text(AppStrings.continueLabel));
      await _fillFirstGoal(tester);
      await tapAndSettle(tester, find.text(AppStrings.enterApp));

      expect(ProfileRepository().profile?.displayName, 'Khôi');
      expect(find.textContaining(', Khôi'), findsOneWidget, reason: 'Hôm nay greets by name');
    });

    testWidgets('The reel length is asked by Gret, kept when going back and saved at the end', (
      tester,
    ) async {
      await pumpApp(tester);
      await tapAndSettle(tester, find.text(AppStrings.continueLabel)); // No name.
      expect(
        find.descendant(
          of: find.byType(ThoughtBubble),
          matching: find.text(AppStrings.reelLengthQuestion),
        ),
        findsOneWidget,
      );
      await tapAndSettle(tester, find.text('60 giây'));
      await tapAndSettle(tester, find.text(AppStrings.continueLabel));
      expect(find.text('Câu 1/7'), findsOneWidget);

      await tapAndSettle(tester, find.text(AppStrings.back));
      expect(tester.getSemantics(find.text('60 giây')), isSemantics(isSelected: true));

      await tapAndSettle(tester, find.text(AppStrings.continueLabel));
      await _answerQuiz(tester);
      await tapAndSettle(tester, find.text(AppStrings.continueLabel));
      expect(find.text(AppStrings.gretGoalPrompt), findsOneWidget);
      await _fillFirstGoal(tester);
      await tapAndSettle(tester, find.text(AppStrings.enterApp));

      expect(find.text(AppStrings.start), findsOneWidget);
      expect(ProfileRepository().profile?.preferredReelLength, 60);
      expect(ProfileRepository().profile?.displayName, '');
      expect(GoalRepository().getAll().single.title, 'Qua môn Toán');
      expect(HabitRepository().getAll().single.name, 'Làm đề');
    });

    testWidgets('Quiz: the question is in Gret\'s thought bubble, with step dots', (tester) async {
      await pumpApp(tester);
      await _toQuiz(tester);

      expect(
        find.descendant(
          of: find.byType(ThoughtBubble),
          matching: find.text('Điều gì khiến bạn muốn cố gắng nhất?'),
        ),
        findsOneWidget,
      );
      expect(find.text('Câu 1/7'), findsOneWidget);
      expect(find.byKey(const ValueKey('quiz-step-dots')), findsOneWidget);
      expect(_gretMood(tester), MascotMood.neutral);
    });

    testWidgets('Quiz: Gret is happy for a moment before the next question', (tester) async {
      await pumpApp(tester);
      await _toQuiz(tester);
      await _animationsOn(tester);

      await tester.tap(find.text('Có công việc mình thật sự muốn làm'));
      await tester.pump();
      expect(
        find.text('Câu 1/7'),
        findsOneWidget,
        reason: 'Still on the question during the reaction',
      );
      expect(_gretMood(tester), MascotMood.happy);

      // A second tap during the reaction does not answer twice.
      await tester.tap(find.text('Làm người thân tự hào và yên tâm'));
      await tester.pump(AppMotion.reaction);
      await tester.pump();
      expect(find.text('Câu 2/7'), findsOneWidget);
      expect(_gretMood(tester), MascotMood.neutral);

      // Back shows the first answer, not the second tap.
      await tester.tap(find.text(AppStrings.back));
      await tester.pump();
      expect(
        tester.getSemantics(find.text('Có công việc mình thật sự muốn làm')),
        isSemantics(isSelected: true),
      );

      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('Apps: the reminder list is preselected; the choice is saved only at the end', (
      tester,
    ) async {
      await pumpApp(tester);
      await _toQuiz(tester);
      await _answerQuiz(tester);

      expect(find.text(AppStrings.appsQuestion), findsOneWidget);
      for (final app in BlockedAppsRepository.onboardingApps.keys) {
        expect(tester.getSemantics(find.text(app)), isSemantics(isSelected: true), reason: app);
      }

      await tapAndSettle(tester, find.text('TikTok'));
      await tapAndSettle(tester, find.text('Chrome'));
      expect(tester.getSemantics(find.text('TikTok')), isSemantics(isSelected: false));
      expect(
        BlockedAppsRepository().packages,
        BlockedAppsRepository.defaultPackages,
        reason: 'Nothing is saved before the last page',
      );

      await tapAndSettle(tester, find.text(AppStrings.continueLabel));
      await _fillFirstGoal(tester);
      await tapAndSettle(tester, find.text(AppStrings.enterApp));

      expect(BlockedAppsRepository().packages, {
        'com.facebook.katana',
        'com.instagram.android',
        'com.google.android.youtube',
      });
    });

    testWidgets('Without the reminder feature (web) there is no app page', (tester) async {
      await pumpApp(tester, native: FakeNativeBridge(supported: false));
      await _toQuiz(tester);
      await _answerQuiz(tester);

      expect(find.text(AppStrings.appsQuestion), findsNothing);
      expect(find.text(AppStrings.gretGoalPrompt), findsOneWidget);
    });
  });

  group('Finish', () {
    testWidgets('Finishing shows "your sea is ready" with a happy Gret, then Hôm nay', (
      tester,
    ) async {
      await pumpApp(tester);
      await _toFirstGoal(tester);
      await _fillFirstGoal(tester);
      await _animationsOn(tester);

      await tester.tap(find.text(AppStrings.enterApp));
      await tester.pump();
      await tester.pump(AppMotion.entrance);
      expect(find.text(AppStrings.seaReady), findsOneWidget);
      expect(_gretMood(tester), MascotMood.happy);
      // Everything is saved before the moment, so closing the app now loses nothing.
      expect(ProfileRepository().isOnboardingDone, isTrue);
      expect(GoalRepository().getAll(), hasLength(1));

      await tester.pump(AppMotion.seaReady);
      await tester.pump(const Duration(seconds: 1));
      expect(find.text(AppStrings.seaReady), findsNothing);
      expect(find.text(AppStrings.start), findsOneWidget);

      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('With "remove animations" on, finishing goes straight to Hôm nay', (tester) async {
      await pumpApp(tester);
      await _toFirstGoal(tester);
      await _fillFirstGoal(tester);
      await tapAndSettle(tester, find.text(AppStrings.enterApp));

      expect(find.text(AppStrings.seaReady), findsNothing);
      expect(find.text(AppStrings.start), findsOneWidget);
    });
  });
}
