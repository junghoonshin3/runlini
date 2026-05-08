import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:runlini/core/location/location_stream_client.dart';
import 'package:runlini/features/run_tracking/state/run_playback_providers.dart';
import 'package:runlini/features/run_tracking/state/run_settings_providers.dart';
import 'package:runlini/features/run_tracking/types/run_session_ghost_summary.dart';

import 'run_playback_provider_harness.dart';

void main() {
  test('ghost completion continue suppresses the prompt for the run', () async {
    final streamClient = TrackingLocationStreamClient();
    final summary = _ghostSummary();
    final container = _container(streamClient: streamClient);
    addTearDown(() async {
      await streamClient.close();
      container.dispose();
    });

    await _startRun(container, streamClient);

    container
        .read(runPlaybackControllerProvider.notifier)
        .updateGhostCompletion(candidateCount: 2, completedSummary: summary);
    expect(
      container
          .read(runPlaybackControllerProvider)
          .ghostCompletionPromptPending,
      isTrue,
    );

    container
        .read(runPlaybackControllerProvider.notifier)
        .continueAfterGhostCompletion();
    var playbackState = container.read(runPlaybackControllerProvider);
    expect(playbackState.ghostCompletionPromptPending, isFalse);
    expect(playbackState.ghostCompletionPromptDismissed, isTrue);
    expect(playbackState.ghostCompletionSummary, summary);

    container
        .read(runPlaybackControllerProvider.notifier)
        .updateGhostCompletion(candidateCount: 2, completedSummary: summary);
    playbackState = container.read(runPlaybackControllerProvider);
    expect(playbackState.ghostCompletionPromptPending, isFalse);
    expect(playbackState.ghostCompletionPromptDismissed, isTrue);
  });

  test('stop can preserve a continued ghost completion summary', () async {
    final streamClient = TrackingLocationStreamClient();
    final summary = _ghostSummary();
    final container = _container(streamClient: streamClient);
    addTearDown(() async {
      await streamClient.close();
      container.dispose();
    });

    await _startRun(container, streamClient);
    container
        .read(runPlaybackControllerProvider.notifier)
        .updateGhostCompletion(candidateCount: 2, completedSummary: summary);
    container
        .read(runPlaybackControllerProvider.notifier)
        .continueAfterGhostCompletion();

    await container
        .read(runPlaybackControllerProvider.notifier)
        .stop(
          ghostSummary: container
              .read(runPlaybackControllerProvider)
              .ghostCompletionSummary,
        );

    final pendingSession = container
        .read(runPlaybackControllerProvider)
        .pendingFinishedSession;
    expect(pendingSession?.ghostSummary, summary);
  });

  test(
    'ghost completion is ignored while manually paused and works after resume',
    () async {
      final streamClient = TrackingLocationStreamClient();
      final summary = _ghostSummary();
      final container = _container(streamClient: streamClient);
      addTearDown(() async {
        await streamClient.close();
        container.dispose();
      });

      await _startRun(container, streamClient);
      await container.read(runPlaybackControllerProvider.notifier).pause();
      container
          .read(runPlaybackControllerProvider.notifier)
          .updateGhostCompletion(candidateCount: 2, completedSummary: summary);

      var playbackState = container.read(runPlaybackControllerProvider);
      expect(playbackState.ghostCompletionPromptPending, isFalse);
      expect(playbackState.ghostCompletionSummary, isNull);

      await container.read(runPlaybackControllerProvider.notifier).resume();
      container
          .read(runPlaybackControllerProvider.notifier)
          .updateGhostCompletion(candidateCount: 1);
      container
          .read(runPlaybackControllerProvider.notifier)
          .updateGhostCompletion(candidateCount: 2, completedSummary: summary);

      playbackState = container.read(runPlaybackControllerProvider);
      expect(playbackState.ghostCompletionPromptPending, isTrue);
      expect(playbackState.ghostCompletionSummary, summary);
    },
  );
}

ProviderContainer _container({
  required TrackingLocationStreamClient streamClient,
}) {
  return ProviderContainer(
    overrides: [
      deviceLocationClientProvider.overrideWithValue(
        TestDeviceLocationClient(),
      ),
      locationStreamClientProvider.overrideWithValue(streamClient),
      runSettingsRepositoryProvider.overrideWithValue(
        TestRunSettingsRepository(),
      ),
      runPlaybackClockProvider.overrideWithValue(
        () => DateTime(2026, 4, 20, 6, 0, 3),
      ),
    ],
  );
}

Future<void> _startRun(
  ProviderContainer container,
  TrackingLocationStreamClient streamClient,
) async {
  await container.read(runSettingsControllerProvider.future);
  await startVisibleLiveTracking(container);
  await streamClient.emit(
    playbackSample(
      latitude: 37,
      longitude: 127,
      capturedAt: DateTime(2026, 4, 20, 6),
    ),
  );
  await container.read(runPlaybackControllerProvider.notifier).start();
}

RunSessionGhostSummary _ghostSummary() {
  return const RunSessionGhostSummary(
    ghostSessionId: 'ghost-1',
    ghostLabel: 'Morning Ghost',
    result: RunSessionGhostResult.ahead,
    timeGapMs: 12000,
    distanceGapM: 42,
  );
}
