import 'dart:math' as math;

import 'package:latlong2/latlong.dart';
import 'package:runlini/features/run_tracking/types/run_point.dart';

class RunPointSanitizer {
  const RunPointSanitizer({
    this.maxMetersPerSecond = 8.5,
    this.maxAccelerationMps2 = 4.5,
    this.maxHorizontalAccuracyM = 35,
    this.minMovementM = 3,
    this.stationarySpeedMps = 0.7,
    this.resumeSpeedMps = 1.2,
    this.stationaryWindowMs = 15 * 1000,
    this.stationaryClusterRadiusM = 15,
    this.resumeConfirmationCount = 2,
  });

  final double maxMetersPerSecond;
  final double maxAccelerationMps2;
  final double maxHorizontalAccuracyM;
  final double minMovementM;
  final double stationarySpeedMps;
  final double resumeSpeedMps;
  final int stationaryWindowMs;
  final double stationaryClusterRadiusM;
  final int resumeConfirmationCount;

  static const Distance _distance = Distance();

  List<RunPoint> filter(List<RunPoint> points) {
    final accepted = <RunPoint>[];

    final recentRaw = <RunPoint>[];
    var stationaryLocked = false;

    for (final point in points) {
      _addRecentRaw(recentRaw, point);
      final previous = accepted.isEmpty ? null : accepted.last;
      final previousPrevious = accepted.length < 2
          ? null
          : accepted[accepted.length - 2];
      if (previous != null) {
        if (stationaryLocked) {
          if (isMovementConfirmed(
            recentRawPoints: recentRaw,
            anchor: previous,
          )) {
            stationaryLocked = false;
          } else {
            continue;
          }
        } else if (hasStationaryWindow(recentRaw) ||
            _looksLikeStationaryDrift(
              previous,
              point,
              _distanceMeters(previous, point),
            )) {
          stationaryLocked = hasStationaryWindow(recentRaw);
          continue;
        }
      }
      if (_isAcceptable(
        previousPrevious: previousPrevious,
        previous: previous,
        next: point,
      )) {
        accepted.add(point);
      }
    }

    return accepted;
  }

  bool hasStationaryWindow(List<RunPoint> rawPoints) {
    if (rawPoints.length < 2) {
      return false;
    }
    final latest = rawPoints.last;
    final window = rawPoints
        .where(
          (point) =>
              latest.timestampRelMs - point.timestampRelMs <=
              stationaryWindowMs + 3000,
        )
        .toList(growable: false);
    if (window.length < 2) {
      return false;
    }
    if (latest.timestampRelMs - window.first.timestampRelMs <
        stationaryWindowMs) {
      return false;
    }
    final anchor = window.first;
    for (final point in window) {
      if (_hasPoorAccuracy(point) || !_hasStationarySpeed(point)) {
        return false;
      }
      if (_distanceMeters(anchor, point) > _stationaryRadius(anchor, point)) {
        return false;
      }
    }
    return true;
  }

  bool isMovementConfirmed({
    required List<RunPoint> recentRawPoints,
    required RunPoint? anchor,
  }) {
    if (anchor == null || recentRawPoints.length < resumeConfirmationCount) {
      return false;
    }
    final startIndex = math.max(
      0,
      recentRawPoints.length - resumeConfirmationCount,
    );
    final recent = recentRawPoints.skip(startIndex).toList(growable: false);
    if (recent.length < resumeConfirmationCount) {
      return false;
    }
    return recent.every((point) => _isMovementPoint(anchor, point));
  }

  bool _isAcceptable({
    required RunPoint? previousPrevious,
    required RunPoint? previous,
    required RunPoint next,
  }) {
    if (previous == null) {
      return true;
    }

    final elapsedMs = next.timestampRelMs - previous.timestampRelMs;
    if (elapsedMs <= 0) {
      return false;
    }

    if (_hasPoorAccuracy(next)) {
      return false;
    }

    final distanceM = _distanceMeters(previous, next);
    if (distanceM < minMovementM) {
      return false;
    }

    final speedMetersPerSecond = distanceM / (elapsedMs / 1000);
    if (speedMetersPerSecond > maxMetersPerSecond) {
      return false;
    }

    if (_looksLikeStationaryDrift(previous, next, distanceM)) {
      return false;
    }

    if (_hasImplausibleAcceleration(
      previousPrevious: previousPrevious,
      previous: previous,
      nextSpeedMps: speedMetersPerSecond,
      elapsedMs: elapsedMs,
    )) {
      return false;
    }

    return true;
  }

