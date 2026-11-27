# Feature Specification: Richer Motivation Quiz with Video-Format Preference

**Feature Branch**: `feature/003-motivation-quiz-formats`

**Renumbered**: written as spec 003; renumbered to 015 on 2026-11-27 when merged with the Gret ocean
specs 003–014. Task IDs inside stay T001…; cite them as `015-Txxx`.

**Created**: 2026-11-23

**Status**: Draft

**Input**: User description: "Thiết kế quiz nhiều câu hỏi hơn để xác định được dạng động lực target
vào người dùng, có thể set up bộ câu hỏi như kiểu: 'dạng video nào sẽ truyền cảm hứng cho bạn nhất'
(video phỏng vấn người nổi tiếng, video edit truyền động lực, ...)."

**Depends on**: feature 002 (bounded motivation dose, recommender without likes).

## Clarifications

### Session 2026-11-23

- Q: Add new reels for formats the 6 bundled videos do not cover, or offer only existing formats?
  → A: Add new reels so every offered format has eligible reels (FR-010, FR-011).

### Session 2026-11-27

- The project lead approved [quiz-and-tags-design.md](quiz-and-tags-design.md) and its defaults
  for the open questions: add the reasons `growth` and `contribution`; core quiz of 7 questions
  (about 75 s) plus an optional extra part of 4; the scenario question shows 5 videos; the team
  collects and labels the videos. FR-001 to FR-006, FR-012 to FR-014, SC-001, SC-002 and the Key
  Entities below follow that design; where this spec and the design disagree, the design wins.

## User Scenarios & Testing *(mandatory)*

### User Story 1 - The first reel already fits me (Priority: P1)

A new student opens DisGret for the first time. Besides *why* they want to study (money, family,
career, proving themselves, freedom), the quiz now asks *what kind of video* inspires them: an
interview or talk by a well-known person, a motivational edit with music and quotes, a
study-with-me or day-in-the-life of a student, or a short story or animation. When they later
press "Bắt đầu", the reels they see match both their reasons and their preferred kind of video.

**Why this priority**: Scenario S1 (hard to start). Hypothesis H1 says the *right* reel helps the
user start faster; today the profile only knows the reason, not the form that actually moves
the user, so the first reel is often the wrong kind.

**Independent Test**: Complete onboarding choosing "Video phỏng vấn người nổi tiếng" as the
preferred kind, press "Bắt đầu" on Hôm nay, and confirm the first reel is an interview-type reel
whenever one is eligible for the context.

**Acceptance Scenarios**:

1. **Given** a first-time user, **When** they go through onboarding, **Then** the quiz asks the
   motivation questions and then the video-format questions, one question per step with a visible
   progress indicator, and each answer moves to the next step with a single tap.
2. **Given** the user picked one or two preferred video formats, **When** the motivation step
   builds its playlist, **Then** among eligible reels those that match a preferred format rank
   above those that do not, other rules (pinned first, motivation-tag matches, recently-watched
   penalty, playlist length of spec 002) staying in force.
3. **Given** no eligible reel matches the preferred formats, **When** the playlist is built,
   **Then** reels are still shown, ranked by the existing rules, so the step is never empty
   because of the format preference.
4. **Given** the user does not want to answer a format question, **When** they choose "Không chắc
   / gì cũng được", **Then** onboarding continues and format has no effect on ranking.

---

### User Story 2 - I can see and change my motivation profile (Priority: P2)

The student can see, in Cài đặt, what DisGret believes motivates them (top reasons and preferred
video formats) and can retake the quiz at any time.

**Why this priority**: Scenario S3 (keeping it up). Preferences change; a profile the user cannot
see or fix makes recommendations feel arbitrary.

**Independent Test**: Open Cài đặt, read the profile summary, retake the quiz choosing different
answers, and confirm the summary and the next playlist change accordingly.

**Acceptance Scenarios**:

1. **Given** a completed profile, **When** the user opens Cài đặt, **Then** they see their top
   motivation reasons and their preferred video formats in Vietnamese.
2. **Given** the user retakes the quiz from Cài đặt, **When** they finish, **Then** the new
   reasons and formats replace the old ones and are used from the next opening of the motivation
   step; habits, sessions and events are untouched.
3. **Given** the user leaves the retaken quiz before the end, **When** they return to Cài đặt,
   **Then** the previous profile is unchanged.

---

### User Story 3 - The team can see which video formats lead to studying (Priority: P3)

For the experiment, the team needs to know, per video format, how many reels were shown and what
share was followed by a session start.

**Why this priority**: Evidence for H1 by format; invisible to users.

**Independent Test**: Watch and start from reels of two different formats, open Tiến độ →
Phiên học and confirm each format shows its own count and start share.

**Acceptance Scenarios**:

1. **Given** watch records exist, **When** the statistics view is opened, **Then** it shows, per
   video format with at least one record, the number of reels shown and the share followed by a
   session start.
2. **Given** watch records from before this feature, **When** statistics are computed, **Then**
   they are attributed using each reel's current format and still counted in the overall totals.

### Edge Cases

- A profile saved by an earlier version (no formats): it stays valid, format has no effect, and
  Cài đặt invites the user to retake the quiz to add formats.
- A reel in the catalogue has no format tag: it is treated as "other" and never wrongly matched.
- A reel carries an unknown format value (added by a later catalogue edit): treated as "other",
  no crash.
- The user answers "Không chắc" everywhere: the profile has no preference and the playlist is
  ordered as today (reasons, then catalogue order).
- Onboarding is interrupted (app killed) during the format questions: on next start onboarding
  resumes as it does today; no half-written profile is saved.
