import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:runlini/core/location/location_stream_client.dart';
import 'package:runlini/core/motion/run_motion_evidence_client.dart';
import 'package:runlini/features/run_tracking/state/run_live_metrics_providers.dart';
import 'package:runlini/features/run_tracking/state/run_playback_providers.dart';
import 'package:runlini/features/run_tracking/state/run_settings_providers.dart';
import 'package:runlini/features/run_tracking/types/live_run_metrics.dart';
import 'package:runlini/features/run_tracking/types/run_playback_state.dart';
import 'package:runlini/features/run_tracking/types/run_screen_status.dart';
import 'package:runlini/features/run_tracking/types/run_settings.dart';

import 'run_playback_provider_harness.dart';

void main() {
  test(
    'stationary GPS drift updates live location but not recorded metrics',
    () async {
      final startedAt = DateTime(2026, 4, 20, 6, 0, 0);
      var now = startedAt;
      final tickerController = StreamController<int>.broadcast();
      final streamClient = TrackingLocationStreamClient();
      final motionClient = TrackingMotionEvidenceClient();
      final container = ProviderContainer(
        overrides: [
          deviceLocationClientProvider.overrideWithValue(
            TestDeviceLocationClient(),
          ),
          locationStreamClientProvider.overrideWithValue(streamClient),
          runMotionEvidenceClientProvider.overrideWithValue(motionClient),
          runSettingsRepositoryProvider.overrideWithValue(
            TestRunSettingsRepository(const RunSettingsState(bodyWeightKg: 70)),
          ),
          runPlaybackClockProvider.overrideWithValue(() => now),
          liveRunMetricsTickerProvider.overrideWith(
            (Ref ref) => tickerController.stream,
          ),
        ],
      );
      final metricsSubscription = container.listen<LiveRunMetrics?>(
        liveRunMetricsProvider,
        (LiveRunMetrics? previous, LiveRunMetrics? next) {},
      );
      addTearDown(() {
        metricsSubscription.close();
        unawaited(motionClient.close());
        container.dispose();
      });

      await startVisibleLiveTracking(container);
      await streamClient.emit(
        playbackSample(
          latitude: 37,
          longitude: 127,
          capturedAt: startedAt,
          speedMps: 0,
          horizontalAccuracyM: 8,
        ),
      );
      await container.read(runPlaybackControllerProvider.notifier).start();

      now = startedAt.add(const Duration(seconds: 10));
      await streamClient.emit(
        playbackSample(
          latitude: 37.00009,
          longitude: 127,
          capturedAt: now,
          speedMps: 0,
          horizontalAccuracyM: 8,
        ),
      );
      tickerController.add(1);
      await settleAsync();

      final liveSample = container.read(liveLocationProvider);
      final playbackState = container.read(runPlaybackControllerProvider);
      final metrics = metricsSubscription.read()!;

      expect(liveSample!.latitude, 37.00009);
      expect(playbackState.recordedPoints, hasLength(1));
      expect(metrics.distanceKm, 0);
      expect(metrics.averageSpeedKmh, 0);
      expect(metrics.caloriesKcal, isNull);
    },
  );

  test(
    'auto pause freezes time and resumes only after stable movement',
    () async {
      final startedAt = DateTime(2026, 4, 20, 6, 0, 0);
      var now = startedAt;
      final streamClient = TrackingLocationStreamClient();
      final motionClient = TrackingMotionEvidenceClient();
      final container = ProviderContainer(
        overrides: [
          deviceLocationClientProvider.overrideWithValue(
            TestDeviceLocationClient(),
          ),
          locationStreamClientProvider.overrideWithValue(streamClient),
          runMotionEvidenceClientProvider.overrideWithValue(motionClient),
          runSettingsRepositoryProvider.overrideWithValue(
            TestRunSettingsRepository(
              const RunSettingsState(autoPauseEnabled: true),
            ),
          ),
          runPlaybackClockProvider.overrideWithValue(() => now),
        ],
      );
      addTearDown(() async {
        await streamClient.close();
        await motionClient.close();
        container.dispose();
      });

      await startVisibleLiveTracking(container);
      await streamClient.emit(
        playbackSample(latitude: 37, longitude: 127, capturedAt: startedAt),
      );
      await container.read(runPlaybackControllerProvider.notifier).start();

      for (var index = 1; index <= 3; index += 1) {
        now = startedAt.add(Duration(seconds: index * 4));
        await streamClient.emit(
          playbackSample(
            latitude: 37 + (0.00002 * index),
            longitude: 127,
            capturedAt: now,
            speedMps: 0,
            horizontalAccuracyM: 8,
          ),
        );
      }

      var playbackState = container.read(runPlaybackControllerProvider);
      expect(playbackState.status, RunScreenStatus.paused);
      expect(playbackState.pauseReason, RunPauseReason.auto);
      expect(playbackState.elapsedBeforePauseMs, 8000);
      expect(playbackState.recordedPoints, hasLength(1));

      now = startedAt.add(const Duration(seconds: 18));
      await streamClient.emit(
        playbackSample(
          latitude: 37.00025,
          longitude: 127,
          capturedAt: now,
          speedMps: 1.4,
          horizontalAccuracyM: 6,
        ),
      );
      expect(
        container.read(runPlaybackControllerProvider).status,
        RunScreenStatus.paused,
      );

      now = startedAt.add(const Duration(seconds: 22));
      await streamClient.emit(
        playbackSample(
          latitude: 37.00045,
          longitude: 127,
          capturedAt: now,
          speedMps: 1.4,
          horizontalAccuracyM: 6,
        ),
      );

      playbackState = container.read(runPlaybackControllerProvider);
      expect(playbackState.status, RunScreenStatus.running);
      expect(playbackState.pauseReason, isNull);
      expect(playbackState.recordedPoints, hasLength(2));
    },
  );

  test('manual pause is not automatically resumed by GPS movement', () async {
    final startedAt = DateTime(2026, 4, 20, 6, 0, 0);
    final streamClient = TrackingLocationStreamClient();
    final motionClient = TrackingMotionEvidenceClient();
    final container = ProviderContainer(
      overrides: [
        deviceLocationClientProvider.overrideWithValue(
          TestDeviceLocationClient(),
        ),
        locationStreamClientProvider.overrideWithValue(streamClient),
        runMotionEvidenceClientProvider.overrideWithValue(motionClient),
        runSettingsRepositoryProvider.overrideWithValue(
          TestRunSettingsRepository(
            const RunSettingsState(autoPauseEnabled: true),
          ),
        ),
        runPlaybackClockProvider.overrideWithValue(() => startedAt),
      ],
    );
    addTearDown(() async {
      await streamClient.close();
      await motionClient.close();
      container.dispose();
    });

    await startVisibleLiveTracking(container);
    await streamClient.emit(
      playbackSample(latitude: 37, longitude: 127, capturedAt: startedAt),
    );
    await container.read(runPlaybackControllerProvider.notifier).start();
    await container.read(runPlaybackControllerProvider.notifier).pause();
    await streamClient.emit(
      playbackSample(
        latitude: 37.001,
        longitude: 127,
        capturedAt: startedAt.add(const Duration(seconds: 20)),
        speedMps: 2,
        horizontalAccuracyM: 6,
      ),
    );

    final playbackState = container.read(runPlaybackControllerProvider);
    expect(playbackState.status, RunScreenStatus.paused);
    expect(playbackState.pauseReason, RunPauseReason.manual);
  });
}
