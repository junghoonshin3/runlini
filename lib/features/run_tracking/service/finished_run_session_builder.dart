import 'package:runlini/features/run_tracking/service/run_calorie_calculator.dart';
import 'package:runlini/features/run_tracking/service/run_route_segmenter.dart';
import 'package:runlini/features/run_tracking/types/run_point.dart';
import 'package:runlini/features/run_tracking/types/run_session.dart';
import 'package:runlini/features/run_tracking/types/run_session_ghost_summary.dart';

class FinishedRunSessionBuilder {
  const FinishedRunSessionBuilder({
    this.calorieCalculator = const RunCalorieCalculator(),
    this.routeSegmenter = const RunRouteSegmenter(),
  });

  final RunCalorieCalculator calorieCalculator;
  final RunRouteSegmenter routeSegmenter;

  RunSession build({
    required String id,
    required DateTime startedAt,
    required DateTime endedAt,
    required int durationMs,
    required List<RunPoint> recordedPoints,
    required double? bodyWeightKg,
    int cadenceStepCount = 0,
    RunSessionGhostSummary? ghostSummary,
  }) {
    final distanceM = routeSegmenter.segment(recordedPoints).distanceM;
    final safeDurationMs = durationMs < 0 ? 0 : durationMs;
    return RunSession(
      id: id,
      startedAt: startedAt,
      endedAt: endedAt,
      distanceM: distanceM,
      durationMs: safeDurationMs,
      sourceSummary: 'device:gps',
      points: List<RunPoint>.unmodifiable(recordedPoints),
      averageCadenceSpm: _averageCadence(
        stepCount: cadenceStepCount,
        durationMs: safeDurationMs,
      ),
      caloriesKcal: calorieCalculator.activeCaloriesKcal(
        distanceM: distanceM,
        bodyWeightKg: bodyWeightKg,
      ),
      ghostSummary: ghostSummary,
    );
  }

  double? _averageCadence({required int stepCount, required int durationMs}) {
    if (stepCount <= 0 || durationMs <= 0) {
      return null;
    }
    return stepCount / (durationMs / Duration.millisecondsPerMinute);
  }
}
