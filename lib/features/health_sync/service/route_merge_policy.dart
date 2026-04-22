import 'package:runlini/features/run_tracking/types/run_point.dart';

class RouteMergePolicy {
  const RouteMergePolicy();

  List<RunPoint> merge({
    required List<RunPoint> primaryPoints,
    required List<RunPoint> secondaryPoints,
  }) {
    final mergedByTimestamp = <int, RunPoint>{
      for (final point in primaryPoints) point.timestampRelMs: point,
    };

    for (final point in secondaryPoints) {
      mergedByTimestamp[point.timestampRelMs] = point;
    }

    final orderedTimestamps = mergedByTimestamp.keys.toList()..sort();
    return orderedTimestamps
        .map((int timestamp) => mergedByTimestamp[timestamp]!)
        .toList(growable: false);
  }
}
