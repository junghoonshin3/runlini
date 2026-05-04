import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:runlini/app/theme/app_colors.dart';
import 'package:runlini/core/location/location_stream_client.dart';
import 'package:runlini/core/map/map_coordinate.dart';
import 'package:runlini/core/map/map_polyline_segment.dart';
import 'package:runlini/features/run_tracking/state/run_playback_providers.dart';
import 'package:runlini/features/run_tracking/types/live_location_sample.dart';
import 'package:runlini/features/run_tracking/types/run_map_static_state.dart';
import 'package:runlini/features/run_tracking/types/run_point.dart';

class _FixedDeviceLocationClient implements DeviceLocationClient {
  const _FixedDeviceLocationClient({this.currentSample});

  final LiveLocationSample? currentSample;

  @override
  Future<LiveLocationSample?> fetchLastKnownSample() async => null;

  @override
  Future<LiveLocationSample?> fetchCurrentSample() async => currentSample;
}

class _EmptyLocationStreamClient implements LocationStreamClient {
  const _EmptyLocationStreamClient();

  @override
  Future<LiveLocationSample?> fetchLastKnownSample() async => null;

  @override
  Future<LiveLocationSample?> fetchCurrentSample() async => null;

  @override
  Stream<LiveLocationSample> watchLocationSamples({
    LocationTrackingMode mode = LocationTrackingMode.passive,
    LocationTrackingConfig? config,
  }) => const Stream<LiveLocationSample>.empty();
}

LiveLocationSample _sample({
  required double latitude,
  required double longitude,
}) {
  return LiveLocationSample(
    latitude: latitude,
    longitude: longitude,
    capturedAt: DateTime(2026, 4, 20, 6),
    source: RunPointSource.deviceGps,
  );
}

void main() {
  test(
    'run map view state follows live location while preserving runner and ghost polylines',
    () async {
      final container = ProviderContainer(
        overrides: [
          deviceLocationClientProvider.overrideWithValue(
            _FixedDeviceLocationClient(
              currentSample: _sample(latitude: 37.55, longitude: 126.97),
            ),
          ),
          locationStreamClientProvider.overrideWithValue(
            const _EmptyLocationStreamClient(),
          ),
          currentRunnerPolylinePointsProvider.overrideWith(
            (Ref ref) => const <MapCoordinate>[
              MapCoordinate(latitude: 37.1, longitude: 127.1),
              MapCoordinate(latitude: 37.11, longitude: 127.11),
            ],
          ),
          runMapStaticStateProvider.overrideWith((Ref ref) async {
            return const RunMapStaticState(
              fallbackMapCenter: MapCoordinate(
                latitude: 37.0,
                longitude: 127.0,
              ),
              ghostPolylinePoints: <MapCoordinate>[
                MapCoordinate(latitude: 37.2, longitude: 127.2),
                MapCoordinate(latitude: 37.3, longitude: 127.3),
              ],
              ghostPolylineSegments: <MapPolylineSegment>[
                MapPolylineSegment(
                  points: <MapCoordinate>[
                    MapCoordinate(latitude: 37.2, longitude: 127.2),
                    MapCoordinate(latitude: 37.3, longitude: 127.3),
                  ],
                  color: AppColors.voltGreen,
                ),
              ],
            );
          }),
        ],
      );
      addTearDown(container.dispose);

      await container.read(liveLocationProvider.notifier).refresh();
      await container.read(runMapStaticStateProvider.future);
      final mapViewState = container.read(runMapViewStateProvider);

      expect(
        mapViewState.mapCenter,
        const MapCoordinate(latitude: 37.55, longitude: 126.97),
      );
      expect(
        mapViewState.runnerMarkerPoint,
        const MapCoordinate(latitude: 37.55, longitude: 126.97),
      );
      expect(mapViewState.currentRunnerPolylinePoints, hasLength(2));
      expect(mapViewState.ghostPolylinePoints, hasLength(2));
      expect(mapViewState.ghostPolylineSegments, hasLength(1));
      expect(
        mapViewState.ghostPolylineSegments.first.color,
        AppColors.voltGreen,
      );
    },
  );

  test(
    'run map view state falls back to the fixture center without live GPS',
    () async {
      final container = ProviderContainer(
        overrides: [
          deviceLocationClientProvider.overrideWithValue(
            const _FixedDeviceLocationClient(),
          ),
          locationStreamClientProvider.overrideWithValue(
            const _EmptyLocationStreamClient(),
          ),
          currentRunnerPolylinePointsProvider.overrideWith(
            (Ref ref) => const <MapCoordinate>[
              MapCoordinate(latitude: 37.1, longitude: 127.1),
            ],
          ),
          runMapStaticStateProvider.overrideWith((Ref ref) async {
            return const RunMapStaticState(
              fallbackMapCenter: MapCoordinate(
                latitude: 37.44,
                longitude: 127.44,
              ),
              ghostPolylinePoints: <MapCoordinate>[],
            );
          }),
        ],
      );
      addTearDown(container.dispose);

      await container.read(runMapStaticStateProvider.future);
      final mapViewState = container.read(runMapViewStateProvider);

      expect(
        mapViewState.mapCenter,
        const MapCoordinate(latitude: 37.44, longitude: 127.44),
      );
      expect(mapViewState.runnerMarkerPoint, isNull);
      expect(mapViewState.currentRunnerPolylinePoints, hasLength(1));
    },
  );

  test(
    'run map view state uses the Seoul fallback while static state loads',
    () {
      final pendingStaticState = Completer<RunMapStaticState>();
      final container = ProviderContainer(
        overrides: [
          deviceLocationClientProvider.overrideWithValue(
            const _FixedDeviceLocationClient(),
          ),
          locationStreamClientProvider.overrideWithValue(
            const _EmptyLocationStreamClient(),
          ),
          runMapStaticStateProvider.overrideWith((Ref ref) {
            return pendingStaticState.future;
          }),
        ],
      );
      addTearDown(container.dispose);

      final mapViewState = container.read(runMapViewStateProvider);

      expect(
        mapViewState.mapCenter,
        const MapCoordinate(latitude: 37.5665, longitude: 126.9780),
      );
      expect(mapViewState.runnerMarkerPoint, isNull);
      expect(mapViewState.ghostPolylinePoints, isEmpty);
      expect(mapViewState.ghostPolylineSegments, isEmpty);
    },
  );

  test('run map view state keeps rendering when static state fails', () {
    final container = ProviderContainer(
      overrides: [
        deviceLocationClientProvider.overrideWithValue(
          const _FixedDeviceLocationClient(),
        ),
        locationStreamClientProvider.overrideWithValue(
          const _EmptyLocationStreamClient(),
        ),
        runMapStaticStateProvider.overrideWith((Ref ref) async {
          throw StateError('static map state failed');
        }),
      ],
    );
    addTearDown(container.dispose);

    final mapViewState = container.read(runMapViewStateProvider);

    expect(
      mapViewState.mapCenter,
      const MapCoordinate(latitude: 37.5665, longitude: 126.9780),
    );
    expect(mapViewState.runnerMarkerPoint, isNull);
    expect(mapViewState.ghostPolylinePoints, isEmpty);
    expect(mapViewState.ghostPolylineSegments, isEmpty);
  });
}
