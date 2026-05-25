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
    required this.recordRacePolylinePoints,
    this.recordRacePolylineSegments = const <MapPolylineSegment>[],
    this.recordRaceRouteEndpointMarkers = const <MapRouteEndpointMarker>[],
    this.recordRaceMarkerPoint,
    this.selectedRecordRaceSession,
  });

  final MapCoordinate mapCenter;
  final MapCoordinate? runnerMarkerPoint;
  final MapCoordinate? recenterTargetPoint;
  final List<MapCoordinate> currentRunnerPolylinePoints;
  final List<MapPolylineSegment> currentRunnerPolylineSegments;
  final List<MapCoordinate> recordRacePolylinePoints;
  final List<MapPolylineSegment> recordRacePolylineSegments;
  final List<MapRouteEndpointMarker> recordRaceRouteEndpointMarkers;
  final MapCoordinate? recordRaceMarkerPoint;
  final RunSession? selectedRecordRaceSession;

  RunMapViewState copyWith({
    MapCoordinate? mapCenter,
    MapCoordinate? runnerMarkerPoint,
    MapCoordinate? recenterTargetPoint,
    List<MapCoordinate>? currentRunnerPolylinePoints,
    List<MapPolylineSegment>? currentRunnerPolylineSegments,
    List<MapCoordinate>? recordRacePolylinePoints,
    List<MapPolylineSegment>? recordRacePolylineSegments,
    List<MapRouteEndpointMarker>? recordRaceRouteEndpointMarkers,
    MapCoordinate? recordRaceMarkerPoint,
    bool clearRecordRaceMarkerPoint = false,
    RunSession? selectedRecordRaceSession,
  }) {
    return RunMapViewState(
      mapCenter: mapCenter ?? this.mapCenter,
      runnerMarkerPoint: runnerMarkerPoint ?? this.runnerMarkerPoint,
      recenterTargetPoint: recenterTargetPoint ?? this.recenterTargetPoint,
      currentRunnerPolylinePoints:
          currentRunnerPolylinePoints ?? this.currentRunnerPolylinePoints,
      currentRunnerPolylineSegments:
          currentRunnerPolylineSegments ?? this.currentRunnerPolylineSegments,
      recordRacePolylinePoints:
          recordRacePolylinePoints ?? this.recordRacePolylinePoints,
      recordRacePolylineSegments:
          recordRacePolylineSegments ?? this.recordRacePolylineSegments,
      recordRaceRouteEndpointMarkers:
          recordRaceRouteEndpointMarkers ?? this.recordRaceRouteEndpointMarkers,
      recordRaceMarkerPoint: clearRecordRaceMarkerPoint
          ? null
          : recordRaceMarkerPoint ?? this.recordRaceMarkerPoint,
      selectedRecordRaceSession:
          selectedRecordRaceSession ?? this.selectedRecordRaceSession,
    );
  }
}
