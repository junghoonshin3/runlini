import 'dart:math' as math;

import 'package:runlini/features/run_tracking/service/run_session_detail_calculator.dart';
import 'package:runlini/features/run_tracking/types/run_session.dart';
import 'package:runlini/features/run_tracking/types/run_session_record_race_summary.dart';

class RunRecordRaceComparisonBuilder {
  const RunRecordRaceComparisonBuilder({
    this.detailCalculator = const RunSessionDetailCalculator(),
  });

  final RunSessionDetailCalculator detailCalculator;

  RunRecordRaceComparison build({
    required RunSession currentSession,
    required RunSessionRecordRaceSummary summary,
    RunSession? recordRaceSession,
  }) {
    if (recordRaceSession == null ||
        summary.result == RunSessionRecordRaceResult.offRoute) {
      return RunRecordRaceComparison(summary: summary);
    }

    final currentDetail = detailCalculator.calculate(currentSession);
    final recordRaceDetail = detailCalculator.calculate(recordRaceSession);
    final recordRaceDistanceM = recordRaceDetail.distanceKm * 1000;
    if (recordRaceSession.durationMs <= 0 || recordRaceDistanceM <= 0) {
      return RunRecordRaceComparison(
        summary: summary,
        recordRaceSession: recordRaceSession,
      );
    }

    final courseDurationMs = math.max(
      0,
      recordRaceSession.durationMs - summary.timeGapMs,
    );
    final courseDistanceKm = recordRaceDistanceM / 1000;
    final currentPaceSecPerKm = courseDurationMs <= 0
        ? null
        : (courseDurationMs / 1000) / courseDistanceKm;
    final recordRacePaceSecPerKm =
        (recordRaceSession.durationMs / 1000) / courseDistanceKm;
    final currentSpeedKmh = _speedKmh(courseDistanceKm, courseDurationMs);
    final recordRaceSpeedKmh = _speedKmh(
      courseDistanceKm,
      recordRaceSession.durationMs,
    );
    final currentDistanceM = currentDetail.distanceKm * 1000;

    return RunRecordRaceComparison(
      summary: summary,
      recordRaceSession: recordRaceSession,
      currentCourseDurationMs: courseDurationMs,
      recordRaceCourseDurationMs: recordRaceSession.durationMs,
      comparedDistanceM: recordRaceDistanceM,
      currentCoursePaceSecPerKm: currentPaceSecPerKm,
      recordRacePaceSecPerKm: recordRacePaceSecPerKm,
      currentCourseSpeedKmh: currentSpeedKmh,
      recordRaceSpeedKmh: recordRaceSpeedKmh,
      currentDistanceM: currentDistanceM,
      recordRaceDistanceM: recordRaceDistanceM,
      extraDurationMs: math.max(
        0,
        currentSession.durationMs - courseDurationMs,
      ),
      extraDistanceM: math.max(0, currentDistanceM - recordRaceDistanceM),
      currentAverageCadenceSpm: currentDetail.averageCadenceSpm,
      recordRaceAverageCadenceSpm: recordRaceDetail.averageCadenceSpm,
      currentElevationGainM: currentDetail.elevationGainM,
      recordRaceElevationGainM: recordRaceDetail.elevationGainM,
    );
  }

  double? _speedKmh(double distanceKm, int durationMs) {
    if (distanceKm <= 0 || durationMs <= 0) {
      return null;
    }
    return distanceKm / (durationMs / Duration.millisecondsPerHour);
  }
}

class RunRecordRaceComparison {
  const RunRecordRaceComparison({
    required this.summary,
    this.recordRaceSession,
    this.currentCourseDurationMs,
    this.recordRaceCourseDurationMs,
    this.comparedDistanceM,
    this.currentCoursePaceSecPerKm,
    this.recordRacePaceSecPerKm,
    this.currentCourseSpeedKmh,
    this.recordRaceSpeedKmh,
    this.currentDistanceM,
    this.recordRaceDistanceM,
    this.extraDurationMs = 0,
    this.extraDistanceM = 0,
    this.currentAverageCadenceSpm,
    this.recordRaceAverageCadenceSpm,
    this.currentElevationGainM,
    this.recordRaceElevationGainM,
  });

  final RunSessionRecordRaceSummary summary;
  final RunSession? recordRaceSession;
  final int? currentCourseDurationMs;
  final int? recordRaceCourseDurationMs;
  final double? comparedDistanceM;
  final double? currentCoursePaceSecPerKm;
  final double? recordRacePaceSecPerKm;
  final double? currentCourseSpeedKmh;
  final double? recordRaceSpeedKmh;
  final double? currentDistanceM;
  final double? recordRaceDistanceM;
  final int extraDurationMs;
  final double extraDistanceM;
  final double? currentAverageCadenceSpm;
  final double? recordRaceAverageCadenceSpm;
  final double? currentElevationGainM;
  final double? recordRaceElevationGainM;

  bool get hasCourseMetrics =>
      currentCourseDurationMs != null &&
      recordRaceCourseDurationMs != null &&
      comparedDistanceM != null;
}
