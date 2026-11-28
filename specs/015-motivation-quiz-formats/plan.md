# Implementation Plan: Richer Motivation Quiz with Video-Format Preference

**Branch**: `feature/003-motivation-quiz-formats` | **Date**: 2026-11-23 | **Spec**: [spec.md](spec.md)

**Input**: Feature specification from `specs/015-motivation-quiz-formats/spec.md`

**Depends on**: feature 002 (bounded dose, recommender without likes, `MotivationScreen`)

## Summary

Grow the onboarding / retake quiz from 4 to 8 one-tap steps: 6 reason questions (same top-2
rule) and 2 video-format questions (a direct "choose up to 2" and a scenario check). Store up to 2
`VideoFormat`s on `UserProfile` (default empty). Give every reel a `format` in `reels.json`
(default `other`), add new bundled reels so each of the 4 quiz formats has start-eligible reels,
and add a +1 format bonus to `ReelRecommender.score` (half a tag match). Show the profile in
Cài đặt and a per-format "reels shown / started" breakdown in Tiến độ → Phiên học.

## Technical Context

**Language/Version**: Dart SDK ^3.13.7, Flutter 3.47.x

**Primary Dependencies**: flutter_riverpod, go_router, hive, video_player (all existing). No new
dependency.

**Storage**: Hive `profile` box (new optional field `preferredFormats`); `assets/reels/reels.json`
(new optional field `format`); new video files under `assets/reels/`.

**Testing**: unit tests for quiz scoring, format derivation, recommender and catalogue; widget
tests for onboarding, retake quiz, Cài đặt profile and stats.

**Target Platform**: Android (web for UI iteration)

**Project Type**: mobile-app

**Performance Goals**: each quiz step reacts to a tap immediately; onboarding ≤ 75 s median
(SC-001)

**Constraints**: local-only; profiles from earlier versions must load (Constitution III); APK
grows ~2 MB per new reel

**Scale/Scope**: 2 pure modules extended, 1 widget added, 4 screens touched, 4–8 new videos

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

| Principle | Check | Status |
|---|---|---|
| I. Scenario-Driven Scope | S1 (first reel fits → start faster, H1), S3 (profile visible and editable); no feed or social mechanic; bounded dose unchanged | Pass |
| II. Local-Only Privacy | No identifying questions; profile and formats stay in Hive; new videos bundled, no streaming | Pass |
| III. Data Integrity | `preferredFormats` defaults to empty; unknown format names map to `other` / are dropped; no box renamed | Pass |
| IV. Layered Simplicity | Scoring and derivation are pure functions (`motivation_quiz.dart`, `reel_recommender.dart`, `focus_stats.dart`); screens only render; no new package | Pass |
| V. Verified Changes | Unit + widget tests listed in quickstart; catalogue test enforces SC-006 | Pass (to verify) |
| VI. Traceability | ADR-0007 updated for new videos before they are added; README demo + data-model doc updated | Pass with note R5 |
| VII. Agent Collaboration | Shared files: `user_profile.dart`, `reel.dart`, `reel_recommender.dart`, `focus_stats.dart`, `app_providers.dart`; dependents in research R6 | Pass |

Post-design re-check: unchanged.

## Project Structure

### Documentation (this feature)

```text
specs/015-motivation-quiz-formats/
├── plan.md
├── research.md
├── data-model.md
├── quickstart.md
├── contracts/quiz-flow.md
├── contracts/reels-catalogue.md
├── checklists/requirements.md
└── tasks.md              # /speckit-tasks
```

### Source Code (repository root)

```text
lib/
├── data/models/video_format.dart        # NEW: enum + Vietnamese labels + safe parse
├── data/models/user_profile.dart        # + preferredFormats (default const [])
├── data/models/reel.dart                # + format (default VideoFormat.other)
├── data/motivation_quiz.dart            # 6 reason questions; 2 format questions; preferredFormatsFrom()
├── providers/app_providers.dart         # ProfileNotifier.updateMotivationProfile(types, formats) replaces updateMotivationTypes; focusStatsProvider passes reel formats
├── services/reel_recommender.dart       # + format bonus (+1), profile formats
├── services/focus_stats.dart            # + per-format shown / started counts
├── screens/onboarding_screen.dart       # 8 quiz steps, format steps
├── screens/quiz_screen.dart             # same 8 steps for the retake
├── screens/settings_screen.dart         # profile summary: reasons + formats
├── screens/stats_screen.dart            # per-format rows in the Reels card
├── widgets/quiz_question_view.dart      # takes step index / total (no longer motivationQuestions.length)
├── widgets/format_question_view.dart    # NEW: multi-select (≤2) with "Không chắc"
└── l10n/app_strings.dart                # quiz, format labels, profile and stats text
assets/reels/reels.json                  # + format on every reel; new reels
assets/reels/r7.mp4 … rN.mp4             # NEW videos (sourced by the team)

test/
├── motivation_quiz_test.dart            # 6 questions, every reason once per question; format derivation
├── reel_recommender_test.dart           # format bonus; pinned and limits unchanged
├── data_test.dart                       # profile without formats loads; unknown format; catalogue per format (SC-006)
├── stats_test.dart                      # per-format counts
├── onboarding / widget_test.dart        # 8 steps, progress "Câu i/8", skip format
└── settings / quiz retake tests         # summary, retake replaces, leaving keeps old
```

**Structure Decision**: same single Flutter project as features 001 and 002.

## Complexity Tracking

No constitution violations.

## Revision 2026-11-27

The lead approved [quiz-and-tags-design.md](quiz-and-tags-design.md). It replaces the earlier
choices in this plan where they differ:

- New files: `lib/data/models/reel_labels.dart` (label enums), `lib/data/models/reel_preferences.dart`
  (stored quiz answers → preferences, pure). `video_format.dart` is not created; `VideoFormat`
  lives in `reel_labels.dart`.
- Changed: `motivation_type.dart` (+2 reasons), `reel.dart` (labels), `user_profile.dart`
  (`quizAnswers`), `motivation_quiz.dart` (11 questions with ids and parts),
  `reel_recommender.dart` (filter, weights, variety), `quiz_question_view.dart` (multi choice,
  "Không chắc"), `onboarding_screen.dart` (core part), `quiz_screen.dart` (all / extra part),
  `settings_screen.dart` (summary, extra-part entry), `app_providers.dart`
  (`saveQuizAnswers` replaces `updateMotivationTypes`).
- Constitution check unchanged: rule-based, on-device, no new permission or dependency, no
  identifying question (FR-014). Data change is additive (new optional key, new enum values).
- Data model and tasks: [data-model.md](data-model.md), [tasks.md](tasks.md).