- After a distraction (playlist of 1, pinned reel first), the pinned reel still wins over format
  preference.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: The quiz MUST score seven motivation reasons (the five of today plus `growth` "Hiểu
  biết, giỏi lên mỗi ngày" and `contribution` "Giúp ích người khác") with four reason questions
  (design §4 Q1–Q4), every question offering every reason once; the top-2 rule and the tie-break
  by earliest answer stay.
- **FR-002**: The quiz MUST also ask, as in design §4: preferred video formats (Q5, up to 2),
  preferred tone (Q7), preferred messengers (Q6, up to 2), a scenario question (Q8), what blocks
  the user from starting (Q9, up to 2), the nearest study goal (Q10) and what the user never wants
  to see (Q11, several). Every question MUST offer "Không chắc", which means no preference.
- **FR-003**: The profile MUST keep the quiz answers and derive from them, by design §5.1: top-2
  reasons, up to 2 formats, one tone, up to 2 messengers, the themes behind the chosen blockers,
  one goal, avoided flags and languages. A profile without these answers MUST stay valid and mean
  "no preference" in every new dimension.
- **FR-004**: Every reel MUST be readable with the label set of design §3 (motivation, format,
  tone, messenger, origin, theme, goal, language, flags); a missing or unknown value MUST fall back
  to the default (format `other`, language `vi`, empty lists) without a crash. The old `tags`
  field MUST still be read as `motivation`.
- **FR-005**: Reel ranking MUST follow design §5.2–5.4: drop reels with an avoided flag or
  language; score with the weights of §5.3 (reason stays the largest single weight); vary formats
  inside a playlist (§5.4). Pinned reels, the playlist length per context (spec 002 FR-002) and the
  catalogue order for ties MUST be unchanged. Learning from behaviour (§5.5) is out of scope here.
- **FR-006**: Onboarding MUST ask only the core part (Q1, Q2, Q5, Q7, Q9, Q10, Q11), one screen
  per question, with progress ("Câu 3/7"); single-choice questions advance on tap, multi-choice
  questions have a "Tiếp" button.
- **FR-007**: Cài đặt MUST show the current motivation profile (top reasons and preferred formats)
  and keep the existing "Làm lại quiz động lực" entry; finishing a retake replaces the profile,
  leaving it early changes nothing.
- **FR-008**: The statistics view MUST show, per format with data, the number of reels shown and
  the share followed by a session start; it MUST NOT add any social or engagement count.
- **FR-009**: All quiz text MUST be Vietnamese and come from the shared UI strings file
  (ADR-0005); no answer MUST collect names, school, age or anything identifying the student.
- **FR-010**: The bundled catalogue MUST be extended with new reels so that each of the four
  formats offered by the quiz has at least one reel eligible before a session (target: two), so
  every answer can actually change the playlist. Each new reel MUST carry the same catalogue data
  as today (title, motivation tags, length, contexts, source credit) plus its format.
- **FR-012**: Cài đặt MUST offer "Giúp app hiểu bạn hơn", which asks only the extra part (Q3, Q4,
  Q6, Q8) and merges the answers into the profile; "Làm lại quiz động lực" asks all 11 questions
  and replaces the stored answers.
- **FR-013**: A profile saved before this feature (only top reasons, no answers) MUST keep its
  reasons until the user answers reason questions again; answering only the extra part MUST count
  the old reasons as earlier answers.
- **FR-014**: The quiz MUST NOT ask for grades as numbers, money at home, health, school, age or
  location (users may be under 18).
- **FR-011**: New videos MUST be short (15–60 seconds), bundled with the app (no streaming,
  Constitution II), and their sources recorded; their licensing risk MUST be recorded by updating
  ADR-0007 before they are added.

### Key Entities

- **Motivation profile**: existing entity; gains the stored quiz answers and the reel preferences
  derived from them (design §5.1). Top-2 reasons and preferred reel length unchanged.
- **Reel labels**: closed lists with Vietnamese names (design §3): 7 reasons, 10 formats, 6 tones,
  8 messengers, 2 origins, 12 themes, 4 goals, 3 languages, 4 flags.
- **Reel**: existing catalogue entry; gains the labels above with defaults.
- **Quiz question**: has a stable id (q1–q11), a part (core or extra), a choice limit and answers
  with stable ids that carry labels.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: A first-time user finishes the core quiz in 75 seconds or less in a
  hallway test with 5 students (median).
- **SC-002**: For the worked example of design §5.6 and every unit-test profile, the playlist equals
  the one computed by hand with the §5 rules; a reel with an avoided flag or language is never
  shown (100%).
- **SC-003**: 100% of profiles saved by the previous version load without error and keep their
  motivation reasons.
- **SC-004**: After one week of use, the share of reels followed by a session start can be read
  per format from on-device data alone.
- **SC-005**: In the hallway test, at least 4 of 5 students say the profile summary in Cài đặt
  "describes me" (yes/no question).
- **SC-006**: Every format offered by the quiz has at least one reel eligible before a session in
  the shipped catalogue (checked automatically).

## Assumptions

- The quiz stays rule-based and on-device (no AI, no network), as in 1.1 and 1.3 today.
- Reel length stays as asked today. The Hôm nay invitation to the extra part (design §4) is a
  follow-up; this feature offers it in Cài đặt.
- The team, not the user, assigns the format of each bundled reel and sources the new videos;
  implementation of FR-010 waits for those files.
- The catalogue grows from 6 to about 10–14 reels; the app size grows by roughly 2 MB per reel,
  which is acceptable for a course project APK.
- Retaking the quiz does not reset watch history; the recently-watched penalty keeps working.
