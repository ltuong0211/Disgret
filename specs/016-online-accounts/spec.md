# Feature Specification: Optional Online Accounts

**Feature Branch**: `feature/016-online-accounts` (cut from `feature/003-gret-ocean`)

**Created**: 2026-11-27

**Status**: Draft — blocked on approval of constitution 2.0.0 and ADR-0013 (both Proposed)

**Input**: Project lead: each student signs up, logs in and logs out with their own account. The
lead chose real online accounts over local per-device profiles, knowing it needs a constitution
change, a backend, the INTERNET permission and an under-18 privacy rule.

**Depends on**: constitution 2.0.0 (Principle II "Local-First Privacy with Minimal Accounts"),
ADR-0013 (backend, synced data), spec 015 (quiz/profile fields that sync) landing on
`feature/003-gret-ocean` first.

## Clarifications

### Session 2026-11-27

- Q: Which backend stores accounts and data? → A: Firebase (Authentication + Cloud Firestore,
  Spark free plan, region asia-southeast1), as proposed in ADR-0013.
- Q: Which sign-in methods? → A: Email + password only; Google sign-in is out of scope for 016.
- Q: What data leaves the phone? → A: Study data — goals, habits, habit logs, sessions and the
  study profile choices (quiz answers, display name, Góc của Gret, study place); never the
  blocked-app list, installed apps or events.
- Q: What is the minimum age for an account? → A: No age check. Anyone may create an account; the
  privacy notice tells students under 16 to ask a parent first, and the minimal-data and
  self-deletion rules apply to everyone.

**Scenario served**: S3 (keeping it up over several days) — a student keeps their streaks, habits
and history when they change phone, reinstall the app or share a phone with a sibling. It does not
move an R-code directly; it protects the multi-day evidence that R-codes in S3 rely on.

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Keep using the app without an account (Priority: P1)

A student who never signs in uses DisGret exactly as today. Accounts are an extra, never a gate.

**Why this priority**: the app must stay fully usable offline and without an account (constitution
Principle II); breaking the current flow would break every other feature.

**Independent Test**: fresh install, skip sign-in, complete onboarding, create a habit and run a
focus session with the network off; everything works and nothing asks for an account again.

**Acceptance Scenarios**:

1. **Given** a fresh install, **When** onboarding starts, **Then** its first page offers
   "Đã có tài khoản? Đăng nhập" as a secondary link and the main action continues the story as
   today.
2. **Given** a guest (not signed in), **When** they use Hôm nay, Focus, Reset break, reels, Góc
   của Gret and Thống kê, **Then** every feature behaves exactly as before this feature.
3. **Given** a guest, **When** they open Cài đặt, **Then** a "Tài khoản" row reads "Chưa đăng
   nhập — dữ liệu chỉ lưu trên máy này" and opens the sign-in screen.
4. **Given** a build without backend configuration, **Then** no account entry point is shown at all.

---

### User Story 2 - Sign up and keep my existing data (Priority: P1)

A student who has used the app as a guest creates an account; everything they already have on the
phone (goals, habits, logs, sessions, profile choices) moves into the new account.

**Why this priority**: the core value — "my history is safe and follows me".

**Independent Test**: as a guest with sample data ("Tạo dữ liệu mẫu"), sign up; reinstall the app,
sign in; the same goals, habits, streaks and sessions appear.

**Acceptance Scenarios**:

