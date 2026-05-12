// 기록 레이스 코스의 거리 진행률 projection을 계산하는 route 모델
import 'dart:math' as math;

import 'package:latlong2/latlong.dart';
import 'package:runlini/features/record_race/types/record_race_projection_source.dart';
import 'package:runlini/features/run_tracking/types/run_point.dart';

class RecordRaceRouteModel {
  const RecordRaceRouteModel({required this.segments});

  final List<RecordRaceRouteSegment> segments;

  static const Distance _distance = Distance();

  double get totalDistanceM =>
      segments.isEmpty ? 0 : segments.last.endDistanceM;

  factory RecordRaceRouteModel.from(List<RunPoint> points) {
    final segments = <RecordRaceRouteSegment>[];
    var distanceBeforeM = 0.0;
    for (var index = 0; index < points.length - 1; index += 1) {
      final start = points[index];
      final end = points[index + 1];
      final distanceM = distanceBetween(start, end);
      if (distanceM <= 0) {
        continue;
      }

      final segment = RecordRaceRouteSegment(
        start: start,
        end: end,
        startDistanceM: distanceBeforeM,
        endDistanceM: distanceBeforeM + distanceM,
      );
      segments.add(segment);
      distanceBeforeM = segment.endDistanceM;
    }

    return RecordRaceRouteModel(segments: segments);
  }

  static double distanceBetween(RunPoint left, RunPoint right) {
    return _distance.as(
      LengthUnit.Meter,
      LatLng(left.latitude, left.longitude),
      LatLng(right.latitude, right.longitude),
    );
  }

  RecordRaceRouteProjection projectGlobal(RunPoint runnerPoint) {
    RecordRaceRouteProjection? bestProjection;
    for (final segment in segments) {
      final projection = segment.project(
        runnerPoint,
        source: RecordRaceProjectionSource.global,
      );
      if (bestProjection == null ||
          projection.distanceFromRouteM < bestProjection.distanceFromRouteM) {
        bestProjection = projection;
      }
    }

    return bestProjection!;
  }

  RecordRaceRouteProjection? projectWithinDistanceWindow({
    required RunPoint runnerPoint,
    required double minDistanceM,
    required double maxDistanceM,
  }) {
    RecordRaceRouteProjection? bestProjection;
    for (final segment in segments) {
      if (segment.endDistanceM < minDistanceM ||
          segment.startDistanceM > maxDistanceM) {
        continue;
      }
      final projection = segment.project(
        runnerPoint,
        source: RecordRaceProjectionSource.tracked,
      );
      if (projection.distanceAlongRouteM < minDistanceM ||
          projection.distanceAlongRouteM > maxDistanceM) {
        continue;
      }
      if (bestProjection == null ||
          projection.distanceFromRouteM < bestProjection.distanceFromRouteM) {
        bestProjection = projection;
      }
    }
    return bestProjection;
  }

  RecordRaceRouteProjection projectTracked({
    required RunPoint runnerPoint,
    required double? anchorDistanceAlongRouteM,
    required double behindWindowM,
    required double aheadWindowM,
    required double onRouteThresholdM,
  }) {
    final globalProjection = projectGlobal(runnerPoint);
    if (anchorDistanceAlongRouteM == null) {
      return globalProjection;
    }

    final anchorDistance = anchorDistanceAlongRouteM.clamp(0.0, totalDistanceM);
    final windowProjection = projectWithinDistanceWindow(
      runnerPoint: runnerPoint,
      minDistanceM: (anchorDistance - behindWindowM).clamp(0.0, totalDistanceM),
      maxDistanceM: (anchorDistance + aheadWindowM).clamp(0.0, totalDistanceM),
    );
    if (windowProjection != null &&
        windowProjection.distanceFromRouteM <= onRouteThresholdM) {
      return windowProjection;
    }

    return RecordRaceRouteProjection(
      distanceFromRouteM: globalProjection.distanceFromRouteM,
      distanceAlongRouteM: anchorDistance.toDouble(),
      elapsedMs: elapsedAtDistance(anchorDistance.toDouble()),
      source: RecordRaceProjectionSource.held,
    );
  }

  double distanceAtElapsed(int elapsedMs) {
    if (elapsedMs <= segments.first.start.timestampRelMs) {
      return segments.first.startDistanceM;
    }

    for (final segment in segments) {
      final startMs = segment.start.timestampRelMs;
      final endMs = segment.end.timestampRelMs;
      if (elapsedMs > endMs) {
        continue;
      }

      if (endMs <= startMs) {
        return segment.startDistanceM;
      }

      final ratio = ((elapsedMs - startMs) / (endMs - startMs))
          .clamp(0.0, 1.0)
          .toDouble();
      return segment.startDistanceM +
          ((segment.endDistanceM - segment.startDistanceM) * ratio);
    }

    return segments.last.endDistanceM;
  }

