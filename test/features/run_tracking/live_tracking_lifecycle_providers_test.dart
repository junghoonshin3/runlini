import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:runlini/core/location/location_stream_client.dart';
import 'package:runlini/features/dashboard/state/app_shell_providers.dart';
import 'package:runlini/features/dashboard/types/app_tab.dart';
import 'package:runlini/features/run_tracking/repo/run_settings_repository.dart';
import 'package:runlini/features/run_tracking/state/run_playback_providers.dart';
import 'package:runlini/features/run_tracking/state/run_session_providers.dart';
import 'package:runlini/features/run_tracking/state/run_settings_providers.dart';
import 'package:runlini/features/run_tracking/types/live_location_sample.dart';
import 'package:runlini/features/run_tracking/types/run_point.dart';
import 'package:runlini/features/run_tracking/types/run_screen_status.dart';
import 'package:runlini/features/run_tracking/types/run_session.dart';
import 'package:runlini/features/run_tracking/types/run_settings.dart';
import 'package:runlini/features/run_tracking/types/run_shoe.dart';

import 'run_playback_provider_harness.dart';

void main() {
  test('maps location tracking presets to passive and workout configs', () {
    expect(
      locationTrackingConfigForPreset(
        RunLocationTrackingPreset.batterySaver,
        LocationTrackingMode.passive,
      ),
      const LocationTrackingConfig(
        androidInterval: Duration(seconds: 5),
        distanceFilterM: 10,
      ),
    );
    expect(
      locationTrackingConfigForPreset(
        RunLocationTrackingPreset.balanced,
        LocationTrackingMode.workout,
      ),
      LocationTrackingConfig.workoutDefault,
    );
    expect(
      locationTrackingConfigForPreset(
        RunLocationTrackingPreset.highAccuracy,
        LocationTrackingMode.workout,
      ),
      const LocationTrackingConfig(
        androidInterval: Duration(seconds: 1),
        distanceFilterM: 1,
      ),
    );
  });

  test(
    'idle live tracking stops when the user leaves the running tab',
    () async {
      final streamClient = TrackingLocationStreamClient();
      final container = ProviderContainer(
        overrides: [
          deviceLocationClientProvider.overrideWithValue(
            TestDeviceLocationClient(),
          ),
          locationStreamClientProvider.overrideWithValue(streamClient),
        ],
      );
      addTearDown(() async {
        await streamClient.close();
        container.dispose();
      });

      container.read(liveLocationProvider);
      await settleAsync();
      expect(streamClient.activeSubscriptions, 0);

      container.read(appTabProvider.notifier).setTab(AppTab.running);
      await settleAsync();
      await container.read(liveLocationProvider.notifier).syncTracking();
      await settleAsync();
      expect(streamClient.activeSubscriptions, 1);
      expect(streamClient.lastWatchMode, LocationTrackingMode.passive);

      container.read(appTabProvider.notifier).setTab(AppTab.history);
      await settleAsync();

      expect(streamClient.activeSubscriptions, 0);
    },
  );

  test(
    'paused live tracking stops when the user leaves the running tab',
    () async {
      final startedAt = DateTime(2026, 4, 20, 6, 0, 0);
      final streamClient = TrackingLocationStreamClient();
      final container = ProviderContainer(
        overrides: [
          deviceLocationClientProvider.overrideWithValue(
            TestDeviceLocationClient(),
          ),
          locationStreamClientProvider.overrideWithValue(streamClient),
          runPlaybackClockProvider.overrideWithValue(() => startedAt),
        ],
      );
      addTearDown(() async {
        await streamClient.close();
        container.dispose();
      });

      await startVisibleLiveTracking(container);
      await streamClient.emit(
        playbackSample(latitude: 37.0, longitude: 127.0, capturedAt: startedAt),
      );
      await container.read(runPlaybackControllerProvider.notifier).start();
      await settleAsync();
      expect(streamClient.activeSubscriptions, 1);
      expect(streamClient.lastWatchMode, LocationTrackingMode.workout);

      await container.read(runPlaybackControllerProvider.notifier).pause();
      await settleAsync();
      expect(
        container.read(runPlaybackControllerProvider).status,
        RunScreenStatus.paused,
      );
      expect(streamClient.activeSubscriptions, 1);
      expect(streamClient.lastWatchMode, LocationTrackingMode.passive);

      container.read(appTabProvider.notifier).setTab(AppTab.history);
      await settleAsync();

      expect(streamClient.activeSubscriptions, 0);
    },
  );

  test(
    'rapid manual pause and resume leaves live tracking in workout mode',
    () async {
      final startedAt = DateTime(2026, 4, 20, 6, 0, 0);
      var now = startedAt;
      final streamClient = _DelayedCancelLocationStreamClient();
      final container = ProviderContainer(
        overrides: [
          deviceLocationClientProvider.overrideWithValue(
            TestDeviceLocationClient(),
          ),
          locationStreamClientProvider.overrideWithValue(streamClient),
          runPlaybackClockProvider.overrideWithValue(() => now),
        ],
      );
      addTearDown(() async {
        streamClient.completePendingCancel();
        await streamClient.close();
        container.dispose();
      });

      await startVisibleLiveTracking(container);
      await streamClient.emit(
        playbackSample(latitude: 37.0, longitude: 127.0, capturedAt: startedAt),
      );
      await container.read(runPlaybackControllerProvider.notifier).start();
      await settleAsync();
      expect(streamClient.lastWatchMode, LocationTrackingMode.workout);

      streamClient.delayNextCancel();
      now = startedAt.add(const Duration(seconds: 5));
      await container.read(runPlaybackControllerProvider.notifier).pause();
      for (
        var index = 0;
        index < 5 && !streamClient.hasPendingCancel;
        index++
      ) {
        await Future<void>.delayed(Duration.zero);
      }
      expect(streamClient.hasPendingCancel, isTrue);

      now = startedAt.add(const Duration(seconds: 6));
      await container.read(runPlaybackControllerProvider.notifier).resume();
      streamClient.completePendingCancel();
      await settleAsync();
      await settleAsync();

      expect(
        container.read(runPlaybackControllerProvider).status,
        RunScreenStatus.running,
      );
      expect(streamClient.activeSubscriptions, 1);
      expect(streamClient.lastWatchMode, LocationTrackingMode.workout);
    },
  );

  test(
    'live tracking stays active on the history tab while a run is in progress',
    () async {
      final streamClient = TrackingLocationStreamClient();
      final deviceLocationClient = TestDeviceLocationClient(
        currentResponses: <Future<LiveLocationSample?>>[
          Future<LiveLocationSample?>.value(
            playbackSample(
              latitude: 37.0,
              longitude: 127.0,
              capturedAt: DateTime(2026, 4, 20, 6, 0, 0),
            ),
          ),
        ],
      );
      final container = ProviderContainer(
        overrides: [
          deviceLocationClientProvider.overrideWithValue(deviceLocationClient),
          locationStreamClientProvider.overrideWithValue(streamClient),
        ],
      );
      addTearDown(() async {
        await streamClient.close();
        container.dispose();
      });

      await startVisibleLiveTracking(container);
      await container.read(runPlaybackControllerProvider.notifier).start();
      await settleAsync();
      expect(streamClient.lastWatchMode, LocationTrackingMode.workout);

      container.read(appTabProvider.notifier).setTab(AppTab.history);
      await settleAsync();
      expect(streamClient.activeSubscriptions, 1);
      expect(streamClient.lastWatchMode, LocationTrackingMode.workout);

      await container.read(runPlaybackControllerProvider.notifier).stop();
      await settleAsync();
      expect(streamClient.activeSubscriptions, 0);
    },
  );

  test('changing the location preset restarts active live tracking', () async {
    final streamClient = TrackingLocationStreamClient();
    final settingsRepository = _FakeRunSettingsRepository();
    final container = ProviderContainer(
      overrides: [
        deviceLocationClientProvider.overrideWithValue(
          TestDeviceLocationClient(),
        ),
        locationStreamClientProvider.overrideWithValue(streamClient),
        runSettingsRepositoryProvider.overrideWithValue(settingsRepository),
      ],
    );
    addTearDown(() async {
      await streamClient.close();
      container.dispose();
    });

    await container.read(runSettingsControllerProvider.future);
    await startVisibleLiveTracking(container);
    expect(streamClient.watchCallCount, 1);
    expect(streamClient.lastWatchMode, LocationTrackingMode.passive);
    expect(streamClient.lastWatchConfig, LocationTrackingConfig.passiveDefault);

    await container
        .read(runSettingsControllerProvider.notifier)
        .setLocationTrackingPreset(RunLocationTrackingPreset.highAccuracy);
    await settleAsync();

    expect(streamClient.activeSubscriptions, 1);
    expect(streamClient.watchCallCount, greaterThanOrEqualTo(2));
    expect(streamClient.lastWatchMode, LocationTrackingMode.passive);
    expect(
      streamClient.lastWatchConfig,
      const LocationTrackingConfig(
        androidInterval: Duration(seconds: 2),
        distanceFilterM: 3,
      ),
    );
  });

  test('live location refresh does not reload static map state', () async {
    var sessionListBuildCount = 0;
    final refreshedSample = playbackSample(
      latitude: 37.55,
      longitude: 126.97,
      capturedAt: DateTime(2026, 4, 20, 6, 0, 0),
    );
    final session = RunSession(
      id: 'fixture-session',
      startedAt: DateTime(2026, 4, 20, 6),
      endedAt: DateTime(2026, 4, 20, 6, 30),
      distanceM: 5000,
      durationMs: 1800000,
      sourceSummary: 'fixture',
      points: const <RunPoint>[
        RunPoint(
          latitude: 37.5,
          longitude: 127.0,
          timestampRelMs: 0,
          source: RunPointSource.simulated,
        ),
      ],
    );
    final streamClient = TrackingLocationStreamClient();
    final container = ProviderContainer(
      overrides: [
        deviceLocationClientProvider.overrideWithValue(
          TestDeviceLocationClient(
            currentResponses: <Future<LiveLocationSample?>>[
              Future<LiveLocationSample?>.value(refreshedSample),
            ],
          ),
        ),
        locationStreamClientProvider.overrideWithValue(streamClient),
        runSessionListProvider.overrideWith((Ref ref) async {
          sessionListBuildCount += 1;
          return <RunSession>[session];
        }),
      ],
    );
    addTearDown(() async {
      await streamClient.close();
      container.dispose();
    });

    await container.read(runMapStaticStateProvider.future);
    expect(sessionListBuildCount, 1);

    expect(container.read(runMapViewStateProvider), isNotNull);
    await container.read(liveLocationProvider.notifier).refresh();

    expect(container.read(runMapViewStateProvider), isNotNull);
    expect(sessionListBuildCount, 1);
  });
}

