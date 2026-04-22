import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:runlini/core/health/health_workout_recorder.dart';
import 'package:runlini/core/location/location_stream_client.dart';
import 'package:runlini/core/map/map_coordinate.dart';
import 'package:runlini/features/ghost_racer/types/ghost_race_frame.dart';
import 'package:runlini/features/run_tracking/state/run_ghost_race_providers.dart';
import 'package:runlini/features/run_tracking/state/run_live_metrics_providers.dart';
import 'package:runlini/features/run_tracking/state/run_playback_providers.dart';
import 'package:runlini/features/run_tracking/types/live_location_sample.dart';
import 'package:runlini/features/run_tracking/types/run_map_static_state.dart';
import 'package:runlini/features/run_tracking/types/run_point.dart';
import 'package:runlini/features/run_tracking/types/run_session.dart';

class _TestDeviceLocationClient implements DeviceLocationClient {
  const _TestDeviceLocationClient();

  @override
  Future<LiveLocationSample?> fetchCurrentSample() async => null;

  @override
  Future<LiveLocationSample?> fetchLastKnownSample() async => null;
}

class _TrackingLocationStreamClient implements LocationStreamClient {
  _TrackingLocationStreamClient() {
    _controller = StreamController<LiveLocationSample>.broadcast();
  }

  late final StreamController<LiveLocationSample> _controller;

  @override
  Future<LiveLocationSample?> fetchCurrentSample() async => null;

  @override
  Future<LiveLocationSample?> fetchLastKnownSample() async => null;

  @override
  Stream<LiveLocationSample> watchLocationSamples({
    LocationTrackingMode mode = LocationTrackingMode.passive,
  }) => _controller.stream;

  Future<void> emit(LiveLocationSample sample) async {
    _controller.add(sample);
    await Future<void>.delayed(Duration.zero);
  }

  Future<void> close() async {
    await _controller.close();
  }
}

class _NoopHealthWorkoutRecorder implements HealthWorkoutRecorder {
  const _NoopHealthWorkoutRecorder();

  @override
  Future<void> beginRunCapture() async {}

  @override
  Future<void> cancelRunCapture() async {}

  @override
  Future<void> finishRunCapture({
    required DateTime startedAt,
    required DateTime endedAt,
    required List<RunPoint> recordedPoints,
  }) async {}

  @override
  Future<void> prepareRunCapture() async {}
}

LiveLocationSample _sample({
  required double latitude,
  required double longitude,
  required DateTime capturedAt,
}) {
  return LiveLocationSample(
    latitude: latitude,
    longitude: longitude,
    capturedAt: capturedAt,
    source: RunPointSource.deviceGps,
  );
}

RunSession _ghostSession() {
  return RunSession(
    id: 'ghost-route',
    startedAt: DateTime.utc(2026, 4, 19, 6),
    endedAt: DateTime.utc(2026, 4, 19, 6, 10),
    distanceM: 1000,
    durationMs: 600000,
    sourceSummary: 'test',
    points: const [
      RunPoint(
        latitude: 0,
        longitude: 0,
        timestampRelMs: 0,
        source: RunPointSource.simulated,
      ),
      RunPoint(
        latitude: 0,
        longitude: 0.009,
        timestampRelMs: 600000,
        source: RunPointSource.simulated,
      ),
    ],
  );
}

Future<void> _settleAsync() async {
  await Future<void>.delayed(Duration.zero);
  await Future<void>.delayed(Duration.zero);
}

Future<void> _startVisibleLiveTracking(ProviderContainer container) async {
  container.read(liveLocationProvider);
  await container.read(liveLocationProvider.notifier).syncTracking();
  await _settleAsync();
}

