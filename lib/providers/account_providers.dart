// 6.3 Tài khoản và đồng bộ (spec 016, contracts/services.md): the account state, the sync status
// and the only actions screens call. Sync runs in the background after start, on resume, a few
// seconds after a change and every minute while changes wait (research.md R8).
import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/repositories/account_repository.dart';
import '../data/sync_journal.dart';
import '../l10n/app_strings.dart';
import '../services/accounts_config.dart';
import '../services/auth_service.dart';
import '../services/firebase_auth_service.dart';
import '../services/firestore_remote_store.dart';
import '../services/remote_store.dart';
import '../services/sync_engine.dart';
import 'app_providers.dart';
import 'focus_session_provider.dart';
import 'gret_corner_providers.dart';
import 'sea_cafe_providers.dart';

/// False when the build has no Firebase settings or Firebase did not start (FR-003).
final accountsAvailableProvider = Provider<bool>((ref) => AccountsConfig.ready);

final authServiceProvider = Provider<AuthService?>(
  (ref) => ref.watch(accountsAvailableProvider) ? FirebaseAuthService() : null,
);

final remoteStoreProvider = Provider<RemoteStore?>(
  (ref) => ref.watch(accountsAvailableProvider) ? FirestoreRemoteStore() : null,
);

final syncJournalProvider = Provider<SyncJournal>((ref) => SyncJournal.shared);

final accountRepositoryProvider = Provider((ref) => AccountRepository());

final syncEngineProvider = Provider<SyncEngine?>((ref) {
  final auth = ref.watch(authServiceProvider);
  final remote = ref.watch(remoteStoreProvider);
  if (auth == null || remote == null) return null;
  return SyncEngine(
    auth: auth,
    remote: remote,
    journal: ref.watch(syncJournalProvider),
    account: ref.watch(accountRepositoryProvider),
    clock: ref.watch(clockProvider),
  );
});

enum AccountKind { unavailable, guest, signedIn, signInAgain }

class AccountState {
  const AccountState(this.kind, {this.email = ''});

  final AccountKind kind;
  final String email;

  bool get isSignedIn => kind == AccountKind.signedIn;
}

enum SyncKind { synced, syncing, pending, signInAgain }

class SyncStatus {
  const SyncStatus(this.kind, {this.lastOkAt});

  final SyncKind kind;
  final DateTime? lastOkAt;
}

/// Who owns the data on this phone, kept in step with the sign-in backend.
class AccountNotifier extends Notifier<AccountState> {
  StreamSubscription<AccountUser?>? _authChanges;
  StreamSubscription<void>? _localChanges;
  Timer? _debounce;
  Timer? _retry;

  @override
  AccountState build() {
    final auth = ref.watch(authServiceProvider);
    ref.onDispose(_stopTimers);
    if (auth == null) return const AccountState(AccountKind.unavailable);
    _authChanges = auth.authStateChanges().listen((_) => refresh());
    ref.onDispose(() => _authChanges?.cancel());
    final state = _compute();
    if (state.isSignedIn) _startTimers();
    return state;
  }

  AccountState _compute() {
    final auth = ref.read(authServiceProvider);
    if (auth == null) return const AccountState(AccountKind.unavailable);
    final account = ref.read(accountRepositoryProvider);
    final user = auth.currentUser;
    final owner = account.ownerUid;
    if (user != null && user.uid == owner) {
      return AccountState(AccountKind.signedIn, email: user.email);
    }
    if (user == null && owner != null) {
      return AccountState(AccountKind.signInAgain, email: account.email);
    }
    return const AccountState(AccountKind.guest);
  }

  /// Re-reads the state after sign-in, sign-out or deletion.
  void refresh() {
    final next = _compute();
    state = next;
    _stopTimers();
    if (next.isSignedIn) _startTimers();
  }

  void _startTimers() {
    final journal = ref.read(syncJournalProvider);
    _localChanges = journal.changes.listen((_) {
      _debounce?.cancel();
      _debounce = Timer(const Duration(seconds: 5), _sync);
    });
    _retry = Timer.periodic(const Duration(minutes: 1), (_) {
      if (journal.pendingCount > 0) _sync();
    });
  }

  void _sync() => unawaited(ref.read(accountActionsProvider).syncNow());

  void _stopTimers() {
    _localChanges?.cancel();
    _localChanges = null;
    _debounce?.cancel();
    _debounce = null;
    _retry?.cancel();
    _retry = null;
  }
}

final accountStateProvider = NotifierProvider<AccountNotifier, AccountState>(AccountNotifier.new);

class SyncStatusNotifier extends Notifier<SyncStatus> {
  @override
  SyncStatus build() {
    final lastOk = ref.read(accountRepositoryProvider).lastSyncOkAt;
    final pending = ref.read(syncJournalProvider).pendingCount;
    return SyncStatus(
      lastOk != null && pending == 0 ? SyncKind.synced : SyncKind.pending,
      lastOkAt: lastOk,
    );
  }

  void set(SyncKind kind) =>
      state = SyncStatus(kind, lastOkAt: ref.read(accountRepositoryProvider).lastSyncOkAt);
}

