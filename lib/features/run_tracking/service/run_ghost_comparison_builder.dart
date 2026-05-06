import 'dart:math' as math;

import 'package:runlini/features/run_tracking/service/run_session_detail_calculator.dart';
import 'package:runlini/features/run_tracking/types/run_session.dart';
import 'package:runlini/features/run_tracking/types/run_session_ghost_summary.dart';

class RunGhostComparisonBuilder {
  const RunGhostComparisonBuilder({
    this.detailCalculator = const RunSessionDetailCalculator(),
  });

  final RunSessionDetailCalculator detailCalculator;

  RunGhostComparison build({
    required RunSession currentSession,
    required RunSessionGhostSummary summary,
    RunSession? ghostSession,
  }) {
    if (ghostSession == null ||
        summary.result == RunSessionGhostResult.offRoute) {
      return RunGhostComparison(summary: summary);
    }

    final currentDetail = detailCalculator.calculate(currentSession);
    final ghostDetail = detailCalculator.calculate(ghostSession);
    final ghostDistanceM = ghostDetail.distanceKm * 1000;
    if (ghostSession.durationMs <= 0 || ghostDistanceM <= 0) {
      return RunGhostComparison(summary: summary, ghostSession: ghostSession);
    }

    final courseDurationMs = math.max(
      0,
      ghostSession.durationMs - summary.timeGapMs,
    );
    final courseDistanceKm = ghostDistanceM / 1000;
    final currentPaceSecPerKm = courseDurationMs <= 0
        ? null
        : (courseDurationMs / 1000) / courseDistanceKm;
    final ghostPaceSecPerKm =
        (ghostSession.durationMs / 1000) / courseDistanceKm;
    final currentSpeedKmh = _speedKmh(courseDistanceKm, courseDurationMs);
    final ghostSpeedKmh = _speedKmh(courseDistanceKm, ghostSession.durationMs);
    final currentDistanceM = currentDetail.distanceKm * 1000;

    return RunGhostComparison(
      summary: summary,
      ghostSession: ghostSession,
      currentCourseDurationMs: courseDurationMs,
      ghostCourseDurationMs: ghostSession.durationMs,
      comparedDistanceM: ghostDistanceM,
      currentCoursePaceSecPerKm: currentPaceSecPerKm,
      ghostPaceSecPerKm: ghostPaceSecPerKm,
      currentCourseSpeedKmh: currentSpeedKmh,
      ghostSpeedKmh: ghostSpeedKmh,
      currentDistanceM: currentDistanceM,
      ghostDistanceM: ghostDistanceM,
      extraDurationMs: math.max(
        0,
        currentSession.durationMs - courseDurationMs,
      ),
      extraDistanceM: math.max(0, currentDistanceM - ghostDistanceM),
      currentAverageCadenceSpm: currentDetail.averageCadenceSpm,
      ghostAverageCadenceSpm: ghostDetail.averageCadenceSpm,
      currentElevationGainM: currentDetail.elevationGainM,
      ghostElevationGainM: ghostDetail.elevationGainM,
    );
  }

  double? _speedKmh(double distanceKm, int durationMs) {
    if (distanceKm <= 0 || durationMs <= 0) {
      return null;
    }
    return distanceKm / (durationMs / Duration.millisecondsPerHour);
  }
}

class RunGhostComparison {
  const RunGhostComparison({
    required this.summary,
    this.ghostSession,
    this.currentCourseDurationMs,
    this.ghostCourseDurationMs,
    this.comparedDistanceM,
    this.currentCoursePaceSecPerKm,
    this.ghostPaceSecPerKm,
    this.currentCourseSpeedKmh,
    this.ghostSpeedKmh,
    this.currentDistanceM,
    this.ghostDistanceM,
    this.extraDurationMs = 0,
    this.extraDistanceM = 0,
    this.currentAverageCadenceSpm,
    this.ghostAverageCadenceSpm,
    this.currentElevationGainM,
    this.ghostElevationGainM,
  });

  final RunSessionGhostSummary summary;
  final RunSession? ghostSession;
  final int? currentCourseDurationMs;
  final int? ghostCourseDurationMs;
  final double? comparedDistanceM;
  final double? currentCoursePaceSecPerKm;
  final double? ghostPaceSecPerKm;
  final double? currentCourseSpeedKmh;
  final double? ghostSpeedKmh;
  final double? currentDistanceM;
  final double? ghostDistanceM;
  final int extraDurationMs;
  final double extraDistanceM;
  final double? currentAverageCadenceSpm;
  final double? ghostAverageCadenceSpm;
  final double? currentElevationGainM;
  final double? ghostElevationGainM;

  bool get hasCourseMetrics =>
      currentCourseDurationMs != null &&
      ghostCourseDurationMs != null &&
      comparedDistanceM != null;
}
