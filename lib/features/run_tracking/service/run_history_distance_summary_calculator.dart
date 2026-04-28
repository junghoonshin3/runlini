import 'package:runlini/features/run_tracking/types/run_history_distance_summary.dart';
import 'package:runlini/features/run_tracking/types/run_history_period.dart';
import 'package:runlini/features/run_tracking/types/run_session.dart';

class RunHistoryDistanceSummaryCalculator {
  const RunHistoryDistanceSummaryCalculator();

  RunHistoryDistanceSummary calculate({
    required List<RunSession> sessions,
    required RunHistoryPeriod period,
    required DateTime now,
    required double goalDistanceM,
  }) {
    final range = _rangeFor(period, now);
    final periodSessions = sessions
        .where((RunSession session) {
          return !session.startedAt.isBefore(range.start) &&
              session.startedAt.isBefore(range.end);
        })
        .toList(growable: false);
    final distanceM = periodSessions.fold<double>(
      0,
      (double total, RunSession session) => total + session.distanceM,
    );

    return RunHistoryDistanceSummary(
      period: period,
      startedAt: range.start,
      endedAt: range.end,
      distanceM: distanceM,
      goalDistanceM: goalDistanceM,
      runCount: periodSessions.length,
    );
  }

  _DateTimeRange _rangeFor(RunHistoryPeriod period, DateTime now) {
    return switch (period) {
      RunHistoryPeriod.week => _weekRange(now),
      RunHistoryPeriod.month => _monthRange(now),
      RunHistoryPeriod.year => _yearRange(now),
    };
  }

  _DateTimeRange _weekRange(DateTime now) {
    final localNow = now.toLocal();
    final start = DateTime(
      localNow.year,
      localNow.month,
      localNow.day,
    ).subtract(Duration(days: localNow.weekday - DateTime.monday));
    return _DateTimeRange(start, start.add(const Duration(days: 7)));
  }

  _DateTimeRange _monthRange(DateTime now) {
    final localNow = now.toLocal();
    final start = DateTime(localNow.year, localNow.month);
    return _DateTimeRange(start, DateTime(localNow.year, localNow.month + 1));
  }

  _DateTimeRange _yearRange(DateTime now) {
    final localNow = now.toLocal();
    final start = DateTime(localNow.year);
    return _DateTimeRange(start, DateTime(localNow.year + 1));
  }
}

class _DateTimeRange {
  const _DateTimeRange(this.start, this.end);

  final DateTime start;
  final DateTime end;
}
