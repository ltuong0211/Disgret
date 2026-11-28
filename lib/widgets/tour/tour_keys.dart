// 5.7 Hướng dẫn lần đầu (spec 022): one key per feature the tour points at, so the overlay can find
// where it is on screen. Only Hôm nay and the tab bar carry them.
import 'package:material_ui/material_ui.dart';

import '../../data/guided_tour.dart';

class TourKeys {
  TourKeys._();

  static final Map<TourTarget, GlobalKey> _keys = {
    for (final target in TourTarget.values) target: GlobalKey(debugLabel: 'tour-${target.name}'),
  };

  static GlobalKey of(TourTarget target) => _keys[target]!;

  /// Wraps [child] so the tour can spotlight it.
  static Widget mark(TourTarget target, Widget child) =>
      KeyedSubtree(key: of(target), child: child);
}
