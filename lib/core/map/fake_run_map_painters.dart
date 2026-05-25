// 테스트용 지도 표면의 route projection과 polyline painter를 제공한다.
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:runlini/app/theme/app_colors.dart';
import 'package:runlini/core/map/map_coordinate.dart';

class FakeRunPolylinePainter extends CustomPainter {
  const FakeRunPolylinePainter({
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
        .map((MapCoordinate point) => fakeRunMapProject(point, allPoints, size))
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
  bool shouldRepaint(covariant FakeRunPolylinePainter oldDelegate) {
    return oldDelegate.points != points ||
        oldDelegate.allPoints != allPoints ||
        oldDelegate.color != color ||
        oldDelegate.strokeWidth != strokeWidth;
  }
}

Offset fakeRunMapProject(
  MapCoordinate point,
  List<MapCoordinate> allPoints,
  Size size,
) {
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
