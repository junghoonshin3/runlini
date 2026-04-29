import 'package:flutter_test/flutter_test.dart';
import 'package:runlini/features/run_tracking/service/run_history_calendar_summary_calculator.dart';
import 'package:runlini/features/run_tracking/types/run_history_day_summary.dart';
import 'package:runlini/features/run_tracking/types/run_session.dart';

void main() {
  test('groups sessions by local calendar day', () {
    const calculator = RunHistoryCalendarSummaryCalculator();

    final summaries = calculator.calculate(
      sessions: [
        _session('morning', DateTime(2026, 4, 28, 6), 3200),
        _session('night', DateTime(2026, 4, 28, 20), 1800),
        _session('next-day', DateTime(2026, 4, 29, 7), 5000),
      ],
    );

    final april28 = summaries[DateTime(2026, 4, 28)];
    final april29 = summaries[DateTime(2026, 4, 29)];

    expect(april28?.distanceM, 5000);
    expect(april28?.runCount, 2);
    expect(april29?.distanceM, 5000);
    expect(april29?.runCount, 1);
  });

  test('groups UTC Wear sessions by local calendar day', () {
    const calculator = RunHistoryCalendarSummaryCalculator();
    final localStart = DateTime(2026, 4, 29, 0, 30);

    final summaries = calculator.calculate(
      sessions: [_session('wear-utc', localStart.toUtc(), 3200)],
    );

    final localDate = DateTime(
      localStart.year,
      localStart.month,
      localStart.day,
    );
    expect(summaries[localDate]?.distanceM, 3200);
    expect(summaries[localDate]?.runCount, 1);
  });

  test('day progress is clamped to one', () {
    final summary = calculatorSummary(distanceM: 5000);

    expect(summary.progressForGoal(2500), 1);
    expect(summary.progressForGoal(10000), 0.5);
    expect(summary.progressForGoal(0), 0);
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

RunHistoryDaySummary calculatorSummary({required double distanceM}) {
  const calculator = RunHistoryCalendarSummaryCalculator();
  return calculator
      .calculate(sessions: [_session('run', DateTime(2026, 4, 28), distanceM)])
      .values
      .single;
}
