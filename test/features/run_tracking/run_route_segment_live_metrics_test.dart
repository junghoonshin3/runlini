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

import 'run_playback_provider_harness.dart';

void main() {
  test('long GPS reacquisition bridges do not inflate live distance', () async {
    final startedAt = DateTime(2026, 4, 20, 6);
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
    await streamClient.emit(_sample(37, 127, startedAt));
    await container.read(runPlaybackControllerProvider.notifier).start();
    await streamClient.emit(
      _sample(37.01, 127.01, startedAt.add(const Duration(minutes: 25))),
    );
    await streamClient.emit(
      _sample(
        37.01,
        127.011,
        startedAt.add(const Duration(minutes: 25, seconds: 30)),
      ),
    );
    now = startedAt.add(const Duration(minutes: 25, seconds: 30));
    tickerController.add(1);
    await _settleAsync();

    final metrics = metricsSubscription.read()!;
    expect(metrics.distanceKm, closeTo(0.089, 0.006));
    expect(metrics.averageSpeedKmh, lessThan(1));
  });
}

LiveLocationSample _sample(double latitude, double longitude, DateTime time) {
  return LiveLocationSample(
    latitude: latitude,
    longitude: longitude,
    capturedAt: time,
    source: RunPointSource.deviceGps,
  );
}

Future<void> _startVisibleLiveTracking(ProviderContainer container) async {
  container.read(appTabProvider.notifier).setTab(AppTab.running);
  await _settleAsync();
  container.read(liveLocationProvider);
  await container.read(liveLocationProvider.notifier).syncTracking();
  await _settleAsync();
}

Future<void> _settleAsync() async {
  await Future<void>.delayed(Duration.zero);
  await Future<void>.delayed(Duration.zero);
}
