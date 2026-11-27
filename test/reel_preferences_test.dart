// 1.1 ReelPreferences.fromAnswers (spec 015, data-model.md ReelPreferences.*, design §5.1).
import 'package:flutter_test/flutter_test.dart';
import 'package:focus_app/data/models/motivation_type.dart';
import 'package:focus_app/data/models/reel_labels.dart';
import 'package:focus_app/data/models/reel_preferences.dart';
import 'package:focus_app/data/models/user_profile.dart';

void main() {
  test('no answers: no preference anywhere', () {
    final prefs = ReelPreferences.fromAnswers(const {});
    expect(prefs.motivationTypes, isEmpty);
    expect(prefs.formats, isEmpty);
    expect(prefs.tone, VideoTone.unknown);
    expect(prefs.messengers, isEmpty);
    expect(prefs.themes, isEmpty);
    expect(prefs.goal, isNull);
    expect(prefs.avoidFlags, isEmpty);
    expect(prefs.avoidLanguages, isEmpty);
  });

  test('reasons: top 2 over q1..q4, earliest wins ties', () {
    final prefs = ReelPreferences.fromAnswers(const {
      'q1': ['q1.growth'],
      'q2': ['q2.career'],
      'q3': ['q3.career'],
      'q4': ['q4.money'],
    });
    expect(prefs.motivationTypes, [MotivationType.career, MotivationType.growth]);
  });

  test('legacy reasons are kept when q1 and q2 are unanswered', () {
    final legacy = [MotivationType.family, MotivationType.money];
    expect(ReelPreferences.fromAnswers(const {}, legacyTypes: legacy).motivationTypes, legacy);
    // Only the extra part answered: old reasons count as earlier answers.
    final prefs = ReelPreferences.fromAnswers(const {
      'q3': ['q3.growth'],
      'q4': ['q4.growth'],
    }, legacyTypes: legacy);
    expect(prefs.motivationTypes, [MotivationType.growth, MotivationType.family]);
  });

  test('legacy reasons are ignored once q1 or q2 is answered', () {
    final prefs = ReelPreferences.fromAnswers(
      const {
        'q1': ['q1.freedom'],
      },
      legacyTypes: const [MotivationType.money],
    );
    expect(prefs.motivationTypes, [MotivationType.freedom]);
  });

  test('formats: q5 +2 per format, q8 +1; favourite +2, liked +1', () {
    final prefs = ReelPreferences.fromAnswers(const {
      'q5': ['q5.edit', 'q5.journey'],
      'q8': ['q8.journey'],
    });
    expect(prefs.formats, [VideoFormat.journey, VideoFormat.edit, VideoFormat.quote]);
    expect(prefs.formatBonus(VideoFormat.journey), 2);
    expect(prefs.formatBonus(VideoFormat.edit), 1);
    expect(prefs.formatBonus(VideoFormat.quote), 1);
    expect(prefs.formatBonus(VideoFormat.story), 0);
    expect(prefs.formatBonus(VideoFormat.other), 0);
  });

  test('two favourites with equal points both get +2', () {
    final prefs = ReelPreferences.fromAnswers(const {
      'q5': ['q5.interview', 'q5.story'],
    });
    expect(prefs.formatBonus(VideoFormat.interview), 2);
    expect(prefs.formatBonus(VideoFormat.story), 2);
  });

  test('tone: q7, else the tone of the q8 video', () {
    expect(
      ReelPreferences.fromAnswers(const {
        'q7': ['q7.calm'],
        'q8': ['q8.edit'],
      }).tone,
      VideoTone.calm,
    );
    expect(
      ReelPreferences.fromAnswers(const {
        'q7': [],
        'q8': ['q8.edit'],
      }).tone,
      VideoTone.hype,
    );
  });

  test('messengers, themes, goal and dislikes', () {
    final prefs = ReelPreferences.fromAnswers(const {
      'q6': ['q6.peer', 'q6.expert'],
      'q9': ['q9.phone', 'q9.giveUp'],
      'q10': ['q10.language'],
      'q11': ['q11.loud', 'q11.en'],
    });
    expect(prefs.messengers, [Messenger.expert, Messenger.peer]);
    expect(prefs.themes, {
      ReelTheme.digitalDetox,
      ReelTheme.consistency,
      ReelTheme.discipline,
      ReelTheme.comeback,
    });
    expect(prefs.goal, StudyGoal.language);
    expect(prefs.avoidFlags, {ReelFlag.loud});
    expect(prefs.avoidLanguages, {ReelLanguage.en});
  });

  test('unknown question and answer ids are ignored', () {
    final prefs = ReelPreferences.fromAnswers(const {
      'q99': ['q99.x'],
      'q7': ['q7.shout'],
      'q10': ['q10.exam', 'q10.mars'],
    });
    expect(prefs.tone, VideoTone.unknown);
    expect(prefs.goal, StudyGoal.exam);
  });

  test('UserProfile keeps answers through toMap/fromMap; old maps load without them', () {
    const profile = UserProfile(
      motivationTypes: [MotivationType.career],
      preferredReelLength: 30,
      quizAnswers: {
        'q7': ['q7.funny'],
      },
    );
    final restored = UserProfile.fromMap(Map<String, dynamic>.from(profile.toMap()));
    expect(restored.quizAnswers, {
      'q7': ['q7.funny'],
    });
    expect(restored.preferences.tone, VideoTone.funny);

    final old = UserProfile.fromMap({
      'motivationTypes': ['money', 'somethingNew'],
      'preferredReelLength': 30,
    });
    expect(old.motivationTypes, [MotivationType.money]);
    expect(old.quizAnswers, isEmpty);
    expect(old.preferences.motivationTypes, [MotivationType.money]);
  });
}
