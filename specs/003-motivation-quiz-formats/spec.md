# Feature Specification: Richer Motivation Quiz with Video-Format Preference

**Feature Branch**: `feature/003-motivation-quiz-formats`

**Created**: 2026-11-23

**Status**: Draft

**Input**: User description: "Thiết kế quiz nhiều câu hỏi hơn để xác định được dạng động lực target
vào người dùng, có thể set up bộ câu hỏi như kiểu: 'dạng video nào sẽ truyền cảm hứng cho bạn nhất'
(video phỏng vấn người nổi tiếng, video edit truyền động lực, ...)."

**Depends on**: feature 002 (bounded motivation dose, recommender without likes).

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
- The user picks every format in the multi-select question: equivalent to no preference.
- Onboarding is interrupted (app killed) during the format questions: on next start onboarding
  resumes as it does today; no half-written profile is saved.
- After a distraction (playlist of 1, pinned reel first), the pinned reel still wins over format
  preference.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: The motivation quiz MUST contain at least 6 questions that score the five
  motivation reasons (today: 4), every question offering every reason once, so the top-2 result
  is more stable; the existing top-2 rule and tie-break by earliest answer stay.
- **FR-002**: The quiz MUST add a video-format part: one question "Dạng video nào truyền cảm hứng
  cho bạn nhất?" (choose up to 2) and one scenario question that confirms the choice (single
  choice). Formats offered: interview/talk by a well-known person; motivational edit with music
  and quotes; study-with-me / day-in-the-life of a student; short story or animation; plus
  "Không chắc / gì cũng được".
- **FR-003**: The profile MUST store up to 2 preferred video formats, derived from the format
  answers (direct choice first, scenario answer as tie-break). A profile without formats MUST
  remain valid and mean "no format preference".
- **FR-004**: Every reel in the bundled catalogue MUST be classifiable by format; reels without a
  format, or with an unknown one, MUST be treated as "other".
- **FR-005**: Reel ranking MUST add a format-match bonus that is smaller than one matching
  motivation tag, so reason stays the primary signal and format breaks ties; pinned reels, the
  recently-watched penalty and the playlist length per context (spec 002 FR-002) MUST be
  unchanged.
- **FR-006**: Onboarding including the longer quiz MUST still be completable in about one minute
  (one tap per question, no typing); every quiz step MUST show progress ("Câu 3/8").
- **FR-007**: Cài đặt MUST show the current motivation profile (top reasons and preferred formats)
  and keep the existing "Làm lại quiz động lực" entry; finishing a retake replaces the profile,
  leaving it early changes nothing.
- **FR-008**: The statistics view MUST show, per format with data, the number of reels shown and
  the share followed by a session start; it MUST NOT add any social or engagement count.
- **FR-009**: All quiz text MUST be Vietnamese and come from the shared UI strings file
  (ADR-0005); no answer MUST collect names, school, age or anything identifying the student.
- **FR-010**: The catalogue MUST offer at least one eligible reel for each format the quiz
  proposes before a session, so that every answer can actually change the playlist.
  [NEEDS CLARIFICATION: Does this feature include adding new reels for formats the 6 bundled
  videos do not cover (with the licensing risk of ADR-0007), or should the quiz only offer the
  formats the current catalogue already has?]

### Key Entities

- **Motivation profile**: existing entity; gains up to 2 preferred video formats (empty by
  default). Top-2 motivation reasons and preferred reel length unchanged.
- **Video format**: a closed list (interview/talk, motivational edit, study-with-me /
  day-in-the-life, story/animation, other) with a Vietnamese label.
- **Reel**: existing catalogue entry; gains one format (default "other").
- **Quiz question**: existing; a question now belongs either to the reason part or to the format
  part.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: A first-time user finishes onboarding, quiz included, in 75 seconds or less in a
  hallway test with 5 students (median).
- **SC-002**: For a profile with a preferred format, the first reel of the before-session playlist
  matches that format in 100% of openings where at least one eligible reel of that format exists
  and no pinned reel applies.
- **SC-003**: 100% of profiles saved by the previous version load without error and keep their
  motivation reasons.
- **SC-004**: After one week of use, the share of reels followed by a session start can be read
  per format from on-device data alone.
- **SC-005**: In the hallway test, at least 4 of 5 students say the profile summary in Cài đặt
  "describes me" (yes/no question).

## Assumptions

- The quiz stays rule-based and on-device (no AI, no network), as in 1.1 and 1.3 today.
- "About one minute" is the current onboarding target; 8 one-tap steps fit it.
- The format bonus is half of a motivation-tag match (exact value set in the plan).
- Tone of voice (gentle vs tough) and reel length preference are out of scope; reel length stays
  as asked today.
- The team, not the user, assigns the format of each bundled reel.
- Retaking the quiz does not reset watch history; the recently-watched penalty keeps working.
