import 'package:flutter/foundation.dart';

@immutable
class RunSessionDetail {
  const RunSessionDetail({
    required this.distanceKm,
    required this.durationMs,
    required this.averagePaceSecPerKm,
    required this.averageSpeedKmh,
    required this.caloriesLabel,
    required this.splits,
    required this.paceSamplesSecPerKm,
    required this.speedSamplesKmh,
    required this.elevationSamplesM,
    required this.heartRateSamplesBpm,
    this.averageHeartRateBpm,
    this.elevationGainM,
  });

  final double distanceKm;
  final int durationMs;
  final double? averagePaceSecPerKm;
  final double averageSpeedKmh;
  final String caloriesLabel;
  final int? averageHeartRateBpm;
  final double? elevationGainM;
  final List<RunSplitDetail> splits;
  final List<RunMetricSample> paceSamplesSecPerKm;
  final List<RunMetricSample> speedSamplesKmh;
  final List<RunMetricSample> elevationSamplesM;
  final List<RunMetricSample> heartRateSamplesBpm;
}

@immutable
class RunMetricSample {
  const RunMetricSample({required this.elapsedMs, required this.value});

  final int elapsedMs;
  final double value;
}

@immutable
class RunSplitDetail {
  const RunSplitDetail({
    required this.index,
    required this.distanceM,
    required this.durationMs,
    required this.paceSecPerKm,
    this.elevationDeltaM,
    this.averageHeartRateBpm,
  });

  final int index;
  final double distanceM;
  final int durationMs;
  final double paceSecPerKm;
  final double? elevationDeltaM;
  final int? averageHeartRateBpm;
}
