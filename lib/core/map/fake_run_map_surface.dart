import 'package:flutter/material.dart';
import 'package:runlini/app/theme/app_colors.dart';
import 'package:runlini/core/map/fake_run_map_painters.dart';
import 'package:runlini/core/map/fake_run_route_endpoint_marker_layer.dart';
import 'package:runlini/core/map/map_coordinate.dart';
import 'package:runlini/core/map/map_polyline_segment.dart';
import 'package:runlini/core/map/map_route_endpoint_marker.dart';

class FakeRunMapSurface extends StatelessWidget {
  const FakeRunMapSurface({
    super.key,
    required this.mapCenter,
    this.runnerMarkerPoint,
    this.ghostMarkerPoint,
    required this.currentRunnerPolylinePoints,
    this.currentRunnerPolylineSegments = const <MapPolylineSegment>[],
    required this.ghostPolylinePoints,
    required this.ghostPolylineSegments,
    this.ghostRouteEndpointMarkers = const <MapRouteEndpointMarker>[],
  });

  final MapCoordinate mapCenter;
  final MapCoordinate? runnerMarkerPoint;
  final MapCoordinate? ghostMarkerPoint;
  final List<MapCoordinate> currentRunnerPolylinePoints;
  final List<MapPolylineSegment> currentRunnerPolylineSegments;
  final List<MapCoordinate> ghostPolylinePoints;
  final List<MapPolylineSegment> ghostPolylineSegments;
  final List<MapRouteEndpointMarker> ghostRouteEndpointMarkers;

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
      ...ghostRouteEndpointMarkers.map(
        (MapRouteEndpointMarker marker) => marker.coordinate,
      ),
      ...ghostPolylineSegments.expand(
        (MapPolylineSegment segment) => segment.points,
      ),
      ...currentRunnerPolylinePoints,
      ...currentRunnerPolylineSegments.expand(
        (MapPolylineSegment segment) => segment.points,
      ),
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
                              painter: FakeRunPolylinePainter(
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
              if (_runnerSegments().isNotEmpty)
                Positioned.fill(
                  child: KeyedSubtree(
                    key: const Key('runner-polyline-layer'),
                    child: Stack(
                      children: [
                        for (final segment in _runnerSegments())
                          Positioned.fill(
                            child: CustomPaint(
                              painter: FakeRunPolylinePainter(
                                points: segment.points,
                                allPoints: allPoints,
                                color: segment.color,
                                strokeWidth: 6,
                              ),
                            ),
                          ),
                      ],
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
                            final markerOffset = fakeRunMapProject(
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
                      if (ghostRouteEndpointMarkers.isNotEmpty)
                        Positioned.fill(
                          child: FakeRunRouteEndpointMarkerLayer(
                            markers: ghostRouteEndpointMarkers,
                            allPoints: allPoints,
                            size: constraints.biggest,
                          ),
                        ),
                      if (runnerMarkerPoint != null)
                        Builder(
                          builder: (BuildContext context) {
                            final markerOffset = fakeRunMapProject(
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

  List<MapPolylineSegment> _runnerSegments() {
    if (currentRunnerPolylineSegments.isNotEmpty) {
      return currentRunnerPolylineSegments;
    }
    if (currentRunnerPolylinePoints.length < 2) {
      return const <MapPolylineSegment>[];
    }
    return <MapPolylineSegment>[
      MapPolylineSegment(
        points: currentRunnerPolylinePoints,
        color: AppColors.voltGreen,
      ),
    ];
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
