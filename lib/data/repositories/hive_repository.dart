// 6.2 Lưu trữ local – phần dùng chung của các repository.
// Mỗi đối tượng được lưu trong Hive dưới dạng Map (không cần sinh code TypeAdapter),
// nên chạy được trên cả Android lẫn web.
import 'package:hive/hive.dart';

import '../sync_journal.dart';

int _idCounter = 0;

/// Tạo id mới theo thời gian; thêm bộ đếm để hai id tạo cùng lúc không trùng nhau.
String newId() => '${DateTime.now().microsecondsSinceEpoch}_${_idCounter++}';

abstract class HiveRepository<T> {
  HiveRepository(this.boxName);

  final String boxName;

  Box<dynamic> get _box => Hive.box<dynamic>(boxName);

  // Mỗi repository con chỉ cần cho biết cách đổi đối tượng <-> Map và id của nó.
  T fromMap(Map<String, dynamic> map);
  Map<String, dynamic> toMap(T item);
  String idOf(T item);

  List<T> getAll() => _box.values.map(_decode).toList();

  T? getById(String id) {
    final value = _box.get(id);
    return value == null ? null : _decode(value);
  }

  // 6.3 Every write is journaled so it can sync to the account (spec 016); the journal ignores
  // boxes that never sync, such as events.
  Future<void> save(T item) async {
    await _box.put(idOf(item), toMap(item));
    await SyncJournal.shared.touch(boxName, idOf(item));
  }

  Future<void> delete(String id) async {
    await _box.delete(id);
    await SyncJournal.shared.touch(boxName, id, deleted: true);
  }

  T _decode(dynamic value) => fromMap(Map<String, dynamic>.from(value as Map));
}
