import 'package:flutter/foundation.dart';

@immutable
class LiveRunMetrics {
  const LiveRunMetrics({
    required this.distanceKm,
    required this.elapsedMs,
    required this.averagePaceSecPerKm,
    required this.averageSpeedKmh,
    required this.caloriesLabel,
    required this.isPaused,
  });

  final double distanceKm;
  final int elapsedMs;
  final double? averagePaceSecPerKm;
  final double averageSpeedKmh;
  final String caloriesLabel;
  final bool isPaused;
}
