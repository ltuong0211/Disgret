# Data Model: Motivation Quiz, Reel Labels and Matching

Revised 2026-11-27 to follow [quiz-and-tags-design.md](quiz-and-tags-design.md) (approved).

## MotivationType (enum) — changed

Adds `growth` ("Hiểu biết") and `contribution` ("Giúp ích người khác"). Existing names unchanged,
so stored profiles and reels still parse.

## Reel labels (enums, `lib/data/models/reel_labels.dart`) — new

Every enum has a Vietnamese `label` and `fromName(String?)`: unknown or null → the default.

| Enum | Values (stored name) | Default |
|---|---|---|
| VideoFormat | interview, speech, edit, quote, journey, studyWithMe, dayInLife, story, tips, other | other |
| VideoTone | hype, toughLove, calm, emotional, funny, practical, unknown | unknown |
| Messenger | celebrity, achiever, athlete, expert, peer, ordinary, character, none | none |
| Origin | vietnamese, international | vietnamese |
| ReelTheme | startSmall, digitalDetox, fearCourage, futureSelf, timeMatters, ownPath, consistency, discipline, comeback, selfCompassion, examPressure, gratitude | (unknown names dropped) |
| StudyGoal | exam, language, grades, skill | (unknown names dropped) |
| ReelLanguage | vi, enSub, en | vi |
| ReelFlag | loud, sad, wealthDisplay, fastCuts | (unknown names dropped) |

## Reel (`assets/reels/reels.json`) — changed

| Field | Type | Default | Rule |
|---|---|---|---|
| tags | List<MotivationType> | `[]` | JSON key `motivation`; falls back to `tags`; unknown names dropped |
| format | VideoFormat | other | |
| tone | VideoTone | unknown | `unknown` never matches |
| messenger | Messenger | none | `none` never matches |
| origin | Origin | vietnamese | not scored yet (catalogue info) |
| themes | List<ReelTheme> | `[]` | 1–3 in the team's labels |
| goals | List<StudyGoal> | `[]` | empty = fits any goal, no bonus |
| language | ReelLanguage | vi | |
| flags | List<ReelFlag> | `[]` | |
| (others) | | | unchanged: id, assetPath, title, lengthSec, context, pinFirst, source, creditUrl |

## Quiz (pure, `lib/data/motivation_quiz.dart`)

- `QuizQuestion`: `id` (q1–q11, stable), `text`, `part` (core / extra), `maxChoices` (1 = single,
  tap advances), `answers`.
- `QuizAnswer`: `id` (stable, e.g. `q5.journey`), `text`, optional `hint`, and the labels it
  carries: `type` (MotivationType?), `formats`, `tone`, `messengers`, `themes`, `goal`, `flags`,
  `languages`.
- `quizQuestions`: all 11 in design order; `corePart` / `extraPart` filter by part.
  `motivationQuestions` (q1–q4) is kept for the reason questions.
- `topMotivationTypes(answers)`: unchanged rule (top 2, earliest wins ties).

## QuizAnswers / ReelPreferences (`lib/data/models/reel_preferences.dart`) — new

`QuizAnswers` = `Map<String questionId, List<String answerId>>`. An empty list or a missing key
means "Không chắc". Unknown question or answer ids are ignored on read.

`ReelPreferences.fromAnswers(QuizAnswers, {List<MotivationType> legacyTypes})` (pure, design §5.1):

| Field | Type | Rule |
|---|---|---|
| motivationTypes | List<MotivationType> | `topMotivationTypes` over q1..q4 answers in question order; if none of q1..q4 is answered, `legacyTypes` |
| formatScores | Map<VideoFormat, int> | q5 answers +2 per format, q8 +1; `formats` lists them highest first (ties: first seen) |
| tone | VideoTone | q7; else q8's tone; else unknown |
| messengers | List<Messenger> (0–2) | q6 |
| themes | Set<ReelTheme> | union of q9 answers' themes |
| goal | StudyGoal? | q10 |
| avoidFlags | Set<ReelFlag> | q11 |
| avoidLanguages | Set<ReelLanguage> | q11 |

## UserProfile (Hive `profile` box) — changed

| Field | Type | Default | Rule |
|---|---|---|---|
| motivationTypes | List<MotivationType> | — | stored as today; rewritten from answers after any quiz |
| quizAnswers | QuizAnswers | `{}` | NEW, key `quizAnswers`; profiles from earlier versions have none |
| preferences | ReelPreferences | — | NEW getter, derived from `quizAnswers` + `motivationTypes` (not stored) |

## Score (pure, `ReelRecommender`)

Hard filter: drop a reel whose flags meet `avoidFlags` or whose language is in `avoidLanguages`.
Score (design §5.3): +3 per reason match (max 2), +2 per theme match (max 2), +2/+1 favourite/liked
format, +2 tone, +1 messenger, +1 goal, +2 context bonus (`distracted` and theme `digitalDetox`
or `startSmall`), +1 not watched in 24 h, −3 last watched. Variety (§5.4) when filling slot 2+.
Pinned-first, `limitFor(context)` and catalogue order for ties unchanged.

## Events

No new event type. `reel_watched` unchanged.
