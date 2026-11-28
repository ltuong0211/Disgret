# Implementation Plan: Guided Tour on First Launch

**Branch**: `feature/016-online-accounts` | **Date**: 2026-11-28 | **Spec**: [spec.md](spec.md)

## Summary

A pure step list (`lib/data/guided_tour.dart`) names 8 targets. Hôm nay and the tab bar wrap those
widgets with `TourKeys.mark` (one `GlobalKey` per target). `MainShell` stacks
`GuidedTourOverlay` over the whole shell: a `BackdropFilter` blur + scrim clipped with an inverted
rounded rectangle (`Path.combine(difference)`), a glowing border, and a card with Gret. The overlay
scrolls the target into view (`Scrollable.ensureVisible`), measures it after the frame and animates
the spotlight with a `RectTween`. `GuidedTourNotifier` holds the current step; the
`tour_pending` profile key (phone-only) says whether a tour waits.

## Technical Context

Dart ^3.13.7 / Flutter 3.47+, Riverpod, Hive. No new dependency (a coach-mark package was rejected:
its text and styling would bypass `AppStrings` and the theme). Tests: unit tests for the step rules,
widget tests for the full walk, back, skip, small phone, replay and onboarding scheduling.

## Constitution Check

| Principle | Check | Status |
|---|---|---|
| I | S1; onboarding keeps one primary action; the tour has one main button per step | Pass |
| II | Nothing leaves the phone; `tour_pending` not on the allow-list | Pass |
| III | New key with default false; no box added; old profiles read as "no tour waiting" | Pass |
| IV | Step rules pure; screens read the notifier; theme tokens only | Pass |
| V | 8 tests; full suite green | Pass |
| VI | Spec, plan, tasks; README demo + map updated | Pass |
| VII | Shared files touched: `main_shell.dart`, `today_screen.dart`, `onboarding_screen.dart`, `settings_screen.dart`, `profile_repository.dart`, `app_theme.dart`, `app_strings.dart`, `test_helpers.dart` | Pass |

## Files

`lib/data/guided_tour.dart`, `lib/providers/tour_providers.dart`, `lib/widgets/tour/tour_keys.dart`,
`lib/widgets/tour/guided_tour_overlay.dart`, `test/guided_tour_test.dart`; edits listed above.
