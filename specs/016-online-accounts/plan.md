# Implementation Plan: Optional Online Accounts

**Branch**: `feature/016-online-accounts` | **Date**: 2026-11-27 | **Spec**: [spec.md](spec.md)

**Input**: Feature specification from `specs/016-online-accounts/spec.md`

**Depends on**: constitution 2.0.0 and ADR-0013 approved by the lead (both Proposed); spec 015
merged into `feature/003-gret-ocean` (it edits `user_profile.dart`, onboarding and Cài đặt, which
this feature also touches).

## Summary

Add optional email + password accounts on Firebase Authentication and sync study data to Cloud
Firestore (`asia-southeast1`), while Hive stays the source of truth and the app works fully as a
guest and offline. A new `sync_meta` box journals every change to the synced boxes (goals,
habits, habit logs, sessions, selected profile keys) without changing any model; a `SyncEngine`
pushes dirty records and pulls newer ones with last-write-wins per record. First login migrates
guest data (or asks merge/replace); sign-out clears the account's data so the next account sees
nothing; "Xoá tài khoản" deletes all online data and the user from the app. Firebase config comes
from a git-ignored `--dart-define-from-file`; without it every account entry point is hidden.

## Technical Context

**Language/Version**: Dart SDK ^3.13.7, Flutter 3.47.x

**Primary Dependencies**: existing (flutter_riverpod, go_router, hive) + **new** `firebase_core`,
`firebase_auth`, `cloud_firestore` (justified below; versions pinned at implementation time, R1).

**Storage**: Hive (unchanged boxes + new `account`, `sync_meta`); Cloud Firestore
`users/{uid}/records/*` (contracts/sync-records.md).

**Testing**: unit tests for merge rules, first-login decision, journal, engine (fakes), error
mapping; widget tests for the account flows and the hidden state; manual emulator scenarios in
quickstart.md.

**Target Platform**: Android (accounts disabled on web)

**Project Type**: mobile-app

**Performance Goals**: sign-up < 2 min end to end (SC-001); sync after reconnect + open < 1 min
(SC-004); sync never blocks the UI (runs after first frame, awaits off the build path)

**Constraints**: offline-first; no analytics/tracking SDKs; ≤ Firebase Spark quotas (20k writes /
50k reads per day); no committed config; old Hive data readable

**Scale/Scope**: course scale (tens to a few hundred accounts, ~1,000 records each); 4 new
screens, 1 new row in Cài đặt, 1 link in onboarding, ~8 new Dart files, 6 shared files touched

### New dependency justification (Principle IV)

| Package | Problem | Alternatives | Maintenance |
|---|---|---|---|
| `firebase_core` | initialise Firebase with manual options | none for Firebase | FlutterFire, Google, frequent releases |
| `firebase_auth` | email/password sign-up, sign-in, reset, re-auth, delete | REST calls by hand (more code, token refresh ourselves) | FlutterFire |
| `cloud_firestore` | per-user remote records with security rules | Realtime Database (weaker queries), REST | FlutterFire |

Architecture-changing → covered by ADR-0013.

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

Checked against **2.0.0 (Proposed)**. Under the ratified 1.0.0, Principle II forbids this feature
outright, so **implementation is blocked until the lead approves 2.0.0 and ADR-0013** (task
T001).

| Principle | Check | Status |
|---|---|---|
| I. Scenario-Driven Scope | Serves S3 (history survives phone change/sharing); no social mechanics; onboarding keeps one primary action (sign-in is a secondary link) | Pass, note: no R-code moved directly (spec) |
| II. Local-First Privacy (2.0.0) | One ADR backend; only email + study data leave the phone; events, blocked/installed apps never; no age stored; privacy notice; in-app deletion; app fully usable offline and as guest; network only to Firebase | Pass under 2.0.0 / **Fail under 1.0.0** → T001 gate |
| III. Data Integrity | No model field added; new box names `account`, `sync_meta` never used before; old data journaled lazily (missing meta = 0); unknown remote box/key ignored; sign-out deletes local account data — covered by ADR-0013 and spec FR-008 | Pass |
| IV. Layered Simplicity | Firebase only in `firebase_auth_service.dart` and `firestore_remote_store.dart`; screens call `accountActionsProvider`; merge rules pure; 3 new packages justified above | Pass |
| V. Verified Changes | Unit + widget tests listed in quickstart; fakes, no network in tests; native checklist re-run (app start changed) | Pass (to verify) |
| VI. Traceability | ADR-0013; README 6.3 row + demo note; data-model doc section; AGENTS.md and ADR-0001 updated when 2.0.0 is approved | Pass |
| VII. Agent Collaboration | Shared files listed in research R13; config never committed; agents do not create the Firebase project | Pass |

