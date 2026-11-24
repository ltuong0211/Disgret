---
description: "Tasks for feature 003: richer motivation quiz with video-format preference"
---

# Tasks: Richer Motivation Quiz with Video-Format Preference

**Input**: `specs/003-motivation-quiz-formats/` (plan.md, spec.md, research.md, data-model.md,
contracts/quiz-flow.md, contracts/reels-catalogue.md, quickstart.md)

**Prerequisite**: feature 002 merged (recommender without likes, `MotivationScreen`).

**Tests**: Required by Constitution V. Pure-logic tests are written first and must fail.

**Gate for every task**: `dart format --set-exit-if-changed lib test`, `flutter analyze`,
`flutter test` all pass. Before editing a shared file, run `graphify explain "<Symbol>"` and
`grep -rn "<Symbol>" lib test` (dependents: research.md R6).

## Format: `[ID] [P?] [Story] Description`

## Phase 1: Setup

- [ ] T001 Add quiz, format-label, profile-summary and per-format stats strings to
      `lib/l10n/app_strings.dart` (wording drafts in research.md R1/R2, contracts/quiz-flow.md).
- [ ] T002 [P] Team task: watch r1–r6 and record their format (`interview` / `edit` /
      `studyWithMe` / `story`) in a table in `specs/003-motivation-quiz-formats/research.md` R5;
      list which formats still need new reels.

## Phase 2: Foundational (blocks every story)

- [ ] T003 [P] Write unit tests in `test/data_test.dart`: `VideoFormat.fromName` maps unknown and
      null to `other` (data-model.md VideoFormat); a profile map without `preferredFormats` loads
      with an empty list and keeps `motivationTypes` (data-model.md UserProfile.preferredFormats,
      SC-003); unknown stored format names are dropped; a reel map without `format` or with an
      unknown one gets `other` (data-model.md Reel.format). **Done when** tests exist and fail.
- [ ] T004 Create `lib/data/models/video_format.dart` (enum, Vietnamese labels, `fromName`) per
      data-model.md VideoFormat.
- [ ] T005 Add `preferredFormats` to `lib/data/models/user_profile.dart` (constructor default
      `const []`, `copyWith`, `toMap`, `fromMap`) per data-model.md UserProfile.preferredFormats;
      add `format` to `lib/data/models/reel.dart` (`Reel.fromMap` reads optional `format`) per
      data-model.md Reel.format. T003 passes.
- [ ] T006 Replace `ProfileNotifier.updateMotivationTypes` with
      `updateMotivationProfile(types, formats)` in `lib/providers/app_providers.dart`; update its
      caller in `lib/screens/quiz_screen.dart` (formats passed as the current profile's until
      US1 lands).

## Phase 3: User Story 1 — The first reel already fits me (P1) 🎯 MVP

**Independent test**: quickstart scenarios 1–3.

- [ ] T007 [P] [US1] Update `test/motivation_quiz_test.dart`: exactly 6 reason questions, each with
      every MotivationType once and varied order (FR-001); `topMotivationTypes` unchanged;
      `formatQuestions` has Q7 (4 formats + "Không chắc") and Q8 (4 formats + "Gì cũng được");
      `preferredFormatsFrom` cases from research.md R2 (none, one, two, scenario reorders,
      scenario appends, "Không chắc" + scenario, never `other`, ≤2) per data-model.md
      UserProfile.preferredFormats. **Done when** tests exist and fail.
- [ ] T008 [US1] In `lib/data/motivation_quiz.dart` add the 2 new reason questions (research.md
      R1), `formatQuestions` and `preferredFormatsFrom`; T007 passes.
- [ ] T009 [P] [US1] Update `test/reel_recommender_test.dart`: +1 when `reel.format` ∈
      `profile.preferredFormats`, `other` never matches, tag match (2) still beats format (1),
      tie on tags → preferred format first (SC-002), pinned first and `limitFor` unchanged; then
      add the bonus to `ReelRecommender.score` / `recommend` in
      `lib/services/reel_recommender.dart` per data-model.md Score.
- [ ] T010 [US1] Generalise `lib/widgets/quiz_question_view.dart` to take step index and total
      ("Câu i/8") instead of `motivationQuestions.length`; create
      `lib/widgets/format_question_view.dart` (multi-select ≤2, "Không chắc" exclusive, "Tiếp"
      enabled when something is selected) per contracts/quiz-flow.md.
