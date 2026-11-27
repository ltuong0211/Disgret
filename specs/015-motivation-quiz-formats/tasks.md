---
description: "Tasks for feature 015: motivation quiz, reel labels and matching"
---

# Tasks: Motivation Quiz, Reel Labels and Matching

Revised 2026-11-27 after the lead approved
[quiz-and-tags-design.md](quiz-and-tags-design.md). The earlier task list (6 reason questions + 2
format questions, 4 formats) is replaced; its unfinished tasks are folded in below.

**Input**: spec.md (FR-001..FR-014), data-model.md, quiz-and-tags-design.md, contracts/.

**Tests**: Required by Constitution V. Pure-logic tests first.

**Gate for every task**: `dart format --set-exit-if-changed lib test`, `flutter analyze`,
`flutter test`. Before editing a shared file, run `graphify explain` and `grep -rn` on it.

## Phase 1: Setup

- [x] T001 Add quiz, label, settings and button strings to `lib/l10n/app_strings.dart`
      (design §3, §4).
- [ ] T002 [P] Team task: label r1–r6 with the full label set (design §3, §7) and put the agreed
      values in `assets/reels/reels.json`.

## Phase 2: Foundational

- [x] T003 [P] Tests in `test/reel_labels_test.dart`: every label enum's `fromName` maps unknown
      and null to its default (data-model.md Reel labels); `Reel.fromMap` reads `motivation` and
      falls back to `tags`, drops unknown names and fills defaults (data-model.md Reel.tags,
      Reel.format, Reel.tone, Reel.messenger, Reel.origin, Reel.themes, Reel.goals, Reel.language,
      Reel.flags).
- [x] T004 Add `growth` and `contribution` to `lib/data/models/motivation_type.dart` (data-model.md
      MotivationType) with icons; create `lib/data/models/reel_labels.dart` (data-model.md Reel
      labels) and extend `lib/data/models/reel.dart` (data-model.md Reel.*). T003 passes.
- [x] T005 [P] Tests in `test/reel_preferences_test.dart` for `ReelPreferences.fromAnswers`
      (data-model.md ReelPreferences.motivationTypes, .formats, .tone, .messengers, .themes, .goal,
      .avoidFlags, .avoidLanguages): each rule, "Không chắc" = empty, unknown ids ignored, legacy
      reasons kept when q1–q4 are unanswered and counted first when only q3/q4 are answered.
- [x] T006 Create `lib/data/models/reel_preferences.dart`; add `quizAnswers` and the `preferences`
      getter to `lib/data/models/user_profile.dart` (data-model.md UserProfile.quizAnswers,
      UserProfile.preferences); old profile maps still load (SC-003). T005 passes.
- [x] T007 Rewrite `lib/data/motivation_quiz.dart` with the 11 questions of design §4 (ids, parts,
      choice limits, answer ids and labels per data-model.md Quiz); update
      `test/motivation_quiz_test.dart` (counts, every reason once per reason question, unique ids,
      core = 7, extra = 4).
- [x] T008 `ProfileNotifier.saveQuizAnswers(answers, {merge})` in `lib/providers/app_providers.dart`
      replaces `updateMotivationTypes`: stores answers (replace or merge) and rewrites
      `motivationTypes` from `ReelPreferences.fromAnswers`; provider tests in
      `test/providers_test.dart`.

## Phase 3: US1 — the first reel fits me (P1)

- [x] T009 [P] [US1] Tests in `test/reel_recommender_test.dart`: hard filter, every weight of design
      §5.3 (data-model.md Score), variety rule §5.4, worked example §5.6, pinned-first and limits
      unchanged.
- [x] T010 [US1] Implement the filter, score and variety in `lib/services/reel_recommender.dart`;
      `MotivationScreen` passes the profile preferences. T009 passes.
- [x] T011 [US1] Generalise `lib/widgets/quiz_question_view.dart`: takes a `QuizQuestion`, step and
      total; single choice advances on tap; multi choice toggles up to `maxChoices` with a "Tiếp"
      button; every question has "Không chắc"; answer hints shown under the text.
- [x] T012 [US1] `lib/screens/onboarding_screen.dart`: core part pages (7), saved with the profile at
      the end.
- [x] T013 [US1] Widget tests: onboarding walks the 7 core questions (single tap, multi + Tiếp,
      Không chắc) and saves answers and reasons (`test/widget_test.dart`).

## Phase 4: US2 — retake and extend from Cài đặt (P2)

- [x] T014 [US2] `lib/screens/quiz_screen.dart` takes a part (all / extra): "Làm lại quiz động lực"
      asks 11 questions and replaces answers; "Giúp app hiểu bạn hơn" asks the extra 4 and merges.
      Route `AppRoutes.quiz` with `?part=extra`.
- [x] T015 [US2] `lib/screens/settings_screen.dart`: profile summary (reasons, formats, tone) and the
      "Giúp app hiểu bạn hơn" entry; widget tests for both entries.

## Phase 5: US3 — measure per format (P3)

- [ ] T016 [P] [US3] Tests in `test/stats_test.dart` for `FocusStats.formatStats` (shown, started per
      format; unknown reel id → other; old records counted).
- [ ] T017 [US3] Add `formatStats` to `lib/services/focus_stats.dart` and a row group to the
      statistics view.

## Phase 6: Catalogue and polish

- [ ] T018 Team task: collect about 30 videos per design §6 (720p, ~1 Mbps, 15–45 s), update
      ADR-0007 with sources and licensing first.
- [ ] T019 [P] Catalogue test in `test/data_test.dart`: every reel file exists, every label is in the
      fixed lists, each quiz format has ≥1 `start` reel once T018 lands (SC-006).
- [ ] T020 Hôm nay invitation to the extra part after the third finished session (design §4).
- [ ] T021 Update `README.md`, `docs/architecture/data-model.md`, ADR-0003 note on the new scoring.
- [ ] T022 Run the gate and the quickstart (onboarding timing for SC-001 on the emulator); mark the
      spec Implemented.

## Dependencies

T001 → T003/T004 → T005/T006 → T007 → T008 → US1 (T009 → T010; T011 → T012 → T013) → US2 → US3.
T002, T018 are team work in parallel. T019 waits for T018.
