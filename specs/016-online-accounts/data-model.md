# Data Model: Optional Online Accounts (016)

Existing models (`Goal`, `Habit`, `HabitLog`, `Session`, `UserProfile`, `Event`) are **not
changed**. Two new Hive boxes hold the bookkeeping; both names are new and never used before.

## New Hive boxes

### `account` (key → value)

| Key | Type | Meaning | Missing → |
|---|---|---|---|
| `owner_uid` | String | Firebase uid that the local data belongs to | guest data |
| `email` | String | email shown in Cài đặt → Tài khoản | empty |
| `last_pulled_at` | int (ms, server time) | `syncedAt` of the newest remote record applied; the next pull starts 60 000 ms earlier (overlap) | 0 (pull all) |
| `last_sync_ok_at` | int (ms, device time) | last fully successful sync, for "Đã đồng bộ lúc HH:mm" | never synced |

### `sync_meta` (key `"<box>/<recordKey>"` → map)

| Field | Type | Meaning | Missing → |
|---|---|---|---|
| `updatedAt` | int (ms, device clock) | time of the last local or applied remote change | 0 |
| `deleted` | bool | the record was deleted (tombstone) | false |
| `dirty` | bool | changed locally and not yet pushed | false |

Rules:

- `SyncJournal.touch(box, key, {deleted})` sets `updatedAt = now`, `deleted`, `dirty = true` for a
  synced box/key (R6 table); calls for other boxes/keys are ignored.
- Records that existed before this feature have no `sync_meta` entry; they count as
  `updatedAt = 0, dirty = false`. On first upload (`uploadGuest`) every existing synced record is
  journaled as dirty first.
- Pending count = number of entries with `dirty == true`.
- After a successful push of an entry, `dirty = false`. Tombstones (`deleted == true`) keep their
  `updatedAt` locally after the push (analyze U2), so a re-pulled older remote copy cannot bring a
  deleted record back; the remote tombstone stays too.

## Remote documents (Firestore)

`users/{uid}/records/{box}__{key}` — see [contracts/sync-records.md](contracts/sync-records.md).

| Field | Type | Notes |
|---|---|---|
| `box` | string | one of the synced boxes |
| `key` | string | Hive key (record id or profile key) |
| `data` | map | Hive map; absent when `deleted`; for `profile/user` only the allow-listed fields |
| `updatedAt` | int | device ms, used for last-write-wins |
| `deleted` | bool | tombstone |
| `syncedAt` | timestamp | server time, used for incremental pull |

No other document exists; there is no `users/{uid}` profile document with personal data.

## Account session (in memory, Riverpod)

`AccountState`: `unavailable` (no config / web) | `guest` | `signedIn(uid, email)`.
`SyncStatus`: `idle(lastOkAt)` | `syncing` | `offline(pendingCount)` | `error(messageKey)`.

## State transitions

```text
unavailable ── (never changes at runtime)

guest ──sign up──► signedIn  [plan uploadGuest]
guest ──sign in──► signedIn  [plan downloadOnly | uploadGuest | askMergeOrReplace]
signedIn ──sign out──► guest [push, warn if pending, clearAccountData]
signedIn ──delete account──► guest [remote deleted; local kept or cleared]
signedIn ──account gone / token revoked on sync──► guest [local kept as guest data]
```

`FirstLoginPlan.decide` (pure):

| localHasData | localOwnerUid | remoteHasData | Result |
|---|---|---|---|
| any | == uid | any | `normalSync` |
| any | other uid | any | `clearThenDownload` (should not happen; sign-out clears) |
| false | none | any | `downloadOnly` |
| true | none | false | `uploadGuest` |
| true | none | true | `askMergeOrReplace` → merge = `uploadGuest` then `normalSync`; replace = clear synced boxes then `downloadOnly` |

## Validation

- Email: trimmed, must contain one `@` and a dot after it (backend validates fully).
- Password: at least 8 characters (FR-006).
- No name, age, school, phone, photo or location fields anywhere (FR-019).
