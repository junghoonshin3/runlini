import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:runlini/core/location/location_stream_client.dart';
import 'package:runlini/features/dashboard/state/app_shell_providers.dart';
import 'package:runlini/features/dashboard/types/app_tab.dart';
import 'package:runlini/features/run_tracking/state/run_live_metrics_providers.dart';
import 'package:runlini/features/run_tracking/state/run_playback_providers.dart';
import 'package:runlini/features/run_tracking/state/run_settings_providers.dart';
import 'package:runlini/features/run_tracking/types/live_location_sample.dart';
import 'package:runlini/features/run_tracking/types/live_run_metrics.dart';
import 'package:runlini/features/run_tracking/types/run_point.dart';
import 'package:runlini/features/run_tracking/types/run_settings.dart';

import 'run_playback_provider_harness.dart';

LiveLocationSample _sample({
  required double latitude,
  required double longitude,
  required DateTime capturedAt,
  double? speedMps,
  double? horizontalAccuracyM,
}) {
  return LiveLocationSample(
    latitude: latitude,
    longitude: longitude,
    capturedAt: capturedAt,
    speedMps: speedMps,
    horizontalAccuracyM: horizontalAccuracyM,
    source: RunPointSource.deviceGps,
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

void main() {
  test(
    'seeded running metrics start at zero distance and keep elapsed time moving without new GPS',
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
            TestRunSettingsRepository(),
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

      await _startVisibleLiveTracking(container);
      await streamClient.emit(
        _sample(latitude: 0, longitude: 0, capturedAt: startedAt),
      );
      await container.read(runPlaybackControllerProvider.notifier).start();

      final initialMetrics = metricsSubscription.read();
      expect(initialMetrics, isNotNull);
      expect(initialMetrics!.distanceKm, 0);
      expect(initialMetrics.elapsedMs, 0);
      expect(initialMetrics.averagePaceSecPerKm, isNull);
      expect(initialMetrics.averageSpeedKmh, 0);
      expect(initialMetrics.caloriesKcal, isNull);
      expect(initialMetrics.isPaused, isFalse);

      now = startedAt.add(const Duration(seconds: 2));
      tickerController.add(1);
      await _settleAsync();

      expect(metricsSubscription.read()!.elapsedMs, 2000);
      expect(metricsSubscription.read()!.distanceKm, 0);
    },
  );

  test(
    'running metrics derive distance, average pace, and average speed from accepted recorded points',
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

      await _startVisibleLiveTracking(container);
      await streamClient.emit(
        _sample(latitude: 0, longitude: 0, capturedAt: startedAt),
      );
      await container.read(runPlaybackControllerProvider.notifier).start();
      await streamClient.emit(
        _sample(
          latitude: 0,
          longitude: 0.00045,
          capturedAt: startedAt.add(const Duration(seconds: 30)),
        ),
      );
      await streamClient.emit(
        _sample(
          latitude: 0,
          longitude: 0.0009,
          capturedAt: startedAt.add(const Duration(seconds: 60)),
        ),
      );
      await _settleAsync();
      now = startedAt.add(const Duration(seconds: 60));
      tickerController.add(1);
      await _settleAsync();

      final metrics = metricsSubscription.read()!;
      expect(metrics.distanceKm, closeTo(0.1, 0.01));
      expect(metrics.elapsedMs, 60000);
      expect(metrics.averagePaceSecPerKm, isNotNull);
      expect(metrics.averagePaceSecPerKm!, closeTo(600, 20));
      expect(metrics.averageSpeedKmh, closeTo(6.0, 0.2));
      expect(metrics.caloriesKcal, closeTo(7, 1));
      expect(metrics.isPaused, isFalse);
    },
  );

  test('spike samples stay out of distance and average calculations', () async {
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
          TestRunSettingsRepository(),
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

    await _startVisibleLiveTracking(container);
    await streamClient.emit(
      _sample(latitude: 0, longitude: 0, capturedAt: startedAt),
    );
    await container.read(runPlaybackControllerProvider.notifier).start();
    await streamClient.emit(
      _sample(
        latitude: 0,
        longitude: 0.00045,
        capturedAt: startedAt.add(const Duration(seconds: 30)),
      ),
    );
    await streamClient.emit(
      _sample(
        latitude: 0,
        longitude: 0.0009,
        capturedAt: startedAt.add(const Duration(seconds: 60)),
      ),
    );
    await _settleAsync();

    final distanceBeforeSpike = metricsSubscription.read()!.distanceKm;

    now = startedAt.add(const Duration(seconds: 61));
    await streamClient.emit(
      _sample(
        latitude: 1,
        longitude: 1,
        capturedAt: startedAt.add(const Duration(seconds: 61)),
      ),
    );
    tickerController.add(1);
    await _settleAsync();

    final metricsAfterSpike = metricsSubscription.read()!;
    expect(metricsAfterSpike.distanceKm, closeTo(distanceBeforeSpike, 0.001));
    expect(metricsAfterSpike.averagePaceSecPerKm, closeTo(610, 20));
    expect(metricsAfterSpike.averageSpeedKmh, closeTo(6.0, 0.2));
    expect(metricsAfterSpike.isPaused, isFalse);
  });

  test(
    'paused metrics freeze elapsed time and expose the paused state',
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

      await _startVisibleLiveTracking(container);
      await streamClient.emit(
        _sample(latitude: 0, longitude: 0, capturedAt: startedAt),
      );
      await container.read(runPlaybackControllerProvider.notifier).start();

      now = startedAt.add(const Duration(seconds: 4));
      tickerController.add(1);
      await _settleAsync();
      await container.read(runPlaybackControllerProvider.notifier).pause();
      await _settleAsync();

      final pausedMetrics = metricsSubscription.read()!;
      expect(pausedMetrics.elapsedMs, 4000);
      expect(pausedMetrics.isPaused, isTrue);

      now = startedAt.add(const Duration(seconds: 9));
      tickerController.add(2);
      await _settleAsync();

      expect(metricsSubscription.read()!.elapsedMs, 4000);
      expect(metricsSubscription.read()!.isPaused, isTrue);
    },
  );
}
