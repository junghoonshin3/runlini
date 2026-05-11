import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:runlini/core/health/health_workout_recorder.dart';
import 'package:runlini/core/location/location_stream_client.dart';
import 'package:runlini/core/map/map_coordinate.dart';
import 'package:runlini/features/dashboard/state/app_shell_providers.dart';
import 'package:runlini/features/dashboard/types/app_tab.dart';
import 'package:runlini/features/ghost_racer/types/ghost_race_frame.dart';
import 'package:runlini/features/run_tracking/state/run_ghost_race_providers.dart';
import 'package:runlini/features/run_tracking/state/run_live_metrics_providers.dart';
import 'package:runlini/features/run_tracking/state/run_playback_providers.dart';
import 'package:runlini/features/run_tracking/state/run_settings_providers.dart';
import 'package:runlini/features/run_tracking/types/live_location_sample.dart';
import 'package:runlini/features/run_tracking/types/run_map_static_state.dart';
import 'package:runlini/features/run_tracking/types/run_point.dart';
import 'package:runlini/features/run_tracking/types/run_session.dart';

import 'run_playback_provider_harness.dart';

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
    LocationTrackingConfig? config,
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
  Future<HealthWorkoutExportResult> finishRunCapture({
    required DateTime startedAt,
    required DateTime endedAt,
    required List<RunPoint> recordedPoints,
  }) async {
    return const HealthWorkoutExportResult.synced();
  }

  @override
  Future<void> openHealthConnectInstall() async {}

  @override
  Future<HealthRunPreparationResult> prepareRunCapture() async {
    return HealthRunPreparationResult.ready;
  }
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
  container.read(appTabProvider.notifier).setTab(AppTab.running);
  await _settleAsync();
  container.read(liveLocationProvider);
  await container.read(liveLocationProvider.notifier).syncTracking();
  await _settleAsync();
}

Future<void> _confirmGhostStart({
  required _TrackingLocationStreamClient streamClient,
  required DateTime startedAt,
  required void Function(DateTime value) setNow,
}) async {
  setNow(startedAt.add(const Duration(seconds: 10)));
  await streamClient.emit(
    _sample(
      latitude: 0,
      longitude: 0.0003,
      capturedAt: startedAt.add(const Duration(seconds: 10)),
    ),
  );
  setNow(startedAt.add(const Duration(seconds: 20)));
  await streamClient.emit(
    _sample(
      latitude: 0,
      longitude: 0.0006,
      capturedAt: startedAt.add(const Duration(seconds: 20)),
    ),
  );
}

void main() {
  test('active ghost run shows the current ghost marker on the map', () async {
    final startedAt = DateTime(2026, 4, 20, 6);
    var now = startedAt;
    final tickerController = StreamController<int>.broadcast();
    final streamClient = _TrackingLocationStreamClient();
    final ghostSession = _ghostSession();
    final settingsRepository = TestRunSettingsRepository();
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
        runSettingsRepositoryProvider.overrideWithValue(settingsRepository),
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
    await _confirmGhostStart(
      streamClient: streamClient,
      startedAt: startedAt,
      setNow: (value) => now = value,
    );

    now = startedAt.add(const Duration(seconds: 25));
    await streamClient.emit(
      _sample(latitude: 0, longitude: 0.0008, capturedAt: now),
    );
    tickerController.add(1);
    await _settleAsync();

    expect(
      container
          .read(runPlaybackControllerProvider)
          .recordedPoints
          .last
          .longitude,
      closeTo(0.0008, 0.00001),
    );
    final frame = frameSubscription.read();
    expect(frame, isNotNull);
    expect(frame!.status, GhostRaceStatus.ahead);
    expect(frame.timeGapMs, greaterThan(20000));
    expect(frame.ghostMarkerPoint, isNotNull);

    final mapViewState = container.read(ghostAwareRunMapViewStateProvider);
    expect(mapViewState.ghostMarkerPoint, frame.ghostMarkerPoint);

    await container.read(runSettingsControllerProvider.future);
    await container
        .read(runSettingsControllerProvider.notifier)
        .setShowGhostMarker(true);
    await _settleAsync();

    final visibleMapViewState = container.read(
      ghostAwareRunMapViewStateProvider,
    );
    expect(visibleMapViewState.ghostMarkerPoint, frame.ghostMarkerPoint);
  });
}
