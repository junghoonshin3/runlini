// 기록 레이스 기록 선택에서 경로 모양 미리보기를 그리는 위젯
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:runlini/app/theme/app_colors.dart';
import 'package:runlini/core/map/map_coordinate.dart';
import 'package:runlini/core/map/map_polyline_segment.dart';
import 'package:runlini/features/run_tracking/service/pace_colored_route_segment_builder.dart';
import 'package:runlini/features/run_tracking/service/run_route_segmenter.dart';
import 'package:runlini/features/run_tracking/types/run_point.dart';

class RecordRaceRouteShapePreview extends StatelessWidget {
  const RecordRaceRouteShapePreview({
    super.key,
    required this.points,
    this.isLoading = false,
    this.errorMessage,
  });

  final List<RunPoint>? points;
  final bool isLoading;
  final String? errorMessage;

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const Key('record-race-route-shape-preview'),
      height: 150,
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.black,
        border: Border.all(color: AppColors.chalk, width: 3),
        borderRadius: BorderRadius.circular(6),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(3),
        child: _body(context),
      ),
    );
  }

  Widget _body(BuildContext context) {
    if (isLoading) {
      return const _RouteShapeMessage(
        key: Key('record-race-route-shape-loading'),
        message: '경로를 불러오는 중',
      );
    }
    if (errorMessage != null) {
      return _RouteShapeMessage(
        key: const Key('record-race-route-shape-fallback'),
        message: errorMessage!,
      );
    }

    final routePoints = points;
    if (routePoints == null || routePoints.length < 2) {
      return const _RouteShapeMessage(
        key: Key('record-race-route-shape-fallback'),
        message: '경로 데이터가 부족해요.',
      );
    }

    final route = const RunRouteSegmenter().segment(routePoints);
    final routeSegments = const PaceColoredRouteSegmentBuilder()
        .buildRouteSegments(route.segments);
    if (routeSegments.isEmpty) {
      return const _RouteShapeMessage(
        key: Key('record-race-route-shape-fallback'),
        message: '경로 데이터가 부족해요.',
      );
    }

    return CustomPaint(
      key: const Key('record-race-route-shape-layer'),
      painter: _RecordRaceRouteShapePainter(routeSegments),
      child: const SizedBox.expand(),
    );
  }
}

class _RouteShapeMessage extends StatelessWidget {
  const _RouteShapeMessage({super.key, required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        message,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
          color: AppColors.muted,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _RecordRaceRouteShapePainter extends CustomPainter {
  const _RecordRaceRouteShapePainter(this.segments);

  final List<MapPolylineSegment> segments;

  @override
  void paint(Canvas canvas, Size size) {
    final allPoints = segments
        .expand((MapPolylineSegment segment) => segment.points)
        .toList(growable: false);
    if (allPoints.length < 2) {
      return;
    }

    final bounds = _RouteBounds.from(allPoints);
    final transform = _RouteTransform(bounds: bounds, size: size);
    final basePaint = Paint()
      ..color = AppColors.chalk.withValues(alpha: 0.14)
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke
      ..strokeWidth = 8;
    final segmentPaint = Paint()
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5;

    for (final segment in segments) {
      final path = _pathFor(segment.points, transform);
      canvas.drawPath(path, basePaint);
    }
    for (final segment in segments) {
      segmentPaint.color = segment.color;
      canvas.drawPath(_pathFor(segment.points, transform), segmentPaint);
    }

    _drawDot(canvas, transform.project(allPoints.first), AppColors.voltGreen);
    _drawDot(canvas, transform.project(allPoints.last), AppColors.electricRed);
  }

  Path _pathFor(List<MapCoordinate> points, _RouteTransform transform) {
    final path = Path();
    for (var index = 0; index < points.length; index += 1) {
      final offset = transform.project(points[index]);
      if (index == 0) {
        path.moveTo(offset.dx, offset.dy);
      } else {
        path.lineTo(offset.dx, offset.dy);
      }
    }
    return path;
  }

  void _drawDot(Canvas canvas, Offset center, Color color) {
    final outline = Paint()..color = AppColors.black;
    final fill = Paint()..color = color;
    canvas.drawCircle(center, 7, outline);
    canvas.drawCircle(center, 4.5, fill);
  }

  @override
  bool shouldRepaint(covariant _RecordRaceRouteShapePainter oldDelegate) {
    return oldDelegate.segments != segments;
  }
}

class _RouteBounds {
  const _RouteBounds({
    required this.minLat,
    required this.maxLat,
    required this.minLng,
    required this.maxLng,
  });

  factory _RouteBounds.from(List<MapCoordinate> points) {
    var minLat = points.first.latitude;
    var maxLat = points.first.latitude;
    var minLng = points.first.longitude;
    var maxLng = points.first.longitude;
    for (final point in points.skip(1)) {
      minLat = math.min(minLat, point.latitude);
      maxLat = math.max(maxLat, point.latitude);
      minLng = math.min(minLng, point.longitude);
      maxLng = math.max(maxLng, point.longitude);
    }
    return _RouteBounds(
      minLat: minLat,
      maxLat: maxLat,
      minLng: minLng,
      maxLng: maxLng,
    );
  }

  final double minLat;
  final double maxLat;
  final double minLng;
  final double maxLng;

  double get latSpan => math.max(maxLat - minLat, 0.00001);
  double get lngSpan => math.max(maxLng - minLng, 0.00001);
}

class _RouteTransform {
  const _RouteTransform({required this.bounds, required this.size});

  static const double _padding = 18;

  final _RouteBounds bounds;
  final Size size;

  Offset project(MapCoordinate point) {
    final drawWidth = math.max(size.width - (_padding * 2), 1.0);
    final drawHeight = math.max(size.height - (_padding * 2), 1.0);
    final scale = math.min(
      drawWidth / bounds.lngSpan,
      drawHeight / bounds.latSpan,
    );
    final contentWidth = bounds.lngSpan * scale;
    final contentHeight = bounds.latSpan * scale;
    final left = (size.width - contentWidth) / 2;
    final top = (size.height - contentHeight) / 2;
    final x = left + ((point.longitude - bounds.minLng) * scale);
    final y = top + ((bounds.maxLat - point.latitude) * scale);
    return Offset(x, y);
  }
}
