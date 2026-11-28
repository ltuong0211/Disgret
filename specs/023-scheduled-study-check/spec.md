# Feature Specification: Reminder Time Covers a Distracting App

**Feature Branch**: `feature/016-online-accounts` (built together with the team merge, 2026-11-28)

**Created**: 2026-11-28

**Status**: Implemented (2026-11-28); emulator checklist pending

**Input**: Project lead: "tính năng habit tracker tôi muốn có một scenario nhất định, người dùng đặt
lịch hẹn thì tới giờ sẽ gửi thông báo nhắc, hoặc tới giờ sẽ chặn màn hình nhắc nhở (như là lúc nhắc
nhở có chắc chắn muốn vào app không)". Builds on spec 009 (reminder notifications) and the design
of the earlier draft spec 004 (scheduled study start, branch `feature/004-scheduled-study-start`).

**Scenario served**: S1 (hard to start) — at the planned time the student is often already
scrolling; criterion R2.2 (start within 10 minutes of the planned time).

## Clarifications

### Session 2026-11-28

- Q: When does the app cover the screen instead of only notifying? → A: Only when a blocked app
  (TikTok, YouTube…) is on screen at the reminder time; otherwise the spec 009 notification alone.
  On/off per habit.

## User Scenarios & Testing *(mandatory)*

### User Story 1 - At my study time, Gret stops me at the door of TikTok (Priority: P1)

**Acceptance Scenarios**:

1. **Given** habit "Ôn Toán, 25 phút, nhắc 20:00" with "Chặn app gây xao nhãng khi tới giờ" on,
   **When** at 20:00 (a few minutes late is fine) TikTok is on screen and no session runs,
   **Then** the Gret screen covers TikTok: "Tới giờ Ôn Toán rồi! Bạn có chắc muốn vào TikTok
   không?", "Chỉ 25 phút thôi, mình bắt đầu nhé? 🐟", Gret breathing for 5 seconds.
2. After 5 seconds: "Bắt đầu học ngay" opens DisGret on the motivation step for that habit and
   its minutes; "Để 10 phút nữa" closes it and checks again 10 minutes later (at most 2 times per
   habit and day); "Vẫn vào TikTok" closes it. Back = "Bắt đầu học ngay".
3. **Given** no blocked app on screen, the screen off or locked, a session running, the habit done
   or not due today, **Then** nothing covers the screen (the notification of spec 009 still comes
   when due).
4. **Given** Usage access or "display over other apps" is not granted, **Then** nothing covers the
   screen and nothing breaks.

### User Story 2 - I choose which habits may interrupt me (Priority: P2)

1. In the habit form, under "Nhắc nhở", a switch "Chặn app gây xao nhãng khi tới giờ"; on by
   default for new habits, off for habits saved before this version. Android only.

### Edge Cases

- Reboot: the checks are rebuilt the next time DisGret opens (reminder notifications survive via
  the plugin's boot receiver; checks may be missed until then). Accepted for course scale.
- Changing the blocked-app list re-sends the checks.
- No Reset-break events are recorded for these screens (statistics stay about sessions).

## Requirements *(mandatory)*

- **FR-001**: `Habit.reminderInterrupt` (bool, default false when missing).
- **FR-002**: A pure `StudyCheckPlan.from(reminders, habits)` turns the spec 009 reminder plan into
  checks for habits with the switch on.
- **FR-003**: The app sends the checks and the blocked list to Android at start and whenever the
  reminder plan or the blocked list changes (`scheduleStudyChecks`).
- **FR-004**: Android uses inexact alarms (no exact-alarm permission); at each, it covers a blocked
  app on screen with the scheduled mode of the intervention screen.
- **FR-005**: "Bắt đầu học ngay" sends `start_scheduled` with the habit id; Flutter plans that habit
  and opens the motivation step (single study entry, ADR-0002).
- **FR-006**: "Để 10 phút nữa" at most twice per habit and day.
- **FR-007**: No new Android permission (ADR-0014).

## Success Criteria *(mandatory)*

- **SC-001**: In the emulator checklist, at a reminder time with YouTube open, the Gret screen
  appears within the alarm window and "Bắt đầu học ngay" opens the motivation step for that habit.
- **SC-002**: With no blocked app open, nothing covers the screen.
