// 6.2 Lưu trữ local – tên các box Hive, mỗi loại dữ liệu nằm trong một box.
import 'package:hive/hive.dart';

class HiveBoxes {
  HiveBoxes._();

  static const String profile = 'profile';
  static const String goals = 'goals';
  static const String habits = 'habits';
  static const String habitLogs = 'habit_logs';
  static const String sessions = 'sessions';
  static const String events = 'events';

  /// 6.3 Which account the local data belongs to (spec 016, data-model.md `account`).
  static const String account = 'account';

  /// 6.3 One change record per synced record (spec 016, data-model.md `sync_meta`).
  static const String syncMeta = 'sync_meta';

  /// Reel đọc từ asset (1.2) nên không có box riêng.
  static const List<String> all = [
    profile,
    goals,
    habits,
    habitLogs,
    sessions,
    events,
    account,
    syncMeta,
  ];

  /// 6.3 Profile keys that belong to the phone, not to an account (spec 016 FR-013).
  static const List<String> phoneBoundProfileKeys = [
    'blocked_packages',
    'reminder_permission_asked',
  ];

  /// Boxes of removed features. Never opened or read, and their names are never reused.
  /// Older versions may have left them on disk; only [clearUserData] deletes them.
  /// - `reel_reactions`, `reel_comments`: reel likes and comments (removed by spec 002, ADR-0003).
  static const List<String> retired = ['reel_reactions', 'reel_comments'];

  /// Mở toàn bộ box; gọi một lần lúc khởi động, trước khi dùng repository.
  static Future<void> openAll() async {
    for (final name in all) {
      await Hive.openBox<dynamic>(name);
    }
  }

  /// Xoá toàn bộ dữ liệu người dùng, đưa app về trạng thái như mới cài.
  /// This explicit reset ("Xoá toàn bộ dữ liệu") also deletes [retired] boxes from disk.
  static Future<void> clearUserData() async {
    for (final name in all) {
      await Hive.box<dynamic>(name).clear();
    }
    for (final name in retired) {
      try {
        await Hive.deleteBoxFromDisk(name);
      } on ArgumentError {
        // Hive has no disk path (memory-only boxes, as in tests): nothing on disk to delete.
      }
    }
  }

  /// 6.3 Sign-out (spec 016 FR-008, research.md R7): removes the signed-in account's data so the
  /// next account on this phone sees none of it. Only [phoneBoundProfileKeys] survive.
  static Future<void> clearAccountData() async {
    for (final name in all) {
      if (name == profile) continue;
      await Hive.box<dynamic>(name).clear();
    }
    final profileBox = Hive.box<dynamic>(profile);
    final keys = profileBox.keys.where((key) => !phoneBoundProfileKeys.contains(key)).toList();
    await profileBox.deleteAll(keys);
  }
}
