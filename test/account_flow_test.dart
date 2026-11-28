// 6.3 Account flows with fakes (spec 016 US2, US3, US6, US7 and edge cases).
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:focus_app/app.dart';
import 'package:focus_app/data/hive_boxes.dart';
import 'package:focus_app/data/models/goal.dart';
import 'package:focus_app/data/models/habit.dart';
import 'package:focus_app/data/models/motivation_type.dart';
import 'package:focus_app/data/models/user_profile.dart';
import 'package:focus_app/data/repositories/goal_repository.dart';
import 'package:focus_app/data/repositories/habit_repository.dart';
import 'package:focus_app/data/repositories/profile_repository.dart';
import 'package:focus_app/data/sync_merge.dart';
import 'package:focus_app/l10n/app_strings.dart';
import 'package:focus_app/providers/focus_session_provider.dart';
import 'package:focus_app/router/app_router.dart';
import 'package:focus_app/widgets/gradient_pill_button.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive/hive.dart';
import 'package:material_ui/material_ui.dart';
import 'package:video_player_platform_interface/video_player_platform_interface.dart';

import 'fakes/account_overrides.dart';
import 'fakes/fake_auth_service.dart';
import 'fakes/in_memory_remote_store.dart';
import 'test_helpers.dart';

const _email = 'an@example.com';
const _password = 'matkhau123';
const _goal = Goal(id: 'g1', title: 'Đỗ đại học', reason: '');
const _habit = Habit(id: 'h1', goalId: 'g1', name: 'Ôn bài', minMinutesPerDay: 25);

Future<void> _onboard() => ProfileRepository().completeOnboarding(
  const UserProfile(motivationTypes: [MotivationType.career], preferredReelLength: 30),
);

ProviderContainer _container(WidgetTester tester) =>
    ProviderScope.containerOf(tester.element(find.byType(DisGretApp)));

Future<void> _go(WidgetTester tester, String location) async {
  _container(tester).read(routerProvider).go(location);
  await tester.pumpAndSettle();
}

Finder _field(String label) => find.widgetWithText(TextFormField, label);

Finder _primary(String label) => find.widgetWithText(GradientPillButton, label);

Future<void> _fill(
  WidgetTester tester, {
  String email = _email,
  String password = _password,
}) async {
  await tester.enterText(_field(AppStrings.accountEmail), email);
  await tester.enterText(_field(AppStrings.accountPassword), password);
}

Future<void> _tapVisible(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
  await tapAndSettle(tester, finder);
}

