// 1.2 Reel labels (spec 015, data-model.md Reel labels and Reel.*): defaults and old catalogues.
import 'package:flutter_test/flutter_test.dart';
import 'package:focus_app/data/models/motivation_type.dart';
import 'package:focus_app/data/models/reel.dart';
import 'package:focus_app/data/models/reel_labels.dart';

Map<String, dynamic> _base() => {
  'id': 'r',
  'assetPath': 'assets/reels/r.mp4',
  'title': 'Reel',
  'lengthSec': 20,
  'context': ['start'],
};

void main() {
  test('fromName: unknown and null fall back to the default', () {
    expect(VideoFormat.fromName('journey'), VideoFormat.journey);
    expect(VideoFormat.fromName('hologram'), VideoFormat.other);
    expect(VideoFormat.fromName(null), VideoFormat.other);
    expect(VideoTone.fromName('loudest'), VideoTone.unknown);
    expect(Messenger.fromName(null), Messenger.none);
    expect(Origin.fromName('mars'), Origin.vietnamese);
    expect(ReelLanguage.fromName('fr'), ReelLanguage.vi);
  });

  test('a catalogue entry from before spec 015 gets every default', () {
    final reel = Reel.fromMap({
      ..._base(),
      'tags': ['money', 'family'],
    });
    expect(reel.tags, [MotivationType.money, MotivationType.family]);
    expect(reel.format, VideoFormat.other);
    expect(reel.tone, VideoTone.unknown);
    expect(reel.messenger, Messenger.none);
    expect(reel.origin, Origin.vietnamese);
    expect(reel.themes, isEmpty);
    expect(reel.goals, isEmpty);
    expect(reel.language, ReelLanguage.vi);
    expect(reel.flags, isEmpty);
  });

  test('a labelled entry is read field by field; motivation wins over tags', () {
    final reel = Reel.fromMap({
      ..._base(),
      'tags': ['money'],
      'motivation': ['proveYourself', 'growth'],
      'format': 'journey',
      'tone': 'emotional',
      'messenger': 'peer',
      'origin': 'international',
      'theme': ['consistency', 'comeback'],
      'goal': ['language'],
      'language': 'enSub',
      'flags': ['sad'],
    });
    expect(reel.tags, [MotivationType.proveYourself, MotivationType.growth]);
    expect(reel.format, VideoFormat.journey);
    expect(reel.tone, VideoTone.emotional);
    expect(reel.messenger, Messenger.peer);
    expect(reel.origin, Origin.international);
    expect(reel.themes, [ReelTheme.consistency, ReelTheme.comeback]);
    expect(reel.goals, [StudyGoal.language]);
    expect(reel.language, ReelLanguage.enSub);
    expect(reel.flags, [ReelFlag.sad]);
  });

  test('unknown names in lists are dropped, duplicates kept once, no crash', () {
    final reel = Reel.fromMap({
      ..._base(),
      'motivation': ['career', 'fame', 'career'],
      'theme': ['startSmall', 'tomorrow'],
      'flags': ['glitter'],
    });
    expect(reel.tags, [MotivationType.career]);
    expect(reel.themes, [ReelTheme.startSmall]);
    expect(reel.flags, isEmpty);
  });
}
