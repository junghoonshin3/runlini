// 테스트용 지도 표면에 기록 레이스 코스 시작과 종료 깃발을 그린다.
import 'package:flutter/material.dart';
import 'package:runlini/core/map/fake_run_map_painters.dart';
import 'package:runlini/core/map/map_coordinate.dart';
import 'package:runlini/core/map/map_route_endpoint_marker.dart';
import 'package:runlini/core/map/run_route_endpoint_icon_bytes.dart';

class FakeRunRouteEndpointMarkerLayer extends StatelessWidget {
  const FakeRunRouteEndpointMarkerLayer({
    super.key,
    required this.markers,
    required this.allPoints,
    required this.size,
  });

  final List<MapRouteEndpointMarker> markers;
  final List<MapCoordinate> allPoints;
  final Size size;

  @override
  Widget build(BuildContext context) {
    return KeyedSubtree(
      key: const Key('route-endpoint-marker-layer'),
      child: Stack(
        children: [
          for (final marker in markers)
            _PositionedEndpointMarker(
              marker: marker,
              allPoints: allPoints,
              size: size,
            ),
        ],
      ),
    );
  }
}

class _PositionedEndpointMarker extends StatelessWidget {
  const _PositionedEndpointMarker({
    required this.marker,
    required this.allPoints,
    required this.size,
  });

  final MapRouteEndpointMarker marker;
  final List<MapCoordinate> allPoints;
  final Size size;

  @override
  Widget build(BuildContext context) {
    final offset = fakeRunMapProject(marker.coordinate, allPoints, size);
    return Positioned(
      left: offset.dx - 14,
      top: offset.dy - 42,
      width: 40,
      height: 48,
      child: KeyedSubtree(
        key: _markerKey(marker.role),
        child: IgnorePointer(
          child: Image.asset(
            routeEndpointAssetPath(marker.role),
            fit: BoxFit.contain,
            filterQuality: FilterQuality.high,
          ),
        ),
      ),
    );
  }
}

Key _markerKey(MapRouteEndpointRole role) {
  return switch (role) {
    MapRouteEndpointRole.start => const Key('route-endpoint-marker-start'),
    MapRouteEndpointRole.finish => const Key('route-endpoint-marker-finish'),
    MapRouteEndpointRole.startFinish => const Key(
      'route-endpoint-marker-start-finish',
    ),
  };
}