  int elapsedAtDistance(double distanceAlongRouteM) {
    final distance = distanceAlongRouteM.clamp(0.0, totalDistanceM).toDouble();
    for (final segment in segments) {
      if (distance > segment.endDistanceM) {
        continue;
      }
      final segmentDistance = segment.endDistanceM - segment.startDistanceM;
      if (segmentDistance <= 0) {
        return segment.start.timestampRelMs;
      }
      final ratio = ((distance - segment.startDistanceM) / segmentDistance)
          .clamp(0.0, 1.0)
          .toDouble();
      return segment.start.timestampRelMs +
          ((segment.end.timestampRelMs - segment.start.timestampRelMs) * ratio)
              .round();
    }
    return segments.last.end.timestampRelMs;
  }

  double progressFor(double distanceAlongRouteM) {
    final total = totalDistanceM;
    if (total <= 0) {
      return 0;
    }
    return (distanceAlongRouteM / total).clamp(0.0, 1.0).toDouble();
  }

  double distanceToFinish(double distanceAlongRouteM) {
    return (totalDistanceM - distanceAlongRouteM).clamp(0.0, double.infinity);
  }
}

class RecordRaceRouteSegment {
  const RecordRaceRouteSegment({
    required this.start,
    required this.end,
    required this.startDistanceM,
    required this.endDistanceM,
  });

  final RunPoint start;
  final RunPoint end;
  final double startDistanceM;
  final double endDistanceM;

  RecordRaceRouteProjection project(
    RunPoint runnerPoint, {
    required RecordRaceProjectionSource source,
  }) {
    final startOffset = _meterOffset(
      originLatitude: runnerPoint.latitude,
      originLongitude: runnerPoint.longitude,
      latitude: start.latitude,
      longitude: start.longitude,
    );
    final endOffset = _meterOffset(
      originLatitude: runnerPoint.latitude,
      originLongitude: runnerPoint.longitude,
      latitude: end.latitude,
      longitude: end.longitude,
    );
    final segmentVector = endOffset - startOffset;
    final segmentLengthSquared = segmentVector.lengthSquared;
    const runnerOffset = _MeterOffset(0, 0);
    final rawRatio = segmentLengthSquared <= 0
        ? 0.0
        : ((runnerOffset - startOffset).dot(segmentVector) /
              segmentLengthSquared);
    final ratio = rawRatio.clamp(0.0, 1.0).toDouble();
    final projectedOffset = startOffset + (segmentVector * ratio);
    final elapsedMs =
        start.timestampRelMs +
        ((end.timestampRelMs - start.timestampRelMs) * ratio).round();

    return RecordRaceRouteProjection(
      distanceFromRouteM: projectedOffset.distance,
      distanceAlongRouteM:
          startDistanceM + ((endDistanceM - startDistanceM) * ratio),
      elapsedMs: elapsedMs,
      source: source,
    );
  }
}

class RecordRaceRouteProjection {
  const RecordRaceRouteProjection({
    required this.distanceFromRouteM,
    required this.distanceAlongRouteM,
    required this.elapsedMs,
    required this.source,
  });

  final double distanceFromRouteM;
  final double distanceAlongRouteM;
  final int elapsedMs;
  final RecordRaceProjectionSource source;
}

class _MeterOffset {
  const _MeterOffset(this.dx, this.dy);

  final double dx;
  final double dy;

  double get lengthSquared => (dx * dx) + (dy * dy);

  double get distance => math.sqrt(lengthSquared);

  _MeterOffset operator -(_MeterOffset other) {
    return _MeterOffset(dx - other.dx, dy - other.dy);
  }

  _MeterOffset operator +(_MeterOffset other) {
    return _MeterOffset(dx + other.dx, dy + other.dy);
  }

  _MeterOffset operator *(double value) {
    return _MeterOffset(dx * value, dy * value);
  }

  double dot(_MeterOffset other) {
    return (dx * other.dx) + (dy * other.dy);
  }
}

_MeterOffset _meterOffset({
  required double originLatitude,
  required double originLongitude,
  required double latitude,
  required double longitude,
}) {
  final latitudeScaleM = 111320.0;
  final longitudeScaleM =
      latitudeScaleM * math.cos(originLatitude * math.pi / 180);
  return _MeterOffset(
    (longitude - originLongitude) * longitudeScaleM,
    (latitude - originLatitude) * latitudeScaleM,
  );
}
