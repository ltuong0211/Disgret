// 2.2 Nhắc giờ học có chặn app (spec 023): which reminders also check for a distracting app, and
// what "Bắt đầu học ngay" on the Android screen does.
import 'package:flutter_test/flutter_test.dart';
import 'package:focus_app/data/models/goal.dart';
import 'package:focus_app/data/models/habit.dart';
import 'package:focus_app/data/models/motivation_type.dart';
import 'package:focus_app/data/models/user_profile.dart';
import 'package:focus_app/data/reminder_plan.dart';
import 'package:focus_app/data/repositories/goal_repository.dart';
import 'package:focus_app/data/repositories/habit_repository.dart';
import 'package:focus_app/data/repositories/profile_repository.dart';
import 'package:focus_app/data/study_check_plan.dart';
import 'package:focus_app/services/native_bridge.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive/hive.dart';
import 'package:video_player_platform_interface/video_player_platform_interface.dart';

import 'test_helpers.dart';

void main() {
  group('StudyCheckPlan', () {
    final at = DateTime(2026, 11, 28, 20);
    const on = Habit(
      id: 'on',
      goalId: 'g',
      name: 'Ôn Toán',
      minMinutesPerDay: 25,
      reminderEnabled: true,
      reminderInterrupt: true,
    );
    const off = Habit(id: 'off', goalId: 'g', name: 'Đọc sách', minMinutesPerDay: 10);

    test('only reminders of habits with the interruption on become checks', () {
      final checks = StudyCheckPlan.from(
        [
          PlannedReminder(habitId: 'on', at: at, title: '', body: ''),
          PlannedReminder(habitId: 'off', at: at, title: '', body: ''),
          PlannedReminder(habitId: 'gone', at: at, title: '', body: ''),
        ],
        [on, off],
      );
      expect(checks, hasLength(1));
      expect(checks.single.toMap(), {
        'habitId': 'on',
        'habitName': 'Ôn Toán',
        'minutes': 25,
        'atMillis': at.millisecondsSinceEpoch,
      });
    });

    test('habits saved before spec 023 read with the interruption off', () {
      final old = Habit.fromMap({...on.toMap()}..remove('reminderInterrupt'));
      expect(old.reminderInterrupt, isFalse);
      expect(Habit.fromMap(on.toMap()).reminderInterrupt, isTrue);
    });
  });

  group('the app side', () {
    setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

    setUp(() async {
      await openMemoryBoxes();
      VideoPlayerPlatform.instance = FakeVideoPlayerPlatform();
      await ProfileRepository().completeOnboarding(
        const UserProfile(motivationTypes: [MotivationType.career], preferredReelLength: 30),
      );
      await GoalRepository().save(const Goal(id: 'g', title: 'Qua môn', reason: ''));
      await HabitRepository().save(
        const Habit(
          id: 'h',
          goalId: 'g',
          name: 'Ôn Toán',
          minMinutesPerDay: 25,
          reminderEnabled: true,
          reminderTime: '23:59',
          reminderInterrupt: true,
        ),
      );
    });

    tearDown(() async => Hive.close());

    testWidgets('the checks and the blocked list go to Android at start', (tester) async {
      final native = FakeNativeBridge();
      await pumpApp(tester, native: native, clock: () => DateTime(2026, 11, 28, 9));
      expect(native.studyChecks, isNotEmpty);
      final (checks, blocked) = native.studyChecks.last;
      expect(checks.first.habitId, 'h');
      expect(checks.first.at.hour, 23);
      expect(blocked, isNotEmpty);
    });

    testWidgets('"Bắt đầu học ngay" opens the motivation step for that habit', (tester) async {
      final native = FakeNativeBridge();
      await pumpApp(tester, native: native);
      native.emit(NativeAction.startScheduled, habitId: 'h');
      await tester.pumpAndSettle();
      expect(find.text('Bỏ qua'), findsOneWidget, reason: 'motivation step is open');
    });
  });
}
