// 5.7 Hướng dẫn lần đầu (spec 022): which tour step shows, if any. The tour starts once on Hôm nay
// after onboarding, or again from Cài đặt → "Xem lại hướng dẫn".
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/guided_tour.dart';
import 'app_providers.dart';

/// Tests turn the tour off unless they test it (like the launch screen).
final guidedTourEnabledProvider = Provider<bool>((ref) => true);

/// The index in [GuidedTour.steps] being shown; null when no tour is running.
class GuidedTourNotifier extends Notifier<int?> {
  @override
  int? build() => null;

  /// Called from onboarding's end and from Cài đặt: show the tour next time Hôm nay is open.
  Future<void> schedule() => ref.read(profileRepositoryProvider).setTourPending(true);

  /// Starts the tour if one is waiting. Returns whether it started.
  bool startIfPending() {
    if (state != null || !ref.read(guidedTourEnabledProvider)) return false;
    if (!ref.read(profileRepositoryProvider).isTourPending) return false;
    state = 0;
    return true;
  }

  void goTo(int step) => state = step;

  /// Ends the tour ("Bỏ qua", "Bắt đầu thôi!" or Back); it does not come back by itself.
  Future<void> finish() async {
    state = null;
    await ref.read(profileRepositoryProvider).setTourPending(false);
  }
}

final guidedTourProvider = NotifierProvider<GuidedTourNotifier, int?>(GuidedTourNotifier.new);
