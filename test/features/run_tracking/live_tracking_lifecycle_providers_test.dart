import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:runlini/core/location/location_stream_client.dart';
import 'package:runlini/features/dashboard/state/app_shell_providers.dart';
import 'package:runlini/features/dashboard/types/app_tab.dart';
import 'package:runlini/features/run_tracking/state/run_playback_providers.dart';
import 'package:runlini/features/run_tracking/state/run_session_providers.dart';
import 'package:runlini/features/run_tracking/types/live_location_sample.dart';
import 'package:runlini/features/run_tracking/types/run_point.dart';
import 'package:runlini/features/run_tracking/types/run_screen_status.dart';
import 'package:runlini/features/run_tracking/types/run_session.dart';

import 'run_playback_provider_harness.dart';

void main() {
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
