// 6.3 Sync engine with fakes (spec 016 US2, US3, US5, US7): no network.
import 'package:flutter_test/flutter_test.dart';
import 'package:focus_app/data/hive_boxes.dart';
import 'package:focus_app/data/models/event.dart';
import 'package:focus_app/data/models/goal.dart';
import 'package:focus_app/data/models/motivation_type.dart';
import 'package:focus_app/data/models/user_profile.dart';
import 'package:focus_app/data/repositories/account_repository.dart';
import 'package:focus_app/data/repositories/blocked_apps_repository.dart';
import 'package:focus_app/data/repositories/event_repository.dart';
import 'package:focus_app/data/repositories/goal_repository.dart';
import 'package:focus_app/data/repositories/profile_repository.dart';
import 'package:focus_app/data/sync_journal.dart';
import 'package:focus_app/data/sync_merge.dart';
import 'package:focus_app/services/sync_engine.dart';
import 'package:hive/hive.dart';

import 'fakes/fake_auth_service.dart';
import 'fakes/in_memory_remote_store.dart';
import 'test_helpers.dart';

const _email = 'an@example.com';
const _password = 'matkhau123';

Goal _goal(String id, [String title = 'Mục tiêu']) => Goal(id: id, title: title, reason: '');

void main() {
  late FakeAuthService auth;
  late InMemoryRemoteStore remote;
  late AccountRepository account;
  late SyncEngine engine;

  setUp(() async {
    await openMemoryBoxes();
    auth = FakeAuthService();
    remote = InMemoryRemoteStore();
    account = AccountRepository();
    engine = SyncEngine(auth: auth, remote: remote, journal: SyncJournal.shared, account: account);
  });
  tearDown(Hive.close);

  Box<dynamic> goals() => Hive.box<dynamic>(HiveBoxes.goals);
  Iterable<SyncRecord> online(String uid) => remote.accounts[uid]?.values ?? const [];

  Future<void> guestWithData() async {
    await GoalRepository().save(_goal('g1'));
    await ProfileRepository().completeOnboarding(
      const UserProfile(
        motivationTypes: [MotivationType.family],
        preferredReelLength: 30,
        displayName: 'Khôi',
        demoMode: true,
      ),
    );
    await BlockedAppsRepository().save({'com.zhiliaoapp.musically'});
    await EventRepository().save(
      Event(id: 'e1', type: EventType.values.first, time: DateTime(2026)),
    );
  }

  group('US2 sign up keeps the guest data', () {
    test(
      'uploadGuest pushes every synced record, nothing phone-only, and sets the owner',
      () async {
        await guestWithData();
        final user = await auth.signUp(_email, _password);
        expect(await engine.firstLogin(user), FirstLoginStatus.done);

        expect(account.ownerUid, user.uid);
        expect(account.email, _email);
        expect(account.lastSyncOkAt, isNotNull);
        expect(SyncJournal.shared.pendingCount, 0);

        final keys = online(user.uid).map((record) => '${record.box}/${record.key}').toSet();
        expect(keys, {'goals/g1', 'profile/user', 'profile/onboarding_done'});
        final userMap =
            online(user.uid).firstWhere((record) => record.key == 'user').data!['value']
                as Map<String, dynamic>;
        // FR-019 / ADR-0012: no display name, no demo mode, nothing personal.
        expect(userMap.keys.toSet(), SyncScope.userFields);
      },
    );

    test('an upload killed halfway finishes on the next sync without duplicates', () async {
      for (var i = 0; i < SyncEngine.batchSize + 5; i++) {
        await GoalRepository().save(_goal('g$i'));
      }
      remote.failAfterPushes = 1;
      final user = await auth.signUp(_email, _password);
      await engine.firstLogin(user);
      expect(SyncJournal.shared.pendingCount, 5);

      remote.failAfterPushes = null;
      final outcome = await engine.syncNow();
      expect(outcome.result, SyncResult.ok);
      expect(SyncJournal.shared.pendingCount, 0);
      expect(online(user.uid).length, SyncEngine.batchSize + 5);
    });
  });

  group('US3 sign in on another phone, sign out', () {
    Future<String> accountWithData() async {
      final user = auth.addUser(_email, _password);
      remote.seed(
        user.uid,
        SyncRecord(
          box: HiveBoxes.goals,
          key: 'remote',
          updatedAt: 10,
          data: _goal('remote').toMap(),
        ),
      );
      remote.seed(
        user.uid,
        const SyncRecord(
          box: HiveBoxes.profile,
          key: 'onboarding_done',
          updatedAt: 10,
          data: {'value': true},
        ),
      );
      return user.uid;
    }

    test('a fresh phone downloads the account and skips onboarding', () async {
      await accountWithData();
      final user = await auth.signIn(_email, _password);
      await engine.firstLogin(user);
      expect(goals().keys, ['remote']);
      expect(ProfileRepository().isOnboardingDone, isTrue);
      expect(SyncJournal.shared.pendingCount, 0);
    });

    test('guest data + account data asks once; merge keeps both sides', () async {
      final uid = await accountWithData();
      await GoalRepository().save(_goal('local'));
      final user = await auth.signIn(_email, _password);
      expect(await engine.firstLogin(user), FirstLoginStatus.needsMergeChoice);
      expect(account.ownerUid, isNull);

      await engine.firstLogin(user, choice: MergeChoice.merge);
      expect(goals().keys.toSet(), {'local', 'remote'});
      expect(online(uid).map((record) => record.key), contains('local'));
    });

    test('"use the account only" clears the guest data first', () async {
      await accountWithData();
      await GoalRepository().save(_goal('local'));
      await BlockedAppsRepository().save({'com.example'});
      final user = await auth.signIn(_email, _password);
      await engine.firstLogin(user, choice: MergeChoice.useAccount);
      expect(goals().keys, ['remote']);
      expect(BlockedAppsRepository().packages, {'com.example'});
    });

    test('sign-out offline reports the changes that would be lost', () async {
      final user = await auth.signUp(_email, _password);
      await engine.firstLogin(user);
      remote.offline = true;
      await GoalRepository().save(_goal('g1'));
      expect(await engine.prepareSignOut(), 1);

      remote.offline = false;
      expect(await engine.prepareSignOut(), 0);
      await engine.signOut();
      expect(auth.currentUser, isNull);
      expect(goals().isEmpty, isTrue);
      expect(account.ownerUid, isNull);
    });
  });

  group('US5 offline and two phones', () {
    late String uid;

    setUp(() async {
      // A realistic server clock (ms), so "60 s earlier" is still a positive time.
      remote.serverTime = 1764300000000;
      final user = await auth.signUp(_email, _password);
      uid = user.uid;
      await engine.firstLogin(user);
    });

    test('offline changes stay pending and go up later', () async {
      remote.offline = true;
      await GoalRepository().save(_goal('g1'));
      expect((await engine.syncNow()).result, SyncResult.offline);
      expect(SyncJournal.shared.pendingCount, 1);

      remote.offline = false;
      expect((await engine.syncNow()).result, SyncResult.ok);
      expect(online(uid).map((record) => record.key), contains('g1'));
    });

    test('the newer edit of the same record wins; records from both phones are kept', () async {
      await GoalRepository().save(_goal('shared', 'Trên máy này'));
      await engine.syncNow();
      final mine = SyncJournal.shared.metaOf(HiveBoxes.goals, 'shared')!.updatedAt;
      // The other phone edits it later and adds its own record.
      remote.seed(
        uid,
        SyncRecord(
          box: HiveBoxes.goals,
          key: 'shared',
          updatedAt: mine + 1000,
          data: _goal('shared', 'Trên máy kia').toMap(),
        ),
      );
      remote.seed(
        uid,
        SyncRecord(
          box: HiveBoxes.goals,
          key: 'other',
          updatedAt: mine,
          data: _goal('other').toMap(),
        ),
      );
      final outcome = await engine.syncNow();
      expect(outcome.dataChanged, isTrue);
      expect(GoalRepository().getById('shared')!.title, 'Trên máy kia');
      expect(goals().keys.toSet(), {'shared', 'other'});

      // An older remote edit loses against a newer local one.
      await GoalRepository().save(_goal('shared', 'Mới nhất'));
      remote.seed(
        uid,
        SyncRecord(
          box: HiveBoxes.goals,
          key: 'shared',
          updatedAt: 1,
          data: _goal('shared', 'Cũ').toMap(),
        ),
      );
      await engine.syncNow();
      expect(GoalRepository().getById('shared')!.title, 'Mới nhất');
    });

    test('a record committed with a slightly older server time is still pulled (U1)', () async {
      await GoalRepository().save(_goal('first'));
      await engine.syncNow();
      final last = account.lastPulledAt;
      expect(last, greaterThan(0));
      remote.seed(
        uid,
        SyncRecord(box: HiveBoxes.goals, key: 'late', updatedAt: 5, data: _goal('late').toMap()),
        syncedAt: last - 30000,
      );
      await engine.syncNow();
      expect(goals().containsKey('late'), isTrue);
    });

    test('a remote tombstone deletes the record here', () async {
      await GoalRepository().save(_goal('g1'));
      await engine.syncNow();
      final mine = SyncJournal.shared.metaOf(HiveBoxes.goals, 'g1')!.updatedAt;
      remote.seed(
        uid,
        SyncRecord(box: HiveBoxes.goals, key: 'g1', updatedAt: mine + 1, deleted: true),
      );
      await engine.syncNow();
      expect(goals().containsKey('g1'), isFalse);
    });

    test('account deleted elsewhere: data stays as guest data', () async {
      await GoalRepository().save(_goal('g1'));
      auth.reloadFailure = 'user-not-found';
      expect((await engine.syncNow()).result, SyncResult.accountGone);
      expect(account.ownerUid, isNull);
      expect(auth.currentUser, isNull);
      expect(goals().containsKey('g1'), isTrue);
    });

    test('expired sign-in keeps the owner and the pending changes', () async {
      await GoalRepository().save(_goal('g1'));
      auth.reloadFailure = 'user-token-expired';
      expect((await engine.syncNow()).result, SyncResult.signInAgain);
      expect(account.ownerUid, uid);
      expect(SyncJournal.shared.pendingCount, 1);
    });
  });

  group('US7 delete the account', () {
    late String uid;

    setUp(() async {
      final user = await auth.signUp(_email, _password);
      uid = user.uid;
      await GoalRepository().save(_goal('g1'));
      await engine.firstLogin(user);
    });

    test('needs the password, deletes everything online, keeps local data as guest', () async {
      await expectLater(
        engine.deleteAccount('sai-mat-khau', clearLocal: false),
        throwsA(isA<Object>()),
      );
      expect(online(uid), isNotEmpty);

      await engine.deleteAccount(_password, clearLocal: false);
      expect(remote.accounts[uid], isNull);
      expect(auth.hasUser(_email), isFalse);
      expect(account.ownerUid, isNull);
      expect(goals().containsKey('g1'), isTrue);
      expect(SyncJournal.shared.pendingCount, 0);
    });

    test('with the checkbox the phone is cleared too', () async {
      await engine.deleteAccount(_password, clearLocal: true);
      expect(goals().isEmpty, isTrue);
    });
  });
}