  bool _hasPoorAccuracy(RunPoint point) {
    final accuracy = point.horizontalAccuracyM;
    return accuracy != null && accuracy > maxHorizontalAccuracyM;
  }

  bool _looksLikeStationaryDrift(
    RunPoint previous,
    RunPoint next,
    double distanceM,
  ) {
    if (!_hasStationarySpeed(next)) {
      return false;
    }

    final noiseRadiusM = _combinedAccuracyRadiusM(previous, next);
    return noiseRadiusM != null && distanceM <= noiseRadiusM;
  }

  bool _hasStationarySpeed(RunPoint point) {
    final speed = point.speedMps;
    if (speed == null || speed <= stationarySpeedMps) {
      return true;
    }

    final accuracy = point.speedAccuracyMps;
    return accuracy != null && speed - accuracy <= stationarySpeedMps;
  }

  bool _isMovementPoint(RunPoint anchor, RunPoint point) {
    if (_hasPoorAccuracy(point)) {
      return false;
    }
    final speed = point.speedMps;
    final speedAccuracy = point.speedAccuracyMps;
    final speedLooksMoving =
        speed != null &&
        speed >= resumeSpeedMps &&
        (speedAccuracy == null || speed - speedAccuracy > stationarySpeedMps);
    final distanceLooksMoving =
        _distanceMeters(anchor, point) > _stationaryRadius(anchor, point);
    return speedLooksMoving || distanceLooksMoving;
  }

  double _stationaryRadius(RunPoint left, RunPoint right) {
    return math.max(
      stationaryClusterRadiusM,
      _combinedAccuracyRadiusM(left, right) ?? minMovementM,
    );
  }

  void _addRecentRaw(List<RunPoint> points, RunPoint point) {
    points.add(point);
    points.removeWhere(
      (candidate) =>
          point.timestampRelMs - candidate.timestampRelMs >
          stationaryWindowMs + 5 * 1000,
    );
  }

  double? _combinedAccuracyRadiusM(RunPoint previous, RunPoint next) {
    final previousAccuracy = _usableAccuracy(previous.horizontalAccuracyM);
    final nextAccuracy = _usableAccuracy(next.horizontalAccuracyM);
    if (previousAccuracy == null && nextAccuracy == null) {
      return null;
    }

    if (previousAccuracy == null) {
      return math.max(minMovementM, nextAccuracy!);
    }
    if (nextAccuracy == null) {
      return math.max(minMovementM, previousAccuracy);
    }

    final combined = math.sqrt(
      previousAccuracy * previousAccuracy + nextAccuracy * nextAccuracy,
    );
    return math.max(minMovementM, combined);
  }

  double? _usableAccuracy(double? accuracy) {
    if (accuracy == null ||
        !accuracy.isFinite ||
        accuracy <= 0 ||
        accuracy > maxHorizontalAccuracyM) {
      return null;
    }
    return accuracy;
  }

  bool _hasImplausibleAcceleration({
    required RunPoint? previousPrevious,
    required RunPoint previous,
    required double nextSpeedMps,
    required int elapsedMs,
  }) {
    if (previousPrevious == null) {
      return false;
    }

    final previousElapsedMs =
        previous.timestampRelMs - previousPrevious.timestampRelMs;
    if (previousElapsedMs <= 0) {
      return false;
    }

    final previousSpeedMps =
        _distanceMeters(previousPrevious, previous) /
        (previousElapsedMs / 1000);
    final accelerationMps2 =
        (nextSpeedMps - previousSpeedMps).abs() / (elapsedMs / 1000);
    return accelerationMps2 > maxAccelerationMps2;
  }

  double _distanceMeters(RunPoint left, RunPoint right) {
    return _distance.as(
      LengthUnit.Meter,
      LatLng(left.latitude, left.longitude),
      LatLng(right.latitude, right.longitude),
    );
  }
}
