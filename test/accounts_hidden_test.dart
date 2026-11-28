// 6.3 Accounts never get in the way (spec 016 US1, FR-001–FR-003).
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:focus_app/app.dart';
import 'package:focus_app/data/models/motivation_type.dart';
import 'package:focus_app/data/models/user_profile.dart';
import 'package:focus_app/data/repositories/profile_repository.dart';
import 'package:focus_app/l10n/app_strings.dart';
import 'package:focus_app/router/app_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive/hive.dart';
import 'package:video_player_platform_interface/video_player_platform_interface.dart';

import 'fakes/account_overrides.dart';
import 'fakes/fake_auth_service.dart';
import 'fakes/in_memory_remote_store.dart';
import 'test_helpers.dart';

Future<void> _onboard() => ProfileRepository().completeOnboarding(
  const UserProfile(motivationTypes: [MotivationType.career], preferredReelLength: 30),
);

Future<void> _go(WidgetTester tester, String location) async {
  ProviderScope.containerOf(tester.element(find.byType(DisGretApp)))
      .read(routerProvider)
      .go(location);
  await tester.pumpAndSettle();
}

void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  setUp(() async {
    await openMemoryBoxes();
    VideoPlayerPlatform.instance = FakeVideoPlayerPlatform();
  });

  tearDown(() async => Hive.close());

  group('build without backend settings (FR-003)', () {
    testWidgets('Cài đặt has no account row and account routes go back', (tester) async {
      await _onboard();
      await pumpApp(tester);
      await _go(tester, AppRoutes.settings);
      expect(find.text(AppStrings.accountTitle), findsNothing);
      expect(find.text(AppStrings.accountGuestSubtitle), findsNothing);

      await _go(tester, AppRoutes.accountSignIn);
      expect(find.text(AppStrings.accountForgotPassword), findsNothing);
      expect(find.text('Cài đặt'), findsWidgets);
    });

    testWidgets('onboarding shows no sign-in link', (tester) async {
      await pumpApp(tester);
      expect(find.text(AppStrings.accountHaveAccount), findsNothing);
    });
  });

  group('guest with accounts available (US1)', () {
    late FakeAuthService auth;
    late InMemoryRemoteStore remote;

    setUp(() {
      auth = FakeAuthService();
      remote = InMemoryRemoteStore();
    });

    testWidgets('Cài đặt shows the guest note and opens the account screen', (tester) async {
      await _onboard();
      await pumpApp(tester, overrides: accountOverrides(auth, remote));
      await _go(tester, AppRoutes.settings);
      expect(find.text(AppStrings.accountGuestSubtitle), findsOneWidget);

      await tapAndSettle(tester, find.text(AppStrings.accountGuestSubtitle));
      expect(find.text(AppStrings.accountGuestIntro), findsOneWidget);
      expect(find.text(AppStrings.accountSignUp), findsOneWidget);
    });

    testWidgets('onboarding page 1 has a secondary sign-in link, then it is gone', (tester) async {
      await pumpApp(tester, overrides: accountOverrides(auth, remote));
      expect(find.text(AppStrings.continueLabel), findsOneWidget);
      expect(find.text(AppStrings.accountHaveAccount), findsOneWidget);

      await tapAndSettle(tester, find.text(AppStrings.continueLabel));
      expect(find.text(AppStrings.accountHaveAccount), findsNothing);
    });

    testWidgets('the link opens sign-in before the intro is done', (tester) async {
      await pumpApp(tester, overrides: accountOverrides(auth, remote));
      await tapAndSettle(tester, find.text(AppStrings.accountHaveAccount));
      expect(find.text(AppStrings.accountForgotPassword), findsOneWidget);
    });
  });
}
