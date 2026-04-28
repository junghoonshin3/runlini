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
  });

  final double maxMetersPerSecond;
  final double maxAccelerationMps2;
  final double maxHorizontalAccuracyM;
  final double minMovementM;
  final double stationarySpeedMps;

  static const Distance _distance = Distance();

  List<RunPoint> filter(List<RunPoint> points) {
    final accepted = <RunPoint>[];

    for (final point in points) {
      final previous = accepted.isEmpty ? null : accepted.last;
      final previousPrevious = accepted.length < 2
          ? null
          : accepted[accepted.length - 2];
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
