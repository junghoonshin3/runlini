import 'package:flutter_test/flutter_test.dart';
import 'package:runlini/features/run_tracking/service/run_history_distance_summary_calculator.dart';
import 'package:runlini/features/run_tracking/types/run_history_period.dart';
import 'package:runlini/features/run_tracking/types/run_session.dart';

void main() {
  const calculator = RunHistoryDistanceSummaryCalculator();
  final now = DateTime(2026, 4, 28, 12);

  test('calculates current week distance from Monday through Sunday', () {
    final summary = calculator.calculate(
      sessions: [
        _session('sunday-before', DateTime(2026, 4, 26), 900),
        _session('monday', DateTime(2026, 4, 27), 1200),
        _session('tuesday', DateTime(2026, 4, 28), 1800),
        _session('next-monday', DateTime(2026, 5, 4), 600),
      ],
      period: RunHistoryPeriod.week,
      now: now,
      goalDistanceM: 6000,
    );

    expect(summary.distanceM, 3000);
    expect(summary.runCount, 2);
    expect(summary.startedAt, DateTime(2026, 4, 27));
    expect(summary.endedAt, DateTime(2026, 5, 4));
  });

  test('calculates current month and year totals separately', () {
    final sessions = [
      _session('march', DateTime(2026, 3, 31), 1000),
      _session('april-a', DateTime(2026, 4, 1), 2000),
      _session('april-b', DateTime(2026, 4, 28), 3000),
      _session('next-year', DateTime(2027, 1, 1), 4000),
    ];

    final month = calculator.calculate(
      sessions: sessions,
      period: RunHistoryPeriod.month,
      now: now,
      goalDistanceM: 10000,
    );
    final year = calculator.calculate(
      sessions: sessions,
      period: RunHistoryPeriod.year,
      now: now,
      goalDistanceM: 12000,
    );

    expect(month.distanceM, 5000);
    expect(month.runCount, 2);
    expect(month.goalDistanceM, 10000);
    expect(year.distanceM, 6000);
    expect(year.runCount, 3);
    expect(year.goalDistanceM, 12000);
  });
}

RunSession _session(String id, DateTime startedAt, double distanceM) {
  return RunSession(
    id: id,
    startedAt: startedAt,
    distanceM: distanceM,
    durationMs: 600000,
    sourceSummary: 'test',
    points: const [],
  );
}
