// Google 지도 러닝 polyline과 코스 endpoint marker를 만든다.
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart' as gmap;
import 'package:runlini/app/theme/app_colors.dart';
import 'package:runlini/core/map/google_map_coordinate_adapter.dart';
import 'package:runlini/core/map/map_coordinate.dart';
import 'package:runlini/core/map/map_polyline_segment.dart';
import 'package:runlini/core/map/map_route_endpoint_marker.dart';

Set<gmap.Polyline> googleRunnerPolylines({
  required List<MapCoordinate> points,
  required List<MapPolylineSegment> segments,
}) {
  final routeSegments = segments.isEmpty
      ? <MapPolylineSegment>[
          if (points.length >= 2)
            MapPolylineSegment(points: points, color: AppColors.voltGreen),
        ]
      : segments;
  return <gmap.Polyline>{
    for (var index = 0; index < routeSegments.length; index += 1)
      _googlePolyline(
        id: 'runner-polyline-$index',
        points: routeSegments[index].points,
        color: routeSegments[index].color,
        width: 6,
        zIndex: 2,
      ),
  };
}

Set<gmap.Polyline> googleGhostPolylines({
  required List<MapCoordinate> points,
  required List<MapPolylineSegment> segments,
}) {
  if (segments.isEmpty && points.isEmpty) {
    return const <gmap.Polyline>{};
  }

  final routeSegments = segments.isEmpty
      ? <MapPolylineSegment>[
          MapPolylineSegment(points: points, color: AppColors.electricRed),
        ]
      : segments;
  return <gmap.Polyline>{
    for (var index = 0; index < routeSegments.length; index += 1)
      _googlePolyline(
        id: 'ghost-polyline-$index',
        points: routeSegments[index].points,
        color: routeSegments[index].color,
        width: 10,
        zIndex: 1,
      ),
  };
}

Set<gmap.Marker> googleRouteEndpointMarkers({
  required List<MapRouteEndpointMarker> markers,
  required Map<MapRouteEndpointRole, gmap.BitmapDescriptor>? icons,
}) {
  if (icons == null) {
    return const <gmap.Marker>{};
  }

  return <gmap.Marker>{
    for (final marker in markers)
      if (icons[marker.role] != null)
        gmap.Marker(
          markerId: gmap.MarkerId(_endpointMarkerId(marker.role)),
          position: marker.coordinate.toGoogleLatLng(),
          anchor: const Offset(0.34, 0.92),
          icon: icons[marker.role]!,
          zIndexInt: 1,
        ),
  };
}

gmap.Polyline _googlePolyline({
  required String id,
  required List<MapCoordinate> points,
  required Color color,
  required int width,
  required int zIndex,
}) {
  return gmap.Polyline(
    polylineId: gmap.PolylineId(id),
    startCap: gmap.Cap.roundCap,
    endCap: gmap.Cap.roundCap,
    jointType: gmap.JointType.round,
    points: points
        .map((MapCoordinate point) => point.toGoogleLatLng())
        .toList(growable: false),
    color: color,
    width: width,
    zIndex: zIndex,
  );
}

String _endpointMarkerId(MapRouteEndpointRole role) {
  return switch (role) {
    MapRouteEndpointRole.start => 'ghost-route-start-marker',
    MapRouteEndpointRole.finish => 'ghost-route-finish-marker',
    MapRouteEndpointRole.startFinish => 'ghost-route-start-finish-marker',
  };
}
