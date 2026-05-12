import 'dart:math' as math;

import 'package:latlong2/latlong.dart';
import 'package:runlini/core/map/map_coordinate.dart';
import 'package:runlini/core/map/map_polyline_segment.dart';
import 'package:runlini/features/run_tracking/service/pace_color_mapper.dart';
import 'package:runlini/features/run_tracking/types/run_point.dart';
import 'package:runlini/features/run_tracking/types/run_session.dart';

class PaceColoredRouteSegmentBuilder {
  const PaceColoredRouteSegmentBuilder({
    this.paceColorMapper = const PaceColorMapper(),
    this.chunkDistanceM = 20,
    this.rollingWindowM = 60,
  });

  final PaceColorMapper paceColorMapper;
  final double chunkDistanceM;
  final double rollingWindowM;

  List<MapPolylineSegment> buildRecordRaceSegments(RunSession session) {
    if (session.points.length < 2) {
      return const <MapPolylineSegment>[];
    }

    return buildRouteSegments(<List<RunPoint>>[
      session.points,
    ], fallbackBaselinePaceSecPerKm: _averagePaceSecPerKm(session));
  }

  List<MapPolylineSegment> buildRouteSegments(
    List<List<RunPoint>> routeSegments, {
    double fallbackBaselinePaceSecPerKm = 0,
  }) {
    if (routeSegments.isEmpty || chunkDistanceM <= 0) {
      return const <MapPolylineSegment>[];
    }

    final routes = routeSegments
        .where((points) => points.length >= 2)
        .map(_DistanceTimedRoute.fromPoints)
        .where((route) => route.totalDistanceM > 0)
        .toList(growable: false);
    if (routes.isEmpty) {
      return const <MapPolylineSegment>[];
    }

    final baselinePaceSecPerKm =
        _median(
          routes
              .expand((route) => route.validSegmentPacesSecPerKm)
              .toList(growable: false),
        ) ??
        fallbackBaselinePaceSecPerKm;
    return <MapPolylineSegment>[
      for (final route in routes)
        ..._buildSegmentsForRoute(route, baselinePaceSecPerKm),
    ];
  }

  List<MapPolylineSegment> _buildSegmentsForRoute(
    _DistanceTimedRoute route,
    double baselinePaceSecPerKm,
  ) {
    final segments = <MapPolylineSegment>[];
    for (
      var startM = 0.0;
      startM < route.totalDistanceM;
      startM += chunkDistanceM
    ) {
      final endM = math.min(startM + chunkDistanceM, route.totalDistanceM);
      final centerM = (startM + endM) / 2;
      final segment = MapPolylineSegment(
        points: <MapCoordinate>[
          route.coordinateAtDistance(startM),
          route.coordinateAtDistance(endM),
        ],
        color: paceColorMapper.colorForRelativeGradient(
          paceSecPerKm: route.rollingPaceSecPerKm(
            centerDistanceM: centerM,
            windowDistanceM: rollingWindowM,
          ),
          baselinePaceSecPerKm: baselinePaceSecPerKm,
        ),
      );
      _appendSegment(segments, segment);
    }

    return segments;
  }

  void _appendSegment(
    List<MapPolylineSegment> segments,
    MapPolylineSegment next,
  ) {
    if (segments.isEmpty || segments.last.color != next.color) {
      segments.add(next);
      return;
    }

    final previous = segments.removeLast();
    segments.add(
      MapPolylineSegment(
        points: <MapCoordinate>[...previous.points, next.points.last],
        color: previous.color,
      ),
    );
  }

  double _averagePaceSecPerKm(RunSession session) {
    final distanceKm = session.distanceM / 1000;
    if (distanceKm <= 0 || session.durationMs <= 0) {
      return 0;
    }

    return (session.durationMs / 1000) / distanceKm;
  }

  double? _median(List<double> values) {
    if (values.isEmpty) {
      return null;
    }

    final sorted = values.toList()..sort();
    final middle = sorted.length ~/ 2;
    if (sorted.length.isOdd) {
      return sorted[middle];
    }

    return (sorted[middle - 1] + sorted[middle]) / 2;
  }
}

class _DistanceTimedRoute {
  _DistanceTimedRoute({
    required this.points,
    required this.cumulativeMeters,
    required this.validSegmentPacesSecPerKm,
  });

  static const Distance _distance = Distance();

