// 6.3 Đồng bộ (spec 016, contracts/sync-records.md): where synced records live online. Only
// firestore_remote_store.dart talks to Firebase; tests use an in-memory fake.
import '../data/sync_merge.dart';

/// No network, a timeout or the backend is down: the change stays pending.
class RemoteUnavailable implements Exception {
  const RemoteUnavailable([this.reason = '']);

  final String reason;

  @override
  String toString() => 'RemoteUnavailable($reason)';
}

class PullResult {
  const PullResult(this.records, this.newestSyncedAt);

  final List<SyncRecord> records;

  /// Server time (ms) of the newest record returned; 0 when there is none.
  final int newestSyncedAt;
}

abstract class RemoteStore {
  /// Sends at most 400 records in one batch; the backend sets their `syncedAt`.
  Future<void> push(String uid, List<SyncRecord> records);

  /// Records whose server time is after [syncedAfterMs], oldest first.
  Future<PullResult> pullSince(String uid, int syncedAfterMs);

  Future<bool> hasAny(String uid);

  /// Deletes every record of the account.
  Future<void> deleteAll(String uid);
}
