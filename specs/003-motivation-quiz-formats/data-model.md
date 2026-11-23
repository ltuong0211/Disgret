# Data Model: Richer Motivation Quiz with Video-Format Preference

## VideoFormat (new enum)

| Value | Stored name | Vietnamese label |
|---|---|---|
| interview | `interview` | Phỏng vấn, chia sẻ của người nổi tiếng |
| edit | `edit` | Video edit truyền động lực |
| studyWithMe | `studyWithMe` | Study with me, một ngày của học sinh |
| story | `story` | Câu chuyện ngắn, hoạt hình |
| other | `other` | Khác (never offered in the quiz, never matches) |

`VideoFormat.fromName(String?)`: unknown or null → `other`.

## UserProfile (Hive `profile` box) — changed

| Field | Type | Default | Rule |
|---|---|---|---|
| motivationTypes | List<MotivationType> | — | unchanged: top 2 of 6 answers |
| preferredFormats | List<VideoFormat> | `[]` | NEW. 0–2 entries, never `other`; unknown stored names dropped on read |
| preferredReelLength | int | 30 | unchanged |
| demoMode | bool | false | unchanged |

Profiles written by 001/002 have no `preferredFormats` key → empty list = no preference.

## Reel (`assets/reels/reels.json`) — changed

| Field | Type | Default | Rule |
|---|---|---|---|
| format | VideoFormat | `other` | NEW, optional in JSON |
| (others) | | | unchanged: id, assetPath, title, tags, lengthSec, context, pinFirst, source, creditUrl |

Catalogue invariant (SC-006): for each of interview, edit, studyWithMe, story there is ≥1 reel
with `start` in `context`.

## Quiz (pure, `lib/data/motivation_quiz.dart`)

- `motivationQuestions`: 6 × `QuizQuestion` (5 answers, each MotivationType once).
- `formatQuestions`: Q7 direct (4 formats + "Không chắc", multi ≤2, "Không chắc" exclusive), Q8
  scenario (4 formats + "Gì cũng được", single).
- `topMotivationTypes(answers)`: unchanged.
- `preferredFormatsFrom({Set<VideoFormat> direct, VideoFormat? scenario})` → `List<VideoFormat>`
  (0–2), rules in research R2.

## Score (pure, `ReelRecommender.score`)

`2 × matching tags + 1 (not watched in 24 h) − 2 (last watched) + 1 (format ∈ preferredFormats)`.
Pinned-first and `limitFor(context)` unchanged.

## FocusStats — changed

| Field | Type | Rule |
|---|---|---|
| formatStats | Map<VideoFormat, ({int shown, int started})> | from `reel_watched`; format looked up by reelId in the current catalogue; unknown id → other |

## Events

No new event type. `reel_watched` unchanged.
