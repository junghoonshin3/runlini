import 'dart:math' as math;

import 'package:runlini/features/run_tracking/service/run_calorie_calculator.dart';
import 'package:runlini/features/run_tracking/service/run_route_segmenter.dart';
import 'package:runlini/features/run_tracking/types/live_run_metrics.dart';
import 'package:runlini/features/run_tracking/types/run_playback_state.dart';

class LiveRunMetricsCalculator {
  const LiveRunMetricsCalculator({
    this.calorieCalculator = const RunCalorieCalculator(),
    this.routeSegmenter = const RunRouteSegmenter(),
  });

  final RunCalorieCalculator calorieCalculator;
  final RunRouteSegmenter routeSegmenter;

  LiveRunMetrics calculate({
    required RunPlaybackState playbackState,
    required DateTime now,
    required double? bodyWeightKg,
  }) {
    if (!playbackState.hasActiveSession) {
      return const LiveRunMetrics(
        distanceKm: 0,
        elapsedMs: 0,
        averagePaceSecPerKm: null,
        averageSpeedKmh: 0,
        caloriesKcal: null,
        isPaused: false,
      );
    }

    final elapsedMs = math.max(0, playbackState.elapsedAt(now));
    final distanceMeters = routeSegmenter
        .segment(playbackState.recordedPoints)
        .distanceM;
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
      caloriesKcal: calorieCalculator.activeCaloriesKcal(
        distanceM: distanceMeters,
        bodyWeightKg: bodyWeightKg,
      ),
      isPaused: playbackState.isPaused,
    );
  }
}
