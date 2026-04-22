import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:runlini/app/theme/app_colors.dart';
import 'package:runlini/core/map/map_coordinate.dart';
import 'package:runlini/core/map/map_polyline_segment.dart';

class FakeRunMapSurface extends StatelessWidget {
  const FakeRunMapSurface({
    super.key,
    required this.mapCenter,
    this.runnerMarkerPoint,
    this.ghostMarkerPoint,
    required this.currentRunnerPolylinePoints,
    required this.ghostPolylinePoints,
    required this.ghostPolylineSegments,
  });

  final MapCoordinate mapCenter;
  final MapCoordinate? runnerMarkerPoint;
  final MapCoordinate? ghostMarkerPoint;
  final List<MapCoordinate> currentRunnerPolylinePoints;
  final List<MapCoordinate> ghostPolylinePoints;
  final List<MapPolylineSegment> ghostPolylineSegments;

  @override
  Widget build(BuildContext context) {
    final runnerMarkerPoints = runnerMarkerPoint == null
        ? null
        : <MapCoordinate>[runnerMarkerPoint!];
    final ghostMarkerPoints = ghostMarkerPoint == null
        ? null
        : <MapCoordinate>[ghostMarkerPoint!];
    final allPoints = <MapCoordinate>[
      mapCenter,
      ...?runnerMarkerPoints,
      ...?ghostMarkerPoints,
      ...ghostPolylinePoints,
      ...ghostPolylineSegments.expand(
        (MapPolylineSegment segment) => segment.points,
      ),
      ...currentRunnerPolylinePoints,
    ];

    return ColoredBox(
      color: AppColors.graphite,
      child: LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
          return Stack(
            children: [
              const Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: <Color>[AppColors.panel, AppColors.graphite],
                    ),
                  ),
                ),
              ),
              if (ghostPolylinePoints.isNotEmpty ||
                  ghostPolylineSegments.isNotEmpty)
                Positioned.fill(
                  child: KeyedSubtree(
                    key: const Key('ghost-polyline-layer'),
                    child: Stack(
                      children: [
                        for (final segment in _ghostSegments())
                          Positioned.fill(
                            child: CustomPaint(
                              painter: _PolylinePainter(
                                points: segment.points,
                                allPoints: allPoints,
                                color: segment.color,
                                strokeWidth: 10,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              if (currentRunnerPolylinePoints.isNotEmpty)
                Positioned.fill(
                  child: KeyedSubtree(
                    key: const Key('runner-polyline-layer'),
                    child: CustomPaint(
                      painter: _PolylinePainter(
                        points: currentRunnerPolylinePoints,
                        allPoints: allPoints,
                        color: AppColors.voltGreen,
                        strokeWidth: 6,
                      ),
                    ),
                  ),
                ),
              Positioned.fill(
                child: KeyedSubtree(
                  key: const Key('run-map'),
                  child: Stack(
                    children: [
                      if (ghostMarkerPoint != null)
                        Builder(
                          builder: (BuildContext context) {
                            final markerOffset = _project(
                              ghostMarkerPoint!,
                              allPoints,
                              constraints.biggest,
                            );
                            return Positioned(
                              left: markerOffset.dx - 16,
                              top: markerOffset.dy - 16,
                              width: 32,
                              height: 32,
                              child: const KeyedSubtree(
                                key: Key('ghost-marker-layer'),
                                child: IgnorePointer(
                                  child: DecoratedBox(
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: AppColors.chalk,
                                    ),
                                    child: Padding(
                                      padding: EdgeInsets.all(5),
                                      child: DecoratedBox(
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          color: AppColors.electricRed,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      if (runnerMarkerPoint != null)
                        Builder(
                          builder: (BuildContext context) {
                            final markerOffset = _project(
                              runnerMarkerPoint!,
                              allPoints,
                              constraints.biggest,
                            );
                            return Positioned(
                              left: markerOffset.dx - 24,
                              top: markerOffset.dy - 48,
                              width: 48,
                              height: 48,
                              child: const KeyedSubtree(
                                key: Key('runner-marker-layer'),
                                child: IgnorePointer(
                                  child: FittedBox(
                                    fit: BoxFit.contain,
                                    child: Icon(
                                      Icons.location_on_rounded,
                                      color: AppColors.electricRed,
                                      size: 48,
                                    ),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  List<MapPolylineSegment> _ghostSegments() {
    if (ghostPolylineSegments.isNotEmpty) {
      return ghostPolylineSegments;
    }

    return <MapPolylineSegment>[
      MapPolylineSegment(
        points: ghostPolylinePoints,
        color: AppColors.electricRed,
      ),
    ];
  }
}

class _PolylinePainter extends CustomPainter {
  const _PolylinePainter({
    required this.points,
    required this.allPoints,
    required this.color,
    required this.strokeWidth,
  });

  final List<MapCoordinate> points;
  final List<MapCoordinate> allPoints;
  final Color color;
  final double strokeWidth;

  @override
  void paint(Canvas canvas, Size size) {
    if (points.length < 2) {
      return;
    }

    final path = Path();
    final projected = points
        .map((MapCoordinate point) => _project(point, allPoints, size))
        .toList(growable: false);

    path.moveTo(projected.first.dx, projected.first.dy);
    for (final point in projected.skip(1)) {
      path.lineTo(point.dx, point.dy);
    }

    final borderPaint = Paint()
      ..color = AppColors.black
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth + 3
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    canvas.drawPath(path, borderPaint);

    final linePaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    canvas.drawPath(path, linePaint);
  }

  @override
  bool shouldRepaint(covariant _PolylinePainter oldDelegate) {
    return oldDelegate.points != points ||
        oldDelegate.allPoints != allPoints ||
        oldDelegate.color != color ||
        oldDelegate.strokeWidth != strokeWidth;
  }
}

Offset _project(MapCoordinate point, List<MapCoordinate> allPoints, Size size) {
  const double padding = 24;
  final usableWidth = math.max(size.width - (padding * 2), 1);
  final usableHeight = math.max(size.height - (padding * 2), 1);

  final latitudes = allPoints.map((MapCoordinate point) => point.latitude);
  final longitudes = allPoints.map((MapCoordinate point) => point.longitude);

  final minLat = latitudes.reduce(math.min);
  final maxLat = latitudes.reduce(math.max);
  final minLng = longitudes.reduce(math.min);
  final maxLng = longitudes.reduce(math.max);

  final latRange = math.max(maxLat - minLat, 0.0001);
  final lngRange = math.max(maxLng - minLng, 0.0001);

  final x = padding + ((point.longitude - minLng) / lngRange) * usableWidth;
  final y = padding + ((maxLat - point.latitude) / latRange) * usableHeight;
  return Offset(x, y);
}
