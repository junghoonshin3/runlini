import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:runlini/core/health/health_workout_recorder.dart';
import 'package:runlini/core/location/location_stream_client.dart';
import 'package:runlini/features/run_tracking/state/run_playback_providers.dart';
import 'package:runlini/features/run_tracking/state/run_session_providers.dart';
import 'package:runlini/features/run_tracking/types/run_screen_status.dart';

import 'run_playback_provider_harness.dart';

void main() {
  test(
    'pause freezes route capture until resume and resumed points exclude paused time',
    () async {
      final startedAt = DateTime(2026, 4, 20, 6, 0, 0);
      final acceptedBeforePause = playbackSample(
        latitude: 37.0001,
        longitude: 127.0001,
        capturedAt: startedAt.add(const Duration(seconds: 5)),
      );
      final pausedSample = playbackSample(
        latitude: 37.0002,
        longitude: 127.0002,
        capturedAt: startedAt.add(const Duration(seconds: 12)),
      );
      final acceptedAfterResume = playbackSample(
        latitude: 37.0003,
        longitude: 127.0003,
        capturedAt: startedAt.add(const Duration(seconds: 18)),
      );
      final streamClient = TrackingLocationStreamClient();
      final healthRecorder = TestHealthWorkoutRecorder();
      final sessionRepository = TestRunSessionRepository();
      var now = startedAt;
      final container = ProviderContainer(
        overrides: [
          deviceLocationClientProvider.overrideWithValue(
            TestDeviceLocationClient(),
          ),
          locationStreamClientProvider.overrideWithValue(streamClient),
          healthWorkoutRecorderProvider.overrideWithValue(healthRecorder),
          runSessionRepositoryProvider.overrideWithValue(sessionRepository),
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
      await streamClient.emit(acceptedBeforePause);

      now = startedAt.add(const Duration(seconds: 5));
      await container.read(runPlaybackControllerProvider.notifier).pause();
      expect(
        container.read(runPlaybackControllerProvider).status,
        RunScreenStatus.paused,
      );

      await streamClient.emit(pausedSample);
      expect(
        container.read(runPlaybackControllerProvider).recordedPoints,
        hasLength(2),
      );

      now = startedAt.add(const Duration(seconds: 13));
      await container.read(runPlaybackControllerProvider.notifier).resume();
      expect(
        container.read(runPlaybackControllerProvider).status,
        RunScreenStatus.running,
      );

      await streamClient.emit(acceptedAfterResume);

      final recordedPoints = container
          .read(runPlaybackControllerProvider)
          .recordedPoints;
      expect(recordedPoints, hasLength(3));
      expect(recordedPoints[1].timestampRelMs, 5000);
      expect(recordedPoints[2].timestampRelMs, 10000);

      now = startedAt.add(const Duration(seconds: 20));
      await container.read(runPlaybackControllerProvider.notifier).stop();

      expect(healthRecorder.beginCalls, 0);
      expect(healthRecorder.finishCalls, 0);
      expect(
        container.read(runPlaybackControllerProvider).status,
        RunScreenStatus.reviewing,
      );
      expect(
        container
            .read(runPlaybackControllerProvider)
            .pendingFinishedSession
            ?.durationMs,
        12000,
      );
      await container
          .read(runPlaybackControllerProvider.notifier)
          .saveFinishedRun();

      expect(healthRecorder.finishCalls, 0);
    },
  );

  test(
    'stop from paused creates a review draft with frozen active time',
    () async {
      final startedAt = DateTime(2026, 4, 20, 6, 0, 0);
      final streamClient = TrackingLocationStreamClient();
      final healthRecorder = TestHealthWorkoutRecorder();
      var now = startedAt;
      final container = ProviderContainer(
        overrides: [
          deviceLocationClientProvider.overrideWithValue(
            TestDeviceLocationClient(),
          ),
          locationStreamClientProvider.overrideWithValue(streamClient),
          healthWorkoutRecorderProvider.overrideWithValue(healthRecorder),
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

      now = startedAt.add(const Duration(seconds: 4));
      await container.read(runPlaybackControllerProvider.notifier).pause();
      expect(
        container.read(runPlaybackControllerProvider).status,
        RunScreenStatus.paused,
      );

      now = startedAt.add(const Duration(seconds: 9));
      await container.read(runPlaybackControllerProvider.notifier).stop();

      expect(
        container.read(runPlaybackControllerProvider).status,
        RunScreenStatus.reviewing,
      );
      expect(
        container
            .read(runPlaybackControllerProvider)
            .pendingFinishedSession
            ?.durationMs,
        4000,
      );
      expect(healthRecorder.beginCalls, 0);
      expect(healthRecorder.finishCalls, 0);
    },
  );
}
