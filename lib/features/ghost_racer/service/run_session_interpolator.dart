import 'package:runlini/features/run_tracking/types/run_point.dart';
import 'package:runlini/features/run_tracking/types/run_session.dart';

RunPoint interpolateRunPoint({
  required RunSession session,
  required int elapsedMs,
}) {
  final clampedElapsedMs = elapsedMs.clamp(0, session.durationMs).toInt();
  final points = session.points;

  if (points.isEmpty) {
    throw StateError('Cannot interpolate a session with no points.');
  }

  if (clampedElapsedMs <= points.first.timestampRelMs) {
    return points.first;
  }

  if (clampedElapsedMs >= points.last.timestampRelMs) {
    return points.last;
  }

  for (var index = 0; index < points.length - 1; index++) {
    final current = points[index];
    final next = points[index + 1];
    final isInsideSegment =
        clampedElapsedMs >= current.timestampRelMs &&
        clampedElapsedMs <= next.timestampRelMs;

    if (!isInsideSegment) {
      continue;
    }

    final segmentDuration = next.timestampRelMs - current.timestampRelMs;
    final ratio = (clampedElapsedMs - current.timestampRelMs) / segmentDuration;
    final interpolatedPace =
        current.paceSecPerKm == null || next.paceSecPerKm == null
        ? current.paceSecPerKm ?? next.paceSecPerKm
        : current.paceSecPerKm! +
              ((next.paceSecPerKm! - current.paceSecPerKm!) * ratio);

    return RunPoint(
      latitude: current.latitude + ((next.latitude - current.latitude) * ratio),
      longitude:
          current.longitude + ((next.longitude - current.longitude) * ratio),
      timestampRelMs: clampedElapsedMs,
      paceSecPerKm: interpolatedPace,
      source: current.source,
    );
  }

  return points.last;
}
