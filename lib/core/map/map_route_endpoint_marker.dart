// 기록 레이스 코스 시작점과 종료점 지도 마커를 정의한다.
import 'package:latlong2/latlong.dart';
import 'package:runlini/core/map/map_coordinate.dart';

const double defaultRouteEndpointLoopThresholdM = 10;

enum MapRouteEndpointRole { start, finish, startFinish }

class MapRouteEndpointMarker {
  const MapRouteEndpointMarker({required this.coordinate, required this.role});

  final MapCoordinate coordinate;
  final MapRouteEndpointRole role;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }

    return other is MapRouteEndpointMarker &&
        other.coordinate == coordinate &&
        other.role == role;
  }

  @override
  int get hashCode => Object.hash(coordinate, role);
}

List<MapRouteEndpointMarker> mapRouteEndpointMarkersFor(
  List<MapCoordinate> points, {
  double loopThresholdM = defaultRouteEndpointLoopThresholdM,
}) {
  if (points.length < 2) {
    return const <MapRouteEndpointMarker>[];
  }

  final start = points.first;
  final finish = points.last;
  if (mapCoordinateDistanceM(start, finish) <= loopThresholdM) {
    return <MapRouteEndpointMarker>[
      MapRouteEndpointMarker(
        coordinate: start,
        role: MapRouteEndpointRole.startFinish,
      ),
    ];
  }

  return <MapRouteEndpointMarker>[
    MapRouteEndpointMarker(coordinate: start, role: MapRouteEndpointRole.start),
    MapRouteEndpointMarker(
      coordinate: finish,
      role: MapRouteEndpointRole.finish,
    ),
  ];
}

double mapCoordinateDistanceM(MapCoordinate left, MapCoordinate right) {
  const distance = Distance();
  return distance.as(
    LengthUnit.Meter,
    LatLng(left.latitude, left.longitude),
    LatLng(right.latitude, right.longitude),
  );
}
