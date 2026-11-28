---
description: "Tasks for feature 016: optional online accounts"
---

# Tasks: Optional Online Accounts

**Input**: `specs/016-online-accounts/` (plan.md, spec.md, research.md, data-model.md,
contracts/sync-records.md, contracts/services.md, contracts/account-ui.md, quickstart.md)

**Prerequisites**: (1) the lead approves constitution 2.0.0 and ADR-0013 (T001, done
2026-11-28); (2) spec 015 is merged into `feature/003-gret-ocean` and this branch merges it (T002,
done: 18bc86e); (3) the lead has supplied `firebase.env.json` for the manual checks (T005, not
yet — code is built and tested against fakes first). Cite tasks as `016-Txxx`.

**Tests**: Required by Constitution V. Pure-logic tests are written first and must fail.

**Gate for every task**: `dart format --set-exit-if-changed lib test`, `flutter analyze`,
`flutter test` all pass, with **no** `firebase.env.json` present (accounts hidden) so CI parity
holds. Before editing a shared file, run `graphify explain "<Symbol>"` and
`grep -rn "<Symbol>" lib test` (dependents: research.md R13).

## Format: `[ID] [P?] [Story] Description`

## Phase 1: Setup and governance gate

- [x] T001 Get the lead's approval in chat for constitution 2.0.0 and ADR-0013. Then in
      `.specify/memory/constitution.md` remove the Sync Impact Report comment and the "(Proposed…)"
      note, set **Last Amended** to the approval date; set ADR-0013 Status to "Accepted (project
      lead, chat <date>)" in `docs/decisions/0013-online-accounts-backend.md`; add "Partly
      superseded by ADR-0013 (accounts and sync)" to
      `docs/decisions/0001-brownfield-stack-android-local-only.md`; update the `AGENTS.md` "Stack"
      bullet and the "Security and privacy" bullets to match Principle II 2.0.0. **No code task
      may start before this.**
- [x] T002 Merge `feature/003-gret-ocean` (with 015 landed) into `feature/016-online-accounts`;
      re-check research.md R6/R13 against the merged `user_profile.dart`, onboarding and Cài đặt
      (new profile keys outside `user` are phone-only unless added to R6 and ADR-0013).
- [ ] T003 [P] Add `firebase.env.json` to `.gitignore` and create `firebase.env.example.json` with
      the four keys and empty values (research.md R2).
- [ ] T004 [P] Add `firebase_core`, `firebase_auth`, `cloud_firestore` to `pubspec.yaml` with exact
      versions compatible with Flutter 3.47 (research.md R1); run `flutter pub get`; confirm the
      Android debug build still succeeds without config (`flutter build apk --debug`).
- [ ] T005 [P] Lead task (not an agent): create the Firebase project per quickstart.md
      prerequisites 1–4, publish `firestore.rules` (T006) and put `firebase.env.json` on the
      machine used for manual checks.
- [ ] T006 [P] Create `firestore.rules` at the repo root exactly as in contracts/sync-records.md.

## Phase 2: Foundational (blocks every story)

- [ ] T007 [P] Write unit tests in `test/sync_merge_test.dart`: `resolve` (newer wins, tie →
      deleted wins then remote, missing local meta counts as updatedAt 0 — data-model.md
      sync_meta.updatedAt / sync_meta.deleted); `decideFirstLogin` for every row of the
      data-model.md table; `toRemoteData` keeps only `motivationTypes`, `preferredReelLength`,
      `quizAnswers` of `profile/user` (drops `displayName`, `demoMode` and any unknown field) and
      `fromRemoteData` merges them into the local map keeping local `displayName`/`demoMode`
      (research.md R5 allow-list); unknown box/key → `skip`; a pushed tombstone's local
      `updatedAt` still beats an older remote copy (data-model.md sync_meta.deleted, analyze U2).
      **Done when** tests exist and fail.
- [ ] T008 [P] Write unit tests in `test/auth_error_message_test.dart` for every row of research.md
      R10, plus an unknown code → generic "Đã có lỗi. Thử lại sau.". **Done when** they fail.
- [ ] T009 Implement `lib/data/sync_merge.dart` per contracts/services.md (pure, no Hive, no
      Firebase). T007 and T008 pass.
- [ ] T010 Add `account` and `sync_meta` to `lib/data/hive_boxes.dart` (`all`, `openAll`) and add
      `clearAccountData()` that clears goals, habits, habit_logs, sessions, events, account,
      sync_meta and every profile key except `blocked_packages` and `reminder_permission_asked`
      (research.md R7; data-model.md account.owner_uid, account.email, account.last_pulled_at,
      account.last_sync_ok_at all removed). Keep `clearUserData()` behaviour (it now also
      clears the two new boxes). Update `test/test_helpers.dart` to open the new boxes.
