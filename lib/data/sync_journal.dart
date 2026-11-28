// 6.3 Tài khoản và đồng bộ (spec 016): the `sync_meta` box remembers when each synced record last
// changed, whether it was deleted and whether it still has to be pushed (data-model.md). Models
// stay unchanged. Only Hive here, no network.
import 'dart:async';

import 'package:hive/hive.dart';

import 'hive_boxes.dart';
import 'sync_merge.dart';

class SyncJournal {
  SyncJournal({DateTime Function()? clock}) : _clock = clock ?? DateTime.now;

  /// The journal every repository writes through.
  static final SyncJournal shared = SyncJournal();

  final DateTime Function() _clock;
  final StreamController<void> _changes = StreamController<void>.broadcast();

  /// Fires after every local change of a synced record (used to sync a few seconds later).
  Stream<void> get changes => _changes.stream;

  bool get _ready => Hive.isBoxOpen(HiveBoxes.syncMeta);

  Box<dynamic> get _meta => Hive.box<dynamic>(HiveBoxes.syncMeta);

  static String metaKey(String box, String key) => '$box/$key';

  SyncMeta? metaOf(String box, String key) {
    if (!_ready) return null;
    final raw = _meta.get(metaKey(box, key));
    return raw == null ? null : SyncMeta.fromMap(raw as Map<dynamic, dynamic>);
  }

  /// Records a local change: sync_meta.updatedAt = now, sync_meta.deleted, sync_meta.dirty =
  /// true. Boxes and keys outside [SyncScope] (events, phone-bound settings) are ignored.
  Future<void> touch(String box, String key, {bool deleted = false}) async {
    if (!_ready || !SyncScope.isSynced(box, key)) return;
    await _put(box, key, deleted: deleted);
    _changes.add(null);
  }

  Future<void> _put(String box, String key, {required bool deleted}) => _meta.put(
    metaKey(box, key),
    SyncMeta(updatedAt: _clock().millisecondsSinceEpoch, deleted: deleted, dirty: true).toMap(),
  );

  Iterable<MapEntry<String, SyncMeta>> get _dirtyEntries sync* {
    if (!_ready) return;
    for (final key in _meta.keys) {
      final meta = SyncMeta.fromMap(_meta.get(key) as Map<dynamic, dynamic>);
      if (meta.dirty) yield MapEntry(key as String, meta);
    }
  }

  /// Number of changes not pushed yet.
  int get pendingCount => _dirtyEntries.length;

  /// The records to push, read from Hive as they are now. A record that is gone counts as
  /// deleted.
  List<SyncRecord> pending() {
    final records = <SyncRecord>[];
    for (final entry in _dirtyEntries) {
      final slash = entry.key.indexOf('/');
      final box = entry.key.substring(0, slash);
      final key = entry.key.substring(slash + 1);
      final value = Hive.isBoxOpen(box) ? Hive.box<dynamic>(box).get(key) : null;
      final deleted = entry.value.deleted || value == null;
      records.add(
        SyncRecord(
          box: box,
          key: key,
          updatedAt: entry.value.updatedAt,
          deleted: deleted,
          data: deleted ? null : toRemoteData(box, key, value),
        ),
      );
    }
    return records;
  }

  /// After a push: clears sync_meta.dirty, unless the record changed again meanwhile. Tombstones
  /// keep their updatedAt so an older remote copy cannot bring them back (analyze U2).
  Future<void> markPushed(Iterable<SyncRecord> records) async {
    for (final record in records) {
      final meta = metaOf(record.box, record.key);
      if (meta == null || meta.updatedAt != record.updatedAt) continue;
      await _meta.put(
        metaKey(record.box, record.key),
        SyncMeta(updatedAt: meta.updatedAt, deleted: meta.deleted).toMap(),
      );
    }
  }

  /// Writes a remote record into Hive (not through the repositories, so nothing is journaled as
  /// a local change) and stores its time with sync_meta.dirty = false.
  Future<void> applyRemote(SyncRecord record) async {
    final box = Hive.box<dynamic>(record.box);
    if (record.deleted || record.data == null) {
      await box.delete(record.key);
    } else {
      await box.put(
        record.key,
        fromRemoteData(record.box, record.key, record.data!, box.get(record.key)),
      );
    }
    await _meta.put(
      metaKey(record.box, record.key),
      SyncMeta(updatedAt: record.updatedAt, deleted: record.deleted).toMap(),
    );
  }

  /// Marks every synced record on the phone as changed now, so the first upload sends all of
  /// the guest data (spec FR-010).
  Future<void> journalAllExisting() async {
    for (final name in SyncScope.dataBoxes) {
      for (final key in Hive.box<dynamic>(name).keys) {
        await _put(name, key as String, deleted: false);
      }
    }
    final profile = Hive.box<dynamic>(HiveBoxes.profile);
    for (final key in SyncScope.profileKeys) {
      if (profile.containsKey(key)) await _put(HiveBoxes.profile, key, deleted: false);
    }
  }

  /// True when the phone holds guest data worth keeping: any synced record, or a finished intro.
  bool get hasLocalData =>
      SyncScope.dataBoxes.any((name) => Hive.box<dynamic>(name).isNotEmpty) ||
      Hive.box<dynamic>(HiveBoxes.profile).get('onboarding_done') == true;

  /// Forgets every change record (the data became guest data of a deleted account).
  Future<void> clear() async {
    if (_ready) await _meta.clear();
  }
}
