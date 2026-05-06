import 'package:flutter_test/flutter_test.dart';
import 'package:runlini/features/run_tracking/service/run_ghost_comparison_builder.dart';
import 'package:runlini/features/run_tracking/types/run_session.dart';
import 'package:runlini/features/run_tracking/types/run_session_ghost_summary.dart';

void main() {
  const builder = RunGhostComparisonBuilder();

  test('builds faster course metrics from a positive time gap', () {
    final comparison = builder.build(
      currentSession: _session(durationMs: 700000, distanceM: 1200),
      ghostSession: _session(id: 'ghost', durationMs: 600000, distanceM: 1000),
      summary: _summary(timeGapMs: 12000),
    );

    expect(comparison.hasCourseMetrics, isTrue);
    expect(comparison.currentCourseDurationMs, 588000);
    expect(comparison.ghostCourseDurationMs, 600000);
    expect(comparison.currentCoursePaceSecPerKm, closeTo(588, 0.001));
    expect(comparison.ghostPaceSecPerKm, closeTo(600, 0.001));
    expect(
      comparison.currentCourseSpeedKmh,
      greaterThan(comparison.ghostSpeedKmh!),
    );
  });

  test('uses saved race result instead of full continued duration', () {
    final comparison = builder.build(
      currentSession: _session(durationMs: 900000, distanceM: 1400),
      ghostSession: _session(id: 'ghost', durationMs: 600000, distanceM: 1000),
      summary: _summary(timeGapMs: -47000),
    );

    expect(comparison.currentCourseDurationMs, 647000);
    expect(comparison.extraDurationMs, 253000);
    expect(comparison.extraDistanceM, 400);
  });

  test('falls back to summary only without the original ghost session', () {
    final comparison = builder.build(
      currentSession: _session(),
      summary: _summary(timeGapMs: 12000),
    );

    expect(comparison.hasCourseMetrics, isFalse);
    expect(comparison.summary.timeGapMs, 12000);
  });
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

RunSessionGhostSummary _summary({required int timeGapMs}) {
  return RunSessionGhostSummary(
    result: timeGapMs >= 0
        ? RunSessionGhostResult.ahead
        : RunSessionGhostResult.behind,
    timeGapMs: timeGapMs,
    distanceGapM: 0,
    ghostSessionId: 'ghost',
    ghostLabel: 'Morning Ghost',
  );
}
