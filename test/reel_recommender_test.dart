// 1.3 Unit test bộ đề xuất reel.
import 'package:flutter_test/flutter_test.dart';
import 'package:focus_app/data/models/event.dart';
import 'package:focus_app/data/models/motivation_type.dart';
import 'package:focus_app/data/models/reel.dart';
import 'package:focus_app/data/models/reel_labels.dart';
import 'package:focus_app/data/models/reel_preferences.dart';
import 'package:focus_app/data/models/user_profile.dart';
import 'package:focus_app/services/reel_recommender.dart';

import 'test_helpers.dart';

final DateTime _now = DateTime(2026, 3, 2, 12);

Reel _reel(
  String id, {
  List<MotivationType> tags = const [],
  List<String> context = const [ReelContext.start],
  List<String> pinFirst = const [],
}) {
  return Reel(
    id: id,
    assetPath: '$id.mp4',
    title: id,
    tags: tags,
    lengthSec: 15,
    context: context,
    pinFirst: pinFirst,
  );
}

UserProfile _profile(List<MotivationType> types) =>
    UserProfile(motivationTypes: types, preferredReelLength: 30);

int _nextEventId = 0;

Event _watched(String reelId, {required Duration ago}) => Event(
  id: 'e${_nextEventId++}',
  type: EventType.reelWatched,
  time: _now.subtract(ago),
  meta: {ReelWatchMeta.reelId: reelId, ReelWatchMeta.secondsWatched: 10},
);

List<String> _ids(List<Reel> reels) => reels.map((reel) => reel.id).toList();

