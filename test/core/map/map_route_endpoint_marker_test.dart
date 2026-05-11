// 고스트 코스 시작/종료 마커 판정 규칙을 검증한다.
import 'package:flutter_test/flutter_test.dart';
import 'package:runlini/core/map/map_coordinate.dart';
import 'package:runlini/core/map/map_route_endpoint_marker.dart';
import 'package:runlini/core/map/run_route_endpoint_icon_bytes.dart';

void main() {
  test('creates separate start and finish markers when endpoints differ', () {
    const points = <MapCoordinate>[
      MapCoordinate(latitude: 37.5, longitude: 127),
      MapCoordinate(latitude: 37.5, longitude: 127.001),
    ];

    final markers = mapRouteEndpointMarkersFor(points);

    expect(markers, const <MapRouteEndpointMarker>[
      MapRouteEndpointMarker(
        coordinate: MapCoordinate(latitude: 37.5, longitude: 127),
        role: MapRouteEndpointRole.start,
      ),
      MapRouteEndpointMarker(
        coordinate: MapCoordinate(latitude: 37.5, longitude: 127.001),
        role: MapRouteEndpointRole.finish,
      ),
    ]);
  });

  test('combines start and finish when endpoints are within 10m', () {
    const points = <MapCoordinate>[
      MapCoordinate(latitude: 37.5, longitude: 127),
      MapCoordinate(latitude: 37.50001, longitude: 127.00001),
    ];

    final markers = mapRouteEndpointMarkersFor(points);

    expect(markers, const <MapRouteEndpointMarker>[
      MapRouteEndpointMarker(
        coordinate: MapCoordinate(latitude: 37.5, longitude: 127),
        role: MapRouteEndpointRole.startFinish,
      ),
    ]);
  });

  test('keeps endpoints separate when distance is just over 10m', () {
    const points = <MapCoordinate>[
      MapCoordinate(latitude: 37.5, longitude: 127),
      MapCoordinate(latitude: 37.5001, longitude: 127),
    ];

    final markers = mapRouteEndpointMarkersFor(points);

    expect(markers, hasLength(2));
    expect(markers.first.role, MapRouteEndpointRole.start);
    expect(markers.last.role, MapRouteEndpointRole.finish);
  });

  test('maps endpoint roles to the requested flag asset filenames', () {
    expect(
      routeEndpointAssetPath(MapRouteEndpointRole.start),
      'assets/map/flag_start.png',
    );
    expect(
      routeEndpointAssetPath(MapRouteEndpointRole.finish),
      'assets/map/flag_finish.png',
    );
    expect(
      routeEndpointAssetPath(MapRouteEndpointRole.startFinish),
      'assets/map/flag_sf.png',
    );
  });
}
