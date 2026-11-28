# Specification Analysis Report — 016 Optional Online Accounts

Run: `/speckit-analyze`, 2026-11-27, on commit `cfc4b3b`. Read-only: no artifact was changed by
this analysis; this file only records the report. Constitution used: the text in
`.specify/memory/constitution.md` (2.0.0 **Proposed**; 1.0.0 is still in force).

## Findings

| ID | Category | Severity | Location(s) | Summary | Recommendation |
|----|----------|----------|-------------|---------|----------------|
| C1 | Constitution | CRITICAL | constitution.md Principle II (1.0.0 in force); plan.md Constitution Check | The ratified 1.0.0 forbids backend, accounts, sync and runtime network calls. The whole feature violates it until 2.0.0 is approved. | Keep T001 as a hard gate; the lead approves 2.0.0 + ADR-0013 in chat before any code. |
| C2 | Constitution | CRITICAL | constitution.md II (2.0.0): "a new synced field needs an ADR update first"; research.md R6 last paragraph; research.md R5 `stripPhoneOnly` | R6 says new fields inside the profile `user` map "sync automatically" and R5 only strips `demoMode` (deny-list). Any field another spec adds to `UserProfile` would leave the phone without an ADR update. | Switch to an allow-list: upload only the `user` fields named in ADR-0013/R6 (motivationTypes, preferredReelLength, displayName, and 015's fields once listed); update R5, R6, T007, T009, T022. |
| C3 | Constitution | CRITICAL | constitution.md Principle I ("MUST name … the evaluation criterion (R-code) it moves"); spec.md "Scenario served" | The spec states it moves no R-code. | Lead names the S3 criterion it protects, or the spec records an explicit exception approved with T001. |
| I1 | Inconsistency | HIGH | docs/decisions/0012-local-display-name.md (Accepted: display name "never sent anywhere"); spec.md FR-014; ADR-0013 Decision 5 | Syncing the display name contradicts accepted ADR-0012. | In T001 also amend ADR-0012 ("syncs to the user's own account per ADR-0013"), or exclude `displayName` from sync. |
| I2 | Inconsistency | HIGH | research.md R6 (`onboarding_done`, `celebrated_level` synced); spec.md FR-014 and contracts/account-ui.md notice list; constitution 2.0.0 II ("ADR names … every synced field"); SC-006 | Two synced profile keys are not in FR-014, ADR-0013 Decision 5, or the privacy notice, so SC-006 ("names every piece of data") would fail. | Add both keys (as "trạng thái đã xem giới thiệu, cấp thành tích") to FR-014, ADR-0013 and the notice; or keep them phone-only. |
| U1 | Underspecification | HIGH | data-model.md `account.last_pulled_at`; contracts/sync-records.md `pullSince` | Pulling strictly `syncedAt > last_pulled_at` can miss a batch whose server timestamp is slightly older than a record already pulled (two phones writing at once). | Pull with an overlap (e.g. `last_pulled_at − 60 s`); merge is idempotent. Add a test to T033. |
| U2 | Underspecification | MEDIUM | data-model.md sync_meta rules ("tombstones … then removed from sync_meta") with U1's overlap | Once a local tombstone is dropped, missing meta counts as `updatedAt = 0`, so an older remote copy seen again could resurrect a deleted record. | Keep the tombstone's `updatedAt` (drop only `dirty`), or drop tombstones only after `last_pulled_at` passes them. |
| I3 | Inconsistency | MEDIUM | spec.md Edge Cases ("password changed on another phone … asks to sign in again without losing local changes"); research.md R10 last row; data-model.md transitions | R10 treats an expired token like a deleted account (sign out locally, data becomes guest); the spec asks for a re-sign-in prompt. | Separate the cases: `user-not-found`/`user-disabled` → guest; `user-token-expired` → keep `owner_uid`, show "Hãy đăng nhập lại", resume after sign-in. Update R10 and T033. |
| F1 | Field coverage | HIGH | tasks.md T012, T010, T023 vs data-model.md `sync_meta.updatedAt`, `sync_meta.deleted`, `sync_meta.dirty`, `account.owner_uid`, `account.email`, `account.last_pulled_at`, `account.last_sync_ok_at` | Exact field citations appear only in test tasks (T007, T011, T022). The implementing tasks cite contracts or a wildcard (`account.*` in T010). | Cite the exact fields in T012 (sync_meta.*) and T023/T030 (account.owner_uid, account.email, account.last_pulled_at, account.last_sync_ok_at). |
| G1 | Coverage | MEDIUM | spec.md FR-019 | No task checks that no name/age/school/phone/photo/location is stored or sent. | Extend T041 or T022: assert pushed records contain only box data and the email is the only account attribute. |
| A1 | Ambiguity | LOW | plan.md Performance Goals ("sync never blocks the UI") | No measurable target or task. | Add to T034: sync runs after first frame; a widget test shows Hôm nay renders while a fake push hangs. |
| I4 | Inconsistency | LOW | plan.md ("Firebase confined to two service files"); tasks.md T041 (also allows `main.dart`, `accounts_config.dart`) | Two different rules for where Firebase may be imported. | Align plan with T041 (init + options are not backend calls), or move init into a service. |
| G2 | Coverage | LOW | spec.md Edge Case "Tạo dữ liệu mẫu while signed in" | No explicit test; behaviour follows from repositories being journaled. | Add one case to T022 or T035. |
| P1 | Process | LOW | AGENTS.md (still says no accounts/network) | Shared rules contradict the feature until updated. | Already in T001. |

## Coverage summary

| Requirement | Has task? | Task IDs | Notes |
|---|---|---|---|
| FR-001 guest/offline works | Yes | T018–T021, T042 | |
| FR-002 entry points | Yes | T020 | |
| FR-003 hidden without config | Yes | T015, T018, T021 | |
| FR-004 email + password | Yes | T024, T027 | |
| FR-005 privacy notice | Yes | T026, T027 | see I2 |
| FR-006 password rule, no enumeration | Yes | T024, T026, T029 | |
| FR-007 forgot password | Yes | T036 | |
| FR-008 sign-out clears data | Yes | T010, T030, T031 | |
| FR-009 pending warning, no sign-out in session | Yes | T029, T031 | |
| FR-010 migrate guest data | Yes | T022, T023 | |
| FR-011 merge / replace | Yes | T028, T030, T031 | |
| FR-012 isolation | Yes | T032 | |
| FR-013 phone-bound settings | Yes | T010, T032 | |
| FR-014 what syncs | Yes | T022, T009 | see C2, I1, I2 |
| FR-015 automatic sync | Yes | T034 | |
| FR-016 conflicts | Yes | T007, T033 | see U1, U2 |
| FR-017 status | Yes | T034 | |
| FR-018 delete account | Yes | T037, T038 | |
| FR-019 no personal fields | Partial | T041 | see G1 |
| FR-020 no tracking, one backend | Yes | T004, T041 | |
| FR-021 strings | Yes | T017 | |
| SC-001 sign-up < 2 min, 100% data | Yes | T022, T042 | |
| SC-002 0 records after switch | Yes | T032, T042 | |
| SC-003 offline demo | Yes | T042 | manual |
| SC-004 < 1 min after reconnect | Yes | T034, T042 | manual |
| SC-005 deletion | Yes | T037, T042 | |
| SC-006 notice names all data | Yes | T026 | fails until I2 fixed |

## Constrained-field coverage

| Field | Canonical location | Implementing tasks | Notes |
|---|---|---|---|
| `account.owner_uid` | data-model.md "account" | T010 (`account.*`), T023 (none) | F1: no exact citation in an implementing task |
| `account.email` | data-model.md "account" | T010 (`account.*`) | F1 |
| `account.last_pulled_at` | data-model.md "account" | T010 (`account.*`) | F1; see U1 |
| `account.last_sync_ok_at` | data-model.md "account" | T010 (`account.*`) | F1 |
| `sync_meta.updatedAt` | data-model.md "sync_meta" | T012 (none) | F1; cited only by tests T007/T011 |
| `sync_meta.deleted` | data-model.md "sync_meta" | T012 (none) | F1; see U2 |
| `sync_meta.dirty` | data-model.md "sync_meta" | T012 (none) | F1 |
| Validation (email, password ≥ 8) | data-model.md "Validation" | T027 | cited as a section; consistent with FR-006 |

No task states a constraint that contradicts data-model.md.

## Constitution alignment issues

C1 (feature blocked under 1.0.0), C2 (synced-field rule under 2.0.0), C3 (R-code rule).

## Unmapped tasks

None. T001–T006 are setup/governance; T039–T042 are polish.

## Metrics

- Total requirements: 21 FR + 6 SC = 27
- Total tasks: 42
- Coverage: 27/27 have at least one task (FR-019 partial)
- Ambiguity count: 1
- Duplication count: 0
- Critical issues: 3 (C1 resolved only by the lead's approval)

## Next actions

- Do not run `/speckit-implement` until C1–C3 are resolved: C1 by the lead's approval (T001), C2
  and C3 by small edits to research.md / spec.md / tasks.md.
- Then fix I1, I2, U1, F1 (HIGH) by editing ADR-0012/0013, spec FR-014, contracts, data-model.md
  and tasks T010/T012/T023/T033.
- MEDIUM/LOW items can be folded into the same edit.
- Remediation edits were **not** applied; they wait for the lead's go-ahead.

## Resolution (2026-11-28)

The lead confirmed directly in this session: constitution 2.0.0 ratified and ADR-0013 Accepted
(C1, T001); R-code recorded as an approved exception in spec.md (C3); display name stays
phone-only (I1). Fixed in the docs: C2 (allow-list of `user` fields: `motivationTypes`,
`preferredReelLength`, `quizAnswers`), I2 (`onboarding_done`, `celebrated_level` added to FR-014,
ADR-0013 and the notice), U1 (pull overlap 60 s), U2 (tombstones keep `updatedAt`), I3 (token
expired ≠ account gone), F1 (exact field citations in T010, T012, T023, T034), G1 (FR-019 check
in T022). Remaining LOW items (A1, I4, G2) are handled during implementation.
