import 'package:flutter_test/flutter_test.dart';
import 'package:runlini/core/map/map_coordinate.dart';
import 'package:runlini/features/run_tracking/types/run_point.dart';

void main() {
  test('maps run points to app-owned coordinates without changing order', () {
    const points = <RunPoint>[
      RunPoint(
        latitude: 37.5001,
        longitude: 127.031,
        timestampRelMs: 0,
        paceSecPerKm: 320,
        source: RunPointSource.simulated,
      ),
      RunPoint(
        latitude: 37.5006,
        longitude: 127.0318,
        timestampRelMs: 1000,
        paceSecPerKm: 315,
        source: RunPointSource.simulated,
      ),
    ];

    final coordinates = mapCoordinatesFromRunPoints(points);

    expect(coordinates, const <MapCoordinate>[
      MapCoordinate(latitude: 37.5001, longitude: 127.031),
      MapCoordinate(latitude: 37.5006, longitude: 127.0318),
    ]);
  });
}
