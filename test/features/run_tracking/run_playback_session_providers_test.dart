import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:runlini/core/health/health_workout_recorder.dart';
import 'package:runlini/core/location/location_stream_client.dart';
import 'package:runlini/features/run_tracking/state/run_playback_providers.dart';
import 'package:runlini/features/run_tracking/state/run_session_providers.dart';
import 'package:runlini/features/run_tracking/state/run_settings_providers.dart';
import 'package:runlini/features/run_tracking/types/run_screen_status.dart';
import 'package:runlini/features/run_tracking/types/run_session.dart';
import 'package:runlini/features/run_tracking/types/run_settings.dart';

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
        runSettingsRepositoryProvider.overrideWithValue(
          TestRunSettingsRepository(const RunSettingsState(bodyWeightKg: 70)),
        ),
        runPlaybackClockProvider.overrideWithValue(() => now),
      ],
    );
    addTearDown(() async {
      await streamClient.close();
      container.dispose();
    });

    await container.read(runSettingsControllerProvider.future);
    await startVisibleLiveTracking(container);
    await streamClient.emit(seedSample);
    await container.read(runPlaybackControllerProvider.notifier).start();
    await streamClient.emit(acceptedSample);
    now = DateTime(2026, 4, 20, 6, 0, 8);
    await container.read(runPlaybackControllerProvider.notifier).stop();

    expect(healthRecorder.beginCalls, 0);
    expect(healthRecorder.finishCalls, 0);
    expect(healthRecorder.cancelCalls, 0);
    expect(sessionRepository.savedSessions, isEmpty);
    expect(
      container.read(runPlaybackControllerProvider).status,
      RunScreenStatus.reviewing,
    );
    final pendingSession = container
        .read(runPlaybackControllerProvider)
        .pendingFinishedSession;
    expect(pendingSession, isNotNull);
    expect(pendingSession!.caloriesKcal, isNotNull);

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
    expect(sessionRepository.saveCalls, 1);
    expect(sessionRepository.savedSessions.single.caloriesKcal, isNotNull);
    expect(
      sessionRepository.savedSessions.single.syncStatus,
      RunSessionSyncStatus.syncSkipped,
    );
    expect(sessionRepository.savedSessions.single.externalId, isNull);
    expect(healthRecorder.finishCalls, 0);
    expect(
      container.read(runPlaybackControllerProvider).status,
      RunScreenStatus.idle,
    );
  });

  test('body weight saved during review updates pending calories', () async {
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
    final sessionRepository = TestRunSessionRepository();
    final settingsRepository = TestRunSettingsRepository();
    var now = DateTime(2026, 4, 20, 6, 0, 3);
    final container = ProviderContainer(
      overrides: [
        deviceLocationClientProvider.overrideWithValue(
          TestDeviceLocationClient(),
        ),
        locationStreamClientProvider.overrideWithValue(streamClient),
        runSessionRepositoryProvider.overrideWithValue(sessionRepository),
        runSettingsRepositoryProvider.overrideWithValue(settingsRepository),
        runPlaybackClockProvider.overrideWithValue(() => now),
      ],
    );
    addTearDown(() async {
      await streamClient.close();
      container.dispose();
    });

    await container.read(runSettingsControllerProvider.future);
    await startVisibleLiveTracking(container);
    await streamClient.emit(seedSample);
    await container.read(runPlaybackControllerProvider.notifier).start();
    await streamClient.emit(acceptedSample);
    now = DateTime(2026, 4, 20, 6, 0, 8);
    await container.read(runPlaybackControllerProvider.notifier).stop();

    expect(
      container
          .read(runPlaybackControllerProvider)
          .pendingFinishedSession!
          .caloriesKcal,
      isNull,
    );

    await container
        .read(runSettingsControllerProvider.notifier)
        .setBodyWeightKg(70);
    container
        .read(runPlaybackControllerProvider.notifier)
        .applyBodyWeightToPendingFinishedRun(70);

    final pendingSession = container
        .read(runPlaybackControllerProvider)
        .pendingFinishedSession!;
    expect(pendingSession.caloriesKcal, isNotNull);

    await container
        .read(runPlaybackControllerProvider.notifier)
        .saveFinishedRun();

    expect(settingsRepository.settings.bodyWeightKg, 70);
    expect(sessionRepository.savedSessions.single.caloriesKcal, isNotNull);
  });

  test('run start and save do not request Health backup permissions', () async {
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
        runSettingsRepositoryProvider.overrideWithValue(
          TestRunSettingsRepository(),
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
    await container.read(runPlaybackControllerProvider.notifier).stop();
    await container
        .read(runPlaybackControllerProvider.notifier)
        .saveFinishedRun();

    expect(startResult, RunTrackingToggleResult.started);
    expect(
      container.read(runPlaybackControllerProvider).status,
      RunScreenStatus.idle,
    );
    expect(healthRecorder.prepareCalls, 0);
    expect(healthRecorder.beginCalls, 0);
    expect(healthRecorder.finishCalls, 0);
    expect(
      sessionRepository.savedSessions.single.syncStatus,
      RunSessionSyncStatus.syncSkipped,
    );
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
        runSettingsRepositoryProvider.overrideWithValue(
          TestRunSettingsRepository(),
        ),
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
}
