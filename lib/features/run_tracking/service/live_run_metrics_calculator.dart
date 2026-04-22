import 'dart:math' as math;

import 'package:latlong2/latlong.dart';
import 'package:runlini/features/run_tracking/types/live_run_metrics.dart';
import 'package:runlini/features/run_tracking/types/run_playback_state.dart';
import 'package:runlini/features/run_tracking/types/run_point.dart';

class LiveRunMetricsCalculator {
  const LiveRunMetricsCalculator();

  static const Distance _distance = Distance();

  LiveRunMetrics calculate({
    required RunPlaybackState playbackState,
    required DateTime now,
  }) {
    if (!playbackState.hasActiveSession) {
      return const LiveRunMetrics(
        distanceKm: 0,
        elapsedMs: 0,
        averagePaceSecPerKm: null,
        averageSpeedKmh: 0,
        caloriesLabel: '-- kcal',
        isPaused: false,
      );
    }

    final elapsedMs = math.max(0, playbackState.elapsedAt(now));
    final distanceMeters = _calculateDistanceMeters(
      playbackState.recordedPoints,
    );
    final distanceKm = distanceMeters / 1000;
    final averagePaceSecPerKm = distanceKm <= 0 || elapsedMs <= 0
        ? null
        : (elapsedMs / 1000) / distanceKm;
    final averageSpeedKmh = distanceKm <= 0 || elapsedMs <= 0
        ? 0.0
        : distanceKm / (elapsedMs / Duration.millisecondsPerHour);

    return LiveRunMetrics(
      distanceKm: distanceKm,
      elapsedMs: elapsedMs,
      averagePaceSecPerKm: averagePaceSecPerKm,
      averageSpeedKmh: averageSpeedKmh,
      caloriesLabel: '-- kcal',
      isPaused: playbackState.isPaused,
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