Post-design re-check (after data-model and contracts): unchanged. Two design choices reduce risk
against III/IV: sync metadata lives beside the data instead of in models, and the Firebase layer
sits behind `AuthService` / `RemoteStore` interfaces.

## Project Structure

### Documentation (this feature)

```text
specs/016-online-accounts/
├── spec.md
├── plan.md
├── research.md
├── data-model.md
├── quickstart.md
├── contracts/
│   ├── sync-records.md
│   ├── services.md
│   └── account-ui.md
├── checklists/requirements.md
└── tasks.md
```

### Source Code (repository root)

```text
firestore.rules                              # NEW, committed (no secrets)
firebase.env.example.json                    # NEW, empty values; firebase.env.json git-ignored
lib/
├── main.dart                                # init Firebase when AccountsConfig.isAvailable
├── app.dart                                 # lifecycle resume → sync
├── data/
│   ├── hive_boxes.dart                      # + account, sync_meta; + clearAccountData()
│   ├── sync_journal.dart                    # NEW: sync_meta bookkeeping (Hive only)
│   ├── sync_merge.dart                      # NEW: pure merge / first-login / strip / error map
│   └── repositories/
│       ├── hive_repository.dart             # save/delete → journal.touch
│       ├── profile_repository.dart          # writes → journal.touch
│       ├── study_place_repository.dart      # writes → journal.touch
│       └── gret_corner_repository.dart      # writes → journal.touch
├── services/
│   ├── accounts_config.dart                 # NEW
│   ├── auth_service.dart                    # NEW: interface + AccountUser + AuthFailure
│   ├── firebase_auth_service.dart           # NEW: only file importing firebase_auth
│   ├── remote_store.dart                    # NEW: interface + SyncRecord
│   ├── firestore_remote_store.dart          # NEW: only file importing cloud_firestore
│   └── sync_engine.dart                     # NEW
├── providers/
│   ├── account_providers.dart               # NEW
│   └── app_providers.dart                   # AppDataActions.reloadAll public; clearAll signs out
├── router/app_router.dart                   # + 4 account routes, redirect when unavailable
├── screens/
│   ├── account_screen.dart                  # NEW
│   ├── sign_in_screen.dart                  # NEW
│   ├── sign_up_screen.dart                  # NEW (privacy notice + form)
│   ├── forgot_password_screen.dart          # NEW
│   ├── settings_screen.dart                 # + "Tài khoản" row
│   └── onboarding_screen.dart               # + secondary sign-in link on page 1
└── l10n/app_strings.dart                    # + account strings
test/
├── fakes/fake_auth_service.dart             # NEW
├── fakes/in_memory_remote_store.dart        # NEW
├── sync_merge_test.dart, sync_journal_test.dart, sync_engine_test.dart,
├── auth_error_message_test.dart, account_flow_test.dart, accounts_hidden_test.dart
android/app/src/main/AndroidManifest.xml     # INTERNET comment → ADR-0013 (no new permission)
```

**Structure Decision**: single Flutter app, existing layering; Firebase confined to two service
files behind interfaces.

## Complexity Tracking

| Violation | Why Needed | Simpler Alternative Rejected Because |
|---|---|---|
| Backend + network (Principle II of 1.0.0) | Lead's explicit decision: real accounts across phones | Local per-device profiles were offered and declined |
| 3 new packages | Auth and per-user storage | Hand-written REST auth/token refresh is more code to explain |
| Own sync journal instead of Firestore offline cache | Hive must stay the single source of truth | Two offline stores would disagree and are hard to explain |