final syncStatusProvider = NotifierProvider<SyncStatusNotifier, SyncStatus>(SyncStatusNotifier.new);

/// A one-off notice for Cài đặt, e.g. "Tài khoản đã bị xoá" after a sync found it gone.
class AccountNoticeNotifier extends Notifier<String?> {
  @override
  String? build() => null;

  void show(String? message) => state = message;
}

final accountNoticeProvider = NotifierProvider<AccountNoticeNotifier, String?>(
  AccountNoticeNotifier.new,
);

/// The only entry points the account screens use (contracts/services.md).
class AccountActions {
  AccountActions(this._ref);

  final Ref _ref;

  AuthService get _auth => _ref.read(authServiceProvider)!;
  SyncEngine get _engine => _ref.read(syncEngineProvider)!;

  /// Everything that reads Hive once and caches it (spec FR-012: nothing of the previous account
  /// may stay on screen).
  void _reload() {
    _ref.read(appDataActionsProvider).reloadAll();
    _ref.invalidate(gretCornerProvider);
    _ref.invalidate(studyPlaceProvider);
    _ref.invalidate(todayGoalProvider);
    _ref.invalidate(todayHabitProvider);
  }

  void _afterChange({bool dataChanged = true}) {
    if (dataChanged) _reload();
    _ref.read(accountStateProvider.notifier).refresh();
    _ref.read(syncStatusProvider.notifier).set(_statusKind());
  }

  SyncKind _statusKind() {
    final journal = _ref.read(syncJournalProvider);
    final lastOk = _ref.read(accountRepositoryProvider).lastSyncOkAt;
    return lastOk != null && journal.pendingCount == 0 ? SyncKind.synced : SyncKind.pending;
  }

  /// Signs up and moves the guest data into the new account (FR-010). Throws [AuthFailure].
  Future<void> signUp(String email, String password) async {
    final user = await _auth.signUp(email.trim(), password);
    await _engine.firstLogin(user);
    _afterChange();
  }

  /// Signs in. Returns [FirstLoginStatus.needsMergeChoice] when the screen must ask (FR-011).
  Future<FirstLoginStatus> signIn(String email, String password) async {
    final user = await _auth.signIn(email.trim(), password);
    final status = await _engine.firstLogin(user);
    if (status == FirstLoginStatus.done) _afterChange();
    return status;
  }

  Future<void> completeSignIn(MergeChoice choice) async {
    final user = _auth.currentUser;
    if (user == null) return;
    await _engine.firstLogin(user, choice: choice);
    _afterChange();
  }

  /// The user closed the merge question without choosing: nothing changes on the phone.
  Future<void> cancelSignIn() async {
    await _auth.signOut();
    _afterChange(dataChanged: false);
  }

  Future<void> sendPasswordReset(String email) async {
    try {
      await _auth.sendPasswordReset(email.trim());
    } on AuthFailure catch (failure) {
      // The same message whether or not the email exists (FR-007).
      if (failure.code != 'user-not-found' && failure.code != 'invalid-email') rethrow;
    }
  }

  /// At start: drops a sign-in whose first login never finished (the app was closed on the merge
  /// question), then syncs.
  Future<void> onAppStart() async {
    final auth = _ref.read(authServiceProvider);
    if (auth == null) return;
    if (auth.currentUser != null && _ref.read(accountRepositoryProvider).ownerUid == null) {
      await auth.signOut().catchError((_) {});
      _ref.read(accountStateProvider.notifier).refresh();
      return;
    }
    await syncNow();
  }

  Future<void> syncNow() async {
    final engine = _ref.read(syncEngineProvider);
    if (engine == null || !_ref.read(accountStateProvider).isSignedIn) return;
    _ref.read(syncStatusProvider.notifier).set(SyncKind.syncing);
    final outcome = await engine.syncNow();
    switch (outcome.result) {
      case SyncResult.accountGone:
        _ref.read(accountNoticeProvider.notifier).show(AppStrings.accountGone);
        _afterChange(dataChanged: false);
      case SyncResult.signInAgain:
        _ref.read(syncStatusProvider.notifier).set(SyncKind.signInAgain);
      case SyncResult.ok || SyncResult.offline || SyncResult.skipped:
        if (outcome.dataChanged) _reload();
        _ref.read(syncStatusProvider.notifier).set(_statusKind());
    }
  }

  /// Pushes what it can; returns the changes that would be lost by signing out now (FR-009).
  Future<int> prepareSignOut() => _engine.prepareSignOut();

  Future<void> signOut() async {
    await _engine.signOut();
    _ref.invalidate(focusSessionProvider);
    _afterChange();
  }

  Future<void> deleteAccount(String password, {required bool clearLocal}) async {
    await _engine.deleteAccount(password, clearLocal: clearLocal);
    _ref.invalidate(focusSessionProvider);
    _afterChange();
  }

  /// "Xoá toàn bộ dữ liệu" while signed in: signs out on this phone only; online data stays.
  Future<void> signOutLocally() async {
    final auth = _ref.read(authServiceProvider);
    if (auth == null) return;
    await auth.signOut().catchError((_) {});
    _ref.read(accountStateProvider.notifier).refresh();
  }
}

final accountActionsProvider = Provider(AccountActions.new);
