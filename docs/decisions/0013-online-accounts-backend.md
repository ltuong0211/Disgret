# ADR-0013: Optional online accounts on one backend, local-first sync

- Status: Accepted (project lead, chat 2026-11-28, together with constitution 2.0.0)
- Date: 2026-11-27 (accepted 2026-11-28)
- Related: constitution Principle II (amendment 1.0.0 → 2.0.0), ADR-0001 (Android, local only —
  partly superseded once this is accepted), ADR-0012 (display name), spec 016
  (`specs/016-online-accounts/`)

## Context

The lead wants each student to sign up, log in and log out with their own account, so habits and
history follow them to another phone and two students can share one phone without seeing each
other's data. Until now the constitution forbade any backend, account or network call. Users may be
under 18. The team is four students with no budget and no server to run; the app is demoed on an
Android emulator.

Requirements for the backend:

1. Free for a class-sized user base (tens to a few hundred users) with no credit card.
2. First-class Flutter support, maintained packages, Android sign-in with email/password and
   Google.
3. Works with Hive as the on-device source of truth (offline-first): the app must run with no
   network and no account.
4. Server-side rules so one user can never read another user's data.
5. Data region close to Vietnam and documented; account deletion possible from the app.
6. No analytics or tracking pulled in by default.
7. Simple enough for a team member to explain in the course report.

## Options

| | Firebase Auth + Cloud Firestore | Supabase (Auth + Postgres) | Appwrite Cloud | Self-hosted (PocketBase etc.) |
|---|---|---|---|---|
| Free tier | Spark plan, no card. Auth (email, Google) free regardless of user count; Firestore 1 GiB, 50k reads / 20k writes / 20k deletes per day. Over quota → product stops until the next period, never a bill. | Free plan: 2 projects, 500 MB DB, ~50k MAU. **Projects pause after 1 week without activity** and must be resumed by hand. | Free plan exists; limits change often; smaller community. | Free software but needs a server we pay for and keep online. |
| Flutter support | Official FlutterFire packages (`firebase_core`, `firebase_auth`, `cloud_firestore`), `google_sign_in`. Very common in tutorials. | Official `supabase_flutter`; good, smaller ecosystem. | Official `appwrite` SDK. | Community SDK. |
| Offline | Firestore has its own offline cache; we still keep Hive as truth and sync ourselves (see below). | None built in; we sync ourselves. | None built in. | None built in. |
| Per-user isolation | Security Rules (`request.auth.uid == userId`). | Row Level Security policies in SQL. | Document permissions. | Our own code. |
| Region | Choose at project creation; `asia-southeast1` (Singapore) is the closest. | Singapore (`ap-southeast-1`). | Frankfurt / New York / Sydney / Singapore (varies). | Wherever we host. |
| Account deletion from app | `User.delete()` (needs recent sign-in) + delete the user's documents. | Needs an Edge Function or RPC with the service key — extra server code. | Server function. | Our own code. |
| Tracking risk | Google Analytics is opt-in at project creation; we do not add `firebase_analytics` or Crashlytics. | No analytics SDK. | No analytics SDK. | None. |
| Lock-in | High (proprietary). | Low (Postgres). | Medium. | None. |

Prices and limits were checked on 2026-11-27 against the providers' pricing pages and summaries; the
lead should confirm them in the console when creating the project, since Firebase announced a
pricing change effective 2026-09-01.

## Decision

1. **Backend: Firebase Authentication + Cloud Firestore on the Spark (free) plan**, Firestore
   location `asia-southeast1` (Singapore). Reasons: no inactivity pause (a paused Supabase project
   would break a demo after a holiday week), account deletion works from the client without
   server code, official Flutter packages, Security Rules are short and explainable. Chosen by the
   lead in the spec 016 clarification (2026-11-27). Supabase stays the fallback; the sync design
   below is provider-neutral so only the two service classes would change.
