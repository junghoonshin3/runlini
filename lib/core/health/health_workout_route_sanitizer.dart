import 'package:latlong2/latlong.dart';
import 'package:runlini/features/run_tracking/types/run_point.dart';

class HealthWorkoutRouteSanitizer {
  const HealthWorkoutRouteSanitizer();

  static const Distance _distance = Distance();
  static const double _maxUsableElevationM = 12000;

  List<RunPoint> sanitize(
    List<RunPoint> recordedPoints, {
    required int maxTimestampRelMs,
  }) {
    if (maxTimestampRelMs <= 0 || recordedPoints.isEmpty) {
      return const <RunPoint>[];
    }

    final sortedPoints = List<RunPoint>.from(recordedPoints)
      ..sort(
        (RunPoint left, RunPoint right) =>
            left.timestampRelMs.compareTo(right.timestampRelMs),
      );
    final sanitized = <RunPoint>[];
    int? previousTimestampRelMs;
    for (final point in sortedPoints) {
      if (!_hasValidCoordinate(point.latitude, min: -90, max: 90) ||
          !_hasValidCoordinate(point.longitude, min: -180, max: 180) ||
          point.timestampRelMs < 0 ||
          point.timestampRelMs > maxTimestampRelMs ||
          (previousTimestampRelMs != null &&
              point.timestampRelMs <= previousTimestampRelMs)) {
        continue;
      }

      previousTimestampRelMs = point.timestampRelMs;
      sanitized.add(
        RunPoint(
          latitude: point.latitude,
          longitude: point.longitude,
          timestampRelMs: point.timestampRelMs,
          source: point.source,
          paceSecPerKm: _positiveFinite(point.paceSecPerKm),
          speedMps: _positiveFinite(point.speedMps),
          horizontalAccuracyM: _positiveFinite(point.horizontalAccuracyM),
          speedAccuracyMps: _positiveFinite(point.speedAccuracyMps),
          elevationM: _usableElevation(point.elevationM),
          heartRateBpm: point.heartRateBpm,
        ),
      );
    }

    return sanitized;
  }

  int? calculateDistanceMeters(List<RunPoint> recordedPoints) {
    if (recordedPoints.length < 2) {
      return null;
    }

    var totalMeters = 0.0;
    for (var index = 1; index < recordedPoints.length; index += 1) {
      final previous = recordedPoints[index - 1];
      final current = recordedPoints[index];
      final segmentMeters = _distance.as(
        LengthUnit.Meter,
        LatLng(previous.latitude, previous.longitude),
        LatLng(current.latitude, current.longitude),
      );
      if (segmentMeters.isFinite && segmentMeters > 0) {
        totalMeters += segmentMeters;
      }
    }

    if (!totalMeters.isFinite || totalMeters <= 0) {
      return null;
    }
    return totalMeters.round();
  }

  bool _hasValidCoordinate(
    double value, {
    required double min,
    required double max,
  }) {
    return value.isFinite && value >= min && value <= max;
  }

  double? _positiveFinite(double? value) {
    if (value == null || !value.isFinite || value <= 0) {
      return null;
    }
    return value;
  }

  double? _usableElevation(double? value) {
    if (value == null ||
        !value.isFinite ||
        value.abs() > _maxUsableElevationM) {
      return null;
    }
    return value;
  }
}