class _FakeRunSettingsRepository implements RunSettingsRepository {
  RunSettingsState settings = const RunSettingsState();

  @override
  Future<RunSettingsState> loadSettings() async => settings;

  @override
  Future<void> saveSettings(RunSettingsState settings) async {
    this.settings = settings;
  }

  @override
  Future<List<RunShoe>> listShoes() async => const <RunShoe>[];

  @override
  Future<void> saveShoe(RunShoe shoe) async {}

  @override
  Future<void> retireShoe(String id) async {}

  @override
  Future<void> deleteShoe(String id) async {}
}

class _DelayedCancelLocationStreamClient implements LocationStreamClient {
  _DelayedCancelLocationStreamClient() {
    _controller = StreamController<LiveLocationSample>.broadcast(
      onListen: () => _activeSubscriptions += 1,
      onCancel: _handleCancel,
    );
  }

  late final StreamController<LiveLocationSample> _controller;
  int _activeSubscriptions = 0;
  bool _delayNextCancel = false;
  Completer<void>? _pendingCancel;
  final List<LocationTrackingMode> watchModes = <LocationTrackingMode>[];

  int get activeSubscriptions => _activeSubscriptions;

  bool get hasPendingCancel => _pendingCancel != null;

  LocationTrackingMode? get lastWatchMode =>
      watchModes.isEmpty ? null : watchModes.last;

  void delayNextCancel() {
    _delayNextCancel = true;
  }

  void completePendingCancel() {
    final pendingCancel = _pendingCancel;
    _pendingCancel = null;
    pendingCancel?.complete();
  }

  Future<void> _handleCancel() async {
    _activeSubscriptions -= 1;
    if (!_delayNextCancel || _pendingCancel != null) {
      return;
    }
    _delayNextCancel = false;
    _pendingCancel = Completer<void>();
    await _pendingCancel!.future;
  }

  @override
  Future<LiveLocationSample?> fetchLastKnownSample() async => null;

  @override
  Future<LiveLocationSample?> fetchCurrentSample() async => null;

  @override
  Stream<LiveLocationSample> watchLocationSamples({
    LocationTrackingMode mode = LocationTrackingMode.passive,
    LocationTrackingConfig? config,
  }) {
    watchModes.add(mode);
    return _controller.stream;
  }

  Future<void> emit(LiveLocationSample sample) async {
    _controller.add(sample);
    await Future<void>.delayed(Duration.zero);
  }

  Future<void> close() async {
    await _controller.close();
  }
}
