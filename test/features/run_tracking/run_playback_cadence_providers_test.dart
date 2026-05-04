import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:runlini/core/location/location_stream_client.dart';
import 'package:runlini/core/motion/run_motion_evidence_client.dart';
import 'package:runlini/features/run_tracking/state/run_playback_providers.dart';
import 'package:runlini/features/run_tracking/state/run_session_providers.dart';
import 'package:runlini/features/run_tracking/types/live_location_sample.dart';

import 'run_playback_provider_harness.dart';

void main() {
  test('saves phone run average cadence and point cadence samples', () async {
    final startedAt = DateTime(2026, 4, 20, 6);
    var now = startedAt;
    final streamClient = TrackingLocationStreamClient();
    final motionClient = TrackingMotionEvidenceClient();
    final sessionRepository = TestRunSessionRepository();
    final container = ProviderContainer(
      overrides: [
        deviceLocationClientProvider.overrideWithValue(
          TestDeviceLocationClient(),
        ),
        locationStreamClientProvider.overrideWithValue(streamClient),
        runMotionEvidenceClientProvider.overrideWithValue(motionClient),
        runSessionRepositoryProvider.overrideWithValue(sessionRepository),
        runPlaybackClockProvider.overrideWithValue(() => now),
      ],
    );
    addTearDown(() async {
      await streamClient.close();
      await motionClient.close();
      container.dispose();
    });

    await startVisibleLiveTracking(container);
    await streamClient.emit(_sample(37.0, startedAt));
    await container.read(runPlaybackControllerProvider.notifier).start();
    now = startedAt.add(const Duration(seconds: 10));
    await motionClient.emit(_steps(now, 10));
    await streamClient.emit(_sample(37.0001, now));
    now = startedAt.add(const Duration(seconds: 20));
    await motionClient.emit(_steps(now, 10));
    await streamClient.emit(_sample(37.0002, now));
    await container.read(runPlaybackControllerProvider.notifier).stop();
    await container
        .read(runPlaybackControllerProvider.notifier)
        .saveFinishedRun();

    final session = sessionRepository.savedSessions.single;
    expect(session.averageCadenceSpm, closeTo(60, 0.1));
    expect(
      session.points.where((point) => point.cadenceSpm != null),
      isNotEmpty,
    );
  });

  test('does not count steps recorded during manual pause', () async {
    final startedAt = DateTime(2026, 4, 20, 6);
    var now = startedAt;
    final streamClient = TrackingLocationStreamClient();
    final motionClient = TrackingMotionEvidenceClient();
    final sessionRepository = TestRunSessionRepository();
    final container = ProviderContainer(
      overrides: [
        deviceLocationClientProvider.overrideWithValue(
          TestDeviceLocationClient(),
        ),
        locationStreamClientProvider.overrideWithValue(streamClient),
        runMotionEvidenceClientProvider.overrideWithValue(motionClient),
        runSessionRepositoryProvider.overrideWithValue(sessionRepository),
        runPlaybackClockProvider.overrideWithValue(() => now),
      ],
    );
    addTearDown(() async {
      await streamClient.close();
      await motionClient.close();
      container.dispose();
    });

    await startVisibleLiveTracking(container);
    await streamClient.emit(_sample(37.0, startedAt));
    await container.read(runPlaybackControllerProvider.notifier).start();
    now = startedAt.add(const Duration(seconds: 10));
    await motionClient.emit(_steps(now, 10));
    await streamClient.emit(_sample(37.0001, now));
    await container.read(runPlaybackControllerProvider.notifier).pause();
    now = startedAt.add(const Duration(seconds: 20));
    await motionClient.emit(_steps(now, 50));
    await container.read(runPlaybackControllerProvider.notifier).resume();
    now = startedAt.add(const Duration(seconds: 30));
    await streamClient.emit(_sample(37.0002, now));
    await container.read(runPlaybackControllerProvider.notifier).stop();
    await container
        .read(runPlaybackControllerProvider.notifier)
        .saveFinishedRun();

    expect(
      sessionRepository.savedSessions.single.averageCadenceSpm,
      closeTo(30, 0.1),
    );
  });
}

LiveLocationSample _sample(double latitude, DateTime capturedAt) {
  return playbackSample(
    latitude: latitude,
    longitude: 127,
    capturedAt: capturedAt,
    speedMps: 2.5,
    horizontalAccuracyM: 5,
  );
}

RunMotionEvidence _steps(DateTime timestamp, int stepDelta) {
  return RunMotionEvidence(
    timestamp: timestamp,
    stepDelta: stepDelta,
    sourceAvailability: RunMotionEvidenceSourceAvailability.available,
  );
}
