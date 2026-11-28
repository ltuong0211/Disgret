// 6.3 Two students on one phone (spec 016 US4, FR-012, FR-013, SC-002): after A signs out and B
// signs in, nothing of A is visible or scheduled; phone settings stay.
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:focus_app/app.dart';
import 'package:focus_app/data/gret_corner_catalog.dart';
import 'package:focus_app/data/models/goal.dart';
import 'package:focus_app/data/models/habit.dart';
import 'package:focus_app/data/models/motivation_type.dart';
import 'package:focus_app/data/models/user_profile.dart';
import 'package:focus_app/data/repositories/blocked_apps_repository.dart';
import 'package:focus_app/data/repositories/goal_repository.dart';
import 'package:focus_app/data/repositories/gret_corner_repository.dart';
import 'package:focus_app/data/repositories/habit_repository.dart';
import 'package:focus_app/data/repositories/profile_repository.dart';
import 'package:focus_app/providers/account_providers.dart';
import 'package:focus_app/providers/app_providers.dart';
import 'package:focus_app/providers/gret_corner_providers.dart';
import 'package:focus_app/providers/reminder_providers.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive/hive.dart';
import 'package:video_player_platform_interface/video_player_platform_interface.dart';

import 'fakes/account_overrides.dart';
import 'fakes/fake_auth_service.dart';
import 'fakes/in_memory_remote_store.dart';
import 'test_helpers.dart';

const _goal = Goal(id: 'gA', title: 'Mục tiêu của A', reason: '');
const _habit = Habit(
  id: 'hA',
  goalId: 'gA',
  name: 'Ôn Toán',
  minMinutesPerDay: 25,
  reminderEnabled: true,
);

void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  setUp(() async {
    await openMemoryBoxes();
    VideoPlayerPlatform.instance = FakeVideoPlayerPlatform();
  });

  tearDown(() async => Hive.close());

  testWidgets('B sees nothing of A; A gets everything back', (tester) async {
    final auth = FakeAuthService();
    final remote = InMemoryRemoteStore();
    auth.addUser('a@example.com', 'matkhauA1');
    auth.addUser('b@example.com', 'matkhauB1');

    // A, already using the app, signs up for the first time on this phone.
    await ProfileRepository().completeOnboarding(
      const UserProfile(
        motivationTypes: [MotivationType.career],
        preferredReelLength: 30,
        displayName: 'An',
      ),
    );
    await GoalRepository().save(_goal);
    await HabitRepository().save(_habit);
    await GretCornerRepository().saveOwned({GretCornerCatalog.items.first.id});
    await BlockedAppsRepository().save({'com.google.android.youtube'});

    await pumpApp(tester, overrides: accountOverrides(auth, remote));
    final container = ProviderScope.containerOf(tester.element(find.byType(DisGretApp)));
    final actions = container.read(accountActionsProvider);
    await actions.signIn('a@example.com', 'matkhauA1');
    await tester.pumpAndSettle();
    expect(container.read(habitsProvider).map((habit) => habit.id), ['hA']);
    expect(container.read(reminderPlanProvider), isNotEmpty);

    expect(await actions.prepareSignOut(), 0);
    await actions.signOut();
    await actions.signIn('b@example.com', 'matkhauB1');
    await tester.pumpAndSettle();

    expect(container.read(accountStateProvider).email, 'b@example.com');
    expect(container.read(goalsProvider), isEmpty);
    expect(container.read(habitsProvider), isEmpty);
    expect(container.read(habitLogsProvider), isEmpty);
    expect(container.read(profileProvider)?.displayName ?? '', isEmpty);
    expect(container.read(gretCornerProvider).owned, isEmpty);
    expect(container.read(reminderPlanProvider), isEmpty);
    // Phone-bound (FR-013).
    expect(container.read(blockedAppsProvider), {'com.google.android.youtube'});

    await actions.signOut();
    await actions.signIn('a@example.com', 'matkhauA1');
    await tester.pumpAndSettle();
    expect(container.read(habitsProvider).map((habit) => habit.name), ['Ôn Toán']);
    expect(container.read(gretCornerProvider).owned, isNotEmpty);
    // The display name stays on the phone (ADR-0012): it is not restored from the account.
    expect(container.read(profileProvider)?.displayName ?? '', isEmpty);
  });
}
