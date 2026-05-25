import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:runlini/core/location/location_stream_client.dart';
import 'package:runlini/core/motion/run_motion_evidence_client.dart';
import 'package:runlini/features/run_tracking/state/run_playback_providers.dart';
import 'package:runlini/features/run_tracking/state/run_settings_providers.dart';
import 'package:runlini/features/run_tracking/types/run_session_record_race_summary.dart';
import 'package:runlini/features/run_tracking/types/run_settings.dart';

import 'run_playback_provider_harness.dart';

void main() {
  test(
    'recordRace completion continue suppresses the prompt for the run',
    () async {
      final streamClient = TrackingLocationStreamClient();
      final summary = _recordRaceSummary();
      final container = _container(streamClient: streamClient);
      addTearDown(() async {
        await streamClient.close();
        container.dispose();
      });

      await _startRun(container, streamClient);

      container
          .read(runPlaybackControllerProvider.notifier)
          .updateRecordRaceCompletion(
            candidateCount: 2,
            completedSummary: summary,
          );
      expect(
        container
            .read(runPlaybackControllerProvider)
            .recordRaceCompletionPromptPending,
        isTrue,
      );

      container
          .read(runPlaybackControllerProvider.notifier)
          .continueAfterRecordRaceCompletion();
      var playbackState = container.read(runPlaybackControllerProvider);
      expect(playbackState.recordRaceCompletionPromptPending, isFalse);
      expect(playbackState.recordRaceCompletionPromptDismissed, isTrue);
      expect(playbackState.recordRaceCompletionSummary, summary);

      container
          .read(runPlaybackControllerProvider.notifier)
          .updateRecordRaceCompletion(
            candidateCount: 2,
            completedSummary: summary,
          );
      playbackState = container.read(runPlaybackControllerProvider);
      expect(playbackState.recordRaceCompletionPromptPending, isFalse);
      expect(playbackState.recordRaceCompletionPromptDismissed, isTrue);
    },
  );

  test('stop can preserve a continued recordRace completion summary', () async {
    final streamClient = TrackingLocationStreamClient();
    final summary = _recordRaceSummary();
    final container = _container(streamClient: streamClient);
    addTearDown(() async {
      await streamClient.close();
      container.dispose();
    });

    await _startRun(container, streamClient);
    container
        .read(runPlaybackControllerProvider.notifier)
        .updateRecordRaceCompletion(
          candidateCount: 2,
          completedSummary: summary,
        );
    container
        .read(runPlaybackControllerProvider.notifier)
        .continueAfterRecordRaceCompletion();

    await container
        .read(runPlaybackControllerProvider.notifier)
        .stop(
          recordRaceSummary: container
              .read(runPlaybackControllerProvider)
              .recordRaceCompletionSummary,
        );

    final pendingSession = container
        .read(runPlaybackControllerProvider)
        .pendingFinishedSession;
    expect(pendingSession?.recordRaceSummary, summary);
  });

  test(
    'recordRace completion is ignored while manually paused and works after resume',
    () async {
      final streamClient = TrackingLocationStreamClient();
      final summary = _recordRaceSummary();
      final container = _container(streamClient: streamClient);
      addTearDown(() async {
        await streamClient.close();
        container.dispose();
      });

      await _startRun(container, streamClient);
      await container.read(runPlaybackControllerProvider.notifier).pause();
      container
          .read(runPlaybackControllerProvider.notifier)
          .updateRecordRaceCompletion(
            candidateCount: 2,
            completedSummary: summary,
          );

      var playbackState = container.read(runPlaybackControllerProvider);
      expect(playbackState.recordRaceCompletionPromptPending, isFalse);
      expect(playbackState.recordRaceCompletionSummary, isNull);

      await container.read(runPlaybackControllerProvider.notifier).resume();
      container
          .read(runPlaybackControllerProvider.notifier)
          .updateRecordRaceCompletion(candidateCount: 1);
      container
          .read(runPlaybackControllerProvider.notifier)
          .updateRecordRaceCompletion(
            candidateCount: 2,
            completedSummary: summary,
          );

      playbackState = container.read(runPlaybackControllerProvider);
      expect(playbackState.recordRaceCompletionPromptPending, isTrue);
      expect(playbackState.recordRaceCompletionSummary, summary);
    },
  );

  test('recordRace completion can prompt while auto-paused', () async {
    final startedAt = DateTime(2026, 4, 20, 6);
    var now = startedAt;
    final streamClient = TrackingLocationStreamClient();
    final motionClient = TrackingMotionEvidenceClient();
    final summary = _recordRaceSummary();
    final container = _container(
      streamClient: streamClient,
      motionClient: motionClient,
      settings: const RunSettingsState(autoPauseEnabled: true),
      clock: () => now,
    );
    addTearDown(() async {
      await streamClient.close();
      await motionClient.close();
      container.dispose();
    });

    await _startRun(container, streamClient, startedAt: startedAt);
    for (var index = 1; index <= 3; index += 1) {
      now = startedAt.add(Duration(seconds: index * 5));
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

    expect(container.read(runPlaybackControllerProvider).isAutoPaused, isTrue);

    container
        .read(runPlaybackControllerProvider.notifier)
        .updateRecordRaceCompletion(
          candidateCount: 2,
          completedSummary: summary,
        );

    final playbackState = container.read(runPlaybackControllerProvider);
    expect(playbackState.recordRaceCompletionPromptPending, isTrue);
    expect(playbackState.recordRaceCompletionSummary, summary);
  });
}

ProviderContainer _container({
  required TrackingLocationStreamClient streamClient,
  TrackingMotionEvidenceClient? motionClient,
  RunSettingsState settings = const RunSettingsState(),
  DateTime Function()? clock,
}) {
  return ProviderContainer(
    overrides: [
      deviceLocationClientProvider.overrideWithValue(
        TestDeviceLocationClient(),
      ),
      locationStreamClientProvider.overrideWithValue(streamClient),
      if (motionClient != null)
        runMotionEvidenceClientProvider.overrideWithValue(motionClient),
      runSettingsRepositoryProvider.overrideWithValue(
        TestRunSettingsRepository(settings),
      ),
      runPlaybackClockProvider.overrideWithValue(
        clock ?? () => DateTime(2026, 4, 20, 6, 0, 3),
      ),
    ],
  );
}

Future<void> _startRun(
  ProviderContainer container,
  TrackingLocationStreamClient streamClient, {
  DateTime? startedAt,
}) async {
  final capturedAt = startedAt ?? DateTime(2026, 4, 20, 6);
  await container.read(runSettingsControllerProvider.future);
  await startVisibleLiveTracking(container);
  await streamClient.emit(
    playbackSample(latitude: 37, longitude: 127, capturedAt: capturedAt),
  );
  await container.read(runPlaybackControllerProvider.notifier).start();
}

RunSessionRecordRaceSummary _recordRaceSummary() {
  return const RunSessionRecordRaceSummary(
    recordRaceSessionId: 'record-race-1',
    recordRaceLabel: 'Morning RecordRace',
    result: RunSessionRecordRaceResult.ahead,
    timeGapMs: 12000,
    distanceGapM: 42,
  );
}
