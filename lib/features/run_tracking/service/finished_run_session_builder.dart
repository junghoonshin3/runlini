import 'package:latlong2/latlong.dart';
import 'package:runlini/features/run_tracking/types/run_point.dart';
import 'package:runlini/features/run_tracking/types/run_session.dart';
import 'package:runlini/features/run_tracking/types/run_session_ghost_summary.dart';

class FinishedRunSessionBuilder {
  const FinishedRunSessionBuilder();

  static const Distance _distance = Distance();

  RunSession build({
    required String id,
    required DateTime startedAt,
    required DateTime endedAt,
    required int durationMs,
    required List<RunPoint> recordedPoints,
    RunSessionGhostSummary? ghostSummary,
  }) {
    return RunSession(
      id: id,
      startedAt: startedAt,
      endedAt: endedAt,
      distanceM: _calculateDistanceMeters(recordedPoints),
      durationMs: durationMs < 0 ? 0 : durationMs,
      sourceSummary: 'device:gps',
      points: List<RunPoint>.unmodifiable(recordedPoints),
      ghostSummary: ghostSummary,
    );
  }

  double _calculateDistanceMeters(List<RunPoint> recordedPoints) {
    if (recordedPoints.length < 2) {
      return 0;
    }

    var totalMeters = 0.0;
    for (var index = 1; index < recordedPoints.length; index += 1) {
      final previous = recordedPoints[index - 1];
      final current = recordedPoints[index];
      totalMeters += _distance.as(
        LengthUnit.Meter,
        LatLng(previous.latitude, previous.longitude),
        LatLng(current.latitude, current.longitude),
      );
    }

    return totalMeters;
  }
}
