// 5.7 Hướng dẫn lần đầu (spec 022): the steps of the guided tour over Hôm nay, in order. Pure data
// and rules, unit-tested in test/guided_tour_test.dart.
import '../l10n/app_strings.dart';

/// The parts of the screen the tour points at.
enum TourTarget {
  sea,
  clarity,
  todayTasks,
  shortcuts,
  startButton,
  habitsTab,
  progressTab,
  settings,
}

class TourStep {
  const TourStep(this.target, this.title, this.body);

  final TourTarget target;
  final String title;
  final String body;
}

class GuidedTour {
  GuidedTour._();

  /// Top to bottom on Hôm nay, then the tab bar, then Cài đặt.
  static const List<TourStep> steps = [
    TourStep(TourTarget.sea, AppStrings.tourSeaTitle, AppStrings.tourSeaBody),
    TourStep(TourTarget.clarity, AppStrings.tourClarityTitle, AppStrings.tourClarityBody),
    TourStep(TourTarget.shortcuts, AppStrings.tourShortcutsTitle, AppStrings.tourShortcutsBody),
    TourStep(TourTarget.todayTasks, AppStrings.tourTasksTitle, AppStrings.tourTasksBody),
    TourStep(TourTarget.startButton, AppStrings.tourStartTitle, AppStrings.tourStartBody),
    TourStep(TourTarget.habitsTab, AppStrings.tourHabitsTitle, AppStrings.tourHabitsBody),
    TourStep(TourTarget.progressTab, AppStrings.tourProgressTitle, AppStrings.tourProgressBody),
    TourStep(TourTarget.settings, AppStrings.tourSettingsTitle, AppStrings.tourSettingsBody),
  ];

  /// The next step index, or null when [current] was the last one.
  static int? next(int current) => current + 1 < steps.length ? current + 1 : null;

  /// The previous step index; the first step stays first.
  static int previous(int current) => current > 0 ? current - 1 : 0;

  /// Steps whose target is not on screen are skipped (e.g. no habits today, so no task list).
  static int? firstShown(int from, bool Function(TourTarget target) isShown) {
    for (var i = from; i < steps.length; i++) {
      if (isShown(steps[i].target)) return i;
    }
    return null;
  }

  static int? lastShown(int from, bool Function(TourTarget target) isShown) {
    for (var i = from; i >= 0; i--) {
      if (isShown(steps[i].target)) return i;
    }
    return null;
  }
}
