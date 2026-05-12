import 'package:runlini/core/map/map_coordinate.dart';
import 'package:runlini/core/map/map_polyline_segment.dart';
import 'package:runlini/core/map/map_route_endpoint_marker.dart';
import 'package:runlini/features/run_tracking/types/run_session.dart';

class RunMapStaticState {
  const RunMapStaticState({
    required this.fallbackMapCenter,
    required this.recordRacePolylinePoints,
    this.recordRacePolylineSegments = const <MapPolylineSegment>[],
    this.recordRaceRouteEndpointMarkers = const <MapRouteEndpointMarker>[],
    this.selectedRecordRaceSession,
  });

  final MapCoordinate fallbackMapCenter;
  final List<MapCoordinate> recordRacePolylinePoints;
  final List<MapPolylineSegment> recordRacePolylineSegments;
  final List<MapRouteEndpointMarker> recordRaceRouteEndpointMarkers;
  final RunSession? selectedRecordRaceSession;
}