1. **Given** a guest opens "Tạo tài khoản", **Then** they first see a short privacy notice in
   Vietnamese (what is stored, where, that nothing else is collected, how to delete it, and "Nếu
   bạn dưới 16 tuổi, hãy hỏi ý kiến bố mẹ trước khi tạo tài khoản"); they cannot continue without
   tapping "Tôi đã đọc và đồng ý".
2. **Given** they tap "Để sau" on the notice, **Then** they return to Cài đặt as a guest and
   nothing is stored.
3. **Given** a valid email and a password of at least 8 characters, **When** they sign up, **Then**
   the account is created, the student is signed in and the guest data on the phone becomes the
   account's data and is uploaded.
4. **Given** the email is already registered, **Then** the message "Email này đã có tài khoản.
   Đăng nhập?" is shown with a button to the sign-in screen.
5. **Given** sign-up succeeded, **Then** Cài đặt → "Tài khoản" shows the email and
   "Đã đồng bộ lúc HH:mm".

---

### User Story 3 - Log in on another phone, log out (Priority: P1)

A student signs in on a new or reset phone and gets their data; when finished on a shared phone
they sign out and nothing of theirs remains readable.

**Why this priority**: sign-in and sign-out are the minimum account loop.

**Independent Test**: sign in on emulator B with an account that has data from emulator A; data
appears. Sign out; the app is empty and shows no trace of the account.

**Acceptance Scenarios**:

1. **Given** a fresh install, **When** the student signs in from onboarding's first page, **Then**
   the account's data is downloaded and onboarding is skipped if the account already has a
   profile.
2. **Given** a guest with local data signs in to an account that already has data, **Then** the
   app asks once: "Gộp dữ liệu trên máy vào tài khoản" or "Chỉ dùng dữ liệu của tài khoản (xoá
   dữ liệu khách trên máy)". Merge keeps every record from both sides.
3. **Given** a wrong password, **Then** "Email hoặc mật khẩu không đúng" is shown (no hint which
   one), and after repeated failures the backend's temporary lock message is shown in Vietnamese.
4. **Given** a signed-in student taps "Đăng xuất" with everything synced, **Then** the account's
   local data is removed from the phone and the app returns to the first onboarding page as a new
   guest.
5. **Given** unsynced changes and no network, **When** they tap "Đăng xuất", **Then** the app warns
   "Có N thay đổi chưa lưu lên tài khoản. Nếu đăng xuất bây giờ, các thay đổi này sẽ mất." with
   "Ở lại" (default) and "Vẫn đăng xuất".
6. **Given** a focus session is running, **Then** "Đăng xuất" is disabled with the note "Kết thúc
   phiên học trước khi đăng xuất".

---

### User Story 4 - Two students share one phone (Priority: P2)

Student A signs out, student B signs in on the same phone; B never sees A's data and vice versa.

**Why this priority**: data isolation is a privacy requirement, but most students own their phone.

**Independent Test**: A signs in, creates habit "Ôn Toán", signs out; B signs in; B's Hôm nay,
Thống kê, sea map, Góc của Gret and reminders show nothing from A; A signs back in and sees "Ôn
Toán" again.

**Acceptance Scenarios**:

1. **Given** A signed out, **When** B signs in, **Then** no goal, habit, log, session, profile
   choice, display name or scheduled reminder of A is visible or fires.
2. **Given** B signs in, **Then** the blocked-app list and the device permissions stay as set on
   the phone (they belong to the phone, not the account).
3. **Given** A signs in again later, **Then** A's data is restored from the account.

---

### User Story 5 - Study offline while signed in (Priority: P2)

A signed-in student without network keeps studying; changes upload later.

**Why this priority**: students often study with mobile data off; offline-first is a constitution
rule.

**Independent Test**: signed in, turn the network off, tick a habit and finish a 5-minute session,
turn the network on; within a minute the account shows the new log and session on a second phone.

**Acceptance Scenarios**:

1. **Given** no network, **Then** every study feature works and no error dialog interrupts it;
   Cài đặt → Tài khoản shows "Chưa đồng bộ — sẽ tự đồng bộ khi có mạng".
2. **Given** network returns or the app is opened, **Then** pending changes upload and remote
   changes download without user action.
3. **Given** the same habit was edited on two phones while offline, **Then** the most recent edit
   wins for that habit, and logs/sessions from both phones are all kept.

---

