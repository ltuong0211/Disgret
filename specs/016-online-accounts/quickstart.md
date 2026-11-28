# Quickstart: validating Optional Online Accounts (016)

## Prerequisites (provided by the project lead, never committed)

1. Firebase project created by the lead (Spark plan, **Google Analytics disabled**).
2. Authentication → Sign-in method → **Email/Password** enabled (email link off). Templates →
   language **Vietnamese**.
3. Firestore database created in **production mode**, location **asia-southeast1**; rules from
   `firestore.rules` published.
4. Android app registered with package `com.nhom.focus.focus_app`; from its config copy four
   values into `firebase.env.json` at the repo root (git-ignored), using
   `firebase.env.example.json` as the template:
   `FIREBASE_API_KEY`, `FIREBASE_APP_ID`, `FIREBASE_PROJECT_ID`, `FIREBASE_MESSAGING_SENDER_ID`.
   Shortcut: `flutterfire configure` registers the app and writes `lib/firebase_options.dart`;
   copy the `android` values (apiKey, appId, projectId, messagingSenderId) from it. That file and
   `android/app/google-services.json` are git-ignored and not used by the app.
5. Two Android emulators (Pixel, API 34+), A and B.

## Automated checks

```bash
dart format --set-exit-if-changed lib test
flutter analyze
flutter test
```

Expected: no format changes, "No issues found!", all tests pass. Tests use `FakeAuthService` and
`InMemoryRemoteStore`; no test touches the network.

Key test files: `test/sync_merge_test.dart`, `test/sync_journal_test.dart`,
`test/sync_engine_test.dart`, `test/auth_error_message_test.dart`, `test/account_flow_test.dart`
(widget), `test/accounts_hidden_test.dart` (widget, no config).

## Manual scenarios (emulator)

Run with `flutter run --dart-define-from-file=firebase.env.json`.

1. **No config** — `flutter run` without the file: no "Tài khoản" row, no onboarding link
   (FR-003, US1-4).
2. **Guest unchanged** — fresh install, skip sign-in, finish onboarding, create a habit, run a
   5-minute session with network off: all works (US1, SC-003).
3. **Sign up migrates** — on A: "Tạo dữ liệu mẫu", Cài đặt → Tài khoản → Tạo tài khoản → read
   notice → agree → sign up. Status shows "Đã đồng bộ lúc …". In the Firebase console,
   `users/<uid>/records` has documents for goals/habits/logs/sessions/profile and **none** for
   events or `blocked_packages` (US2, FR-014).
4. **Sign in elsewhere** — on B (fresh install): onboarding first page → "Đã có tài khoản? Đăng
   nhập" → same account: onboarding skipped, same habits and streaks (US3-1, SC-001).
5. **Offline edits** — on A, network off, tick a habit; network on, reopen app; within 1 minute B
   (reopened) shows the tick (US5, SC-004).
6. **Rules** — Firebase console → Firestore → Rules → Playground: the three outcomes in
   `contracts/sync-records.md` hold.
7. **Isolation** — on A: sign out (with network) → onboarding as a new guest; sign up account 2,
   check Hôm nay, Tiến độ, bản đồ biển, Góc của Gret show nothing from account 1; no reminder of
   account 1 fires (US4, SC-002). Blocked-app list unchanged.
8. **Sign-out warning** — signed in, network off, tick a habit, "Đăng xuất" → warning with
   "Có 1 thay đổi…"; "Ở lại" keeps everything (US3-5).
9. **Forgot password** — "Quên mật khẩu?" with a registered and an unregistered email: same
   message; the registered inbox gets a Vietnamese reset email (US6).
10. **Delete account** — Xoá tài khoản with the password, checkbox off: signed out, local data
    still there as guest; console shows no `users/<uid>` records; signing in fails (US7, SC-005).
11. **Native checklist** — Reset break still works signed in and signed out
    (`docs/architecture/native-manual-checklist.md`, Kotlin unchanged but app start changed).

Record results in the PR description.
