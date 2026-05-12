// Apple 지도 러닝 polyline과 코스 endpoint marker를 만든다.
import 'package:apple_maps_flutter/apple_maps_flutter.dart' as amap;
import 'package:flutter/material.dart';
import 'package:runlini/app/theme/app_colors.dart';
import 'package:runlini/core/map/apple_map_coordinate_adapter.dart';
import 'package:runlini/core/map/map_coordinate.dart';
import 'package:runlini/core/map/map_polyline_segment.dart';
import 'package:runlini/core/map/map_route_endpoint_marker.dart';

Set<amap.Polyline> appleRunnerPolylines({
  required List<MapCoordinate> points,
  required List<MapPolylineSegment> segments,
}) {
  final routeSegments = segments.isEmpty
      ? <MapPolylineSegment>[
          if (points.length >= 2)
            MapPolylineSegment(points: points, color: AppColors.voltGreen),
        ]
      : segments;
  return <amap.Polyline>{
    for (var index = 0; index < routeSegments.length; index += 1)
      _applePolyline(
        id: 'runner-polyline-$index',
        points: routeSegments[index].points,
        color: routeSegments[index].color,
        width: 6,
        zIndex: 2,
      ),
  };
}

Set<amap.Polyline> appleRecordRacePolylines({
  required List<MapCoordinate> points,
  required List<MapPolylineSegment> segments,
}) {
  if (segments.isEmpty && points.isEmpty) {
    return const <amap.Polyline>{};
  }

  final routeSegments = segments.isEmpty
      ? <MapPolylineSegment>[
          MapPolylineSegment(points: points, color: AppColors.electricRed),
        ]
      : segments;
  return <amap.Polyline>{
    for (var index = 0; index < routeSegments.length; index += 1)
      _applePolyline(
        id: 'record-race-polyline-$index',
        points: routeSegments[index].points,
        color: routeSegments[index].color,
        width: 10,
        zIndex: 1,
      ),
  };
}

Set<amap.Annotation> appleRouteEndpointAnnotations({
  required List<MapRouteEndpointMarker> markers,
  required Map<MapRouteEndpointRole, amap.BitmapDescriptor>? icons,
}) {
  if (icons == null) {
    return const <amap.Annotation>{};
  }

  return <amap.Annotation>{
    for (final marker in markers)
      if (icons[marker.role] != null)
        amap.Annotation(
          annotationId: amap.AnnotationId(_endpointMarkerId(marker.role)),
          position: marker.coordinate.toAppleLatLng(),
          anchor: const Offset(0.34, 0.92),
          icon: icons[marker.role]!,
          zIndex: 1,
        ),
  };
}

amap.Polyline _applePolyline({
  required String id,
  required List<MapCoordinate> points,
  required Color color,
  required int width,
  required int zIndex,
}) {
  return amap.Polyline(
    polylineId: amap.PolylineId(id),
    polylineCap: amap.Cap.roundCap,
    jointType: amap.JointType.round,
    points: points
        .map((MapCoordinate point) => point.toAppleLatLng())
        .toList(growable: false),
    color: color,
    width: width,
    zIndex: zIndex,
  );
}

String _endpointMarkerId(MapRouteEndpointRole role) {
  return switch (role) {
    MapRouteEndpointRole.start => 'record-race-route-start-marker',
    MapRouteEndpointRole.finish => 'record-race-route-finish-marker',
    MapRouteEndpointRole.startFinish => 'record-race-route-start-finish-marker',
  };
}