- [ ] T011 [P] Write unit tests in `test/sync_journal_test.dart` (Hive memory boxes): `touch` on a
      synced box sets data-model.md sync_meta.updatedAt / sync_meta.dirty and ignores events,
      `blocked_packages`, `reminder_permission_asked`; delete writes sync_meta.deleted;
      `pendingCount`; `markPushed` clears dirty and drops pushed tombstones;
      `journalAllExisting` marks every existing synced record dirty. `clearAccountData` keeps the
      two phone-bound keys. **Done when** they fail.
- [ ] T012 Implement `lib/data/sync_journal.dart` per contracts/services.md and research.md R6,
      writing data-model.md sync_meta.updatedAt, sync_meta.deleted and sync_meta.dirty exactly as
      the data-model.md rules say (tombstones keep `updatedAt` after push); T011 passes.
- [ ] T013 Call the journal from `HiveRepository.save/delete` in
      `lib/data/repositories/hive_repository.dart` (journal ignores the `events` box) and from the
      write methods of `profile_repository.dart`, `study_place_repository.dart`,
      `gret_corner_repository.dart` in `lib/data/repositories/`. Inject the journal with a default
      so existing call sites and tests compile unchanged. Full test suite passes.
- [ ] T014 [P] Create `lib/services/auth_service.dart` and `lib/services/remote_store.dart`
      (interfaces, `AccountUser`, `AuthFailure`, `SyncRecord`, `PullResult`, `RemoteUnavailable`)
      per contracts/services.md; create `test/fakes/fake_auth_service.dart` and
      `test/fakes/in_memory_remote_store.dart` (offline switch, server-time counter).
- [ ] T015 [P] Create `lib/services/accounts_config.dart` (research.md R2): `isAvailable` false on
      web or when any define is empty.
- [ ] T016 Create `lib/providers/account_providers.dart` with `authServiceProvider`,
      `remoteStoreProvider`, `syncJournalProvider`, `accountStateProvider`
      (`unavailable` | `guest` | `signedIn`, data-model.md AccountState) and `syncStatusProvider`
      (data-model.md SyncStatus); make `AppDataActions._reloadAll` public as `reloadAll()` in
      `lib/providers/app_providers.dart`.
- [ ] T017 Add account strings from contracts/account-ui.md and research.md R10 to
      `lib/l10n/app_strings.dart`.

**Checkpoint**: everything compiles, all old tests pass, no Firebase import outside services.

## Phase 3: User Story 1 — keep using the app without an account (P1) 🎯 MVP gate

**Goal**: guests and config-less builds behave exactly as before.
**Independent test**: quickstart manual 1–2; `test/accounts_hidden_test.dart`.

- [ ] T018 [P] [US1] Widget test `test/accounts_hidden_test.dart`: with `accountStateProvider`
      overridden to `unavailable`, Cài đặt shows no "Tài khoản" row and onboarding page 1 has no
      sign-in link; account routes redirect to `/settings`. With `guest`, the row shows "Chưa đăng
      nhập — dữ liệu chỉ lưu trên máy này" and the onboarding link is visible but secondary.
      **Done when** it fails.
- [ ] T019 [US1] Add the four routes and the unavailable-redirect to `lib/router/app_router.dart`
      (`AppRoutes.account`, `accountSignIn`, `accountSignUp`, `accountForgotPassword`) per
      contracts/account-ui.md, with placeholder screens.
- [ ] T020 [US1] Add the "Tài khoản" row to `lib/screens/settings_screen.dart` and the secondary
      "Đã có tài khoản? Đăng nhập" link on page 1 of `lib/screens/onboarding_screen.dart`, both
      only when available (FR-002, FR-003). T018 passes.
- [ ] T021 [US1] In `lib/main.dart` initialise Firebase only when `AccountsConfig.isAvailable`
      (`Firebase.initializeApp(options: AccountsConfig.options)`, Firestore
      `persistenceEnabled: false`, auth language `vi` — research.md R9); failures to initialise
      fall back to `unavailable` without crashing. Rewrite the INTERNET comment in
      `android/app/src/main/AndroidManifest.xml` to cite ADR-0013 (no permission change).

## Phase 4: User Story 2 — sign up and keep my existing data (P1)

**Goal**: privacy notice → sign-up → guest data uploaded.
**Independent test**: quickstart manual 3; `test/sync_engine_test.dart` upload cases;
`test/account_flow_test.dart` sign-up case.

