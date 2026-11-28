// 6.3 Tài khoản và đồng bộ (spec 016, ADR-0013): pure rules — what leaves the phone, which copy
// of a record wins, what to do on the first login, and the Vietnamese text for sign-in errors.
// No Hive, no Firebase: everything here is unit-tested in test/sync_merge_test.dart.
import '../l10n/app_strings.dart';
import 'hive_boxes.dart';

/// The allow-list of ADR-0013 Decision 5. Anything not named here stays on the phone.
class SyncScope {
  SyncScope._();

  /// Every record of these boxes syncs.
  static const Set<String> dataBoxes = {
    HiveBoxes.goals,
    HiveBoxes.habits,
    HiveBoxes.habitLogs,
    HiveBoxes.sessions,
  };

  /// Keys of the profile box that sync.
  static const Set<String> profileKeys = {
    userKey,
    'onboarding_done',
    'celebrated_level',
    'study_place',
    'corner_owned',
    'corner_worn',
    'corner_sea',
    'corner_mascot',
    // Góc của Gret choices added by specs 020 and 021 (ADR-0013 allow-list, 2026-11-28).
    'corner_mascot_style',
    'corner_decor',
    'corner_cafe_look',
  };

  /// The profile key that holds the `UserProfile` map.
  static const String userKey = 'user';

  /// Fields of the `UserProfile` map that sync. The display name (ADR-0012), demo mode and any
  /// field added later stay on the phone.
  static const Set<String> userFields = {'motivationTypes', 'preferredReelLength', 'quizAnswers'};

  static bool isSynced(String box, String key) =>
      dataBoxes.contains(box) || (box == HiveBoxes.profile && profileKeys.contains(key));
}

/// Bookkeeping kept next to one synced record (data-model.md `sync_meta`).
class SyncMeta {
  const SyncMeta({required this.updatedAt, this.deleted = false, this.dirty = false});

  /// A record saved before this feature: never changed since, nothing to push.
  static const SyncMeta none = SyncMeta(updatedAt: 0);

  /// Milliseconds since epoch (device clock) of the last local or applied remote change.
  final int updatedAt;

  /// The record was deleted (tombstone).
  final bool deleted;

  /// Changed on this phone and not pushed yet.
  final bool dirty;

  Map<String, dynamic> toMap() => {'updatedAt': updatedAt, 'deleted': deleted, 'dirty': dirty};

  factory SyncMeta.fromMap(Map<dynamic, dynamic> map) => SyncMeta(
    updatedAt: map['updatedAt'] as int? ?? 0,
    deleted: map['deleted'] as bool? ?? false,
    dirty: map['dirty'] as bool? ?? false,
  );
}

/// One record as it travels to and from the account (contracts/sync-records.md).
class SyncRecord {
  const SyncRecord({
    required this.box,
    required this.key,
    required this.updatedAt,
    this.data,
    this.deleted = false,
    this.syncedAt = 0,
  });

  final String box;
  final String key;

  /// The remote shape of the value ([toRemoteData]); null when [deleted].
  final Map<String, dynamic>? data;

  final int updatedAt;
  final bool deleted;

  /// Server time in milliseconds, set by the backend; 0 before it was pushed.
  final int syncedAt;

  /// Firestore document id: box and key joined by `__` (keys never contain `/`).
  String get documentId => '${box}__$key';
}

enum MergeAction { applyRemote, keepLocal, skip }

/// Which copy wins for the same box/key (research.md R5): the later change wins; on a tie a
/// deletion wins; an identical version (our own push coming back) is skipped.
MergeAction resolveMerge({required SyncMeta? local, required SyncRecord remote}) {
  if (!SyncScope.isSynced(remote.box, remote.key)) return MergeAction.skip;
  final mine = local ?? SyncMeta.none;
  if (remote.updatedAt > mine.updatedAt) return MergeAction.applyRemote;
  if (remote.updatedAt < mine.updatedAt) return MergeAction.keepLocal;
  if (remote.deleted != mine.deleted) {
    return remote.deleted ? MergeAction.applyRemote : MergeAction.keepLocal;
  }
  return mine.dirty ? MergeAction.keepLocal : MergeAction.skip;
}

