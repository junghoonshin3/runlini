import 'package:flutter/foundation.dart';
import 'package:runlini/features/run_tracking/types/run_point.dart';

@immutable
class LiveLocationSample {
  const LiveLocationSample({
    required this.latitude,
    required this.longitude,
    required this.capturedAt,
    required this.source,
    this.paceSecPerKm,
    this.speedMps,
    this.horizontalAccuracyM,
    this.speedAccuracyMps,
    this.elevationM,
    this.heartRateBpm,
  });

  final double latitude;
  final double longitude;
  final DateTime capturedAt;
  final double? paceSecPerKm;
  final double? speedMps;
  final double? horizontalAccuracyM;
  final double? speedAccuracyMps;
  final double? elevationM;
  final int? heartRateBpm;
  final RunPointSource source;

  RunPoint toRunPoint({required int elapsedMs}) {
    return RunPoint(
      latitude: latitude,
      longitude: longitude,
      timestampRelMs: elapsedMs < 0 ? 0 : elapsedMs,
      paceSecPerKm: paceSecPerKm,
      speedMps: speedMps,
      horizontalAccuracyM: horizontalAccuracyM,
      speedAccuracyMps: speedAccuracyMps,
      elevationM: elevationM,
      heartRateBpm: heartRateBpm,
      source: source,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }

    return other is LiveLocationSample &&
        other.latitude == latitude &&
        other.longitude == longitude &&
        other.capturedAt == capturedAt &&
        other.paceSecPerKm == paceSecPerKm &&
        other.speedMps == speedMps &&
        other.horizontalAccuracyM == horizontalAccuracyM &&
        other.speedAccuracyMps == speedAccuracyMps &&
        other.elevationM == elevationM &&
        other.heartRateBpm == heartRateBpm &&
        other.source == source;
  }

  @override
  int get hashCode => Object.hash(
    latitude,
    longitude,
    capturedAt,
    paceSecPerKm,
    speedMps,
    horizontalAccuracyM,
    speedAccuracyMps,
    elevationM,
    heartRateBpm,
    source,
  );
}
