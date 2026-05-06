import 'dart:math' as math;

import 'package:latlong2/latlong.dart';
import 'package:runlini/core/map/map_coordinate.dart';
import 'package:runlini/features/ghost_racer/service/run_session_interpolator.dart';
import 'package:runlini/features/ghost_racer/types/ghost_race_frame.dart';
import 'package:runlini/features/run_tracking/types/run_point.dart';
import 'package:runlini/features/run_tracking/types/run_session.dart';

class GhostRaceGapService {
  const GhostRaceGapService({
    this.levelThresholdMs = 3000,
    this.levelDistanceThresholdM = 3,
    this.offRouteThresholdM = 35,
  });

  final int levelThresholdMs;
  final double levelDistanceThresholdM;
  final double offRouteThresholdM;

  static const Distance _distance = Distance();

  GhostRaceFrame calculate({
    required RunPoint runnerPoint,
    required RunSession ghostSession,
    required int runnerElapsedMs,
  }) {
    if (ghostSession.points.isEmpty) {
      return const GhostRaceFrame.unavailable();
    }

    final route = _GhostRouteModel.from(ghostSession.points);
    final ghostPoint = interpolateRunPoint(
      session: ghostSession,
      elapsedMs: runnerElapsedMs,
    );
    if (route.segments.isEmpty) {
      final distanceGapM = _distanceBetween(runnerPoint, ghostPoint);
      final isLevel = distanceGapM <= levelDistanceThresholdM;
      return GhostRaceFrame(
        status: isLevel ? GhostRaceStatus.level : GhostRaceStatus.offRoute,
        timeGapMs: 0,
        distanceGapM: distanceGapM,
        ghostMarkerPoint: ghostPoint.toMapCoordinate(),
        isOffRoute: distanceGapM >= offRouteThresholdM,
        routeProgress: isLevel ? 1 : 0,
        distanceToFinishM: isLevel ? 0 : distanceGapM,
        distanceFromRouteM: distanceGapM,
        totalRouteDistanceM: 0,
        distanceToFinishPointM: distanceGapM,
      );
    }

    final projection = route.project(runnerPoint);
    final ghostDistanceAtElapsed = route.distanceAtElapsed(runnerElapsedMs);
    final timeGapMs = projection.elapsedMs - runnerElapsedMs;
    final distanceGapM =
        projection.distanceAlongRouteM - ghostDistanceAtElapsed;
    final isOffRoute = projection.distanceFromRouteM >= offRouteThresholdM;

    return GhostRaceFrame(
      status: _statusFor(isOffRoute: isOffRoute, timeGapMs: timeGapMs),
      timeGapMs: timeGapMs,
      distanceGapM: distanceGapM.abs() <= levelDistanceThresholdM
          ? 0
          : distanceGapM,
      ghostMarkerPoint: ghostPoint.toMapCoordinate(),
      isOffRoute: isOffRoute,
      routeProgress: route.progressFor(projection.distanceAlongRouteM),
      distanceToFinishM: route.distanceToFinish(projection.distanceAlongRouteM),
      distanceFromRouteM: projection.distanceFromRouteM,
      totalRouteDistanceM: route.totalDistanceM,
      distanceToFinishPointM: _distanceBetween(
        runnerPoint,
        ghostSession.points.last,
      ),
    );
  }

  GhostRaceStatus _statusFor({
    required bool isOffRoute,
    required int timeGapMs,
  }) {
    if (isOffRoute) {
      return GhostRaceStatus.offRoute;
    }

    if (timeGapMs.abs() <= levelThresholdMs) {
      return GhostRaceStatus.level;
    }

    return timeGapMs > 0 ? GhostRaceStatus.ahead : GhostRaceStatus.behind;
  }

  static double _distanceBetween(RunPoint left, RunPoint right) {
    return _distance.as(
      LengthUnit.Meter,
      LatLng(left.latitude, left.longitude),
      LatLng(right.latitude, right.longitude),
    );
  }
}

class _GhostRouteModel {
  const _GhostRouteModel({required this.segments});

  final List<_GhostRouteSegment> segments;

  double get totalDistanceM =>
      segments.isEmpty ? 0 : segments.last.endDistanceM;

  factory _GhostRouteModel.from(List<RunPoint> points) {
    final segments = <_GhostRouteSegment>[];
    var distanceBeforeM = 0.0;
    for (var index = 0; index < points.length - 1; index += 1) {
      final start = points[index];
      final end = points[index + 1];
      final distanceM = GhostRaceGapService._distanceBetween(start, end);
      if (distanceM <= 0) {
        continue;
      }

      final segment = _GhostRouteSegment(
        start: start,
        end: end,
        startDistanceM: distanceBeforeM,
        endDistanceM: distanceBeforeM + distanceM,
      );
      segments.add(segment);
      distanceBeforeM = segment.endDistanceM;
    }

    return _GhostRouteModel(segments: segments);
  }

  _RouteProjection project(RunPoint runnerPoint) {
    _RouteProjection? bestProjection;
    for (final segment in segments) {
      final projection = segment.project(runnerPoint);
      if (bestProjection == null ||
          projection.distanceFromRouteM < bestProjection.distanceFromRouteM) {
        bestProjection = projection;
      }
    }

    return bestProjection!;
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

class _GhostRouteSegment {
  const _GhostRouteSegment({
    required this.start,
    required this.end,
    required this.startDistanceM,
    required this.endDistanceM,
  });

  final RunPoint start;
  final RunPoint end;
  final double startDistanceM;
  final double endDistanceM;

  _RouteProjection project(RunPoint runnerPoint) {
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

    return _RouteProjection(
      distanceFromRouteM: projectedOffset.distance,
      distanceAlongRouteM:
          startDistanceM + ((endDistanceM - startDistanceM) * ratio),
      elapsedMs: elapsedMs,
    );
  }
}

class _RouteProjection {
  const _RouteProjection({
    required this.distanceFromRouteM,
    required this.distanceAlongRouteM,
    required this.elapsedMs,
  });

  final double distanceFromRouteM;
  final double distanceAlongRouteM;
  final int elapsedMs;
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
