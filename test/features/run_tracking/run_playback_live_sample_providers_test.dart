import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:runlini/core/location/location_stream_client.dart';
import 'package:runlini/features/run_tracking/state/run_playback_providers.dart';

import 'run_playback_provider_harness.dart';

void main() {
  test(
    'running live samples update live location immediately while spikes stay out of the recorded track',
    () async {
      final seedSample = playbackSample(
        latitude: 37.0,
        longitude: 127.0,
        capturedAt: DateTime(2026, 4, 20, 6, 0, 0),
      );
      final acceptedSample = playbackSample(
        latitude: 37.0001,
        longitude: 127.0001,
        capturedAt: DateTime(2026, 4, 20, 6, 0, 5),
      );
      final spikeSample = playbackSample(
        latitude: 37.01,
        longitude: 127.01,
        capturedAt: DateTime(2026, 4, 20, 6, 0, 6),
      );
      final streamClient = TrackingLocationStreamClient();
      final now = DateTime(2026, 4, 20, 6, 0, 0);
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
        await streamClient.close();
        container.dispose();
      });

      await startVisibleLiveTracking(container);
      await streamClient.emit(seedSample);
      await container.read(runPlaybackControllerProvider.notifier).start();
      await streamClient.emit(acceptedSample);

      expect(container.read(liveLocationProvider), acceptedSample);
      expect(
        container.read(runPlaybackControllerProvider).recordedPoints,
        hasLength(2),
      );

      await streamClient.emit(spikeSample);

      expect(container.read(liveLocationProvider), spikeSample);
      expect(
        container.read(runPlaybackControllerProvider).recordedPoints,
        hasLength(2),
      );
    },
  );
}
