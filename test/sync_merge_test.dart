// 6.3 Pure sync rules (spec 016, research.md R5–R7, R10).
import 'package:flutter_test/flutter_test.dart';
import 'package:focus_app/data/hive_boxes.dart';
import 'package:focus_app/data/sync_merge.dart';
import 'package:focus_app/l10n/app_strings.dart';

SyncRecord _remote({
  String box = HiveBoxes.habits,
  String key = 'h1',
  int updatedAt = 100,
  bool deleted = false,
}) => SyncRecord(
  box: box,
  key: key,
  updatedAt: updatedAt,
  deleted: deleted,
  data: deleted ? null : {'id': key},
);

void main() {
  group('SyncScope (ADR-0013 allow-list)', () {
    test('data boxes and listed profile keys sync; the rest stays on the phone', () {
      expect(SyncScope.isSynced(HiveBoxes.goals, 'g1'), isTrue);
      expect(SyncScope.isSynced(HiveBoxes.sessions, 's1'), isTrue);
      expect(SyncScope.isSynced(HiveBoxes.profile, 'user'), isTrue);
      expect(SyncScope.isSynced(HiveBoxes.profile, 'onboarding_done'), isTrue);
      expect(SyncScope.isSynced(HiveBoxes.profile, 'corner_worn'), isTrue);
      expect(SyncScope.isSynced(HiveBoxes.events, 'e1'), isFalse);
      expect(SyncScope.isSynced(HiveBoxes.profile, 'blocked_packages'), isFalse);
      expect(SyncScope.isSynced(HiveBoxes.profile, 'reminder_permission_asked'), isFalse);
      expect(SyncScope.isSynced(HiveBoxes.profile, 'a_key_added_later'), isFalse);
      expect(SyncScope.isSynced(HiveBoxes.account, 'owner_uid'), isFalse);
    });
  });

  group('resolveMerge (research.md R5)', () {
    test('the later change wins', () {
      const local = SyncMeta(updatedAt: 50);
      expect(resolveMerge(local: local, remote: _remote()), MergeAction.applyRemote);
      expect(
        resolveMerge(local: const SyncMeta(updatedAt: 200), remote: _remote()),
        MergeAction.keepLocal,
      );
    });

    test('a record saved before this feature counts as updatedAt 0', () {
      expect(resolveMerge(local: null, remote: _remote(updatedAt: 1)), MergeAction.applyRemote);
    });

    test('on a tie a deletion wins', () {
      expect(
        resolveMerge(local: const SyncMeta(updatedAt: 100), remote: _remote(deleted: true)),
        MergeAction.applyRemote,
      );
      expect(
        resolveMerge(local: const SyncMeta(updatedAt: 100, deleted: true), remote: _remote()),
        MergeAction.keepLocal,
      );
    });

    test('our own push coming back is skipped; a local edit still pending is kept', () {
      expect(
        resolveMerge(local: const SyncMeta(updatedAt: 100), remote: _remote()),
        MergeAction.skip,
      );
      expect(
        resolveMerge(local: const SyncMeta(updatedAt: 100, dirty: true), remote: _remote()),
        MergeAction.keepLocal,
      );
    });

    test('a pushed tombstone keeps beating an older remote copy (analyze U2)', () {
      const tombstone = SyncMeta(updatedAt: 300, deleted: true);
      expect(
        resolveMerge(local: tombstone, remote: _remote(updatedAt: 200)),
        MergeAction.keepLocal,
      );
    });

    test('unknown boxes and keys are skipped', () {
      expect(resolveMerge(local: null, remote: _remote(box: HiveBoxes.events)), MergeAction.skip);
      expect(
        resolveMerge(
          local: null,
          remote: _remote(box: HiveBoxes.profile, key: 'later_key'),
        ),
        MergeAction.skip,
      );
    });
  });

  group('toRemoteData / fromRemoteData', () {
    final localUser = <String, dynamic>{
      'motivationTypes': ['career'],
      'preferredReelLength': 30,
      'demoMode': true,
      'displayName': 'Khôi',
      'quizAnswers': {
        'q1': ['a'],
      },
      'fieldAddedLater': 'x',
    };

    test('the user map keeps only the allow-listed fields', () {
      final data = toRemoteData(HiveBoxes.profile, 'user', localUser);
      expect(data['value'], {
        'motivationTypes': ['career'],
        'preferredReelLength': 30,
        'quizAnswers': {
          'q1': ['a'],
        },
      });
    });

    test('applying a remote user map keeps the local display name and demo mode', () {
      final merged = fromRemoteData(HiveBoxes.profile, 'user', {
        'value': {
          'motivationTypes': ['family'],
          'preferredReelLength': 60,
          'quizAnswers': <String, dynamic>{},
          'displayName': 'Someone else',
        },
      }, localUser) as Map<String, dynamic>;
      expect(merged['motivationTypes'], ['family']);
      expect(merged['preferredReelLength'], 60);
      expect(merged['displayName'], 'Khôi');
      expect(merged['demoMode'], true);
    });

    test('profile values are wrapped; data records go as their map', () {
      expect(toRemoteData(HiveBoxes.profile, 'onboarding_done', true), {'value': true});
      expect(fromRemoteData(HiveBoxes.profile, 'onboarding_done', {'value': true}, null), true);
      final habit = {
        'id': 'h1',
        'weekdays': <dynamic>[1, 3],
      };
      expect(toRemoteData(HiveBoxes.habits, 'h1', habit), habit);
      expect(
        fromRemoteData(HiveBoxes.habits, 'h1', toRemoteData(HiveBoxes.habits, 'h1', habit), null),
        habit,
      );
    });
  });

  group('decideFirstLogin (data-model.md table)', () {
    FirstLoginPlan decide({bool local = false, String? owner, bool remote = false}) =>
        decideFirstLogin(
          localHasData: local,
          localOwnerUid: owner,
          uid: 'me',
          remoteHasData: remote,
        );

    test('every row', () {
      expect(decide(local: true, owner: 'me', remote: true), FirstLoginPlan.normalSync);
      expect(decide(owner: 'me'), FirstLoginPlan.normalSync);
      expect(decide(local: true, owner: 'other'), FirstLoginPlan.clearThenDownload);
      expect(decide(), FirstLoginPlan.downloadOnly);
      expect(decide(remote: true), FirstLoginPlan.downloadOnly);
      expect(decide(local: true), FirstLoginPlan.uploadGuest);
      expect(decide(local: true, remote: true), FirstLoginPlan.askMergeOrReplace);
    });
  });

  group('authErrorMessage (research.md R10)', () {
    test('maps every code', () {
      expect(authErrorMessage('email-already-in-use'), AppStrings.accountEmailInUse);
      for (final code in ['invalid-credential', 'wrong-password', 'user-not-found']) {
        expect(authErrorMessage(code), AppStrings.accountWrongCredentials, reason: code);
      }
      expect(authErrorMessage('invalid-email'), AppStrings.accountInvalidEmail);
      expect(authErrorMessage('weak-password'), AppStrings.accountWeakPassword);
      expect(authErrorMessage('too-many-requests'), AppStrings.accountTooManyRequests);
      expect(authErrorMessage('network-request-failed'), AppStrings.accountNoNetwork);
      expect(authErrorMessage('requires-recent-login'), AppStrings.accountSignInAgain);
      expect(authErrorMessage('user-token-expired'), AppStrings.accountSignInAgain);
      expect(authErrorMessage('something-new'), AppStrings.accountGenericError);
    });

    test('email and password checks', () {
      expect(looksLikeEmail(' an@example.com '), isTrue);
      expect(looksLikeEmail('an@example'), isFalse);
      expect(looksLikeEmail('an example.com'), isFalse);
      expect(minPasswordLength, 8);
    });
  });
}
