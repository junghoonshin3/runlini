class RunHistoryDaySummary {
  const RunHistoryDaySummary({
    required this.date,
    required this.distanceM,
    required this.runCount,
  });

  final DateTime date;
  final double distanceM;
  final int runCount;

  bool get hasRuns => runCount > 0;

  double progressForGoal(double goalDistanceM) {
    if (goalDistanceM <= 0) {
      return 0;
    }
    return (distanceM / goalDistanceM).clamp(0, 1).toDouble();
  }
}
