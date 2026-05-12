import 'package:runlini/features/run_tracking/types/run_point.dart';
import 'package:runlini/features/run_tracking/types/run_session.dart';

class WatchRecordRaceConfig {
  const WatchRecordRaceConfig({
    required this.id,
    required this.startedAt,
    required this.durationMs,
    required this.distanceM,
    required this.sourceSummary,
    required this.points,
  });

  final String id;
  final DateTime startedAt;
  final int durationMs;
  final double distanceM;
  final String sourceSummary;
  final List<RunPoint> points;

  bool get canRunOnWatch {
    if (durationMs <= 0 || !distanceM.isFinite || distanceM <= 0) {
      return false;
    }
    if (points.length < 2) {
      return false;
    }

    var minLat = double.infinity;
    var maxLat = double.negativeInfinity;
    var minLng = double.infinity;
    var maxLng = double.negativeInfinity;
    int? previousTimestampRelMs;

    for (final point in points) {
      if (!_isValidLatitude(point.latitude) ||
          !_isValidLongitude(point.longitude) ||
          point.timestampRelMs < 0 ||
          !_isValidPace(point.paceSecPerKm) ||
          !_isValidSpeed(point.speedMps) ||
          !_isValidPositiveValue(point.horizontalAccuracyM) ||
          !_isValidPositiveValue(point.speedAccuracyMps) ||
          !_isValidElevation(point.elevationM)) {
        return false;
      }

      final previous = previousTimestampRelMs;
      if (previous != null && point.timestampRelMs <= previous) {
        return false;
      }
      previousTimestampRelMs = point.timestampRelMs;
      if (point.latitude < minLat) minLat = point.latitude;
      if (point.latitude > maxLat) maxLat = point.latitude;
      if (point.longitude < minLng) minLng = point.longitude;
      if (point.longitude > maxLng) maxLng = point.longitude;
    }

    if (points.last.timestampRelMs <= 0) {
      return false;
    }

    return maxLat - minLat <= _maxRouteSpanDegrees &&
        maxLng - minLng <= _maxRouteSpanDegrees;
  }

  factory WatchRecordRaceConfig.fromSession(RunSession session) {
    return WatchRecordRaceConfig(
      id: session.id,
      startedAt: session.startedAt,
      durationMs: session.durationMs,
      distanceM: session.distanceM,
      sourceSummary: session.sourceSummary,
      points: session.points,
    );
  }

  factory WatchRecordRaceConfig.fromJson(Map<String, dynamic> json) {
    return WatchRecordRaceConfig(
      id: json['id'] as String,
      startedAt: DateTime.parse(json['startedAt'] as String),
      durationMs: json['durationMs'] as int,
      distanceM: (json['distanceM'] as num).toDouble(),
      sourceSummary: json['sourceSummary'] as String,
      points: (json['points'] as List<dynamic>)
          .map(
            (dynamic point) => RunPoint.fromJson(point as Map<String, dynamic>),
          )
          .toList(growable: false),
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'startedAt': startedAt.toIso8601String(),
      'durationMs': durationMs,
      'distanceM': distanceM,
      'sourceSummary': sourceSummary,
      'points': points.map((RunPoint point) => point.toJson()).toList(),
    };
  }
}

const double _maxRouteSpanDegrees = 2;

bool _isValidLatitude(double value) {
  return value.isFinite && value >= -90 && value <= 90;
}

bool _isValidLongitude(double value) {
  return value.isFinite && value >= -180 && value <= 180;
}

bool _isValidPace(double? value) {
  return value == null || (value.isFinite && value > 0);
}

bool _isValidSpeed(double? value) {
  return value == null || (value.isFinite && value >= 0);
}

bool _isValidPositiveValue(double? value) {
  return value == null || (value.isFinite && value > 0);
}

bool _isValidElevation(double? value) {
  return value == null || (value.isFinite && value.abs() <= 12000);
}
