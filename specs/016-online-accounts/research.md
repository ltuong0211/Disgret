# Research: Optional Online Accounts (016)

All spec clarifications are resolved (spec "Clarifications", 2026-11-27). This file records the
technical decisions behind `plan.md`.

## R1. Backend and packages

- **Decision**: Firebase Authentication (email + password) and Cloud Firestore, Spark plan,
  Firestore location `asia-southeast1`. Packages: `firebase_core`, `firebase_auth`,
  `cloud_firestore` — the latest stable versions that support Flutter 3.47 / Dart 3.13 at
  implementation time, pinned exactly in `pubspec.yaml` (check `flutter pub outdated` and the
  FlutterFire changelog; record the versions in the commit).
- **Rationale**: ADR-0013; the lead chose it in clarify. Official FlutterFire packages are
  maintained by Google, widely documented and work with manual `FirebaseOptions`.
- **Alternatives**: Supabase (pauses idle free projects; deletion needs server code), Appwrite,
  self-hosting — see ADR-0013. `firebase_ui_auth` (prebuilt screens) rejected: English-first UI,
  extra dependency, our screens must use `AppStrings` and the app theme.
- **Never added**: `firebase_analytics`, `firebase_crashlytics`, `firebase_messaging`,
  `firebase_performance`, `google_sign_in`, `connectivity_plus`.

## R2. Configuration without committed secrets

- **Decision**: `Firebase.initializeApp(options: FirebaseOptions(...))` with values from
  `String.fromEnvironment` (`FIREBASE_API_KEY`, `FIREBASE_APP_ID`, `FIREBASE_PROJECT_ID`,
  `FIREBASE_MESSAGING_SENDER_ID`), supplied by `flutter run --dart-define-from-file=firebase.env.json`.
  `firebase.env.json` is git-ignored; `firebase.env.example.json` (empty values) is committed.
  `AccountsConfig.isAvailable` is true only when not on web and all four values are non-empty.
- **Rationale**: no `google-services.json` and no Gradle plugin means the Android build never
  needs the file; CI builds without secrets and gets the app with accounts hidden (FR-003).
- **Alternatives**: `flutterfire configure` (generates `lib/firebase_options.dart` and
  `google-services.json`; would put keys in the tree and make CI depend on them); committing the
  API key (Firebase keys are not strictly secret, but the project rule is "never commit config").

## R3. Local-first sync design

- **Decision**: Hive stays the source of truth. A new Hive box `sync_meta` keeps one entry per
  synced record: `"<box>/<key>" → {updatedAt (ms since epoch, device clock), deleted, dirty}`.
  Every write to a synced box goes through a `SyncJournal` that updates this entry; models are
  unchanged. A `SyncEngine` pushes dirty entries and pulls remote changes; merge rules are pure
  functions in `lib/data/sync_merge.dart`.
- **Rationale**: keeps every model, box name and old datum untouched (Principle III); one place
  (`HiveRepository.save/delete` plus three profile-box repositories) records changes; the merge
  logic is unit-testable without Firebase.
- **Alternatives**: adding `updatedAt` to every model (touches all models, which the 015 session is
  editing; old data needs defaults everywhere); relying on Firestore's offline cache as the store
  (two sources of truth, harder to explain, web/Android differences); listening to `Box.watch()`
  (async events make it hard to tell our own remote applies from user edits).

## R4. Remote layout

- **Decision**: one collection per user: `users/{uid}/records/{box}__{key}` with fields
  `box`, `key`, `data` (the Hive map, absent when deleted), `updatedAt` (int, device ms),
  `deleted` (bool), `syncedAt` (server timestamp). Pull = query `syncedAt > lastPulledAt` ordered
  by `syncedAt` (single-field index, automatic), starting 60 s before `last_pulled_at` (analyze
  U1: a concurrent batch can get a slightly older server time than one already pulled). Push =
  batched writes, ≤ 400 per batch.
- **Rationale**: one generic collection keeps the code tiny and the rules one line; the sample
  data (~1,000 records) uploads in 3 batches, well within the 20k writes/day free quota.
- **Alternatives**: one collection per box (more code, same rules); one document per box (1 MiB
  document limit, conflicts on every edit).

## R5. Merge rules

- **Decision** (`SyncMerge.resolve`): for the same `box/key`, the entry with the larger
  `updatedAt` wins; on a tie, `deleted` wins, then remote wins. A losing local entry that is not
  dirty is overwritten; a winning dirty local entry is pushed. Logs and sessions have unique ids
  (habit logs: `<type>_<habitId>_<date>`), so records from two phones are all kept (FR-016).
- **Rationale**: last-write-wins per record is the simplest rule a student can explain; data loss
  is limited to concurrent edits of the same habit/goal field set.
- **Risk**: device clocks that are badly wrong; accepted for course scale and documented.
- **Allow-list, not deny-list** (analyze C2): from the profile `user` map only `motivationTypes`,
  `preferredReelLength` and `quizAnswers` are uploaded (`SyncScope.userFields`). Applying a remote
  `user` map overwrites only those fields and keeps the local `displayName`, `demoMode` and any
  other field. A field added by a later spec stays local until ADR-0013 and this list name it.

## R6. What is synced

