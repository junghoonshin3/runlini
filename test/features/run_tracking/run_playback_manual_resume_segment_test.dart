// 수동 재개 후 경로 segment 시작 처리를 검증하는 테스트.
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:runlini/core/location/location_stream_client.dart';
import 'package:runlini/features/run_tracking/state/run_playback_providers.dart';

import 'run_playback_provider_harness.dart';

void main() {
  test(
    'manual resume stores the first accepted point as a new route segment',
    () async {
      final startedAt = DateTime(2026, 4, 20, 6, 0, 0);
      final streamClient = TrackingLocationStreamClient();
      var now = startedAt;
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
      await streamClient.emit(
        playbackSample(latitude: 37.0, longitude: 127.0, capturedAt: startedAt),
      );
      await container.read(runPlaybackControllerProvider.notifier).start();
      await streamClient.emit(
        playbackSample(
          latitude: 37.0001,
          longitude: 127.0,
          capturedAt: startedAt.add(const Duration(seconds: 5)),
        ),
      );

      now = startedAt.add(const Duration(seconds: 5));
      await container.read(runPlaybackControllerProvider.notifier).pause();
      now = startedAt.add(const Duration(seconds: 13));
      await container.read(runPlaybackControllerProvider.notifier).resume();
      await streamClient.emit(
        playbackSample(
          latitude: 37.0002,
          longitude: 127.0,
          capturedAt: startedAt.add(const Duration(seconds: 18)),
        ),
      );
      await streamClient.emit(
        playbackSample(
          latitude: 37.0003,
          longitude: 127.0,
          capturedAt: startedAt.add(const Duration(seconds: 23)),
        ),
      );

      final recordedPoints = container
          .read(runPlaybackControllerProvider)
          .recordedPoints;
      expect(recordedPoints, hasLength(4));
      expect(recordedPoints[2].startsNewSegment, isTrue);
      expect(recordedPoints[3].startsNewSegment, isFalse);

      final route = container
          .read(runRouteSegmenterProvider)
          .segment(recordedPoints);
      expect(route.segments, hasLength(2));
      expect(route.segments.first.last, same(recordedPoints[1]));
      expect(route.segments.last.first, same(recordedPoints[2]));
      expect(route.transitions, hasLength(2));
      expect(
        route.transitions.any(
          (transition) =>
              identical(transition.previous, recordedPoints[1]) &&
              identical(transition.current, recordedPoints[2]),
        ),
        isFalse,
      );

      final mapSegments = container.read(currentRunnerPolylineSegmentsProvider);
      expect(mapSegments, hasLength(2));
      expect(container.read(currentRunnerPolylinePointsProvider), isEmpty);

      now = startedAt.add(const Duration(seconds: 23));
      await container.read(runPlaybackControllerProvider.notifier).stop();
      expect(
        container
            .read(runPlaybackControllerProvider)
            .pendingFinishedSession
            ?.distanceM,
        closeTo(route.distanceM, 0.01),
      );
    },
  );
}
