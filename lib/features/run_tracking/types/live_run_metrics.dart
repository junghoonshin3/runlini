import 'package:flutter/foundation.dart';

@immutable
class LiveRunMetrics {
  const LiveRunMetrics({
    required this.distanceKm,
    required this.elapsedMs,
    required this.averagePaceSecPerKm,
    required this.averageSpeedKmh,
    required this.caloriesKcal,
    required this.isPaused,
  });

  final double distanceKm;
  final int elapsedMs;
  final double? averagePaceSecPerKm;
  final double averageSpeedKmh;
  final double? caloriesKcal;
  final bool isPaused;
}