- [ ] T022 [P] [US2] Unit tests in `test/sync_engine_test.dart` with fakes: `firstLogin` on
      `uploadGuest` journals all existing records, pushes them, sets data-model.md
      account.owner_uid / account.email / account.last_sync_ok_at, leaves pending 0; events and
      phone-bound keys are never in the pushed set (FR-014); the pushed `profile/user` has no
      `displayName` or `demoMode`, and no record carries any account attribute other than the email
      stored locally (FR-019, analyze G1); app killed mid-upload (fake throws after first batch) →
      next `syncNow` finishes with no duplicates. **Done when** they fail.
- [ ] T023 [US2] Implement `lib/services/sync_engine.dart` `syncNow` (push then pull, never
      throws, updates `syncStatusProvider`) and `firstLogin` per contracts/services.md and
      data-model.md state transitions; set data-model.md account.owner_uid, account.email,
      account.last_pulled_at (newest `syncedAt` applied; next pull from it − 60 000 ms) and
      account.last_sync_ok_at; apply remote records directly to Hive, set sync_meta.updatedAt from
      the remote and sync_meta.dirty false, call `reloadAll()` and reschedule reminders. T022
      passes.
- [ ] T024 [P] [US2] Implement `lib/services/firebase_auth_service.dart` (signUp, signIn,
      sendPasswordReset, reauthenticate, deleteUser, signOut; maps codes to `AuthFailure`, 15 s
      timeouts) — the only file importing `firebase_auth`.
- [ ] T025 [P] [US2] Implement `lib/services/firestore_remote_store.dart` per
      contracts/sync-records.md (batches ≤ 400, pull pages of 500, `hasAny`, `deleteAll`) — the
      only file importing `cloud_firestore`.
- [ ] T026 [P] [US2] Widget test in `test/account_flow_test.dart`: Tạo tài khoản shows the notice
      first (every item from contracts/account-ui.md SignUpScreen step 1 incl. the under-16
      sentence); "Để sau" stores nothing; password < 8 shows the error without calling the fake;
      `email-already-in-use` shows the message with a button to sign-in; success shows "Đã tạo
      tài khoản" and the email in Cài đặt. **Done when** it fails.
- [ ] T027 [US2] Build `lib/screens/sign_up_screen.dart` and the signed-in/guest views of
      `lib/screens/account_screen.dart` per contracts/account-ui.md; add `accountActionsProvider`
      (signUp → firstLogin) to `lib/providers/account_providers.dart`; validation per
      data-model.md Validation. T026 passes.

## Phase 5: User Story 3 — log in on another phone, log out (P1)

**Goal**: sign-in downloads or merges; sign-out leaves nothing behind.
**Independent test**: quickstart manual 4, 8; tests below.

- [ ] T028 [P] [US3] Extend `test/sync_engine_test.dart`: `downloadOnly` fills empty boxes and
      sets `onboarding_done` so onboarding is skipped; `askMergeOrReplace` merge keeps records
      from both sides; replace clears synced boxes then downloads; `prepareSignOut` returns the
      pending count left when the fake is offline; `clearAccountData` result per T010.
      **Done when** they fail.
- [ ] T029 [P] [US3] Extend `test/account_flow_test.dart`: wrong password shows "Email hoặc mật
      khẩu không đúng"; merge/replace dialog appears only for `askMergeOrReplace`; sign-out with
      pending > 0 shows the warning with "Ở lại" default; sign-out disabled while
      `focusSessionProvider` is running; after sign-out the app is on `/onboarding`.
      **Done when** it fails.
- [ ] T030 [US3] Implement `firstLogin` branches `downloadOnly`, `askMergeOrReplace`,
      `clearThenDownload` and `prepareSignOut` / `clearAccountData` in
      `lib/services/sync_engine.dart`. T028 passes.
- [ ] T031 [US3] Build `lib/screens/sign_in_screen.dart`, the merge/replace dialog and sign-out
      flow (warning dialog, `ref.invalidate(focusSessionProvider)` not needed because sign-out is
      blocked while running) in `lib/screens/account_screen.dart`; add signIn / signOut to
      `accountActionsProvider`. T029 passes.

## Phase 6: User Story 4 — two students share one phone (P2)

**Goal**: zero data of the previous account after switching.
**Independent test**: quickstart manual 7.

- [ ] T032 [US4] Widget/integration test in `test/account_isolation_test.dart`: account A with a
      goal, habit, log, session, display name, corner item and a reminder-enabled habit signs
      out; B signs in (fake remote empty for B): Hôm nay, Thói quen, Tiến độ, bản đồ biển, Góc
      của Gret show nothing of A; `ReminderService` has no schedule for A's habit;
      `blocked_packages` unchanged (FR-012, FR-013, SC-002). Fix any provider that survives
      `reloadAll()` (add it to `reloadAll` in `lib/providers/app_providers.dart`).

## Phase 7: User Story 5 — study offline while signed in (P2)

