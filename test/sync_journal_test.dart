// 6.3 The sync_meta journal and the sign-out clear (spec 016, data-model.md sync_meta).
import 'package:flutter_test/flutter_test.dart';
import 'package:focus_app/data/hive_boxes.dart';
import 'package:focus_app/data/models/event.dart';
import 'package:focus_app/data/models/goal.dart';
import 'package:focus_app/data/models/motivation_type.dart';
import 'package:focus_app/data/models/user_profile.dart';
import 'package:focus_app/data/repositories/blocked_apps_repository.dart';
import 'package:focus_app/data/repositories/event_repository.dart';
import 'package:focus_app/data/repositories/goal_repository.dart';
import 'package:focus_app/data/repositories/profile_repository.dart';
import 'package:focus_app/data/repositories/reminder_settings_repository.dart';
import 'package:focus_app/data/sync_journal.dart';
import 'package:hive/hive.dart';

import 'test_helpers.dart';

const _goal = Goal(id: 'g1', title: 'Đỗ đại học', reason: 'Vì gia đình');

void main() {
  setUp(openMemoryBoxes);
  tearDown(Hive.close);

  final journal = SyncJournal.shared;

  test('saving a synced record marks it changed and pending', () async {
    await GoalRepository().save(_goal);
    final meta = journal.metaOf(HiveBoxes.goals, 'g1')!;
    expect(meta.dirty, isTrue);
    expect(meta.deleted, isFalse);
    expect(meta.updatedAt, greaterThan(0));
    expect(journal.pendingCount, 1);
    expect(journal.pending().single.data, _goal.toMap());
  });

  test('events and phone-bound settings are never journaled', () async {
    await EventRepository().save(
      Event(id: 'e1', type: EventType.values.first, time: DateTime(2026)),
    );
    await BlockedAppsRepository().save({'com.example'});
    await ReminderSettingsRepository().markPermissionAsked();
    expect(journal.pendingCount, 0);
  });

  test('a delete becomes a tombstone without data', () async {
    await GoalRepository().save(_goal);
    await GoalRepository().delete('g1');
    final record = journal.pending().single;
    expect(record.deleted, isTrue);
    expect(record.data, isNull);
    expect(journal.metaOf(HiveBoxes.goals, 'g1')!.deleted, isTrue);
  });

  test('markPushed clears dirty but keeps the time, also for tombstones', () async {
    await GoalRepository().save(_goal);
    await GoalRepository().delete('g1');
    final pushed = journal.pending();
    await journal.markPushed(pushed);
    final meta = journal.metaOf(HiveBoxes.goals, 'g1')!;
    expect(meta.dirty, isFalse);
    expect(meta.deleted, isTrue);
    expect(meta.updatedAt, pushed.single.updatedAt);
    expect(journal.pendingCount, 0);
  });

  test('a change made after the push stays pending', () async {
    await GoalRepository().save(_goal);
    final pushed = journal.pending();
    await Future<void>.delayed(const Duration(milliseconds: 2));
    await GoalRepository().save(const Goal(id: 'g1', title: 'Đổi tên', reason: ''));
    await journal.markPushed(pushed);
    expect(journal.pendingCount, 1);
  });

  test('journalAllExisting marks every synced record, including old ones', () async {
    // Written before this feature: no sync_meta entry.
    await Hive.box<dynamic>(HiveBoxes.goals).put('old', _goal.toMap());
    await Hive.box<dynamic>(HiveBoxes.profile).put('onboarding_done', true);
    await Hive.box<dynamic>(HiveBoxes.profile).put('blocked_packages', ['com.example']);
    expect(journal.pendingCount, 0);
    await journal.journalAllExisting();
    final keys = journal.pending().map((record) => '${record.box}/${record.key}').toSet();
    expect(keys, {'goals/old', 'profile/onboarding_done'});
  });

  test('the pushed user map never carries the display name or demo mode', () async {
    await ProfileRepository().saveProfile(
      const UserProfile(
        motivationTypes: [MotivationType.family],
        preferredReelLength: 30,
        displayName: 'Khôi',
        demoMode: true,
      ),
    );
    final value = journal.pending().single.data!['value'] as Map<String, dynamic>;
    expect(value.keys.toSet(), {'motivationTypes', 'preferredReelLength', 'quizAnswers'});
  });

  test('hasLocalData: any synced record or a finished intro', () async {
    expect(journal.hasLocalData, isFalse);
    await Hive.box<dynamic>(HiveBoxes.profile).put('onboarding_done', true);
    expect(journal.hasLocalData, isTrue);
  });

  test('clearAccountData keeps only the phone-bound profile keys', () async {
    await GoalRepository().save(_goal);
    await ProfileRepository().completeOnboarding(
      const UserProfile(motivationTypes: [], preferredReelLength: 30, displayName: 'Khôi'),
    );
    await BlockedAppsRepository().save({'com.example'});
    await ReminderSettingsRepository().markPermissionAsked();
    await Hive.box<dynamic>(HiveBoxes.account).put('owner_uid', 'uid1');
    await EventRepository().save(
      Event(id: 'e1', type: EventType.values.first, time: DateTime(2026)),
    );

    await HiveBoxes.clearAccountData();

    expect(Hive.box<dynamic>(HiveBoxes.goals).isEmpty, isTrue);
    expect(Hive.box<dynamic>(HiveBoxes.events).isEmpty, isTrue);
    expect(Hive.box<dynamic>(HiveBoxes.account).isEmpty, isTrue);
    expect(Hive.box<dynamic>(HiveBoxes.syncMeta).isEmpty, isTrue);
    expect(Hive.box<dynamic>(HiveBoxes.profile).keys.toSet(), {
      'blocked_packages',
      'reminder_permission_asked',
    });
  });
}
