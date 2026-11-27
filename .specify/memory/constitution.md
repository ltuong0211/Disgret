<!--
Sync Impact Report (2026-11-27) — STATUS: PROPOSED, awaiting project-lead approval
- Version change: 1.0.0 → 2.0.0 (MAJOR: Principle II redefined; accounts and one backend become
  allowed under limits that did not exist before).
- Modified principles:
  - II. Local-Only Privacy → II. Local-First Privacy with Minimal Accounts
  - IV. Layered Simplicity: network calls are added to the one-way layering rule (MINOR-level
    wording expansion carried by this MAJOR bump).
  - VII. Agent Collaboration: backend config files join the never-commit list.
- Added sections: none (rules live inside Principle II and the Platform section).
- Removed sections: none.
- Platform and Technology Constraints: stack line gains "one ADR-approved auth/sync backend".
- Dependent files needing an update once approved (not edited by this proposal):
  - ⚠ AGENTS.md — "Stack" bullet ("No backend, accounts, Firebase, analytics or network calls")
    and "Security and privacy" bullets ("No network requests…").
  - ⚠ docs/decisions/0001-brownfield-stack-android-local-only.md — mark partly superseded by
    ADR-0013.
  - ⚠ docs/architecture/data-model.md — add the account/sync section.
  - ⚠ android/app/src/main/AndroidManifest.xml — INTERNET comment still says google_fonts.
  - ✅ .specify/templates/plan-template.md — Constitution Check reads principles at runtime; no
    change needed.
- Deferred TODOs:
  - TODO(APPROVAL): the lead approves or rejects this amendment (and ADR-0013) in chat; on
    approval set "Ratified/Last Amended", delete this report and update the files above.
  - Resolved 2026-11-27 (spec 016 clarify): no age gate; notice advises under-16s to ask a
    parent. The lead accepted this knowingly; see ADR-0013 "Risks".
-->

# DisGret Constitution

## Core Principles

### I. Scenario-Driven Scope

- Every user-facing screen, flow and feature MUST name, in its spec, the scenario it serves
  (S1 hard to start, S2 distracted mid-session, S3 keeping it up over several days) and the
  evaluation criterion (R-code) it moves. Work that serves none of them is out of the MVP.
- Each screen has one primary action. A second competing entry into a study session MUST NOT be
  added (ADR-0002).
- Infinite-feed and social mechanics are forbidden: no vertical feed of videos, no autoplay loop,
  no likes, comments, shares or follower counts (ADR-0003).
- Parked features (ADR-0004) MUST stay unreachable from the UI until an ADR brings them back.

Rationale: the product exists to help students start and return to studying; anything that
rewards browsing works against the goal and weakens the hypotheses being tested.

### II. Local-First Privacy with Minimal Accounts

- Hive on the device is the source of truth. The app MUST stay fully usable without an account
  and without a network connection; signing in is optional and never blocks studying.
- Exactly one auth/sync backend MAY be used, chosen in an ADR (ADR-0013) that names the provider,
  the data region and every synced field. Adding a second backend or a new synced field needs an
  ADR update first.
- Network requests are allowed only to that backend and only for sign-up, sign-in, sign-out,
  password reset, account deletion and syncing the fields the ADR lists. Fonts and videos stay
  bundled.
- Data minimisation: an account holds only a sign-in identifier (the email) plus the synced
  study data. The app MUST NOT ask for or store a real name, birth date, school,
  class, phone number, photo or location. The optional display name (ADR-0012) syncs only if the
  ADR lists it. The app MUST NOT store a user's age.
- No tracking: no remote analytics, telemetry, crash reporting, advertising or attribution SDKs,
  and no advertising identifier. Backend usage logs that the provider keeps by default are the
  only logs allowed; data is never sold, shared or used for profiling.
- The list of installed apps and the blocked-app list never leave the device. Recorded events
  MUST NOT contain personal identifiers and leave the device only if the ADR lists them.
- Users may be under 18. Before an account is created the app MUST show a Vietnamese privacy
  notice that lists every piece of data leaving the phone, where it is stored and how to delete
  it, and advises students under 16 to ask a parent first. Any age gate or parental-consent step
  is decided in the feature spec and its ADR (spec 016: none).
- "Xoá tài khoản" in the app MUST delete the account and all of its cloud data without contacting
  anyone; local data stays unless the user also chooses to delete it. Signing out MUST NOT leave
  the previous account's data readable by the next account on the same device.
- Any data export MUST be an explicit user action and MUST produce anonymised data.
- A new Android permission MUST be justified in an ADR before it is added to the manifest.

Rationale: users include high-school students, many under 18. Accounts let a student keep their
habits across phones, but every extra field is a liability; collecting the least possible,
keeping the app offline-first and letting users delete everything themselves is the simplest
defensible position that still allows accounts.

### III. Data Integrity and Backward Compatibility

- Data written by any earlier released version MUST remain readable. New model fields MUST have
  defaults; unknown enum values MUST map to a default instead of throwing.
- Hive box names are never reused for a different shape of data. Retired boxes
  (`reel_reactions`, `reel_comments`) are listed as reserved and are simply no longer opened;
  existing user data MUST NOT be deleted without an ADR.
- Rules that decide completion, streaks, strength scores, schedules and statistics MUST live in
  pure functions under `lib/data/` or `lib/services/` and MUST be covered by unit tests.

Rationale: streaks and logs are the user's history and the experiment's evidence; silent data
loss would invalidate both.

### IV. Layered Simplicity

- Dependencies flow one way: screens and widgets → providers → repositories and services.
  Widgets MUST NOT read Hive boxes or call the MethodChannel directly.
