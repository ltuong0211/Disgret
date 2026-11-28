// 5.6 Quán San Hô: the chosen study place, kept in the profile box (spec 006 FR-001).
import 'package:hive/hive.dart';

import '../hive_boxes.dart';
import '../sync_journal.dart';
import '../study_place.dart';

class StudyPlaceRepository {
  static const String _key = 'study_place';

  Box<dynamic> get _box => Hive.box<dynamic>(HiveBoxes.profile);

  /// The café until the student chooses otherwise (lead's decision, ADR-0011).
  StudyPlace get place => StudyPlace.tryParse(_box.get(_key)) ?? StudyPlace.cafe;

  Future<void> save(StudyPlace place) async {
    await _box.put(_key, place.name);
    // 6.3 Synced to the account (spec 016).
    await SyncJournal.shared.touch(HiveBoxes.profile, _key);
  }
}
