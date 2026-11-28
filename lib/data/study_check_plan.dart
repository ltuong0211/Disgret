// 2.2 Nhắc giờ học có chặn app (spec 023): which planned reminders also check, at that time,
// whether a distracting app is open. Pure, unit-tested in test/study_check_plan_test.dart.
import 'models/habit.dart';
import 'reminder_plan.dart';

/// One check handed to the Android layer: at [at], if a blocked app is on screen, cover it with
/// "Tới giờ [habitName] rồi".
class StudyCheck {
  const StudyCheck({
    required this.habitId,
    required this.habitName,
    required this.minutes,
    required this.at,
  });

  final String habitId;
  final String habitName;
  final int minutes;
  final DateTime at;

  Map<String, Object> toMap() => {
    'habitId': habitId,
    'habitName': habitName,
    'minutes': minutes,
    'atMillis': at.millisecondsSinceEpoch,
  };
}

abstract final class StudyCheckPlan {
  /// The reminders whose habit has "Chặn app khi tới giờ" on. The reminder plan already leaves out
  /// habits done today, not scheduled, archived, or past times (spec 009).
  static List<StudyCheck> from(List<PlannedReminder> reminders, List<Habit> habits) {
    final byId = {for (final habit in habits) habit.id: habit};
    return [
      for (final reminder in reminders)
        if (byId[reminder.habitId] case final habit? when habit.reminderInterrupt)
          StudyCheck(
            habitId: habit.id,
            habitName: habit.name,
            minutes: habit.minMinutesPerDay,
            at: reminder.at,
          ),
    ];
  }
}