void main() {
  late FakeAuthService auth;
  late InMemoryRemoteStore remote;

  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  setUp(() async {
    await openMemoryBoxes();
    VideoPlayerPlatform.instance = FakeVideoPlayerPlatform();
    auth = FakeAuthService();
    remote = InMemoryRemoteStore();
  });

  tearDown(() async => Hive.close());

  Future<void> pump(WidgetTester tester) =>
      pumpApp(tester, overrides: accountOverrides(auth, remote));

  Future<void> signInThroughUi(WidgetTester tester) async {
    await _go(tester, AppRoutes.accountSignIn);
    await _fill(tester);
    await _tapVisible(tester, _primary(AppStrings.accountSignIn));
    // The "Đã đăng nhập" snackbar would cover the bottom of the next screen.
    tester.state<ScaffoldMessengerState>(find.byType(ScaffoldMessenger)).removeCurrentSnackBar();
    await tester.pumpAndSettle();
  }

  group('US2 sign up', () {
    testWidgets('notice first; "Để sau" stores nothing; short password is refused; success '
        'uploads the guest data', (tester) async {
      await _onboard();
      await GoalRepository().save(_goal);
      await pump(tester);
      await _go(tester, AppRoutes.account);

      await tapAndSettle(tester, find.widgetWithText(OutlinedButton, AppStrings.accountSignUp));
      for (final text in [
        AppStrings.privacyLeaves,
        AppStrings.privacyWhere,
        AppStrings.privacyStays,
        AppStrings.privacyDelete,
        AppStrings.privacyUnder16,
      ]) {
        expect(find.text(text), findsOneWidget, reason: text);
      }
      await _tapVisible(tester, find.text(AppStrings.privacyLater));
      expect(find.text(AppStrings.accountGuestIntro), findsOneWidget);
      expect(Hive.box<dynamic>(HiveBoxes.account).isEmpty, isTrue);

      await tapAndSettle(tester, find.widgetWithText(OutlinedButton, AppStrings.accountSignUp));
      await _tapVisible(tester, _primary(AppStrings.privacyAgree));
      await _fill(tester, password: 'ngan');
      await _tapVisible(tester, _primary(AppStrings.accountSignUp));
      expect(find.text(AppStrings.accountWeakPassword), findsOneWidget);
      expect(auth.hasUser(_email), isFalse);

      await _fill(tester);
      await _tapVisible(tester, _primary(AppStrings.accountSignUp));
      expect(find.text(AppStrings.accountCreated), findsOneWidget);
      expect(find.text(_email), findsOneWidget);
      final uid = auth.currentUser!.uid;
      expect(remote.accounts[uid]!.keys, contains('goals__g1'));
    });

    testWidgets('an email that already has an account offers sign-in', (tester) async {
      await _onboard();
      auth.addUser(_email, _password);
      await pump(tester);
      await _go(tester, AppRoutes.accountSignUp);
      await _tapVisible(tester, _primary(AppStrings.privacyAgree));
      await _fill(tester);
      await _tapVisible(tester, _primary(AppStrings.accountSignUp));
      expect(find.text(AppStrings.accountEmailInUse), findsOneWidget);
      await tapAndSettle(tester, find.widgetWithText(TextButton, AppStrings.accountSignIn));
      expect(find.text(AppStrings.accountForgotPassword), findsOneWidget);
    });
  });

  group('US3 sign in and sign out', () {
    testWidgets('wrong password: one message for both fields', (tester) async {
      await _onboard();
      auth.addUser(_email, _password);
      await pump(tester);
      await _go(tester, AppRoutes.accountSignIn);
      await _fill(tester, password: 'sai-mat-khau');
      await _tapVisible(tester, _primary(AppStrings.accountSignIn));
      expect(find.text(AppStrings.accountWrongCredentials), findsOneWidget);
      expect(auth.currentUser, isNull);
    });

    testWidgets('phone and account both hold data: asks once, merge keeps both', (tester) async {
      await _onboard();
      await GoalRepository().save(_goal);
      final user = auth.addUser(_email, _password);
      remote.seed(
        user.uid,
        SyncRecord(
          box: HiveBoxes.goals,
          key: 'remote',
          updatedAt: 10,
          data: const Goal(id: 'remote', title: 'Từ máy kia', reason: '').toMap(),
        ),
      );
      await pump(tester);
      await signInThroughUi(tester);
      expect(find.text(AppStrings.mergeTitle), findsOneWidget);
      await tapAndSettle(tester, find.text(AppStrings.mergeKeepBoth));
      expect(find.text(AppStrings.accountSignedIn), findsOneWidget);
      expect(Hive.box<dynamic>(HiveBoxes.goals).keys.toSet(), {'g1', 'remote'});
    });

    testWidgets('sign-out warns about unsynced changes, then clears the phone', (tester) async {
      await _onboard();
      auth.addUser(_email, _password);
      await pump(tester);
      await signInThroughUi(tester);
      await _go(tester, AppRoutes.account);

      remote.offline = true;
      await GoalRepository().save(_goal);
      await tapAndSettle(tester, find.text(AppStrings.accountSignOut));
      expect(find.text(AppStrings.signOutPendingMessage(1)), findsOneWidget);
      await tapAndSettle(tester, find.text(AppStrings.signOutStay));
      expect(auth.currentUser, isNotNull);
      expect(find.text(_email), findsOneWidget);

      remote.offline = false;
      await tapAndSettle(tester, find.text(AppStrings.accountSignOut));
      expect(auth.currentUser, isNull);
      expect(Hive.box<dynamic>(HiveBoxes.goals).isEmpty, isTrue);
      expect(find.text(AppStrings.continueLabel), findsOneWidget);
    });

    testWidgets('sign-out is disabled while a focus session runs', (tester) async {
      await _onboard();
      await GoalRepository().save(_goal);
      await HabitRepository().save(_habit);
      auth.addUser(_email, _password);
      await pump(tester);
      await signInThroughUi(tester);
      _container(tester).read(focusSessionProvider.notifier).start(habit: _habit, minutes: 25);
      await _go(tester, AppRoutes.account);
      expect(find.text(AppStrings.accountSignOutDuringSession), findsOneWidget);
      final button = tester.widget<OutlinedButton>(
        find.ancestor(
          of: find.text(AppStrings.accountSignOut),
          matching: find.bySubtype<OutlinedButton>(),
        ),
      );
      expect(button.onPressed, isNull);
      _container(tester).invalidate(focusSessionProvider);
      await tester.pumpAndSettle();
    });
  });

  testWidgets('US6 forgot password: the same message for an unknown email', (tester) async {
    await _onboard();
    await pump(tester);
    await _go(tester, AppRoutes.accountForgotPassword);
    await tester.enterText(_field(AppStrings.accountEmail), 'khongco@example.com');
    await _tapVisible(tester, _primary(AppStrings.accountSendReset));
    expect(find.text(AppStrings.accountResetSent), findsOneWidget);
    expect(auth.resetsSent, isEmpty);
  });

  testWidgets('US7 delete account: password again, online data gone, phone kept', (tester) async {
    await _onboard();
    await GoalRepository().save(_goal);
    auth.addUser(_email, _password);
    await pump(tester);
    await signInThroughUi(tester);
    final uid = auth.currentUser!.uid;
    await _go(tester, AppRoutes.account);

    await _tapVisible(tester, find.widgetWithText(TextButton, AppStrings.accountDelete));
    expect(find.text(AppStrings.deleteMessage), findsOneWidget);
    await tester.enterText(
      find.descendant(of: find.byType(AlertDialog), matching: find.byType(TextFormField)),
      'sai-mat-khau',
    );
    await tapAndSettle(tester, find.widgetWithText(FilledButton, AppStrings.accountDelete));
    expect(find.text(AppStrings.accountWrongCredentials), findsOneWidget);

    await tester.enterText(
      find.descendant(of: find.byType(AlertDialog), matching: find.byType(TextFormField)),
      _password,
    );
    await tapAndSettle(tester, find.widgetWithText(FilledButton, AppStrings.deleteRetry));
    expect(find.text(AppStrings.accountDeleted), findsOneWidget);
    expect(auth.hasUser(_email), isFalse);
    expect(remote.accounts[uid], isNull);
    expect(Hive.box<dynamic>(HiveBoxes.goals).containsKey('g1'), isTrue);
    expect(find.text(AppStrings.accountGuestSubtitle), findsOneWidget);
  });

  testWidgets('"Xoá toàn bộ dữ liệu" while signed in signs out here; online data stays', (
    tester,
  ) async {
    await _onboard();
    await GoalRepository().save(_goal);
    auth.addUser(_email, _password);
    await pump(tester);
    await signInThroughUi(tester);
    final uid = auth.currentUser!.uid;
    await _go(tester, AppRoutes.settings);
    await tester.scrollUntilVisible(
      find.text('Xoá toàn bộ dữ liệu'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tapAndSettle(tester, find.text('Xoá toàn bộ dữ liệu'));
    await tapAndSettle(tester, find.text('Xoá hết'));
    expect(auth.currentUser, isNull);
    expect(remote.accounts[uid]!.keys, contains('goals__g1'));
    expect(Hive.box<dynamic>(HiveBoxes.account).isEmpty, isTrue);
  });
}