- [ ] T011 [US1] `lib/screens/onboarding_screen.dart`: 6 reason steps + Q7 + Q8, Back to previous
      step, save `preferredFormatsFrom(...)` with the profile in `_finish`; keep the intro and
      goal steps (contracts/quiz-flow.md).
- [ ] T012 [US1] Widget tests in `test/widget_test.dart` (onboarding group): 8 quiz steps with
      "Câu i/8", Q7 caps at 2 and "Không chắc" clears others, finishing stores reasons and
      formats; "Không chắc" + "Gì cũng được" stores no format and onboarding still finishes.
- [ ] T013 [US1] Widget test in `test/motivation_screen_test.dart`: profile with format
      `interview` and a catalogue where an interview reel ties on tags → reel 1/3 is that reel;
      no matching reel → playlist still has reels (US1 scenario 3).

## Phase 4: User Story 2 — I can see and change my profile (P2)

**Independent test**: quickstart scenarios 4–5.

- [ ] T014 [US2] `lib/screens/quiz_screen.dart`: same 8 steps as onboarding (reuse the two quiz
      widgets); finishing calls `updateMotivationProfile`; leaving early saves nothing; SnackBar
      lists the new reasons and formats (contracts/quiz-flow.md).
- [ ] T015 [US2] `lib/screens/settings_screen.dart`: add "Dạng video bạn thích" chips and the
      empty hint "Chưa chọn – làm lại quiz để thêm" below "Động lực của bạn" (contracts/quiz-flow.md).
- [ ] T016 [US2] Widget tests (`test/widget_test.dart` settings group): summary shows reasons and
      formats; old profile shows the hint; retake replaces both; leaving at Câu 4 changes nothing;
      habits and events untouched.

## Phase 5: User Story 3 — Formats that lead to studying (P3)

**Independent test**: quickstart scenario 6.

- [ ] T017 [P] [US3] Tests in `test/stats_test.dart`: `formatStats` counts shown and started per
      format, unknown reel id → `other`, formats with no record omitted in the view (data-model.md
      FocusStats.formatStats).
- [ ] T018 [US3] Add `formatStats` to `lib/services/focus_stats.dart` (`FocusStats.from` takes
      `reelFormats`); pass the catalogue map from `focusStatsProvider` in
      `lib/providers/app_providers.dart`; add the per-format rows to the Reels card in
      `lib/screens/stats_screen.dart` (contracts/quiz-flow.md). T017 passes.

## Phase 6: Catalogue (FR-010, FR-011) — content, then code

- [ ] T019 Team task: source new 15–60 s videos so each quiz format has ≥1 (target 2) reel with
      context `start` (research.md R5); update `docs/decisions/0007-accepted-risk-bundled-instagram-videos.md`
      with the new files and sources **before** committing them.
- [ ] T020 Add the videos under `assets/reels/`, their entries (with `format`, `source`,
      `creditUrl`) to `assets/reels/reels.json` per contracts/reels-catalogue.md, and the
      existing r1–r6 formats from T002.
- [ ] T021 [P] Catalogue test in `test/data_test.dart`: every reel file exists, each of the four
      quiz formats has ≥1 reel with `start` in `context` (SC-006), new reels are 15–60 s.

## Phase 7: Polish

- [ ] T022 Update `README.md` (onboarding step of the demo script, decomposition map 1.1/1.3) and
      `docs/architecture/data-model.md` (UserProfile, Reel, score, FocusStats).
- [ ] T023 Run the full gate and quickstart scenarios 1–6 (scenario 5 on the emulator), time the
      onboarding (SC-001), mark the spec "Implemented".

## Dependencies & order

Phase 1 → Phase 2 (T003 → T004 → T005 → T006) → US1 (T007 → T008; T009; T010 → T011 → T012,
T013) → US2 (T014 → T015 → T016) → US3 (T017 → T018) → Catalogue (T019 → T020 → T021) → Polish.
T002 and T019 are team content tasks and can start at once; T020/T021 wait for the files.
US2 and US3 depend only on Phase 2 and can run in parallel with US1 after T006.

## Parallel examples

- T002 ∥ T003 ∥ T019 (content vs code).
- T007 ∥ T009 ∥ T017 (different test files), then T008, the recommender change, T018.

## Implementation strategy

MVP = Phases 1–3 with r1–r6 tagged (T002): the quiz and the format bonus work even before new
videos arrive. Then US2 (small), US3 (small), and the catalogue phase as soon as content and the
ADR-0007 update are ready; T021 is the gate that keeps the spec from being marked Implemented
without every format covered.