/// The remote shape of a local value. Records of the data boxes go as their map; profile values
/// are wrapped as `{"value": …}`, and the `user` map keeps only [SyncScope.userFields].
Map<String, dynamic> toRemoteData(String box, String key, Object? value) {
  if (SyncScope.dataBoxes.contains(box)) {
    return _plainMap(value as Map<dynamic, dynamic>);
  }
  if (key == SyncScope.userKey && value is Map) {
    return {
      'value': {
        for (final entry in value.entries)
          if (SyncScope.userFields.contains(entry.key)) entry.key.toString(): _plain(entry.value),
      },
    };
  }
  return {'value': _plain(value)};
}

/// The local value for a remote record. For the `user` map only [SyncScope.userFields] are taken
/// from the account; the phone keeps its own display name, demo mode and other fields.
Object? fromRemoteData(String box, String key, Map<String, dynamic> data, Object? localValue) {
  if (SyncScope.dataBoxes.contains(box)) return _plainMap(data);
  final value = data['value'];
  if (key == SyncScope.userKey && value is Map) {
    return {
      if (localValue is Map) ..._plainMap(localValue),
      for (final entry in value.entries)
        if (SyncScope.userFields.contains(entry.key)) entry.key.toString(): _plain(entry.value),
    };
  }
  return _plain(value);
}

Map<String, dynamic> _plainMap(Map<dynamic, dynamic> map) => {
  for (final entry in map.entries) entry.key.toString(): _plain(entry.value),
};

Object? _plain(Object? value) => switch (value) {
  final Map<dynamic, dynamic> map => _plainMap(map),
  final List<dynamic> list => [for (final item in list) _plain(item)],
  _ => value,
};

/// What the first sign-in on this phone does (data-model.md `FirstLoginPlan.decide`).
enum FirstLoginPlan { normalSync, clearThenDownload, downloadOnly, uploadGuest, askMergeOrReplace }

FirstLoginPlan decideFirstLogin({
  required bool localHasData,
  required String? localOwnerUid,
  required String uid,
  required bool remoteHasData,
}) {
  if (localOwnerUid == uid) return FirstLoginPlan.normalSync;
  if (localOwnerUid != null) return FirstLoginPlan.clearThenDownload;
  if (!localHasData) return FirstLoginPlan.downloadOnly;
  return remoteHasData ? FirstLoginPlan.askMergeOrReplace : FirstLoginPlan.uploadGuest;
}

/// Backend error codes that mean the account no longer exists (research.md R10).
const Set<String> accountGoneCodes = {'user-not-found', 'user-disabled'};

/// Backend error codes that mean "sign in again"; local data and the owner are kept.
const Set<String> signInAgainCodes = {'user-token-expired', 'requires-recent-login'};

/// The Vietnamese message for a sign-in error code (research.md R10).
String authErrorMessage(String code) => switch (code) {
  'email-already-in-use' => AppStrings.accountEmailInUse,
  'invalid-credential' ||
  'wrong-password' ||
  'user-not-found' ||
  'INVALID_LOGIN_CREDENTIALS' => AppStrings.accountWrongCredentials,
  'invalid-email' => AppStrings.accountInvalidEmail,
  'weak-password' => AppStrings.accountWeakPassword,
  'too-many-requests' => AppStrings.accountTooManyRequests,
  'network-request-failed' => AppStrings.accountNoNetwork,
  'user-disabled' ||
  'user-token-expired' ||
  'requires-recent-login' => AppStrings.accountSignInAgain,
  _ => AppStrings.accountGenericError,
};

/// Basic email check before calling the backend (data-model.md Validation).
bool looksLikeEmail(String email) => RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email.trim());

/// Shortest password allowed (spec FR-006).
const int minPasswordLength = 8;
