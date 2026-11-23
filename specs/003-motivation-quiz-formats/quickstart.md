# Quickstart Validation: Feature 003

## Prerequisites

Feature 002 merged; new reel files added and ADR-0007 updated; Flutter 3.47.x. Web is enough for
scenarios 1–4 (no blurred video background); emulator for real video playback.

## Automated

```bash
dart format --set-exit-if-changed lib test
flutter analyze
flutter test
```

Expected: all pass, including the updated `motivation_quiz_test.dart`, `reel_recommender_test.dart`
(format bonus), `data_test.dart` (old profile without formats, unknown format, catalogue per
format) and `stats_test.dart` (per-format counts).

## Manual scenarios

1. **Onboarding timing (SC-001)**: fresh install → intro → Câu 1/8 … 8/8 → goal; time it (≤75 s).
2. **Format drives the first reel (US1, SC-002)**: pick "Phỏng vấn…" in Câu 7 and an interview
   example in Câu 8 → Hôm nay → Bắt đầu → reel 1/3 is an interview reel.
3. **No preference**: choose "Không chắc" and "Gì cũng được" → reels still shown, order as in 002.
4. **Profile and retake (US2)**: Cài đặt shows reasons and formats → Làm lại quiz → leave at Câu 4
   → unchanged → retake fully with other answers → summary changes; next Bắt đầu reflects it.
5. **Old profile**: install `master` build, finish onboarding, upgrade → app starts; Cài đặt says
   "Chưa chọn – làm lại quiz để thêm".
6. **Per-format statistics (US3)**: start from reels of two formats → Tiến độ → Phiên học shows one
   row per format.
