# Feature Specification: Schedule a Habit Like a Calendar Event

**Feature Branch**: `feature/016-online-accounts` (2026-11-28)

**Created**: 2026-11-28

**Status**: Implemented (2026-11-28)

**Input**: Project lead: "ở tính năng habit tracker phải có cả set thời gian (giờ phút) thì mới biết
khi nào nhắc… khi thêm vào một thói quen, thì phải xếp lịch cho thói quen đó (vào lúc mấy giờ, lặp
lại trong tuần như thế nào, kiểu như xếp lịch trong google calendar)".

**Scenario served**: S1 (hard to start) and S3 (keeping it up): a concrete time makes the reminder
(spec 009) and the interruption (spec 023) meaningful; criterion R2.2 (start within 10 minutes of
the planned time) needs a planned time.

## User Scenarios & Testing *(mandatory)*

### User Story 1 - I schedule my habit with a time and a repetition (Priority: P1)

1. **Given** "Tạo thói quen", **Then** right after the name a **Lịch** card shows a live summary
   like an event ("T2, T4, T6 · 20:00 – 20:25"), then: Lặp lại (hằng ngày / hằng tuần theo thứ hoặc
   số ngày / hằng tháng) or, for "Việc một lần", the day; **Bắt đầu lúc** (hour and minute, always
   visible); **Kéo dài (tối thiểu)** (minutes; the end time in the summary follows); Kết thúc vào;
   **Nhắc khi tới giờ** (on by default for new habits) with "Chặn app gây xao nhãng khi tới giờ".
2. **Given** the habit is saved, **Then** the habit cards, the habit detail and "Thói quen của tôi"
   show the repetition and the time range; "Việc hôm nay" orders habits by start time.
3. The part of day (Sáng / Chiều / Tối filters on Thói quen) follows the start time: 06–11 sáng,
   12–17 chiều, otherwise tối. The separate "Làm vào" choice is gone.
4. **Given** onboarding's first habit, **Then** it also asks "Học lúc" (default 07:00) and is
   reminded at that time; repetition is daily and can be edited later.

### Edge Cases

- Habits saved before this version have no start time (`hasStartTime` false): cards still show
  their part of day; opening and saving them in the form gives them a start time.
- An end time past midnight wraps (23:50 + 25 phút → 00:15).

## Requirements *(mandatory)*

- **FR-001**: `Habit.hasStartTime` (bool, missing → false); the start time is `reminderTime`.
- **FR-002**: Every habit saved from the form has a start time; `timeOfDay` is derived from it.
- **FR-003**: `HabitSchedule.describe` shows "repetition · HH:mm – HH:mm" when there is a start time;
  pure helpers `timeRange`, `endTime`, `timeOfDayFor` with unit tests.
- **FR-004**: The reminder (spec 009) and the interruption (spec 023) fire at the start time.
- **FR-005**: No new package, permission or box; the habit record syncs as a whole (ADR-0013).

## Success Criteria *(mandatory)*

- **SC-001**: A new habit can be scheduled (name, days, time, length) in under 30 seconds.
- **SC-002**: The summary always matches what will be saved (widget test).
