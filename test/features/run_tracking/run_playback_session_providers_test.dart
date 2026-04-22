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
    'start uses the latest live sample without an extra current fetch',
    () async {
      final seedSample = playbackSample(
        latitude: 37.0,
        longitude: 127.0,
        capturedAt: DateTime(2026, 4, 20, 6, 0, 0),
        paceSecPerKm: 300,
      );
      final deviceLocationClient = TestDeviceLocationClient();
      final streamClient = TrackingLocationStreamClient();
      final container = ProviderContainer(
        overrides: [
          deviceLocationClientProvider.overrideWithValue(deviceLocationClient),
          locationStreamClientProvider.overrideWithValue(streamClient),
          runPlaybackClockProvider.overrideWithValue(
            () => DateTime(2026, 4, 20, 6, 0, 3),
          ),
        ],
      );
      addTearDown(() async {
        await streamClient.close();
        container.dispose();
      });

      await startVisibleLiveTracking(container);
      await streamClient.emit(seedSample);

      final startResult = await container
          .read(runPlaybackControllerProvider.notifier)
          .start();

      expect(startResult, RunTrackingToggleResult.started);
      expect(deviceLocationClient.currentFetchCount, 0);
      expect(
        container.read(runPlaybackControllerProvider).recordedPoints,
        hasLength(1),
      );
      expect(
        container
            .read(runPlaybackControllerProvider)
            .recordedPoints
            .single
            .timestampRelMs,
        0,
      );
      expect(
        container.read(runPlaybackControllerProvider).status,
        RunScreenStatus.running,
      );
      expect(
        container.read(runPlaybackControllerProvider).startedAt,
        DateTime(2026, 4, 20, 6, 0, 3),
      );
    },
  );

  test('stop creates a finished draft and save commits it', () async {
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
    final streamClient = TrackingLocationStreamClient();
    final healthRecorder = TestHealthWorkoutRecorder();
    final sessionRepository = TestRunSessionRepository();
    var now = DateTime(2026, 4, 20, 6, 0, 3);
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
    await streamClient.emit(seedSample);
    await container.read(runPlaybackControllerProvider.notifier).start();
    await streamClient.emit(acceptedSample);
    now = DateTime(2026, 4, 20, 6, 0, 8);
    await container.read(runPlaybackControllerProvider.notifier).stop();

    expect(healthRecorder.beginCalls, 1);
    expect(healthRecorder.finishCalls, 0);
    expect(healthRecorder.cancelCalls, 0);
    expect(sessionRepository.savedSessions, isEmpty);
    expect(
      container.read(runPlaybackControllerProvider).status,
      RunScreenStatus.reviewing,
    );
    expect(
      container.read(runPlaybackControllerProvider).pendingFinishedSession,
      isNotNull,
    );

    await streamClient.emit(
      playbackSample(
        latitude: 37.0002,
        longitude: 127.0002,
        capturedAt: DateTime(2026, 4, 20, 6, 0, 10),
      ),
    );
    expect(
      container.read(runPlaybackControllerProvider).recordedPoints,
      hasLength(2),
    );

    await container
        .read(runPlaybackControllerProvider.notifier)
        .saveFinishedRun();

    expect(sessionRepository.savedSessions, hasLength(1));
    expect(healthRecorder.finishCalls, 1);
    expect(healthRecorder.lastStartedAt, DateTime(2026, 4, 20, 6, 0, 3));
    expect(healthRecorder.lastEndedAt, DateTime(2026, 4, 20, 6, 0, 8));
    expect(healthRecorder.lastRecordedPoints, hasLength(2));
    expect(
      container.read(runPlaybackControllerProvider).status,
      RunScreenStatus.idle,
    );
  });

  test('health export failures do not block run start or save', () async {
    final seedSample = playbackSample(
      latitude: 37.0,
      longitude: 127.0,
      capturedAt: DateTime(2026, 4, 20, 6, 0, 0),
    );
    final healthRecorder = TestHealthWorkoutRecorder()
      ..beginError = StateError('begin failed')
      ..finishError = StateError('finish failed');
    final streamClient = TrackingLocationStreamClient();
    final sessionRepository = TestRunSessionRepository();
    final container = ProviderContainer(
      overrides: [
        deviceLocationClientProvider.overrideWithValue(
          TestDeviceLocationClient(),
        ),
        locationStreamClientProvider.overrideWithValue(streamClient),
        healthWorkoutRecorderProvider.overrideWithValue(healthRecorder),
        runSessionRepositoryProvider.overrideWithValue(sessionRepository),
      ],
    );
    addTearDown(() async {
      await streamClient.close();
      container.dispose();
    });

    await startVisibleLiveTracking(container);
    await streamClient.emit(seedSample);

    final startResult = await container
        .read(runPlaybackControllerProvider.notifier)
        .start();
    await container.read(runPlaybackControllerProvider.notifier).stop();
    await container
        .read(runPlaybackControllerProvider.notifier)
        .saveFinishedRun();

    expect(startResult, RunTrackingToggleResult.started);
    expect(
      container.read(runPlaybackControllerProvider).status,
      RunScreenStatus.idle,
    );
    expect(healthRecorder.beginCalls, 1);
    expect(healthRecorder.finishCalls, 1);
  });

  test('discarding a finished draft cancels health capture', () async {
    final seedSample = playbackSample(
      latitude: 37.0,
      longitude: 127.0,
      capturedAt: DateTime(2026, 4, 20, 6, 0, 0),
    );
    final streamClient = TrackingLocationStreamClient();
    final healthRecorder = TestHealthWorkoutRecorder();
    final sessionRepository = TestRunSessionRepository();
    final container = ProviderContainer(
      overrides: [
        deviceLocationClientProvider.overrideWithValue(
          TestDeviceLocationClient(),
        ),
        locationStreamClientProvider.overrideWithValue(streamClient),
        healthWorkoutRecorderProvider.overrideWithValue(healthRecorder),
        runSessionRepositoryProvider.overrideWithValue(sessionRepository),
      ],
    );
    addTearDown(() async {
      await streamClient.close();
      container.dispose();
    });

    await startVisibleLiveTracking(container);
    await streamClient.emit(seedSample);
    await container.read(runPlaybackControllerProvider.notifier).start();
    await container.read(runPlaybackControllerProvider.notifier).stop();
    await container
        .read(runPlaybackControllerProvider.notifier)
        .discardFinishedRun();

    expect(sessionRepository.savedSessions, isEmpty);
    expect(healthRecorder.finishCalls, 0);
    expect(healthRecorder.cancelCalls, 1);
    expect(
      container.read(runPlaybackControllerProvider).status,
      RunScreenStatus.idle,
    );
  });

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
