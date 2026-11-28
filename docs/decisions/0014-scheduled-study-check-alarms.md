# ADR-0014: Reminder-time check with inexact alarms, no new permission

- Status: Accepted (project lead chose "khi đang mở app bị chặn", chat 2026-11-28)
- Date: 2026-11-28
- Related: spec 023, spec 009 (ADR-0006 reminder notifications), Reset break (FocusGuardService)

## Context

At a habit's reminder time the student may already be in TikTok. Spec 009 only notifies. The lead
wants Gret to cover the distracting app at that moment and ask whether they really want to go on.

## Decision

- Flutter computes the times (spec 009 plan, filtered by `Habit.reminderInterrupt`) and hands them
  to Kotlin. Kotlin sets `AlarmManager.setAndAllowWhileIdle` alarms (inexact; Android may delay them
  a few minutes, inside R2.2's 10-minute window). No `SCHEDULE_EXACT_ALARM`.
- At an alarm, a `BroadcastReceiver` reads the foreground app from UsageStats (Usage access, already
  granted for Reset break) and starts the intervention screen in its scheduled mode; starting an
  activity from the background relies on "display over other apps", also already granted.
- No foreground service: the check is one moment, not a watch.
- Not rescheduled at boot by Kotlin; the next app start rebuilds them.

## Consequences

- No new Android permission; works only when Reset-break permissions are granted.
- A student who opens TikTok a few minutes after the time is not covered (only the moment, plus
  snoozes). Can be widened later with a short watch window.
