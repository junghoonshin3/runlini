import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:runlini/core/location/location_stream_client.dart';
import 'package:runlini/core/motion/run_motion_evidence_client.dart';
import 'package:runlini/features/run_tracking/state/run_playback_providers.dart';
import 'package:runlini/features/run_tracking/state/run_settings_providers.dart';
import 'package:runlini/features/run_tracking/types/run_playback_state.dart';
import 'package:runlini/features/run_tracking/types/run_screen_status.dart';
import 'package:runlini/features/run_tracking/types/run_settings.dart';

import 'run_playback_provider_harness.dart';

void main() {
  test('turning auto pause off during an auto pause resumes the run', () async {
    final startedAt = DateTime(2026, 4, 20, 6, 0);
    var now = startedAt;
    final streamClient = TrackingLocationStreamClient();
    final motionClient = TrackingMotionEvidenceClient();
    final container = _container(
      streamClient: streamClient,
      motionClient: motionClient,
      now: () => now,
      settings: const RunSettingsState(autoPauseEnabled: true),
    );
    addTearDown(() async {
      await streamClient.close();
      await motionClient.close();
      container.dispose();
    });

    await _startRun(container, streamClient, startedAt);
    await _emitStationaryWindow(
      streamClient,
      startedAt,
      updateNow: (value) => now = value,
    );

    expect(container.read(runPlaybackControllerProvider).isAutoPaused, isTrue);

    now = startedAt.add(const Duration(seconds: 16));
    await container
        .read(runSettingsControllerProvider.notifier)
        .setAutoPauseEnabled(false);

    final playbackState = container.read(runPlaybackControllerProvider);
    expect(playbackState.status, RunScreenStatus.running);
    expect(playbackState.pauseReason, isNull);
    expect(playbackState.autoPauseEnabled, isFalse);
    expect(playbackState.resumedAt, now);
  });

  test('turning auto pause off does not resume a manual pause', () async {
    final startedAt = DateTime(2026, 4, 20, 6, 0);
    var now = startedAt;
    final streamClient = TrackingLocationStreamClient();
    final motionClient = TrackingMotionEvidenceClient();
    final container = _container(
      streamClient: streamClient,
      motionClient: motionClient,
      now: () => now,
      settings: const RunSettingsState(autoPauseEnabled: true),
    );
    addTearDown(() async {
      await streamClient.close();
      await motionClient.close();
      container.dispose();
    });

    await _startRun(container, streamClient, startedAt);
    now = startedAt.add(const Duration(seconds: 5));
    await container.read(runPlaybackControllerProvider.notifier).pause();
    await container
        .read(runSettingsControllerProvider.notifier)
        .setAutoPauseEnabled(false);

    final playbackState = container.read(runPlaybackControllerProvider);
    expect(playbackState.status, RunScreenStatus.paused);
    expect(playbackState.pauseReason, RunPauseReason.manual);
    expect(playbackState.autoPauseEnabled, isFalse);
  });

  test(
    'turning auto pause on during a run enables the next pause decision',
    () async {
      final startedAt = DateTime(2026, 4, 20, 6, 0);
      var now = startedAt;
      final streamClient = TrackingLocationStreamClient();
      final motionClient = TrackingMotionEvidenceClient();
      final container = _container(
        streamClient: streamClient,
        motionClient: motionClient,
        now: () => now,
        settings: const RunSettingsState(),
      );
      addTearDown(() async {
        await streamClient.close();
        await motionClient.close();
        container.dispose();
      });

      await _startRun(container, streamClient, startedAt);
      expect(
        container.read(runPlaybackControllerProvider).autoPauseEnabled,
        isFalse,
      );

      await container
          .read(runSettingsControllerProvider.notifier)
          .setAutoPauseEnabled(true);
      await _emitStationaryWindow(
        streamClient,
        startedAt,
        updateNow: (value) => now = value,
      );

      final playbackState = container.read(runPlaybackControllerProvider);
      expect(playbackState.autoPauseEnabled, isTrue);
      expect(playbackState.status, RunScreenStatus.paused);
      expect(playbackState.pauseReason, RunPauseReason.auto);
    },
  );
}

ProviderContainer _container({
  required TrackingLocationStreamClient streamClient,
  required TrackingMotionEvidenceClient motionClient,
  required DateTime Function() now,
  required RunSettingsState settings,
}) {
  return ProviderContainer(
    overrides: [
      deviceLocationClientProvider.overrideWithValue(
        TestDeviceLocationClient(),
      ),
      locationStreamClientProvider.overrideWithValue(streamClient),
      runMotionEvidenceClientProvider.overrideWithValue(motionClient),
      runSettingsRepositoryProvider.overrideWithValue(
        TestRunSettingsRepository(settings),
      ),
      runPlaybackClockProvider.overrideWithValue(now),
    ],
  );
}

Future<void> _startRun(
  ProviderContainer container,
  TrackingLocationStreamClient streamClient,
  DateTime startedAt,
) async {
  await container.read(runSettingsControllerProvider.future);
  await startVisibleLiveTracking(container);
  await streamClient.emit(
    playbackSample(latitude: 37, longitude: 127, capturedAt: startedAt),
  );
  await container.read(runPlaybackControllerProvider.notifier).start();
}

Future<void> _emitStationaryWindow(
  TrackingLocationStreamClient streamClient,
  DateTime startedAt, {
  required void Function(DateTime) updateNow,
}) async {
  for (var index = 1; index <= 3; index += 1) {
    final sampleTime = startedAt.add(Duration(seconds: index * 5));
    updateNow(sampleTime);
    await streamClient.emit(
      playbackSample(
        latitude: 37 + (0.00002 * index),
        longitude: 127,
        capturedAt: sampleTime,
        speedMps: 0,
        horizontalAccuracyM: 8,
      ),
    );
  }
}
