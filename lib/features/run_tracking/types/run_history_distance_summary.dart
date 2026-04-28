import 'package:runlini/features/run_tracking/types/run_history_period.dart';

class RunHistoryDistanceSummary {
  const RunHistoryDistanceSummary({
    required this.period,
    required this.startedAt,
    required this.endedAt,
    required this.distanceM,
    required this.goalDistanceM,
    required this.runCount,
  });

  final RunHistoryPeriod period;
  final DateTime startedAt;
  final DateTime endedAt;
  final double distanceM;
  final double goalDistanceM;
  final int runCount;

  double get progress {
    if (goalDistanceM <= 0) {
      return 0;
    }
    return (distanceM / goalDistanceM).clamp(0, 1).toDouble();
  }

  bool get hasExceededGoal => distanceM >= goalDistanceM;
}
