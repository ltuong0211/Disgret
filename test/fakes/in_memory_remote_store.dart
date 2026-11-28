// 6.3 The online records in memory for tests (spec 016): a counter plays the server clock.
import 'package:focus_app/data/sync_merge.dart';
import 'package:focus_app/services/remote_store.dart';

class InMemoryRemoteStore implements RemoteStore {
  /// uid → document id → record.
  final Map<String, Map<String, SyncRecord>> accounts = {};

  /// Server time in ms; each pushed record gets the next value.
  int serverTime = 1000;

  /// No network: every call throws [RemoteUnavailable].
  bool offline = false;

  /// Throws after this many successful pushes (the app was killed mid-upload).
  int? failAfterPushes;
  int pushes = 0;

  void _check() {
    if (offline) throw const RemoteUnavailable('offline');
  }

  Map<String, SyncRecord> _docs(String uid) => accounts.putIfAbsent(uid, () => {});

  /// Puts a record as if another phone pushed it at [syncedAt] (default: next server time).
  void seed(String uid, SyncRecord record, {int? syncedAt}) {
    final time = syncedAt ?? (serverTime += 10);
    _docs(uid)[record.documentId] = SyncRecord(
      box: record.box,
      key: record.key,
      data: record.data,
      updatedAt: record.updatedAt,
      deleted: record.deleted,
      syncedAt: time,
    );
  }

  @override
  Future<void> push(String uid, List<SyncRecord> records) async {
    _check();
    if (failAfterPushes != null && pushes >= failAfterPushes!) {
      throw const RemoteUnavailable('killed');
    }
    pushes++;
    for (final record in records) {
      seed(uid, record);
    }
  }

  @override
  Future<PullResult> pullSince(String uid, int syncedAfterMs) async {
    _check();
    final records = _docs(uid).values.where((record) => record.syncedAt > syncedAfterMs).toList()
      ..sort((a, b) => a.syncedAt.compareTo(b.syncedAt));
    final newest = records.isEmpty ? 0 : records.last.syncedAt;
    return PullResult(records, newest);
  }

  @override
  Future<bool> hasAny(String uid) async {
    _check();
    return _docs(uid).isNotEmpty;
  }

  @override
  Future<void> deleteAll(String uid) async {
    _check();
    accounts.remove(uid);
  }
}
