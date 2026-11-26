# Research: Richer Motivation Quiz with Video-Format Preference

## R1. Quiz length and structure

- **Decision**: 6 reason questions (the 4 existing + 2 new), then 2 format questions, total 8
  one-tap steps with "Câu i/8". Reason questions keep "every reason once per question" and the
  existing `topMotivationTypes` rule (top 2, tie → earliest chosen).
- **Rationale**: 6 answers over 5 reasons make a 2-way tie less likely than 4 answers; 8 one-tap
  steps of ~5 s each keep onboarding near one minute (SC-001).
- **Alternatives**: a slider per reason (slower, harder to explain); adaptive questions (complex,
  hard to test).
- **New reason questions** (draft, final wording in AppStrings):
  - "Một ngày học tốt sẽ kết thúc thế nào?" (tiền: "Gần hơn với mục tiêu tài chính"; gia đình: "Kể
    cho người thân nghe"; sự nghiệp: "Thêm một kỹ năng cho nghề mình muốn"; chứng minh: "Tự hào vì
    đã không bỏ cuộc"; tự do: "Có thời gian rảnh mà không áy náy").
  - "Lời nào khiến bạn muốn ngồi vào bàn ngay?" (tiền / gia đình / sự nghiệp / chứng minh / tự do,
    one line each).

## R2. Format questions and derivation

- **Decision**:
  - Q7 (direct, multi-select up to 2): "Dạng video nào truyền cảm hứng cho bạn nhất?" — Phỏng vấn /
    chia sẻ của người nổi tiếng; Video edit có nhạc và câu nói truyền động lực; Study with me / một
    ngày của học sinh, sinh viên; Câu chuyện ngắn hoặc hoạt hình; Không chắc / gì cũng được
    (exclusive). A "Tiếp" button confirms (one extra tap only on this step).
  - Q8 (scenario, single): "Còn 1 phút trước khi học, bạn sẽ bấm vào video nào?" — one concrete
    example per format + "Gì cũng được".
  - `preferredFormatsFrom(direct, scenario)`: start from the direct choices (≤2, "Không chắc" =
    none); if the scenario answer is among them, move it first; if fewer than 2 and the scenario
    answer is a format not chosen, append it. Result: 0–2 formats.
- **Rationale**: a direct question is clear; the scenario question catches people who answer the
  direct one aspirationally and orders the top format. The UI cap of 2 makes "all formats chosen"
  impossible, so the spec edge case reduces to "Không chắc".
- **Alternatives**: ranking all formats (slow); showing short video samples per format (needs more
  assets, slower onboarding).

## R3. Recommender bonus

- **Decision**: `score += 1` when `reel.format` is in `profile.preferredFormats` (`other` never
  matches). Tag match stays 2 per tag; not-recent +1; last-watched −2; pinned first and
  `limitFor(context)` unchanged.
- **Rationale**: FR-005 — reason stays primary (a tag match outweighs a format match), format breaks
  ties; integer points keep the rule explainable in the report.
- **Check against SC-002**: SC-002 is stated for ties on motivation reasons, which is exactly
  where the +1 decides (equal tag points, equal recency → format wins; equal everything → catalogue
  order). Recency can still override it (a reel watched in the last 24 h loses 1), which SC-002
  covers by "eligible" being computed per opening.

## R4. Backward compatibility

- **Decision**: `UserProfile.preferredFormats` default `const []`; `fromMap` reads
  `map['preferredFormats'] as List? ?? []`, dropping unknown names. `Reel.format` default
  `VideoFormat.other`; `VideoFormat.fromName` maps unknown or missing values to `other`.
- **Rationale**: Constitution III; `MotivationType.values.byName` throws on unknown values, so the
  new enum must not copy that pattern.

## R5. New reels and licensing

- **Decision**: the team sources 4–8 short videos (15–60 s) so that each of `interview`, `edit`,
  `studyWithMe`, `story` has ≥1 (target 2) reel with context `start`, spread over motivation tags.
  Each gets a `creditUrl` and `source`. ADR-0007 is updated (list of new files, sources, same
  accepted-risk status, revisit before public release) **before** the files are committed.
  Existing r1–r6 are tagged by the team after watching them.
- **Rationale**: clarification Q1 = add reels. Bundling keeps Constitution II (no network).
- **Risk**: content is the critical path; code tasks can merge with existing reels tagged first,
  and the catalogue test (SC-006) is the gate that blocks marking the feature Implemented.

## R6. Shared components and dependents (grep, 2026-11-23)

| Symbol | Dependents |
|---|---|
| `motivationQuestions`, `topMotivationTypes` | `onboarding_screen.dart`, `quiz_screen.dart`, `quiz_question_view.dart`, `motivation_quiz_test.dart` |
| `QuizQuestionView` | `onboarding_screen.dart`, `quiz_screen.dart` |
| `UserProfile` | `app_providers.dart`, `settings_screen.dart`, `onboarding_screen.dart`, `profile_repository.dart`, `reel_recommender.dart`, ~12 test files (constructor only; new field has a default) |
| `ReelRecommender.score` / `recommend` | `motivation_screen.dart`, `motivation_dose.dart` (limitFor only), `reel_recommender_test.dart` |
| `FocusStats.from` | `app_providers.dart` (`focusStatsProvider`), `stats_test.dart` |

Run `graphify explain` and `grep` again for each before editing (AGENTS.md).

## R7. Statistics per format

- **Decision**: `focusStatsProvider` passes `reelFormats: {reelId: format}` from the loaded
  catalogue; `FocusStats` adds `formatStats: Map<VideoFormat, ({int shown, int started})>` from
  `reel_watched` events (unknown reel ids → `other`). The Reels card lists formats with ≥1 record.
- **Rationale**: FR-008, US3; old events are attributed by the reel's current format (spec US3-2).
