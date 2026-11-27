# Contract: Remote records and Security Rules

## Document path and shape

`users/{uid}/records/{box}__{key}`

```json
{
  "box": "habits",
  "key": "1732612345678901_0",
  "data": { "...": "the Hive map as stored by the repository" },
  "updatedAt": 1764230400000,
  "deleted": false,
  "syncedAt": "<server timestamp>"
}
```

- `box` ∈ {`goals`, `habits`, `habit_logs`, `sessions`, `profile`}.
- For `box == "profile"`, `key` ∈ {`user`, `onboarding_done`, `celebrated_level`, `study_place`,
  `corner_owned`, `corner_worn`, `corner_sea`, `corner_mascot`}; `data` is `{"value": <stored value>}`
  for non-map values. `user` never contains `demoMode`.
- Deleted record: `deleted: true`, no `data`.
- Document id uses `__` between box and key; keys never contain `/` (ids are `newId()` or the
  fixed habit-log/profile keys).
- Unknown `box` or `key` values received on pull are ignored (forward compatibility).

## Operations (RemoteStore)

| Operation | Behaviour |
|---|---|
| `push(uid, entries)` | batched `set` (≤ 400 per batch), `syncedAt = serverTimestamp()`; 15 s timeout per batch |
| `pullSince(uid, syncedAfter)` | `where syncedAt > syncedAfter orderBy syncedAt`, pages of 500; returns records + newest `syncedAt` |
| `hasAny(uid)` | `limit(1)` query, used by `FirstLoginPlan` |
| `deleteAll(uid)` | page through `records` and batch-delete until empty |

## Security Rules (`firestore.rules`, committed)

```text
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /users/{uid}/{document=**} {
      allow read, write: if request.auth != null && request.auth.uid == uid;
    }
    match /{document=**} {
      allow read, write: if false;
    }
  }
}
```

Required outcomes (checked in the Rules Playground, quickstart step 6):

1. Signed-in user A reads/writes `users/A/records/x` → allowed.
2. Signed-in user A reads `users/B/records/x` → denied.
3. Unauthenticated read of any path → denied.
