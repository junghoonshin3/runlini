import 'package:runlini/features/run_tracking/types/run_history_day_summary.dart';
import 'package:runlini/features/run_tracking/types/run_session_summary.dart';

class RunHistoryCalendarSummaryCalculator {
  const RunHistoryCalendarSummaryCalculator();

  Map<DateTime, RunHistoryDaySummary> calculate({
    required List<RunSessionSummary> sessions,
  }) {
    final mutableSummaries = <DateTime, _MutableDaySummary>{};
    for (final session in sessions) {
      final date = localDate(session.startedAt);
      final summary = mutableSummaries.putIfAbsent(
        date,
        () => _MutableDaySummary(date),
      );
      summary.distanceM += session.distanceM;
      summary.runCount += 1;
    }

    return Map<DateTime, RunHistoryDaySummary>.unmodifiable(
      mutableSummaries.map(
        (DateTime date, _MutableDaySummary summary) => MapEntry(
          date,
          RunHistoryDaySummary(
            date: date,
            distanceM: summary.distanceM,
            runCount: summary.runCount,
          ),
        ),
      ),
    );
  }

  DateTime localDate(DateTime dateTime) {
    final local = dateTime.toLocal();
    return DateTime(local.year, local.month, local.day);
  }
}

class _MutableDaySummary {
  _MutableDaySummary(this.date);

  final DateTime date;
  double distanceM = 0;
  int runCount = 0;
}