void main() {
  group('Công thức tính điểm', () {
    int score(
      Reel reel, {
      List<MotivationType> types = const [],
      Set<String> recent = const {},
      String? last,
    }) {
      return ReelRecommender.score(
        reel,
        motivationTypes: types,
        recentlyWatchedIds: recent,
        lastWatchedId: last,
      );
    }

    final reel = _reel('a', tags: [MotivationType.money, MotivationType.career]);

    test('Không trùng tag và chưa xem: chỉ được 1 điểm', () {
      expect(score(reel, types: [MotivationType.family]), 1);
    });

    test('Mỗi tag trùng được 3 điểm (spec 015)', () {
      expect(score(reel, types: [MotivationType.money]), 4);
      expect(score(reel, types: [MotivationType.money, MotivationType.career]), 7);
    });

    test('Đã xem trong 24 giờ thì mất điểm cộng', () {
      expect(score(reel, types: [MotivationType.money], recent: {'a'}), 3);
    });

    test('Vừa xem gần nhất thì bị trừ 3 điểm, có thể ra số âm', () {
      expect(score(reel, types: [MotivationType.money], recent: {'a'}, last: 'a'), 0);
      expect(score(reel, recent: {'a'}, last: 'a'), -3);
    });

    test('Vừa xem gần nhất nhưng đã quá 24 giờ thì vẫn được điểm cộng', () {
      expect(score(reel, last: 'a'), -2);
    });
  });

  group('Đề xuất', () {
    test('Chỉ lấy reel đúng ngữ cảnh', () {
      final recommender = ReelRecommender([
        _reel('start_only'),
        _reel('distracted_only', context: [ReelContext.distracted]),
        _reel('both', context: [ReelContext.start, ReelContext.distracted]),
      ]);

      expect(_ids(recommender.recommend(null, ReelContext.start, const [], now: _now)), [
        'start_only',
        'both',
      ]);
      expect(
        _ids(recommender.recommend(null, ReelContext.distracted, const [], now: _now, limit: 3)),
        ['distracted_only', 'both'],
      );
    });

    test('Không có reel đúng ngữ cảnh thì trả về rỗng', () {
      final recommender = ReelRecommender([_reel('a')]);
      expect(
        recommender.recommend(null, ReelContext.distracted, const [], now: _now, limit: 3),
        isEmpty,
      );
    });

    test('Trả về tối đa 3 reel, điểm cao đứng trước', () {
      final recommender = ReelRecommender([
        _reel('zero'),
        _reel('one', tags: [MotivationType.money]),
        _reel('two', tags: [MotivationType.money, MotivationType.career]),
        _reel('other'),
      ]);
      final profile = _profile([MotivationType.money, MotivationType.career]);

      expect(_ids(recommender.recommend(profile, ReelContext.start, const [], now: _now)), [
        'two',
        'one',
        'zero',
      ]);
    });

    test('Bằng điểm thì giữ thứ tự trong danh sách gốc', () {
      final recommender = ReelRecommender([_reel('a'), _reel('b'), _reel('c'), _reel('d')]);
      expect(_ids(recommender.recommend(null, ReelContext.start, const [], now: _now)), [
        'a',
        'b',
        'c',
      ]);
    });

    test('Không reel nào trùng tag thì vẫn trả reel phù hợp ngữ cảnh', () {
      final recommender = ReelRecommender([
        _reel('a', tags: [MotivationType.money]),
        _reel('b', tags: [MotivationType.career]),
      ]);
      final profile = _profile([MotivationType.family]);

      expect(_ids(recommender.recommend(profile, ReelContext.start, const [], now: _now)), [
        'a',
        'b',
      ]);
    });

    test('Chưa có hồ sơ vẫn đề xuất được', () {
      final recommender = ReelRecommender([_reel('a')]);
      expect(_ids(recommender.recommend(null, ReelContext.start, const [], now: _now)), ['a']);
    });

    test('Reel đã xem trong 24 giờ bị xếp sau reel chưa xem', () {
      final recommender = ReelRecommender([_reel('watched'), _reel('fresh'), _reel('last')]);
      final history = [
        _watched('watched', ago: const Duration(hours: 5)),
        _watched('last', ago: const Duration(hours: 1)),
      ];

      expect(_ids(recommender.recommend(null, ReelContext.start, history, now: _now)), [
        'fresh',
        'watched',
        'last',
      ]);
    });

    test('Mốc 24 giờ: còn trong khoảng thì mất điểm cộng, đúng 24 giờ thì được lại', () {
      final recommender = ReelRecommender([_reel('a'), _reel('b')]);
      final newer = [
        _watched('a', ago: const Duration(hours: 23, minutes: 59)),
        _watched('b', ago: const Duration(minutes: 1)),
      ];
      final older = [
        _watched('a', ago: const Duration(hours: 24)),
        _watched('b', ago: const Duration(minutes: 1)),
      ];

      // a: 0 điểm; b: vừa xem gần nhất nên -2.
      expect(_ids(recommender.recommend(null, ReelContext.start, newer, now: _now)), ['a', 'b']);
      // a: 1 điểm vì đã qua 24 giờ.
      final scoreA = ReelRecommender.score(
        recommender.reels.first,
        motivationTypes: const [],
        recentlyWatchedIds: {'b'},
        lastWatchedId: 'b',
      );
      expect(scoreA, 1);
      expect(_ids(recommender.recommend(null, ReelContext.start, older, now: _now)), ['a', 'b']);
    });

    test('Reel vừa xem gần nhất bị trừ điểm dù hợp động lực nhất', () {
      final recommender = ReelRecommender([
        _reel('best', tags: [MotivationType.money]),
        _reel('fresh'),
      ]);
      final profile = _profile([MotivationType.money]);
      final history = [_watched('best', ago: const Duration(minutes: 1))];

      // best: 2 + 0 - 2 = 0; fresh: 0 + 1 = 1.
      expect(_ids(recommender.recommend(profile, ReelContext.start, history, now: _now)), [
        'fresh',
        'best',
      ]);
    });

    test('"Gần nhất" dựa vào thời gian xem, không phụ thuộc thứ tự trong lịch sử', () {
      final recommender = ReelRecommender([_reel('a'), _reel('b')]);
      final history = [
        _watched('b', ago: const Duration(minutes: 1)),
        _watched('a', ago: const Duration(hours: 2)),
      ];

      // a: 0; b: -2. Nếu lấy nhầm phần tử cuối thì a mới bị trừ điểm.
      expect(_ids(recommender.recommend(null, ReelContext.start, history, now: _now)), ['a', 'b']);
    });

    test('Bỏ qua sự kiện khác loại và sự kiện thiếu reelId', () {
      final recommender = ReelRecommender([_reel('a'), _reel('b')]);
      final history = [
        Event(
          id: 'x',
          type: EventType.choseReel,
          time: _now,
          meta: const {ReelWatchMeta.reelId: 'a'},
        ),
        Event(id: 'y', type: EventType.reelWatched, time: _now),
      ];

      // Không có lượt xem hợp lệ nào nên a và b bằng điểm, giữ nguyên thứ tự.
      expect(_ids(recommender.recommend(null, ReelContext.start, history, now: _now)), ['a', 'b']);
    });
  });

  group('Ghim reel (pinFirst)', () {
    const both = [ReelContext.start, ReelContext.distracted];
    final pinnedReel = _reel('ghim', context: both, pinFirst: const [ReelContext.distracted]);
    final reels = [
      _reel('a', tags: [MotivationType.money], context: both),
      _reel('b', tags: [MotivationType.money], context: both),
      pinnedReel,
      _reel('c', tags: [MotivationType.money], context: both),
    ];
    final recommender = ReelRecommender(reels);
    final profile = _profile([MotivationType.money]);

    test('Ngữ cảnh được ghim: reel ghim đứng đầu dù ít điểm nhất', () {
      expect(
        _ids(recommender.recommend(profile, ReelContext.distracted, const [], now: _now, limit: 3)),
        ['ghim', 'a', 'b'],
      );
    });

    test('Reel ghim vẫn đứng đầu dù vừa xem gần nhất', () {
      final history = [_watched('ghim', ago: const Duration(minutes: 1))];
      expect(
        _ids(recommender.recommend(profile, ReelContext.distracted, history, now: _now, limit: 3))
            .first,
        'ghim',
      );
    });

    test('Các reel còn lại vẫn xếp theo điểm, tổng tối đa 3', () {
      // a vừa xem nên bị trừ điểm, b và c lên trước.
      final history = [_watched('a', ago: const Duration(minutes: 1))];
      expect(
        _ids(recommender.recommend(profile, ReelContext.distracted, history, now: _now, limit: 3)),
        ['ghim', 'b', 'c'],
      );
    });

    test('Ngữ cảnh khác không bị ảnh hưởng: reel ghim chỉ xếp theo điểm', () {
      expect(_ids(recommender.recommend(profile, ReelContext.start, const [], now: _now)), [
        'a',
        'b',
        'c',
      ]);
    });

    test('Không reel nào ghim thì kết quả giữ nguyên như trước', () {
      final unpinned = ReelRecommender([
        for (final reel in reels)
          if (reel != pinnedReel) reel,
      ]);
      expect(
        _ids(unpinned.recommend(profile, ReelContext.distracted, const [], now: _now, limit: 3)),
        ['a', 'b', 'c'],
      );
    });
  });

  group('Giới hạn theo ngữ cảnh (spec 002 FR-002)', () {
    test('Trước khi học tối đa 3 reel, sau khi xao nhãng đúng 1 reel', () {
      expect(ReelRecommender.limitFor(ReelContext.start), 3);
      expect(ReelRecommender.limitFor(ReelContext.distracted), 1);
    });

    test('Mặc định dùng giới hạn của ngữ cảnh', () {
      final recommender = ReelRecommender(testReels);
      final profile = _profile([MotivationType.proveYourself]);

      expect(recommender.recommend(profile, ReelContext.start, const [], now: _now), hasLength(3));
      expect(_ids(recommender.recommend(profile, ReelContext.distracted, const [], now: _now)), [
        'r6',
      ]);
    });

    test('Sau khi xao nhãng mà không có reel ghim: 1 reel điểm cao nhất', () {
      final recommender = ReelRecommender([
        _reel('low', context: [ReelContext.distracted]),
        _reel('high', tags: [MotivationType.money], context: [ReelContext.distracted]),
      ]);
      final profile = _profile([MotivationType.money]);

      expect(_ids(recommender.recommend(profile, ReelContext.distracted, const [], now: _now)), [
        'high',
      ]);
    });
  });

  group('Với dữ liệu thật trong reels.json', () {
    final recommender = ReelRecommender(testReels);

    test('r6 "Get back to work!" được ghim cho ngữ cảnh sau khi xao nhãng', () {
      final r6 = testReels.singleWhere((reel) => reel.id == 'r6');
      expect(r6.title, 'Get back to work!');
      expect(r6.pinFirst, [ReelContext.distracted]);
      expect(testReels.where((reel) => reel.pinFirst.isNotEmpty), [r6]);
    });

    test('Sau khi xao nhãng: r6 luôn đứng đầu, kể cả khi vừa xem', () {
      final profile = _profile([MotivationType.proveYourself]);
      final history = [_watched('r6', ago: const Duration(minutes: 1))];

      expect(
        _ids(recommender.recommend(profile, ReelContext.distracted, history, now: _now, limit: 3)),
        ['r6', 'r2', 'r5'],
      );
    });

    test('Trước khi học: r6 không xuất hiện, kết quả không đổi', () {
      final profile = _profile([MotivationType.proveYourself]);
      expect(
        _ids(recommender.recommend(profile, ReelContext.start, const [], now: _now)),
        isNot(contains('r6')),
      );
    });

    test('Hồ sơ tiền bạc + tự do: r4 trùng 2 tag đứng đầu, rồi r2 trùng 1 tag', () {
      final profile = _profile([MotivationType.money, MotivationType.freedom]);
      expect(_ids(recommender.recommend(profile, ReelContext.start, const [], now: _now)), [
        'r4',
        'r2',
        'r1',
      ]);
    });

    test('Vừa xem r4 thì r2 lên đầu', () {
      final profile = _profile([MotivationType.money, MotivationType.freedom]);
      final history = [_watched('r4', ago: const Duration(minutes: 1))];

      // r2: 3 điểm; r4: 4 + 0 - 2 = 2; r1: 1 điểm.
      expect(_ids(recommender.recommend(profile, ReelContext.start, history, now: _now)), [
        'r2',
        'r4',
        'r1',
      ]);
    });

    test('Ngữ cảnh sau khi xao nhãng chỉ có r2, r5, r6', () {
      final profile = _profile([MotivationType.proveYourself]);
      expect(
        _ids(recommender.recommend(profile, ReelContext.distracted, const [], now: _now, limit: 3)),
        unorderedEquals(['r2', 'r5', 'r6']),
      );
    });

    test('Hồ sơ gia đình: kho hiện không có reel tag gia đình nhưng vẫn có reel để xem', () {
      final profile = _profile([MotivationType.family]);
      expect(recommender.recommend(profile, ReelContext.start, const [], now: _now), hasLength(3));
    });
  });

  group('Spec 015: labels, filter and variety (quiz-and-tags-design.md §5)', () {
    Reel labelled(
      String id, {
      List<MotivationType> tags = const [],
      VideoFormat format = VideoFormat.other,
      VideoTone tone = VideoTone.unknown,
      Messenger messenger = Messenger.none,
      List<ReelTheme> themes = const [],
      List<StudyGoal> goals = const [],
      ReelLanguage language = ReelLanguage.vi,
      List<ReelFlag> flags = const [],
      List<String> context = const [ReelContext.start],
    }) => Reel(
      id: id,
      assetPath: '$id.mp4',
      title: id,
      tags: tags,
      lengthSec: 20,
      context: context,
      format: format,
      tone: tone,
      messenger: messenger,
      themes: themes,
      goals: goals,
      language: language,
      flags: flags,
    );

    UserProfile withAnswers(QuizAnswers answers) => UserProfile(
      motivationTypes: ReelPreferences.fromAnswers(answers).motivationTypes,
      preferredReelLength: 30,
      quizAnswers: answers,
    );

    // The user of the worked example (§5.6).
    final example = withAnswers(const {
      'q1': ['q1.prove'],
      'q2': ['q2.career'],
      'q5': ['q5.journey', 'q5.interview'],
      'q7': ['q7.emotional'],
      'q9': ['q9.giveUp'],
      'q10': ['q10.language'],
      'q11': ['q11.loud'],
    });

    int scoreFor(Reel reel, UserProfile profile, {String context = ReelContext.start}) =>
        ReelRecommender.score(
          reel,
          motivationTypes: profile.motivationTypes,
          recentlyWatchedIds: const {},
          lastWatchedId: null,
          preferences: profile.preferences,
          context: context,
        );

    final r7 = labelled(
      'r7',
      tags: [MotivationType.proveYourself, MotivationType.growth],
      format: VideoFormat.journey,
      tone: VideoTone.emotional,
      messenger: Messenger.peer,
      themes: [ReelTheme.consistency, ReelTheme.comeback],
      goals: [StudyGoal.language],
    );
    final r1 = labelled(
      'r1',
      tags: [MotivationType.proveYourself, MotivationType.career],
      format: VideoFormat.interview,
      tone: VideoTone.toughLove,
      themes: [ReelTheme.fearCourage],
    );
    final loud = labelled(
      'rX',
      tags: [MotivationType.proveYourself, MotivationType.career],
      format: VideoFormat.edit,
      tone: VideoTone.hype,
      flags: [ReelFlag.loud],
    );

    test('worked example §5.6: r7 = 13, r1 = 9', () {
      expect(scoreFor(r7, example), 13);
      expect(scoreFor(r1, example), 9);
    });

    test('worked example §5.6: the loud reel is filtered, playlist r7 then r1', () {
      final recommender = ReelRecommender([loud, r1, r7]);
      expect(_ids(recommender.recommend(example, ReelContext.start, const [], now: _now)), [
        'r7',
        'r1',
      ]);
    });

    test('avoided language and pinned reels with an avoided flag are never shown', () {
      final profile = withAnswers(const {
        'q11': ['q11.en', 'q11.sad'],
      });
      final recommender = ReelRecommender([
        labelled('english', language: ReelLanguage.en),
        labelled('subtitled', language: ReelLanguage.enSub),
        Reel(
          id: 'pinnedSad',
          assetPath: 'p.mp4',
          title: 'p',
          tags: const [],
          lengthSec: 10,
          context: const [ReelContext.start],
          pinFirst: const [ReelContext.start],
          flags: const [ReelFlag.sad],
        ),
      ]);
      expect(_ids(recommender.recommend(profile, ReelContext.start, const [], now: _now)), [
        'subtitled',
      ]);
    });

    test('each weight of §5.3 on its own', () {
      final base = withAnswers(const {});
      final plain = labelled('p');
      expect(scoreFor(plain, base), 1, reason: 'only "not watched in 24 h"');

      final themed = withAnswers(const {
        'q9': ['q9.giveUp'],
      });
      final threeThemes = labelled(
        't',
        themes: [ReelTheme.consistency, ReelTheme.discipline, ReelTheme.comeback],
      );
      expect(scoreFor(threeThemes, themed), 1 + 4, reason: 'at most 2 themes count');

      final toned = withAnswers(const {
        'q7': ['q7.calm'],
      });
      expect(scoreFor(labelled('c', tone: VideoTone.calm), toned), 1 + 2);
      expect(scoreFor(labelled('u'), toned), 1, reason: 'unknown tone never matches');

      final voiced = withAnswers(const {
        'q6': ['q6.peer'],
      });
      expect(scoreFor(labelled('m', messenger: Messenger.peer), voiced), 1 + 1);

      final goal = withAnswers(const {
        'q10': ['q10.exam'],
      });
      expect(scoreFor(labelled('g', goals: [StudyGoal.exam]), goal), 1 + 1);
      expect(scoreFor(labelled('g2'), goal), 1, reason: 'a reel without goals gets nothing');

      final formats = withAnswers(const {
        'q5': ['q5.story'],
        'q8': ['q8.edit'],
      });
      expect(scoreFor(labelled('f1', format: VideoFormat.story), formats), 1 + 2);
      expect(scoreFor(labelled('f2', format: VideoFormat.edit), formats), 1 + 1);
    });

    test('after a distraction, digitalDetox and startSmall get the context bonus', () {
      final base = withAnswers(const {});
      final detox = labelled('d', themes: [ReelTheme.digitalDetox]);
      expect(scoreFor(detox, base, context: ReelContext.distracted), 1 + 2);
      expect(scoreFor(detox, base), 1);
    });

    test('variety §5.4: the next slot takes a new format if at most 2 points behind', () {
      final profile = withAnswers(const {
        'q5': ['q5.edit'],
        'q1': ['q1.money'],
      });
      final recommender = ReelRecommender([
        labelled('edit1', format: VideoFormat.edit, tags: [MotivationType.money]),
        labelled('edit2', format: VideoFormat.edit, tags: [MotivationType.money]),
        labelled('story', format: VideoFormat.story, tags: [MotivationType.money]),
        labelled('tips', format: VideoFormat.tips),
      ]);
      // edit1 = edit2 = 1 + 3 + 2 = 6, story = 4, tips = 1.
      expect(_ids(recommender.recommend(profile, ReelContext.start, const [], now: _now)), [
        'edit1',
        'story',
        'edit2',
      ]);
    });

    test('variety §5.4: a new format more than 2 points behind does not jump ahead', () {
      final profile = withAnswers(const {
        'q5': ['q5.edit'],
        'q1': ['q1.money'],
      });
      final recommender = ReelRecommender([
        labelled('edit1', format: VideoFormat.edit, tags: [MotivationType.money]),
        labelled('edit2', format: VideoFormat.edit, tags: [MotivationType.money]),
        labelled('tips', format: VideoFormat.tips),
      ]);
      expect(_ids(recommender.recommend(profile, ReelContext.start, const [], now: _now)), [
        'edit1',
        'edit2',
        'tips',
      ]);
    });

    test('without answers: reasons first, then a new format before a repeated one', () {
      final recommender = ReelRecommender([
        labelled('a', format: VideoFormat.edit),
        labelled('b', format: VideoFormat.edit, tags: [MotivationType.family]),
        labelled('c', format: VideoFormat.story),
      ]);
      expect(
        _ids(
          recommender.recommend(
            _profile([MotivationType.family]),
            ReelContext.start,
            const [],
            now: _now,
          ),
        ),
        ['b', 'c', 'a'],
      );
    });
  });
}
