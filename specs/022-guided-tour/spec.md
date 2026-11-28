# Feature Specification: Guided Tour on First Launch

**Feature Branch**: `feature/016-online-accounts` (built together with the team merge, 2026-11-28)

**Created**: 2026-11-28

**Status**: Implemented (2026-11-28)

**Input**: Project lead: "khi users vào app lần đầu thì sẽ được hướng dẫn cách app hoạt động (có thể
sử dụng các effects làm mờ xung quanh, hiển thị rõ tính năng đang chỉ, kèm hướng dẫn bằng chữ dễ
hiểu sinh động)".

**Scenario served**: S1 (hard to start) — a new student learns where "Giữ để bắt đầu" is and what
happens next, so the first session starts sooner. Criterion: R2.2 (start soon after the plan); the
tour removes the "where do I start?" moment.

## Clarifications

### Session 2026-11-28

- Q: When does the tour appear? → A: It replaces the story pages of the introduction: onboarding
  keeps only the questions it needs (name, reel length, quiz, apps, first goal), then the tour runs
  over the real Hôm nay.

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Gret shows me around Hôm nay (Priority: P1)

**Acceptance Scenarios**:

1. **Given** a student who just finished onboarding, **When** Hôm nay opens, **Then** the screen
   around one feature is dimmed and blurred, the feature stays sharp inside a glowing rounded
   spotlight, and a card with Gret explains it in one or two friendly sentences, with "n/8".
2. **Given** a step, **When** the student taps "Tiếp nhé" or anywhere outside the card, **Then**
   the spotlight glides to the next feature (instantly with "remove animations" on); nothing under
   the dim layer can be pressed.
3. The steps, in order: the sea, độ trong + chuỗi ngày, lối tắt, việc hôm nay, "Giữ để bắt đầu"
   (also says Reset break will call the student back), tab Thói quen (habits and reminder times),
   tab Tiến độ, Cài đặt.
4. **Given** step 2 or later, **When** "Lùi lại" is tapped, **Then** the previous step shows.
5. **Given** any step, **When** "Bỏ qua", the system Back button or "Bắt đầu thôi!" on the last
   step is used, **Then** the tour ends and never starts again by itself.
6. **Given** a feature that is not on screen (e.g. no habit due today), **Then** its step is
   skipped.

### User Story 2 - I can watch it again (Priority: P2)

1. **Given** Cài đặt → "Xem lại hướng dẫn", **Then** Hôm nay opens and the tour starts from step 1.

### Edge Cases

- Students who finished onboarding before this version are not interrupted (no pending tour).
- The tour state is phone-only (`tour_pending` in the profile box, not on the ADR-0013 allow-list);
  signing out clears it with the other local data.
- Small phones (360×640): the card sits above or below the spotlight and scrolls if needed.

## Requirements *(mandatory)*

- **FR-001**: Finishing onboarding MUST schedule the tour; Hôm nay MUST start a scheduled tour once.
- **FR-002**: The story pages MUST be removed from onboarding; its first page is Gret asking the
  name, which also carries the "Đã có tài khoản? Đăng nhập" link (spec 016 FR-002).
- **FR-003**: Each step MUST blur and dim everything except a rounded spotlight around its target
  and MUST block taps on the screen beneath.
- **FR-004**: Text MUST come from `AppStrings`; colours and sizes from `app_theme.dart`
  (`AppColors.tourScrim`, `AppColors.tourGlow`, `AppTour`, `AppMotion.tourMove`).
- **FR-005**: "Bỏ qua", Back and the last step MUST end the tour and clear the pending flag.
- **FR-006**: Cài đặt MUST offer "Xem lại hướng dẫn".
- **FR-007**: No new package, permission or synced field.

## Success Criteria *(mandatory)*

- **SC-001**: The whole tour can be read in under 60 seconds (8 steps, ≤ 2 sentences each).
- **SC-002**: After the tour, a new student finds "Giữ để bắt đầu" without help (demo check).
- **SC-003**: No overflow on a 360×640 phone (widget test).

## Assumptions

- The tour covers Hôm nay and the tab bar only; other screens explain themselves.