### User Story 6 - Forgot password (Priority: P2)

**Acceptance Scenarios**:

1. **Given** the sign-in screen, **When** the student taps "Quên mật khẩu?" and enters an email,
   **Then** the message "Nếu email này có tài khoản, DisGret đã gửi link đặt lại mật khẩu" is shown
   whether or not the email exists.
2. **Given** they set a new password through the link, **Then** they can sign in with it.

---

### User Story 7 - Delete my account (Priority: P2)

**Why this priority**: deletion on request is a constitution rule for under-18 users.

**Acceptance Scenarios**:

1. **Given** Cài đặt → Tài khoản → "Xoá tài khoản", **Then** a confirmation explains that the
   account and all data stored online are deleted for good, with a checkbox "Xoá cả dữ liệu trên
   máy này" (unchecked by default) and asks for the password again.
2. **Given** confirmation, **Then** the account and all its online data are deleted, the student
   is signed out, and local data is kept as guest data unless the checkbox was ticked.
3. **Given** no network, **Then** "Xoá tài khoản" is disabled with "Cần có mạng để xoá tài khoản".

### Edge Cases

- Sign-up or sign-in loses the network halfway: an error "Không có mạng. Thử lại sau." and the
  guest data is untouched.
- The app is killed during the first upload of guest data: on next start the upload resumes; no
  record is duplicated or lost.
- The account was deleted on another phone: the next sync signs this phone out with the notice
  "Tài khoản đã bị xoá" and keeps the local data as guest data.
- A password changed on another phone: this phone stays usable offline; the next sync that fails
  authentication asks to sign in again without losing local changes.
- Backend quota exceeded or backend unreachable for days: the app keeps working locally; status
  shows "Chưa đồng bộ".
- "Xoá toàn bộ dữ liệu" while signed in: deletes local data and signs out; online data is not
  touched (deleting it is "Xoá tài khoản").
- "Tạo dữ liệu mẫu" while signed in: sample records sync like any other data (fixed ids prevent
  duplicates).
- Data written by an older version (no sync fields) is read and uploaded without loss.
- Events (reel views, interventions, distractions) stay on the phone, so Thống kê's Reset-break and
  reel sections show only this phone's history after switching phones.

## Requirements *(mandatory)*

### Functional Requirements

**Guest mode and entry points**

- **FR-001**: The app MUST work fully without an account and without network; no existing feature
  may require sign-in.
- **FR-002**: Account entry points MUST be only: Cài đặt → "Tài khoản", and a secondary
  "Đã có tài khoản? Đăng nhập" link on onboarding's first page. No sign-in prompt elsewhere.
- **FR-003**: When the build has no backend configuration, all account UI MUST be hidden.

**Sign-up, sign-in, sign-out, password**

- **FR-004**: The only sign-in method is email + password. Google or other social sign-in is out
  of scope.
- **FR-005**: Before account creation the app MUST show a Vietnamese privacy notice that lists
  every piece of data that leaves the phone, where it is stored (Singapore), that nothing else is
  collected, how to delete it, and advises students under 16 to ask a parent first. There is no
  age check and no age is stored.
- **FR-006**: Passwords MUST be at least 8 characters; error messages MUST NOT reveal whether an
  email is registered (except the explicit "already has an account" case during sign-up).
- **FR-007**: "Quên mật khẩu?" MUST send a reset link by email and show the same message whether or
  not the email exists.
- **FR-008**: Sign-out MUST remove the account's data from the phone (goals, habits, logs,
  sessions, account-bound profile fields, scheduled reminders) and return to a new guest state.
- **FR-009**: Sign-out with unsynced changes MUST warn with the number of pending changes and
  default to staying signed in. Sign-out MUST be unavailable during a running focus session.

**Data on first login and isolation**

- **FR-010**: Signing up from a guest state MUST move all guest data into the new account.
- **FR-011**: Signing in from a guest state with local data into an account that has data MUST ask
  once to merge or to use only the account's data; merge MUST keep all records from both sides.