2. **Packages** (justified again in plan.md): `firebase_core`, `firebase_auth`, `cloud_firestore`.
   Sign-in is email + password only (spec 016 clarification), so no `google_sign_in`. Never `firebase_analytics`,
   `firebase_crashlytics`, `firebase_messaging`, `firebase_performance` or an ads SDK. Google
   Analytics stays **disabled** when the project is created.
3. **Permission:** `android.permission.INTERNET` is already declared in the manifest (it was added
   for google_fonts runtime fetching, which `main.dart` now disables). It is kept and its comment
   is rewritten to name this ADR. No other permission is added.
4. **Local-first sync:** Hive remains the source of truth. The app works fully without an account.
   When signed in, a sync service pushes local changes and pulls remote ones per record with
   last-write-wins on an `updatedAt` timestamp; Firestore's own offline cache is not relied on.
   Details in `specs/016-online-accounts/research.md` and `data-model.md`.
5. **What syncs** (Firestore path `users/{uid}/…`) — an **allow-list**; anything not named here
   stays on the phone:
   - every record of the `goals`, `habits`, `habit_logs` and `sessions` boxes;
   - profile box keys `onboarding_done`, `celebrated_level`, `study_place`, `corner_owned`,
     `corner_worn`, `corner_sea`, `corner_mascot`;
   - inside the profile `user` map only `motivationTypes`, `preferredReelLength` and
     `quizAnswers` (spec 015 quiz answers: question id → answer ids, no free text).

   **Never synced:** the display name (stays phone-only, ADR-0012 unchanged — lead's decision
   2026-11-28), demo mode, the blocked-app list, installed apps, `events` (reel views,
   interventions, distractions), notification permission flags. A new field or key leaves the
   phone only after it is added to this list (constitution Principle II).
6. **Data minimisation and age:** the account stores only the email (Firebase also keeps its own
   user id, password hash and sign-in timestamps) and the synced data above. No real name, age,
   birth date, school, phone or photo. Per the lead's decision there is **no age gate**: the
   privacy notice shown before sign-up advises students under 16 to ask a parent first.
7. **Deletion:** "Xoá tài khoản" in Cài đặt deletes `users/{uid}` and the Firebase user. Local data
   is kept as guest data unless the user also chooses to delete it.
8. **Config and secrets:** the lead creates the Firebase project and supplies its four Android
   app values (API key, app id, project id, sender id) in a git-ignored `firebase.env.json` passed
   with `--dart-define-from-file`. The lead may run `flutterfire configure` to register the app
   and read the values from the generated files, but those generated files
   (`lib/firebase_options.dart`, `android/app/google-services.json`) are git-ignored and unused. No `google-services.json` and no Gradle Google-services plugin
   are used, so nothing in the repository depends on the config. Without it the app builds and runs
   with the account feature hidden, so CI keeps building without secrets. The Firestore Security
   Rules file (`firestore.rules`) holds no secret and is committed. Agents never create cloud
   projects or accounts.

## Consequences

- The constitution must move to 2.0.0 (Principle II redefined) before any code lands; AGENTS.md,
  ADR-0001 and `docs/architecture/data-model.md` are updated in the same change.
- A privacy notice in Vietnamese (what is stored, where, how to delete) is shown before sign-up.
- Models do not change: change times and deletions are kept in a new `sync_meta` Hive box next to
  the data (see spec 016 data-model.md), so old Hive data stays readable as it is.
- Tests cover the sync merge rules as pure functions; the Firebase layer is wrapped behind
  interfaces so widget tests use fakes and never hit the network.
- Risk: a free-plan quota could be exceeded during a mass demo; the app keeps working locally and
  sync resumes the next day.
- Risk: Google-hosted data for minors with no age gate or verified parental consent. Vietnam's
  Personal Data Protection Law (Law 91/2025/QH15, in force 2026-01-01, guided by Decree
  356/2025/ND-CP) treats under-16s as children and asks for child and parent consent in some
  cases. Mitigations: study data only (no identity data beyond an email), the notice, deletion in
  the app, course-project scale. If the app is published beyond the class, revisit this with an
  age gate or a consent step (a new ADR).