**Goal**: offline never breaks studying; sync catches up.
**Independent test**: quickstart manual 5.

- [ ] T033 [P] [US5] Extend `test/sync_engine_test.dart`: offline push keeps entries dirty and
      status `offline(pending)`; later `syncNow` pushes them; two phones editing the same habit →
      newer `updatedAt` wins on both after sync; logs from both phones all kept (FR-016); a record
      whose server time is up to 60 s older than `last_pulled_at` is still pulled (overlap, analyze
      U1); account gone (`user-not-found`/`user-disabled`) → owner cleared, data kept as guest;
      `user-token-expired` → owner and pending kept, status "Hãy đăng nhập lại" (research.md R10).
      **Done when** they fail.
- [ ] T034 [US5] Implement the triggers (research.md R8): sync after auth ready, on
      `AppLifecycleState.resumed` in `lib/app.dart`, 5 s debounce after a journal change, 60 s
      retry while foreground with pending; pull from data-model.md account.last_pulled_at − 60 000
      ms; handle account-gone and token-expired per research.md R10. Show the
      status strings in Cài đặt and AccountScreen (FR-017). T033 passes.
- [ ] T035 [US5] Make "Xoá toàn bộ dữ liệu" (`AppDataActions.clearAll` in
      `lib/providers/app_providers.dart`) also sign out locally without touching online data
      (spec edge case); widget test in `test/account_flow_test.dart`.

## Phase 8: User Story 6 — forgot password (P2)

- [ ] T036 [US6] Build `lib/screens/forgot_password_screen.dart` per contracts/account-ui.md; the
      same message for any email, including when the fake throws `user-not-found` (FR-007);
      widget test in `test/account_flow_test.dart`.

## Phase 9: User Story 7 — delete my account (P2)

- [ ] T037 [P] [US7] Extend `test/sync_engine_test.dart` / `test/account_flow_test.dart`: delete
      requires the password (re-auth), calls `deleteAll` then `deleteUser`; checkbox off keeps
      local data as guest (owner cleared), on → `clearUserData`; offline → button disabled;
      user deletion failing after records were deleted shows "Thử lại" (research.md R11).
      **Done when** they fail.
- [ ] T038 [US7] Implement `deleteAccount` in `accountActionsProvider` and the delete dialog in
      `lib/screens/account_screen.dart` (FR-018). T037 passes.

## Phase 10: Polish and cross-cutting

- [ ] T039 [P] Add "6.3 Tài khoản và đồng bộ" to the README decomposition map and a short demo
      note (sign up from sample data, sign in on a second emulator) in `README.md`.
- [ ] T040 [P] Add an English "Accounts and sync (feature 016)" section to
      `docs/architecture/data-model.md` (boxes `account`, `sync_meta`, synced keys table from
      research.md R6, events stay local).
- [ ] T041 [P] Grep check: no `firebase_` import outside `lib/services/firebase_auth_service.dart`,
      `lib/services/firestore_remote_store.dart`, `lib/main.dart`, `lib/services/accounts_config.dart`;
      no analytics/crashlytics package in `pubspec.lock`; no `firebase.env.json` tracked by git.
- [ ] T042 Run quickstart.md manual scenarios 1–11 on two emulators with the lead's config;
      record results in the PR description; run `graphify update .`.

## Dependencies

- T001 → everything. T002 → all code tasks (shared files edited by 015).
- Phase 2 (T007–T017) → all stories. T009 → T023; T012/T013 → T022–T023.
- US1 (T018–T021) → US2 (needs routes, entry points, Firebase init).
- US2 → US3 (sign-in reuses engine and screens) → US4 (needs sign-out).
- US5, US6, US7 depend on US2; US5 and US7 also on US3 (sign-out/owner handling). US6 is
  independent of US3–US5.
- Polish after all stories; T042 needs T005.

## Parallel opportunities

- Setup: T003, T004, T006 together (T005 is the lead's, in parallel).
- Foundational: T007, T008, T011, T014, T015 together; then T009, T012 in parallel.
- US2: T024, T025, T026 in parallel after T023 starts; US3 tests T028, T029 together.
- After US3: US6 (T036) alongside US5 (T033–T035) and US7 (T037–T038) — different files except
  `account_screen.dart` (US5 status vs US7 dialog: coordinate or do sequentially).

## Implementation strategy

1. Gate: T001 (approval) and T002 (015 merged). Without approval, stop.
2. MVP = Phases 1–5 (guest unchanged, sign up with migration, sign in/out). Demo-able on two
   emulators.
3. Then US4 (isolation proof), US5 (offline), US7 (deletion — required by the constitution before
   any release beyond the team), US6.
4. Polish and the manual run (T042) before merging into `feature/003-gret-ocean` / `master`.
