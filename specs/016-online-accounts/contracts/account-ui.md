# Contract: Account screens, routes and strings

All text lives in `lib/l10n/app_strings.dart`; colours and spacing from `app_theme.dart`.
Decomposition code for the new files: `// 6.3 Tài khoản và đồng bộ` (next to 6.2 data storage;
5.1–5.6 and 6.2 are taken in README's decomposition map). README gains a 6.3 row.

## Routes (`AppRoutes`)

| Route | Screen | Reached from |
|---|---|---|
| `/account` | `AccountScreen` | Cài đặt → "Tài khoản" |
| `/account/sign-in` | `SignInScreen` | `/account` (guest), onboarding first page link |
| `/account/sign-up` | `SignUpScreen` (privacy notice step, then form) | `/account`, sign-in screen link |
| `/account/forgot-password` | `ForgotPasswordScreen` | sign-in screen |

When `AccountsConfig.isAvailable` is false these routes redirect to `/settings` and no entry point
is shown.

## Cài đặt row

- Guest: title "Tài khoản", subtitle "Chưa đăng nhập — dữ liệu chỉ lưu trên máy này".
- Signed in: title = email, subtitle = sync status:
  "Đã đồng bộ lúc HH:mm" | "Đang đồng bộ…" | "Chưa đồng bộ — sẽ tự đồng bộ khi có mạng".

## AccountScreen

- Guest: primary "Đăng nhập", secondary "Tạo tài khoản".
- Signed in: email, status, "Đồng bộ ngay", "Đăng xuất" (disabled during a running focus session:
  "Kết thúc phiên học trước khi đăng xuất"), and at the bottom a destructive "Xoá tài khoản"
  (disabled offline: "Cần có mạng để xoá tài khoản").

## SignUpScreen

1. Privacy notice (one scroll screen): what leaves the phone (email; goals, habits, logs, study
   sessions, quiz results, tên gọi, Góc của Gret, nơi học), where (máy chủ Google Firebase ở
   Singapore), what never leaves (danh sách app chặn, lịch sử xem reel và Reset break), no ads or
   tracking, "Xoá tài khoản" deletes everything online, and "Nếu bạn dưới 16 tuổi, hãy hỏi ý kiến
   bố mẹ trước khi tạo tài khoản". Buttons: "Tôi đã đọc và đồng ý" (primary), "Để sau".
2. Form: Email, Mật khẩu (≥ 8, show/hide), button "Tạo tài khoản". On success → first-login flow
   (upload guest data) → back to `/account` with a snackbar "Đã tạo tài khoản".

## SignInScreen

Email, Mật khẩu, "Đăng nhập", links "Quên mật khẩu?" and "Chưa có tài khoản? Tạo tài khoản".
After success:

- `askMergeOrReplace` → dialog "Máy này đang có dữ liệu" with "Gộp dữ liệu trên máy vào tài khoản"
  (primary) and "Chỉ dùng dữ liệu của tài khoản (xoá dữ liệu khách trên máy)".
- Account has a profile and onboarding was not done here → go to `/today`, skipping onboarding.

## ForgotPasswordScreen

Email field, "Gửi link đặt lại"; always shows "Nếu email này có tài khoản, DisGret đã gửi link
đặt lại mật khẩu".

## Dialogs

- Sign-out with pending changes: title "Chưa lưu hết lên tài khoản", body "Có N thay đổi chưa lưu
  lên tài khoản. Nếu đăng xuất bây giờ, các thay đổi này sẽ mất.", actions "Ở lại" (default),
  "Vẫn đăng xuất".
- Delete account: title "Xoá tài khoản?", body "Tài khoản và mọi dữ liệu lưu online sẽ bị xoá vĩnh
  viễn.", checkbox "Xoá cả dữ liệu trên máy này" (off), password field, actions "Huỷ", "Xoá tài
  khoản".
- Account gone during sync: snackbar/dialog "Tài khoản đã bị xoá. Dữ liệu vẫn còn trên máy này."

## Onboarding

First page gains a secondary text button "Đã có tài khoản? Đăng nhập" (only when accounts are
available). The main action is unchanged (Principle I: one primary action).