  final List<RunPoint> points;
  final List<double> cumulativeMeters;
  final List<double> validSegmentPacesSecPerKm;

  double get totalDistanceM => cumulativeMeters.last;

  factory _DistanceTimedRoute.fromPoints(List<RunPoint> points) {
    final cumulativeMeters = <double>[0];
    final validSegmentPaces = <double>[];

    for (var index = 1; index < points.length; index += 1) {
      final previous = points[index - 1];
      final current = points[index];
      final segmentDistanceM = _distance.as(
        LengthUnit.Meter,
        LatLng(previous.latitude, previous.longitude),
        LatLng(current.latitude, current.longitude),
      );
      cumulativeMeters.add(cumulativeMeters.last + segmentDistanceM);

      final segmentElapsedMs = current.timestampRelMs - previous.timestampRelMs;
      if (segmentDistanceM > 0 && segmentElapsedMs > 0) {
        validSegmentPaces.add(
          (segmentElapsedMs / 1000) / (segmentDistanceM / 1000),
        );
      }
    }

    return _DistanceTimedRoute(
      points: points,
      cumulativeMeters: cumulativeMeters,
      validSegmentPacesSecPerKm: validSegmentPaces,
    );
  }

  MapCoordinate coordinateAtDistance(double distanceM) {
    if (distanceM <= 0) {
      return points.first.toMapCoordinate();
    }
    if (distanceM >= totalDistanceM) {
      return points.last.toMapCoordinate();
    }

    final index = _segmentIndexAtDistance(distanceM);
    final startDistanceM = cumulativeMeters[index];
    final endDistanceM = cumulativeMeters[index + 1];
    final ratio = _distanceRatio(
      distanceM: distanceM,
      startDistanceM: startDistanceM,
      endDistanceM: endDistanceM,
    );
    final start = points[index];
    final end = points[index + 1];
    return MapCoordinate(
      latitude: start.latitude + ((end.latitude - start.latitude) * ratio),
      longitude: start.longitude + ((end.longitude - start.longitude) * ratio),
    );
  }

  double? rollingPaceSecPerKm({
    required double centerDistanceM,
    required double windowDistanceM,
  }) {
    final halfWindowM = math.max(windowDistanceM, 0) / 2;
    final startDistanceM = (centerDistanceM - halfWindowM).clamp(
      0.0,
      totalDistanceM,
    );
    final endDistanceM = (centerDistanceM + halfWindowM).clamp(
      0.0,
      totalDistanceM,
    );
    final distanceM = endDistanceM - startDistanceM;
    if (distanceM <= 0) {
      return null;
    }

    final startElapsedMs = elapsedAtDistance(startDistanceM);
    final endElapsedMs = elapsedAtDistance(endDistanceM);
    final elapsedMs = endElapsedMs - startElapsedMs;
    if (elapsedMs <= 0) {
      return null;
    }

    return (elapsedMs / 1000) / (distanceM / 1000);
  }

  double elapsedAtDistance(double distanceM) {
    if (distanceM <= 0) {
      return points.first.timestampRelMs.toDouble();
    }
    if (distanceM >= totalDistanceM) {
      return points.last.timestampRelMs.toDouble();
    }

    final index = _segmentIndexAtDistance(distanceM);
    final startDistanceM = cumulativeMeters[index];
    final endDistanceM = cumulativeMeters[index + 1];
    final ratio = _distanceRatio(
      distanceM: distanceM,
      startDistanceM: startDistanceM,
      endDistanceM: endDistanceM,
    );
    final startElapsedMs = points[index].timestampRelMs;
    final endElapsedMs = points[index + 1].timestampRelMs;
    return startElapsedMs + ((endElapsedMs - startElapsedMs) * ratio);
  }

  int _segmentIndexAtDistance(double distanceM) {
    for (var index = 0; index < cumulativeMeters.length - 1; index += 1) {
      if (distanceM <= cumulativeMeters[index + 1]) {
        return index;
      }
    }

    return cumulativeMeters.length - 2;
  }

  double _distanceRatio({
    required double distanceM,
    required double startDistanceM,
    required double endDistanceM,
  }) {
    final segmentDistanceM = endDistanceM - startDistanceM;
    if (segmentDistanceM <= 0) {
      return 0;
    }

    return ((distanceM - startDistanceM) / segmentDistanceM)
        .clamp(0.0, 1.0)
        .toDouble();
  }
}
