// 6.3 Đồng bộ (spec 016, contracts/sync-records.md): records under users/{uid}/records on Cloud
// Firestore. The only file that imports cloud_firestore. Firestore's own offline cache is off
// (research.md R9): Hive is the only store on the phone, and every call times out after 15 s.
import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';

import '../data/sync_merge.dart';
import 'auth_service.dart';
import 'remote_store.dart';

class FirestoreRemoteStore implements RemoteStore {
  static const Duration _timeout = Duration(seconds: 15);
  static const int _pageSize = 500;

  /// Call once at start, before any other Firestore use.
  static void configure() {
    FirebaseFirestore.instance.settings = const Settings(persistenceEnabled: false);
  }

  CollectionReference<Map<String, dynamic>> _records(String uid) =>
      FirebaseFirestore.instance.collection('users').doc(uid).collection('records');

  Future<T> _call<T>(Future<T> Function() action) async {
    try {
      return await action().timeout(_timeout);
    } on TimeoutException {
      throw const RemoteUnavailable('timeout');
    } on FirebaseException catch (error) {
      // The rules refuse a user whose sign-in is no longer valid.
      if (error.code == 'permission-denied' || error.code == 'unauthenticated') {
        throw const AuthFailure('user-token-expired');
      }
      throw RemoteUnavailable(error.code);
    }
  }

  @override
  Future<void> push(String uid, List<SyncRecord> records) => _call(() {
    final batch = FirebaseFirestore.instance.batch();
    for (final record in records) {
      batch.set(_records(uid).doc(record.documentId), {
        'box': record.box,
        'key': record.key,
        'data': ?record.data,
        'updatedAt': record.updatedAt,
        'deleted': record.deleted,
        'syncedAt': FieldValue.serverTimestamp(),
      });
    }
    return batch.commit();
  });

  @override
  Future<PullResult> pullSince(String uid, int syncedAfterMs) => _call(() async {
    final records = <SyncRecord>[];
    var newest = 0;
    DocumentSnapshot<Map<String, dynamic>>? last;
    while (true) {
      var query = _records(uid)
          .where('syncedAt', isGreaterThan: Timestamp.fromMillisecondsSinceEpoch(syncedAfterMs))
          .orderBy('syncedAt')
          .limit(_pageSize);
      if (last != null) query = query.startAfterDocument(last);
      final page = await query.get();
      for (final doc in page.docs) {
        final map = doc.data();
        final syncedAt = (map['syncedAt'] as Timestamp?)?.millisecondsSinceEpoch ?? 0;
        if (syncedAt > newest) newest = syncedAt;
        final data = map['data'];
        records.add(
          SyncRecord(
            box: map['box'] as String? ?? '',
            key: map['key'] as String? ?? '',
            data: data is Map ? Map<String, dynamic>.from(data) : null,
            updatedAt: map['updatedAt'] as int? ?? 0,
            deleted: map['deleted'] as bool? ?? false,
            syncedAt: syncedAt,
          ),
        );
      }
      if (page.docs.length < _pageSize) break;
      last = page.docs.last;
    }
    return PullResult(records, newest);
  });

  @override
  Future<bool> hasAny(String uid) =>
      _call(() async => (await _records(uid).limit(1).get()).docs.isNotEmpty);

  @override
  Future<void> deleteAll(String uid) => _call(() async {
    while (true) {
      final page = await _records(uid).limit(_pageSize).get();
      if (page.docs.isEmpty) return;
      final batch = FirebaseFirestore.instance.batch();
      for (final doc in page.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();
    }
  });
}
