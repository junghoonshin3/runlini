import 'package:flutter_test/flutter_test.dart';
import 'package:runlini/features/run_tracking/service/run_record_race_comparison_builder.dart';
import 'package:runlini/features/run_tracking/types/run_session.dart';
import 'package:runlini/features/run_tracking/types/run_session_record_race_summary.dart';

void main() {
  const builder = RunRecordRaceComparisonBuilder();

  test('builds faster course metrics from a positive time gap', () {
    final comparison = builder.build(
      currentSession: _session(durationMs: 700000, distanceM: 1200),
      recordRaceSession: _session(
        id: 'recordRace',
        durationMs: 600000,
        distanceM: 1000,
      ),
      summary: _summary(timeGapMs: 12000),
    );

    expect(comparison.hasCourseMetrics, isTrue);
    expect(comparison.currentCourseDurationMs, 588000);
    expect(comparison.recordRaceCourseDurationMs, 600000);
    expect(comparison.currentCoursePaceSecPerKm, closeTo(588, 0.001));
    expect(comparison.recordRacePaceSecPerKm, closeTo(600, 0.001));
    expect(
      comparison.currentCourseSpeedKmh,
      greaterThan(comparison.recordRaceSpeedKmh!),
    );
  });

  test('uses saved race result instead of full continued duration', () {
    final comparison = builder.build(
      currentSession: _session(durationMs: 900000, distanceM: 1400),
      recordRaceSession: _session(
        id: 'recordRace',
        durationMs: 600000,
        distanceM: 1000,
      ),
      summary: _summary(timeGapMs: -47000),
    );

    expect(comparison.currentCourseDurationMs, 647000);
    expect(comparison.extraDurationMs, 253000);
    expect(comparison.extraDistanceM, 400);
  });

  test(
    'falls back to summary only without the original recordRace session',
    () {
      final comparison = builder.build(
        currentSession: _session(),
        summary: _summary(timeGapMs: 12000),
      );

      expect(comparison.hasCourseMetrics, isFalse);
      expect(comparison.summary.timeGapMs, 12000);
    },
  );
}

RunSession _session({
  String id = 'current',
  int durationMs = 600000,
  double distanceM = 1000,
}) {
  return RunSession(
    id: id,
    startedAt: DateTime.utc(2026, 4, 20, 6),
    durationMs: durationMs,
    distanceM: distanceM,
    sourceSummary: 'fixture:$id',
    points: const [],
  );
}

RunSessionRecordRaceSummary _summary({required int timeGapMs}) {
  return RunSessionRecordRaceSummary(
    result: timeGapMs >= 0
        ? RunSessionRecordRaceResult.ahead
        : RunSessionRecordRaceResult.behind,
    timeGapMs: timeGapMs,
    distanceGapM: 0,
    recordRaceSessionId: 'recordRace',
    recordRaceLabel: 'Morning RecordRace',
  );
}
