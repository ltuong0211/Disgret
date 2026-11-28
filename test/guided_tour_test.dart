// 5.7 Hướng dẫn lần đầu (spec 022): the steps, and the tour over the real Hôm nay.
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:focus_app/app.dart';
import 'package:focus_app/data/guided_tour.dart';
import 'package:focus_app/data/models/goal.dart';
import 'package:focus_app/data/models/habit.dart';
import 'package:focus_app/data/models/motivation_type.dart';
import 'package:focus_app/data/models/user_profile.dart';
import 'package:focus_app/data/repositories/goal_repository.dart';
import 'package:focus_app/data/repositories/habit_repository.dart';
import 'package:focus_app/data/repositories/profile_repository.dart';
import 'package:focus_app/l10n/app_strings.dart';
import 'package:focus_app/router/app_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive/hive.dart';
import 'package:material_ui/material_ui.dart';
import 'package:video_player_platform_interface/video_player_platform_interface.dart';

import 'test_helpers.dart';

const _goal = Goal(id: 'g1', title: 'Qua môn Toán', reason: '');
const _habit = Habit(id: 'h1', goalId: 'g1', name: 'Làm đề', minMinutesPerDay: 25);

Future<void> _onboarded({bool tourPending = true}) async {
  await ProfileRepository().completeOnboarding(
    const UserProfile(motivationTypes: [MotivationType.career], preferredReelLength: 30),
  );
  await ProfileRepository().setTourPending(tourPending);
  await GoalRepository().save(_goal);
  await HabitRepository().save(_habit);
}

Finder _title(int step) => find.text(GuidedTour.steps[step].title);

void main() {
  group('GuidedTour steps', () {
    test('every step has text and points at a different part of the screen', () {
      final targets = GuidedTour.steps.map((step) => step.target).toSet();
      expect(targets.length, GuidedTour.steps.length);
      expect(targets, TourTarget.values.toSet());
      for (final step in GuidedTour.steps) {
        expect(step.title, isNotEmpty);
        expect(step.body.length, greaterThan(20));
      }
    });

    test('next, previous and skipping parts that are not on screen', () {
      expect(GuidedTour.next(0), 1);
      expect(GuidedTour.next(GuidedTour.steps.length - 1), isNull);
      expect(GuidedTour.previous(0), 0);
      expect(GuidedTour.previous(3), 2);
      bool noTasks(TourTarget target) => target != TourTarget.todayTasks;
      final tasks = GuidedTour.steps.indexWhere((s) => s.target == TourTarget.todayTasks);
      expect(GuidedTour.firstShown(tasks, noTasks), tasks + 1);
      expect(GuidedTour.lastShown(tasks, noTasks), tasks - 1);
      expect(GuidedTour.firstShown(0, (_) => false), isNull);
    });
  });

  group('the tour on Hôm nay', () {
    setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

    setUp(() async {
      await openMemoryBoxes();
      VideoPlayerPlatform.instance = FakeVideoPlayerPlatform();
    });

    tearDown(() async => Hive.close());

    testWidgets('after onboarding it walks through every step, blur and spotlight included', (
      tester,
    ) async {
      await _onboarded();
      await pumpApp(tester, guidedTour: true, size: const Size(400, 860));

      expect(_title(0), findsOneWidget);
      expect(find.byType(BackdropFilter), findsOneWidget);
      expect(find.text(AppStrings.tourProgress(1, GuidedTour.steps.length)), findsOneWidget);
      // The screen underneath cannot be pressed: a tap anywhere outside the card goes on.
      await tester.tap(find.byTooltip(AppStrings.settings), warnIfMissed: false);
      await tester.pumpAndSettle();
      expect(find.text(AppStrings.tourReplay), findsNothing);
      expect(_title(1), findsOneWidget);

      for (var i = 2; i < GuidedTour.steps.length; i++) {
        await tapAndSettle(tester, find.text(AppStrings.tourNext));
        expect(_title(i), findsOneWidget, reason: GuidedTour.steps[i].title);
      }
      await tapAndSettle(tester, find.text(AppStrings.tourDone));
      expect(find.byType(BackdropFilter), findsNothing);
      expect(ProfileRepository().isTourPending, isFalse);
    });

    testWidgets('"Lùi lại" goes back; "Bỏ qua" ends it for good', (tester) async {
      await _onboarded();
      await pumpApp(tester, guidedTour: true, size: const Size(400, 860));
      await tapAndSettle(tester, find.text(AppStrings.tourNext));
      expect(_title(1), findsOneWidget);
      await tapAndSettle(tester, find.byTooltip(AppStrings.tourBack));
      expect(_title(0), findsOneWidget);

      await tapAndSettle(tester, find.text(AppStrings.tourSkip));
      expect(_title(0), findsNothing);
      expect(ProfileRepository().isTourPending, isFalse);
    });

    testWidgets('every step fits on a small phone', (tester) async {
      await _onboarded();
      await pumpApp(tester, guidedTour: true);
      for (var i = 1; i < GuidedTour.steps.length; i++) {
        await tapAndSettle(tester, find.text(AppStrings.tourNext));
        expect(_title(i), findsOneWidget);
      }
      await tapAndSettle(tester, find.text(AppStrings.tourDone));
    });

    testWidgets('students who used the app before are not interrupted', (tester) async {
      await _onboarded(tourPending: false);
      await pumpApp(tester, guidedTour: true);
      expect(_title(0), findsNothing);
    });

    testWidgets('Cài đặt → "Xem lại hướng dẫn" shows it again on Hôm nay', (tester) async {
      await _onboarded(tourPending: false);
      await pumpApp(tester, guidedTour: true, size: const Size(400, 860));
      ProviderScope.containerOf(tester.element(find.byType(DisGretApp)))
          .read(routerProvider)
          .go(AppRoutes.settings);
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
        find.text(AppStrings.tourReplay),
        300,
        scrollable: find.byType(Scrollable).first,
      );
      await tapAndSettle(tester, find.text(AppStrings.tourReplay));
      expect(_title(0), findsOneWidget);
    });

    testWidgets('finishing onboarding schedules the tour', (tester) async {
      await pumpApp(tester);
      await tapAndSettle(tester, find.text(AppStrings.continueLabel)); // No name.
      await tapAndSettle(tester, find.text(AppStrings.continueLabel)); // Reel length.
      await answerCoreQuiz(tester);
      await tapAndSettle(tester, find.text(AppStrings.continueLabel)); // Apps.
      await tester.enterText(find.widgetWithText(TextFormField, 'Tên mục tiêu'), 'Qua môn');
      await tester.enterText(find.widgetWithText(TextFormField, 'Vì sao bạn muốn điều này?'), 'Vì');
      await tester.enterText(find.widgetWithText(TextFormField, 'Tên thói quen'), 'Làm đề');
      await tapAndSettle(tester, find.text(AppStrings.enterApp));
      expect(ProfileRepository().isTourPending, isTrue);
    });
  });
}
