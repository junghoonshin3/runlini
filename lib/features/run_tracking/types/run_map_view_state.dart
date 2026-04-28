import 'package:runlini/core/map/map_coordinate.dart';
import 'package:runlini/core/map/map_polyline_segment.dart';
import 'package:runlini/features/run_tracking/types/run_session.dart';

class RunMapViewState {
  const RunMapViewState({
    required this.mapCenter,
    this.runnerMarkerPoint,
    this.recenterTargetPoint,
    required this.currentRunnerPolylinePoints,
    required this.ghostPolylinePoints,
    this.ghostPolylineSegments = const <MapPolylineSegment>[],
    this.ghostMarkerPoint,
    this.selectedGhostSession,
  });

  final MapCoordinate mapCenter;
  final MapCoordinate? runnerMarkerPoint;
  final MapCoordinate? recenterTargetPoint;
  final List<MapCoordinate> currentRunnerPolylinePoints;
  final List<MapCoordinate> ghostPolylinePoints;
  final List<MapPolylineSegment> ghostPolylineSegments;
  final MapCoordinate? ghostMarkerPoint;
  final RunSession? selectedGhostSession;

  RunMapViewState copyWith({
    MapCoordinate? mapCenter,
    MapCoordinate? runnerMarkerPoint,
    MapCoordinate? recenterTargetPoint,
    List<MapCoordinate>? currentRunnerPolylinePoints,
    List<MapCoordinate>? ghostPolylinePoints,
    List<MapPolylineSegment>? ghostPolylineSegments,
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
      ghostPolylinePoints: ghostPolylinePoints ?? this.ghostPolylinePoints,
      ghostPolylineSegments:
          ghostPolylineSegments ?? this.ghostPolylineSegments,
      ghostMarkerPoint: clearGhostMarkerPoint
          ? null
          : ghostMarkerPoint ?? this.ghostMarkerPoint,
      selectedGhostSession: selectedGhostSession ?? this.selectedGhostSession,
    );
  }
}
