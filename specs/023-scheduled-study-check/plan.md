# Implementation Plan: Reminder Time Covers a Distracting App

**Branch**: `feature/016-online-accounts` | **Date**: 2026-11-28 | **Spec**: [spec.md](spec.md)

## Summary

Dart: `Habit.reminderInterrupt`; `StudyCheckPlan` (pure) from the existing `ReminderPlan`;
`app.dart` sends checks + blocked list through `NativeBridge.scheduleStudyChecks`, handles the new
action `start_scheduled` (plan the habit, open the motivation step). Habit form switch.
Kotlin: `StudyChecks` schedules `AlarmManager.setAndAllowWhileIdle` alarms (inexact) to
`StudyCheckReceiver`; at an alarm it reads the foreground app from UsageStats and, if blocked,
opens `InterventionActivity.openScheduled` (5-second wait, then three choices). Snoozes are kept in
SharedPreferences. ADR-0014 records the choice of inexact alarms and no new permission.

## Constitution Check

| Principle | Check | Status |
|---|---|---|
| I | S1, R2.2; the only way into a session is still the motivation step | Pass |
| II | Nothing leaves the phone; no new permission (Usage access and overlay already exist) | Pass |
| III | New field with default false; old habits read unchanged | Pass |
| IV | Rule pure; native call through `native_bridge.dart`, no-op on web | Pass |
| V | Unit + widget tests; **native checklist on the emulator still to run** | Pending |
| VI | Spec, plan, tasks, ADR-0014, native-bridge.md | Pass |
| VII | Shared: `habit.dart`, `native_bridge.dart`, `app.dart`, `habit_form_screen.dart`, Kotlin `InterventionActivity`, `MainActivity`, `NativeActions`, `NativeChannel`, `FocusGuardService` (read-only flag) | Pass |