| Box | Keys | Synced |
|---|---|---|
| `goals`, `habits`, `habit_logs`, `sessions` | every record | yes |
| `profile` | `user` (only `motivationTypes`, `preferredReelLength`, `quizAnswers`), `onboarding_done`, `celebrated_level`, `study_place`, `corner_owned`, `corner_worn`, `corner_sea`, `corner_mascot` | yes |
| `profile` → `user` | `displayName`, `demoMode`, any later field | no (phone-only; display name per ADR-0012) |
| `profile` | `blocked_packages`, `reminder_permission_asked` | no (phone-bound) |
| `events` | all | no (phone-only; cleared on sign-out) |
| `account`, `sync_meta` | all | no (local bookkeeping) |

Both box keys and `user` fields are allow-listed: anything a later spec adds stays phone-only
until ADR-0013 and this table list it.

## R7. First login and isolation

- **Decision**: a pure `FirstLoginPlan.decide(localHasData, localOwnerUid, uid, remoteHasData)`
  returns `normalSync`, `downloadOnly`, `uploadGuest`, `askMergeOrReplace` or `clearThenDownload`.
  `localHasData` = any record in a synced box or `onboarding_done == true`.
  The `account` box stores `owner_uid` (the uid the local data belongs to; absent for guest),
  `email`, `last_pulled_at`, `last_sync_ok_at`.
- **Sign-out**: push (15 s timeout) → if pending > 0 show the warning → `HiveBoxes.clearAccountData()`
  clears goals, habits, habit_logs, sessions, events, `sync_meta`, `account` and every profile key
  except `blocked_packages` and `reminder_permission_asked` → reminders rescheduled (none) →
  providers invalidated → `context.go(AppRoutes.onboarding)`.
- **Rationale**: one signed-in dataset on the phone at a time; isolation by clearing is easy to
  verify (SC-002) and to explain.
- **Alternatives**: per-account box prefixes (`u_<uid>_habits`) keep several people's data on one
  phone — weaker isolation, many more boxes, every repository changes.

## R8. Sync triggers without a connectivity package

- **Decision**: sync on auth ready at start, on `AppLifecycleState.resumed`, 5 s after the last
  journaled change (debounce), and every 60 s while the app is in the foreground with pending
  changes. Network failures only set the status to "Chưa đồng bộ".
- **Rationale**: SC-004 measures "within 1 minute of getting network back and being opened";
  resume + 60 s retry meets it without `connectivity_plus`.

## R9. Firestore settings

- **Decision**: `FirebaseFirestore.instance.settings = Settings(persistenceEnabled: false)`; every
  remote call has a 15 s timeout. `FirebaseAuth.instance.setLanguageCode('vi')` so reset and
  verification emails are Vietnamese.
- **Rationale**: Hive is the only offline store; without the timeout, an offline batch commit would
  wait forever.

## R10. Auth error mapping

| Firebase code | Message (`AppStrings`) |
|---|---|
| `email-already-in-use` | "Email này đã có tài khoản. Đăng nhập?" |
| `invalid-credential`, `wrong-password`, `user-not-found` | "Email hoặc mật khẩu không đúng" |
| `invalid-email` | "Email không hợp lệ" |
| `weak-password` | "Mật khẩu cần ít nhất 8 ký tự" (also checked before calling) |
| `too-many-requests` | "Bạn thử quá nhiều lần. Hãy đợi vài phút rồi thử lại." |
| `network-request-failed`, timeout | "Không có mạng. Thử lại sau." |
| `requires-recent-login` | ask for the password again |
| `user-not-found`, `user-disabled` on sync | account gone: sign out locally, clear `owner_uid`, keep data as guest, notice "Tài khoản đã bị xoá. Dữ liệu vẫn còn trên máy này." |
| `user-token-expired`, `requires-recent-login` on sync | keep `owner_uid` and pending changes, status "Hãy đăng nhập lại"; after signing in again with the same account sync resumes (`normalSync`) |

The mapping is a pure function (`authErrorMessage(code)`) with a unit test.

## R11. Account deletion

- **Decision**: re-authenticate with the password → delete every `users/{uid}/records` document in
  batches → delete the Firebase user → clear `owner_uid` and `sync_meta` dirty flags (local data
  becomes guest data) or `clearUserData()` if the checkbox is ticked. If the user deletion fails
  after records were deleted, the screen offers "Thử lại"; the records are already gone, so no
  data remains online.
- **Rationale**: works from the client on Spark (no Cloud Functions, which need Blaze).

## R12. Security Rules

- **Decision**: committed `firestore.rules`:
  `match /users/{uid}/{document=**} { allow read, write: if request.auth != null && request.auth.uid == uid; }`
  and deny everything else. The lead deploys it from the console (Rules tab) or the Firebase CLI.
  Checked manually in the Rules Playground (quickstart step 6).

## R13. Dependents of shared components touched (Principle VII)

Confirm with `graphify explain` + `grep -rn` at implementation time; known today:

- `HiveRepository` — subclasses `GoalRepository`, `HabitRepository`, `HabitLogRepository`,
  `SessionRepository`, `EventRepository`; repository providers in `app_providers.dart`; tests
  using `test_helpers.dart`.
- `HiveBoxes` — `main.dart` (`openAll`), `AppDataActions.clearAll`, test helpers.
- Profile-box repositories — `ProfileRepository`, `StudyPlaceRepository`, `GretCornerRepository`,
  `BlockedAppsRepository`, `ReminderSettingsRepository`.
- `app_router.dart` (new routes), `settings_screen.dart`, `onboarding_screen.dart` (both also
  edited by spec 015 — implement 016 after 015 lands), `app.dart` (lifecycle hook), `main.dart`.
