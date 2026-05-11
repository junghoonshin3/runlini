import 'package:runlini/core/map/map_coordinate.dart';
import 'package:runlini/core/map/map_polyline_segment.dart';
import 'package:runlini/core/map/map_route_endpoint_marker.dart';
import 'package:runlini/features/run_tracking/types/run_session.dart';

class RunMapViewState {
  const RunMapViewState({
    required this.mapCenter,
    this.runnerMarkerPoint,
    this.recenterTargetPoint,
    required this.currentRunnerPolylinePoints,
    this.currentRunnerPolylineSegments = const <MapPolylineSegment>[],
    required this.ghostPolylinePoints,
    this.ghostPolylineSegments = const <MapPolylineSegment>[],
    this.ghostRouteEndpointMarkers = const <MapRouteEndpointMarker>[],
    this.ghostMarkerPoint,
    this.selectedGhostSession,
  });

  final MapCoordinate mapCenter;
  final MapCoordinate? runnerMarkerPoint;
  final MapCoordinate? recenterTargetPoint;
  final List<MapCoordinate> currentRunnerPolylinePoints;
  final List<MapPolylineSegment> currentRunnerPolylineSegments;
  final List<MapCoordinate> ghostPolylinePoints;
  final List<MapPolylineSegment> ghostPolylineSegments;
  final List<MapRouteEndpointMarker> ghostRouteEndpointMarkers;
  final MapCoordinate? ghostMarkerPoint;
  final RunSession? selectedGhostSession;

  RunMapViewState copyWith({
    MapCoordinate? mapCenter,
    MapCoordinate? runnerMarkerPoint,
    MapCoordinate? recenterTargetPoint,
    List<MapCoordinate>? currentRunnerPolylinePoints,
    List<MapPolylineSegment>? currentRunnerPolylineSegments,
    List<MapCoordinate>? ghostPolylinePoints,
    List<MapPolylineSegment>? ghostPolylineSegments,
    List<MapRouteEndpointMarker>? ghostRouteEndpointMarkers,
    MapCoordinate? ghostMarkerPoint,
    bool clearGhostMarkerPoint = false,
    RunSession? selectedGhostSession,
  }) {
    return RunMapViewState(
      mapCenter: mapCenter ?? this.mapCenter,
      runnerMarkerPoint: runnerMarkerPoint ?? this.runnerMarkerPoint,
      recenterTargetPoint: recenterTargetPoint ?? this.recenterTargetPoint,
      currentRunnerPolylinePoints:
          currentRunnerPolylinePoints ?? this.currentRunnerPolylinePoints,
      currentRunnerPolylineSegments:
          currentRunnerPolylineSegments ?? this.currentRunnerPolylineSegments,
      ghostPolylinePoints: ghostPolylinePoints ?? this.ghostPolylinePoints,
      ghostPolylineSegments:
          ghostPolylineSegments ?? this.ghostPolylineSegments,
      ghostRouteEndpointMarkers:
          ghostRouteEndpointMarkers ?? this.ghostRouteEndpointMarkers,
      ghostMarkerPoint: clearGhostMarkerPoint
          ? null
          : ghostMarkerPoint ?? this.ghostMarkerPoint,
      selectedGhostSession: selectedGhostSession ?? this.selectedGhostSession,
    );
  }
}
