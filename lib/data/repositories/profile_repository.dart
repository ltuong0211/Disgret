// 6.2 Lưu trữ local – hồ sơ người dùng và cờ "đã qua onboarding".
import 'package:hive/hive.dart';

import '../hive_boxes.dart';
import '../sync_journal.dart';
import '../models/user_profile.dart';

class ProfileRepository {
  static const String _profileKey = 'user';
  static const String _onboardingDoneKey = 'onboarding_done';
  static const String _celebratedLevelKey = 'celebrated_level';
  static const String _tourPendingKey = 'tour_pending';

  Box<dynamic> get _box => Hive.box<dynamic>(HiveBoxes.profile);

  /// False ở lần mở app đầu tiên; router dựa vào đây để vào onboarding hay home.
  bool get isOnboardingDone => _box.get(_onboardingDoneKey, defaultValue: false) as bool;

  UserProfile? get profile {
    final value = _box.get(_profileKey);
    return value == null ? null : UserProfile.fromMap(Map<String, dynamic>.from(value as Map));
  }

  Future<void> saveProfile(UserProfile profile) => _put(_profileKey, profile.toMap());

  /// Lưu hồ sơ và đánh dấu đã xong onboarding.
  Future<void> completeOnboarding(UserProfile profile) async {
    await saveProfile(profile);
    await _put(_onboardingDoneKey, true);
  }

  /// Cho phép xem lại onboarding, hồ sơ đã lưu vẫn được giữ.
  Future<void> resetOnboarding() => _put(_onboardingDoneKey, false);

  /// 6.3 Writes and journals the change for the account sync (spec 016).
  Future<void> _put(String key, Object value) async {
    await _box.put(key, value);
    await SyncJournal.shared.touch(HiveBoxes.profile, key);
  }

  /// 4.2 Cấp thành tích cao nhất đã hiện hộp thoại chúc mừng, để mỗi cấp chỉ chúc mừng một lần.
  int get celebratedLevel => _box.get(_celebratedLevelKey, defaultValue: 0) as int;

  Future<void> saveCelebratedLevel(int level) => _put(_celebratedLevelKey, level);

  /// 5.7 The guided tour waits to be shown on Hôm nay (spec 022). Phone-only: not on the
  /// ADR-0013 allow-list, and cleared with the rest on sign-out.
  bool get isTourPending => _box.get(_tourPendingKey, defaultValue: false) as bool;

  Future<void> setTourPending(bool pending) => _box.put(_tourPendingKey, pending);
}