void main() {
  test(
    'ghost race frame uses accepted recorded points and exposes a map marker',
    () async {
      final startedAt = DateTime(2026, 4, 20, 6);
      var now = startedAt;
      final tickerController = StreamController<int>.broadcast();
      final streamClient = _TrackingLocationStreamClient();
      final ghostSession = _ghostSession();
      final container = ProviderContainer(
        overrides: [
          deviceLocationClientProvider.overrideWithValue(
            const _TestDeviceLocationClient(),
          ),
          locationStreamClientProvider.overrideWithValue(streamClient),
          healthWorkoutRecorderProvider.overrideWithValue(
            const _NoopHealthWorkoutRecorder(),
          ),
          runPlaybackClockProvider.overrideWithValue(() => now),
          liveRunMetricsTickerProvider.overrideWith(
            (Ref ref) => tickerController.stream,
          ),
          runMapStaticStateProvider.overrideWith((Ref ref) async {
            return RunMapStaticState(
              fallbackMapCenter: const MapCoordinate(latitude: 0, longitude: 0),
              ghostPolylinePoints: const <MapCoordinate>[
                MapCoordinate(latitude: 0, longitude: 0),
                MapCoordinate(latitude: 0, longitude: 0.009),
              ],
              selectedGhostSession: ghostSession,
            );
          }),
        ],
      );
      final frameSubscription = container.listen<GhostRaceFrame?>(
        ghostRaceFrameProvider,
        (GhostRaceFrame? previous, GhostRaceFrame? next) {},
      );
      addTearDown(() async {
        frameSubscription.close();
        container.dispose();
        await tickerController.close();
        await streamClient.close();
      });

      await container.read(runMapStaticStateProvider.future);
      await _startVisibleLiveTracking(container);
      await streamClient.emit(
        _sample(latitude: 0, longitude: 0, capturedAt: startedAt),
      );
      await container.read(runPlaybackControllerProvider.notifier).start();

      now = startedAt.add(const Duration(minutes: 4));
      await streamClient.emit(
        _sample(latitude: 0, longitude: 0.0045, capturedAt: now),
      );
      tickerController.add(1);
      await _settleAsync();

      final frame = frameSubscription.read();
      expect(frame, isNotNull);
      expect(frame!.status, GhostRaceStatus.ahead);
      expect(frame.timeGapMs, greaterThan(50000));
      expect(frame.ghostMarkerPoint, isNotNull);

      final mapViewState = container.read(ghostAwareRunMapViewStateProvider);
      expect(mapViewState, isNotNull);
      expect(mapViewState!.ghostMarkerPoint, frame.ghostMarkerPoint);
    },
  );

  test('ghost race frame freezes while playback is paused', () async {
    final startedAt = DateTime(2026, 4, 20, 6);
    var now = startedAt;
    final tickerController = StreamController<int>.broadcast();
    final streamClient = _TrackingLocationStreamClient();
    final ghostSession = _ghostSession();
    final container = ProviderContainer(
      overrides: [
        deviceLocationClientProvider.overrideWithValue(
          const _TestDeviceLocationClient(),
        ),
        locationStreamClientProvider.overrideWithValue(streamClient),
        healthWorkoutRecorderProvider.overrideWithValue(
          const _NoopHealthWorkoutRecorder(),
        ),
        runPlaybackClockProvider.overrideWithValue(() => now),
        liveRunMetricsTickerProvider.overrideWith(
          (Ref ref) => tickerController.stream,
        ),
        runMapStaticStateProvider.overrideWith((Ref ref) async {
          return RunMapStaticState(
            fallbackMapCenter: const MapCoordinate(latitude: 0, longitude: 0),
            ghostPolylinePoints: const <MapCoordinate>[
              MapCoordinate(latitude: 0, longitude: 0),
              MapCoordinate(latitude: 0, longitude: 0.009),
            ],
            selectedGhostSession: ghostSession,
          );
        }),
      ],
    );
    final frameSubscription = container.listen<GhostRaceFrame?>(
      ghostRaceFrameProvider,
      (GhostRaceFrame? previous, GhostRaceFrame? next) {},
    );
    addTearDown(() async {
      frameSubscription.close();
      container.dispose();
      await tickerController.close();
      await streamClient.close();
    });

    await container.read(runMapStaticStateProvider.future);
    await _startVisibleLiveTracking(container);
    await streamClient.emit(
      _sample(latitude: 0, longitude: 0, capturedAt: startedAt),
    );
    await container.read(runPlaybackControllerProvider.notifier).start();

    now = startedAt.add(const Duration(minutes: 4));
    await streamClient.emit(
      _sample(latitude: 0, longitude: 0.0045, capturedAt: now),
    );
    tickerController.add(1);
    await _settleAsync();
    final beforePause = frameSubscription.read()!;

    await container.read(runPlaybackControllerProvider.notifier).pause();
    now = startedAt.add(const Duration(minutes: 5));
    tickerController.add(2);
    await _settleAsync();

    final pausedFrame = frameSubscription.read()!;
    expect(pausedFrame.status, beforePause.status);
    expect(pausedFrame.timeGapMs, beforePause.timeGapMs);
    expect(pausedFrame.distanceGapM, beforePause.distanceGapM);
    expect(pausedFrame.ghostMarkerPoint, beforePause.ghostMarkerPoint);
  });
}
