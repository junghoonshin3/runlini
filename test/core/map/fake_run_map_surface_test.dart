// 테스트용 지도 표면의 기록 레이스 코스 endpoint marker 렌더링을 검증한다.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:runlini/core/map/fake_run_map_surface.dart';
import 'package:runlini/core/map/map_coordinate.dart';
import 'package:runlini/core/map/map_route_endpoint_marker.dart';

void main() {
  testWidgets('renders separate start and finish route endpoint markers', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      const Directionality(
        textDirection: TextDirection.ltr,
        child: SizedBox(
          width: 320,
          height: 240,
          child: FakeRunMapSurface(
            mapCenter: MapCoordinate(latitude: 37.5, longitude: 127),
            currentRunnerPolylinePoints: <MapCoordinate>[],
            recordRacePolylinePoints: <MapCoordinate>[
              MapCoordinate(latitude: 37.5, longitude: 127),
              MapCoordinate(latitude: 37.5, longitude: 127.001),
            ],
            recordRacePolylineSegments: [],
            recordRaceRouteEndpointMarkers: <MapRouteEndpointMarker>[
              MapRouteEndpointMarker(
                coordinate: MapCoordinate(latitude: 37.5, longitude: 127),
                role: MapRouteEndpointRole.start,
              ),
              MapRouteEndpointMarker(
                coordinate: MapCoordinate(latitude: 37.5, longitude: 127.001),
                role: MapRouteEndpointRole.finish,
              ),
            ],
          ),
        ),
      ),
    );

    expect(
      find.byKey(const Key('route-endpoint-marker-layer')),
      findsOneWidget,
    );
    expect(
      find.byKey(const Key('route-endpoint-marker-start')),
      findsOneWidget,
    );
    expect(
      find.byKey(const Key('route-endpoint-marker-finish')),
      findsOneWidget,
    );
    expect(
      find.byKey(const Key('route-endpoint-marker-start-finish')),
      findsNothing,
    );
  });

  testWidgets('renders one combined marker for loop endpoints', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      const Directionality(
        textDirection: TextDirection.ltr,
        child: SizedBox(
          width: 320,
          height: 240,
          child: FakeRunMapSurface(
            mapCenter: MapCoordinate(latitude: 37.5, longitude: 127),
            currentRunnerPolylinePoints: <MapCoordinate>[],
            recordRacePolylinePoints: <MapCoordinate>[
              MapCoordinate(latitude: 37.5, longitude: 127),
              MapCoordinate(latitude: 37.50001, longitude: 127.00001),
            ],
            recordRacePolylineSegments: [],
            recordRaceRouteEndpointMarkers: <MapRouteEndpointMarker>[
              MapRouteEndpointMarker(
                coordinate: MapCoordinate(latitude: 37.5, longitude: 127),
                role: MapRouteEndpointRole.startFinish,
              ),
            ],
          ),
        ),
      ),
    );

    expect(
      find.byKey(const Key('route-endpoint-marker-start-finish')),
      findsOneWidget,
    );
    expect(find.byKey(const Key('route-endpoint-marker-start')), findsNothing);
    expect(find.byKey(const Key('route-endpoint-marker-finish')), findsNothing);
  });
}
