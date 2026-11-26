# UI Contract: Motivation Quiz (onboarding and `/quiz` retake)

## Steps

| Step | Content | Input | Next |
|---|---|---|---|
| Câu 1–6/8 | Reason question, 5 answer cards (each reason once) | one tap | next step at once |
| Câu 7/8 | "Dạng video nào truyền cảm hứng cho bạn nhất?" 4 format cards + "Không chắc / gì cũng được" | tap toggles; max 2 formats; "Không chắc" clears the others | "Tiếp" (enabled when ≥1 card or "Không chắc" is selected) |
| Câu 8/8 | Scenario question, 4 format answers + "Gì cũng được" | one tap | onboarding: goal step (first run) or finish; retake: save and close |

- Every step shows "Câu i/8" and a progress bar; system Back goes to the previous step.
- Onboarding keeps its intro step before Câu 1 and the first goal/habit step after Câu 8.
- Retake (`/quiz` from Cài đặt): leaving before Câu 8 saves nothing; finishing replaces
  `motivationTypes` and `preferredFormats` together and shows a SnackBar with the new reasons
  and formats.

## Cài đặt profile summary

| Element | Content |
|---|---|
| "Động lực của bạn" | chips of the 2 reasons (unchanged) |
| "Dạng video bạn thích" | chips of 0–2 formats; when empty: "Chưa chọn – làm lại quiz để thêm" |
| "Làm lại quiz động lực" | unchanged entry |

## Tiến độ → Phiên học, Reels card

Adds one row per format with ≥1 record: "<format label>: <shown> reel · <started share>%".
No social or engagement count.
