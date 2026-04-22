import 'package:runlini/core/map/map_coordinate.dart';
import 'package:runlini/core/map/map_polyline_segment.dart';
import 'package:runlini/features/run_tracking/types/run_session.dart';

class RunMapStaticState {
  const RunMapStaticState({
    required this.fallbackMapCenter,
    required this.ghostPolylinePoints,
    this.ghostPolylineSegments = const <MapPolylineSegment>[],
    this.selectedGhostSession,
  });

  final MapCoordinate fallbackMapCenter;
  final List<MapCoordinate> ghostPolylinePoints;
  final List<MapPolylineSegment> ghostPolylineSegments;
  final RunSession? selectedGhostSession;
}
