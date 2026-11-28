// 6.3 Tài khoản và đồng bộ (spec 016): which account owns the local data and when it last synced
// (data-model.md `account`). Missing keys mean guest data that never synced.
import 'package:hive/hive.dart';

import '../hive_boxes.dart';

class AccountRepository {
  static const String _ownerKey = 'owner_uid';
  static const String _emailKey = 'email';
  static const String _lastPulledKey = 'last_pulled_at';
  static const String _lastSyncOkKey = 'last_sync_ok_at';

  Box<dynamic> get _box => Hive.box<dynamic>(HiveBoxes.account);

  /// The account the local data belongs to; null for guest data.
  String? get ownerUid => _box.get(_ownerKey) as String?;

  String get email => _box.get(_emailKey) as String? ?? '';

  /// Server time (ms) of the newest remote record applied; 0 pulls everything.
  int get lastPulledAt => _box.get(_lastPulledKey) as int? ?? 0;

  /// Device time of the last complete sync; null if it never synced.
  DateTime? get lastSyncOkAt {
    final ms = _box.get(_lastSyncOkKey) as int?;
    return ms == null ? null : DateTime.fromMillisecondsSinceEpoch(ms);
  }

  Future<void> setOwner(String uid, String email) async {
    await _box.put(_ownerKey, uid);
    await _box.put(_emailKey, email);
  }

  Future<void> setLastPulledAt(int serverMs) => _box.put(_lastPulledKey, serverMs);

  Future<void> setLastSyncOkAt(DateTime time) =>
      _box.put(_lastSyncOkKey, time.millisecondsSinceEpoch);

  /// The local data becomes guest data again (account deleted or gone).
  Future<void> clear() => _box.clear();
}