- Every native call goes through `lib/services/native_bridge.dart` and MUST be safe on web
  (no-op or default value).
- Every backend call goes through one auth service and one sync service under `lib/services/`;
  screens, widgets and repositories MUST NOT call the backend SDK directly.
- Colours, fonts, radii and spacing come only from `lib/theme/app_theme.dart` (Kotlin screens use
  `android/app/src/main/res/values/colors.xml`). New or modified screens take their text from
  `lib/l10n/app_strings.dart` (ADR-0005).
- A new package dependency MUST be justified in the feature's `plan.md` (problem, alternatives,
  maintenance status); one that changes architecture also needs an ADR.
- Prefer the simplest code that a team member can explain in the course report over clever or
  optimised code.

Rationale: four people and their agents edit one codebase under deadline pressure; predictable
structure is what keeps changes reviewable.

### V. Verified Changes (NON-NEGOTIABLE)

- Before any merge into `master`, all of these MUST pass locally and in CI:
  `dart format --set-exit-if-changed lib test`, `flutter analyze` with zero issues, and
  `flutter test` with zero failures.
- New pure logic MUST ship with unit tests. A changed user flow MUST ship with widget tests that
  cover its main path. A bug fix SHOULD include a regression test when the behaviour is testable
  in Dart.
- Changes to Kotlin native code MUST be checked manually on the Android emulator (Pixel, API 34+)
  against `docs/architecture/native-manual-checklist.md`, and the result recorded in the commit or
  PR description.
- Nobody (human or agent) may report a check as passing without having run it in that state of
  the code.

Rationale: the existing 475 tests are the main safety net for a brownfield refactor on a short
timeline.

### VI. Spec-Driven Traceability

- A change that adds or removes a screen, alters a user flow, changes a data model, or adds a
  dependency MUST go through `/speckit-specify` → `/speckit-plan` → `/speckit-tasks` before code is
  written. Small fixes and refactors without behaviour change do not need a spec.
- Every `plan.md` MUST contain a Constitution Check against these principles; violations are
  listed with justification or the plan is revised.
- Decisions that affect architecture, platform, data or privacy are recorded as ADRs in
  `docs/decisions/`.
- Code keeps the existing decomposition-code comments (for example `// 2.3 Màn can thiệp`), and
  `README.md` (demo script and decomposition map) is updated when a flow or file mapping changes.

Rationale: the course evaluates the design reasoning as much as the app; specs and ADRs make that
reasoning traceable.

### VII. Agent Collaboration and Shared Instructions

- `AGENTS.md` is the single source of shared engineering rules for every coding agent; agent-
  specific files (`CLAUDE.md`, `.claude/`) only add tool-specific instructions and MUST NOT
  duplicate or contradict it.
- Before editing a shared component (router, theme, providers, models, repositories, native
  bridge), an agent MUST check its dependents (Graphify graph or code search) and confirm findings
  in the source files. Generated graphs are aids, not authority.
- An agent works only within the current task's scope; any edit outside it is reported explicitly.
- Secrets, keystores, backend config files (for example `google-services.json`, API keys,
  service-account files) and personal data MUST NOT be committed. Agents MUST NOT create cloud
  projects or accounts; the project lead creates them and supplies config out of band. History on `master` MUST NOT be
  rewritten or force-pushed.

Rationale: several agents acting on one repository need one rulebook and a habit of checking
impact before touching shared code.

## Platform and Technology Constraints

- Target: Android only (ADR-0001). Web is used only for fast UI iteration; iOS and desktop are
  unsupported.
- Stack: Flutter, Dart, Riverpod 3, go_router, Material 3, Hive; Kotlin native layer over the
  `focus/native` MethodChannel; one ADR-approved auth/sync backend (Principle II).
- UI text is Vietnamese. Code, comments for new code, specs, ADRs, `AGENTS.md` and commit messages
  are in English. Existing Vietnamese comments may stay.
- Formatting width is 100 (`analysis_options.yaml`); lints come from `flutter_lints`.
- Test environment: Android emulator (Pixel, API 34+, Google Play image); no physical device is
  assumed.

## Development Workflow and Quality Gates

- Branches: `master` holds verified code; work happens on `feature/<topic>` or `fix/<topic>`,
  one branch per spec. Branches merge into `master` only after the Principle V gates pass.
- Commits follow Conventional Commits in English (`feat:`, `fix:`, `refactor:`, `test:`, `docs:`,
  `chore:`, `ci:`).
- Until the 2026-11-24 hand-off, only the project lead and Claude write code and PR review is not
  required. TODO(REVIEW_RULE): after 2026-11-24, amend this section with the four-person ownership
  and review rule.
- CI (GitHub Actions) runs the Principle V gates and builds a debug APK on every push and pull
  request. A hand-off is a tagged GitHub Release carrying that APK.

## Governance

- This constitution overrides `AGENTS.md`, `CLAUDE.md` and other guides where they conflict; those
  files are corrected to match it.
- Amendments are made in a commit that edits this file, explains the reason, and bumps the
  version: MAJOR for removing or redefining a principle, MINOR for adding a principle or
  materially expanding one, PATCH for wording.
- `/speckit-analyze` and every plan's Constitution Check verify compliance; unresolved violations
  block implementation.
- The project lead (repository owner) approves amendments.

**Version**: 2.0.0 (Proposed, not in force until the project lead approves; 1.0.0 applies until
then) | **Ratified**: 2026-11-22 | **Last Amended**: TODO(APPROVAL): date of approval
