# Contract: Account and sync services (Dart)

Widgets and repositories never import Firebase packages; only the two Firebase implementations
below do (constitution 2.0.0 Principle IV). Tests use the fakes.

## `lib/services/accounts_config.dart`

```dart
class AccountsConfig {
  static bool get isAvailable; // !kIsWeb && all four FIREBASE_* defines non-empty
  static FirebaseOptions? get options; // null when !isAvailable
}
```

## `lib/services/auth_service.dart`

```dart
abstract class AuthService {
  Stream<AccountUser?> authStateChanges();
  AccountUser? get currentUser;
  Future<AccountUser> signUp(String email, String password);
  Future<AccountUser> signIn(String email, String password);
  Future<void> sendPasswordReset(String email);
  Future<void> reauthenticate(String password);
  Future<void> deleteUser();              // the Firebase user only
  Future<void> signOut();
}

class AccountUser { final String uid; final String email; }

class AuthFailure implements Exception { final String code; } // mapped by authErrorMessage(code)
```

Implementations: `FirebaseAuthService` (sets language code `vi`, maps `FirebaseAuthException.code`
to `AuthFailure.code`, 15 s timeouts → `network-request-failed`), `FakeAuthService` in
`test/fakes/`.

## `lib/services/remote_store.dart`

```dart
abstract class RemoteStore {
  Future<void> push(String uid, List<SyncRecord> records);
  Future<PullResult> pullSince(String uid, int syncedAfterMs);
  Future<bool> hasAny(String uid);
  Future<void> deleteAll(String uid);
}
```

Implementations: `FirestoreRemoteStore` (contract in `sync-records.md`), `InMemoryRemoteStore`
in `test/fakes/` (can simulate offline by throwing `RemoteUnavailable`).

## `lib/data/sync_journal.dart` (pure Hive, no network)

```dart
class SyncJournal {
  bool isSynced(String box, String key);
  Future<void> touch(String box, String key, {bool deleted = false});
  int get pendingCount;
  List<SyncRecord> pending();           // reads current Hive values for dirty entries
  Future<void> markPushed(Iterable<SyncRecord> records);
  Future<void> journalAllExisting();    // used by uploadGuest
}
```

Called from `HiveRepository.save/delete` and from the profile-box repositories' write methods.

## `lib/data/sync_merge.dart` (pure)

```dart
enum MergeAction { applyRemote, keepLocal, skip }
MergeAction resolve({required SyncMeta? local, required SyncRecord remote});
FirstLoginResult decideFirstLogin({...}); // table in data-model.md
Map<String, dynamic> toRemoteData(String box, String key, dynamic value);  // allow-list (R5/R6)
dynamic fromRemoteData(String box, String key, Map<String, dynamic> data, dynamic localValue);
String authErrorMessage(String code);    // R10 table → AppStrings
```

## `lib/services/sync_engine.dart`

```dart
class SyncEngine {
  Future<SyncOutcome> syncNow();        // push pending, then pull and apply; never throws
  Future<void> firstLogin(FirstLoginChoice? choice);
  Future<SignOutCheck> prepareSignOut(); // pushes; returns pending count left
  Future<void> clearAccountData();
}
```

Applying remote records writes Hive directly (not through the journal) and updates `sync_meta`
with `dirty = false`, then `AppDataActions.reloadAll()` and reminder rescheduling run.

## Providers (`lib/providers/account_providers.dart`)

`authServiceProvider`, `remoteStoreProvider`, `syncJournalProvider`, `syncEngineProvider`,
`accountStateProvider` (StreamProvider over `authStateChanges`, `unavailable` when config is
missing), `syncStatusProvider` (Notifier), `accountActionsProvider` (sign up / in / out, reset,
delete — the only entry points screens call).