- **FR-012**: After sign-out, a different account signed in on the same phone MUST NOT be able to
  see or receive any data of the previous account (UI, reminders, statistics, sea map, Góc của
  Gret).
- **FR-013**: Phone-bound settings (blocked-app list, permission flags, demo mode) MUST NOT change
  when accounts switch and MUST NOT leave the phone.

**Sync and offline**

- **FR-014**: The data that leaves the phone is the account email and the study data: goals,
  habits, habit logs, sessions and the study profile choices (motivation quiz results, preferred
  reel length and formats, display name, Góc của Gret choices, study place). Events, installed
  apps, the blocked-app list, demo mode and permission flags MUST never leave the phone.
- **FR-015**: While signed in, every change MUST be saved on the phone first and synced
  automatically when network is available (on app start, on resume, and shortly after a change).
- **FR-016**: Conflicts: for the same record edited on two phones, the later edit wins; deleted
  records stay deleted; logs and sessions are never merged away.
- **FR-017**: Cài đặt → Tài khoản MUST show the signed-in email and the sync state ("Đã đồng bộ lúc
  HH:mm", "Đang đồng bộ…", "Chưa đồng bộ — sẽ tự đồng bộ khi có mạng").

**Deletion and privacy**

- **FR-018**: "Xoá tài khoản" MUST delete the account and all its online data after
  re-authentication, with an opt-in to delete local data too; it MUST need network.
- **FR-019**: The account MUST store no real name, birth date, age, school, class, phone number,
  photo or location.
- **FR-020**: No analytics, crash reporting, advertising or tracking component may be added; the
  app MUST contact only the backend chosen in ADR-0013.
- **FR-021**: All new screen text MUST come from `app_strings.dart`, in Vietnamese.

### Key Entities

- **Account**: the online identity — the backend's user id and the email; no other personal data.
- **Account session (on the phone)**: which account is signed in (or guest), last successful sync
  time, number of pending changes.
- **Synced record**: an existing local record (goal, habit, habit log, session, study profile
  choice) that also carries when it was last changed and whether it was deleted, so two phones can
  agree.
- **Phone-bound settings**: blocked-app list, permission flags, demo mode — never synced, never
  changed by switching accounts.
- **Phone-only history**: events (reel views, interventions, distractions) — never synced, but
  cleared on sign-out so the next account does not inherit them.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: A guest with sample data can create an account in under 2 minutes, and 100% of their
  goals, habits, logs and sessions are present after reinstalling and signing in.
- **SC-002**: After A signs out and B signs in on the same phone, 0 records of A are visible in any
  tab, and no reminder of A fires within the next day.
- **SC-003**: With the network off, 100% of the study flows in the README demo script complete
  without an error message.
- **SC-004**: Changes made offline appear on a second signed-in phone within 1 minute of the first
  phone getting network back and being opened.
- **SC-005**: After "Xoá tài khoản", signing in with the same email fails and no data of the
  account can be retrieved.
- **SC-006**: The privacy notice can be read in under 1 minute and names every piece of data that
  leaves the phone.

## Assumptions

- The project lead creates the backend project and supplies its configuration; nothing secret is
  committed; builds without configuration hide accounts (CI builds that way).
- One account per person, one signed-in account per phone at a time; no multi-account picker.
- Email verification is sent after sign-up but not required to use the app (a student may sign up
  in class without opening their mailbox); password reset needs a real email.
- Re-installing as a guest after signing out starts a new, empty guest; the earlier guest data
  lives in the account it was migrated to.
- Events stay per phone (constitution 2.0.0); events recorded while signed in belong to the phone
  and are cleared on sign-out together with the account's data so the next account does not
  inherit them.
- Implementation starts only after spec 015 lands on `feature/003-gret-ocean`, because the
  synced profile fields include 015's new ones.
