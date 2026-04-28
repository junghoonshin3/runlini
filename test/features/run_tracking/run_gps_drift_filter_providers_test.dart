import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:runlini/core/location/location_stream_client.dart';
import 'package:runlini/features/run_tracking/state/run_live_metrics_providers.dart';
import 'package:runlini/features/run_tracking/state/run_playback_providers.dart';
import 'package:runlini/features/run_tracking/state/run_settings_providers.dart';
import 'package:runlini/features/run_tracking/types/live_run_metrics.dart';
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
      final container = ProviderContainer(
        overrides: [
          deviceLocationClientProvider.overrideWithValue(
            TestDeviceLocationClient(),
          ),
          locationStreamClientProvider.overrideWithValue(streamClient),
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
}
