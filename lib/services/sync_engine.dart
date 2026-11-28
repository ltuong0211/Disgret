// 6.3 Đồng bộ (spec 016, research.md R3–R8): pushes local changes, pulls newer ones, and handles
// the first sign-in, sign-out and account deletion. Hive stays the source of truth: the engine
// never blocks studying and never throws for a network problem.
import 'dart:math' as math;

import '../data/hive_boxes.dart';
import '../data/repositories/account_repository.dart';
import '../data/sync_journal.dart';
import '../data/sync_merge.dart';
import 'auth_service.dart';
import 'remote_store.dart';

enum SyncResult {
  /// Everything pushed and pulled.
  ok,

  /// No network or backend: changes stay pending.
  offline,

  /// The account no longer exists; the phone's data became guest data.
  accountGone,

  /// The sign-in expired; data and pending changes are kept until the user signs in again.
  signInAgain,

  /// Not signed in, or another sync is running.
  skipped,
}

class SyncOutcome {
  const SyncOutcome(this.result, {this.dataChanged = false});

  final SyncResult result;

  /// Remote records were written into Hive: providers must reload.
  final bool dataChanged;
}

/// What the first sign-in needs from the user, if anything.
enum FirstLoginStatus { done, needsMergeChoice }

enum MergeChoice { merge, useAccount }

class SyncEngine {
  SyncEngine({
    required this.auth,
    required this.remote,
    required this.journal,
    required this.account,
    DateTime Function()? clock,
  }) : _clock = clock ?? DateTime.now;

  final AuthService auth;
  final RemoteStore remote;
  final SyncJournal journal;
  final AccountRepository account;
  final DateTime Function() _clock;

  /// Records per pushed batch (research.md R4).
  static const int batchSize = 400;

  /// Each pull starts this much before the last one ended (analyze U1).
  static const int pullOverlapMs = 60000;

  bool _running = false;

  /// The signed-in user, if the local data belongs to them.
  AccountUser? get _owner {
    final user = auth.currentUser;
    return user != null && user.uid == account.ownerUid ? user : null;
  }

  Future<SyncOutcome> syncNow() async {
    final user = _owner;
    if (user == null || _running) return const SyncOutcome(SyncResult.skipped);
    _running = true;
    try {
      await auth.reload();
      final pending = journal.pending();
      for (var i = 0; i < pending.length; i += batchSize) {
        final batch = pending.sublist(i, math.min(i + batchSize, pending.length));
        await remote.push(user.uid, batch);
        await journal.markPushed(batch);
      }
      final pulled = await remote.pullSince(
        user.uid,
        math.max(0, account.lastPulledAt - pullOverlapMs),
      );
      var changed = false;
      for (final record in pulled.records) {
        final action = resolveMerge(local: journal.metaOf(record.box, record.key), remote: record);
        if (action == MergeAction.applyRemote) {
          await journal.applyRemote(record);
          changed = true;
        }
      }
      if (pulled.newestSyncedAt > account.lastPulledAt) {
        await account.setLastPulledAt(pulled.newestSyncedAt);
      }
      await account.setLastSyncOkAt(_clock());
      return SyncOutcome(SyncResult.ok, dataChanged: changed);
    } on RemoteUnavailable {
      return const SyncOutcome(SyncResult.offline);
    } on AuthFailure catch (failure) {
      if (accountGoneCodes.contains(failure.code)) {
        await _becomeGuest();
        await auth.signOut().catchError((_) {});
        return const SyncOutcome(SyncResult.accountGone);
      }
      if (signInAgainCodes.contains(failure.code)) {
        return const SyncOutcome(SyncResult.signInAgain);
      }
      return const SyncOutcome(SyncResult.offline);
    } finally {
      _running = false;
    }
  }

  /// Right after sign-up or sign-in (data-model.md `FirstLoginPlan`). Returns
  /// [FirstLoginStatus.needsMergeChoice] when both the phone and the account hold data; call
  /// again with [choice].
  Future<FirstLoginStatus> firstLogin(AccountUser user, {MergeChoice? choice}) async {
    final plan = decideFirstLogin(
      localHasData: journal.hasLocalData,
      localOwnerUid: account.ownerUid,
      uid: user.uid,
      remoteHasData: await remote.hasAny(user.uid),
    );
    switch (plan) {
      case FirstLoginPlan.normalSync:
        await syncNow();
      case FirstLoginPlan.uploadGuest:
        await _uploadGuest(user);
      case FirstLoginPlan.downloadOnly:
        await _download(user);
      case FirstLoginPlan.clearThenDownload:
        await HiveBoxes.clearAccountData();
        await _download(user);
      case FirstLoginPlan.askMergeOrReplace:
        switch (choice) {
          case null:
            return FirstLoginStatus.needsMergeChoice;
          case MergeChoice.merge:
            await _uploadGuest(user);
          case MergeChoice.useAccount:
            await HiveBoxes.clearAccountData();
            await _download(user);
        }
    }
    return FirstLoginStatus.done;
  }

  Future<void> _uploadGuest(AccountUser user) async {
    await journal.journalAllExisting();
    await account.setOwner(user.uid, user.email);
    await syncNow();
  }

  Future<void> _download(AccountUser user) async {
    await account.setOwner(user.uid, user.email);
    await account.setLastPulledAt(0);
    await syncNow();
  }

  /// Tries one last push before signing out; returns the changes still not pushed.
  Future<int> prepareSignOut() async {
    await syncNow();
    return journal.pendingCount;
  }

  /// Signs out and removes the account's data from the phone (spec FR-008).
  Future<void> signOut() async {
    await auth.signOut().catchError((_) {});
    await HiveBoxes.clearAccountData();
  }

  /// Deletes every online record, then the account (research.md R11). Local data stays as guest
  /// data unless [clearLocal].
  Future<void> deleteAccount(String password, {required bool clearLocal}) async {
    final user = _owner ?? auth.currentUser;
    if (user == null) return;
    await auth.reauthenticate(password);
    await remote.deleteAll(user.uid);
    await auth.deleteUser();
    if (clearLocal) {
      await HiveBoxes.clearUserData();
    } else {
      await _becomeGuest();
    }
  }

  Future<void> _becomeGuest() async {
    await account.clear();
    await journal.clear();
  }
}
