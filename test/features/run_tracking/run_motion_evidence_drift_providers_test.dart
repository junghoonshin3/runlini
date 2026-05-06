import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:runlini/core/location/location_stream_client.dart';
import 'package:runlini/core/motion/run_motion_evidence_client.dart';
import 'package:runlini/features/run_tracking/state/run_playback_providers.dart';
import 'package:runlini/features/run_tracking/state/run_settings_providers.dart';
import 'package:runlini/features/run_tracking/types/run_screen_status.dart';
import 'package:runlini/features/run_tracking/types/run_settings.dart';

import 'run_playback_provider_harness.dart';

void main() {
  test('motion source blocks GPS-only auto resume', () async {
    final startedAt = DateTime(2026, 4, 20, 6, 0, 0);
    var now = startedAt;
    final streamClient = TrackingLocationStreamClient();
    final motionClient = TrackingMotionEvidenceClient();
    final container = ProviderContainer(
      overrides: [
        deviceLocationClientProvider.overrideWithValue(
          TestDeviceLocationClient(),
        ),
        locationStreamClientProvider.overrideWithValue(streamClient),
        runMotionEvidenceClientProvider.overrideWithValue(motionClient),
        runSettingsRepositoryProvider.overrideWithValue(
          TestRunSettingsRepository(
            const RunSettingsState(autoPauseEnabled: true),
          ),
        ),
        runPlaybackClockProvider.overrideWithValue(() => now),
      ],
    );
    addTearDown(() async {
      await streamClient.close();
      await motionClient.close();
      container.dispose();
    });

    await _startRun(container, streamClient, startedAt);
    await motionClient.emit(_motionEvidence(startedAt));
    await _emitStationaryWindow(
      streamClient,
      startedAt,
      updateNow: (value) {
        now = value;
      },
    );

    now = startedAt.add(const Duration(seconds: 25));
    await streamClient.emit(
      playbackSample(
        latitude: 37.00045,
        longitude: 127,
        capturedAt: now,
        speedMps: 1.4,
        horizontalAccuracyM: 6,
      ),
    );

    final playbackState = container.read(runPlaybackControllerProvider);
    expect(playbackState.status, RunScreenStatus.paused);
    expect(playbackState.recordedPoints, hasLength(1));
  });

  test('recent step evidence allows auto resume', () async {
    final startedAt = DateTime(2026, 4, 20, 6, 0, 0);
    var now = startedAt;
    final streamClient = TrackingLocationStreamClient();
    final motionClient = TrackingMotionEvidenceClient();
    final container = ProviderContainer(
      overrides: [
        deviceLocationClientProvider.overrideWithValue(
          TestDeviceLocationClient(),
        ),
        locationStreamClientProvider.overrideWithValue(streamClient),
        runMotionEvidenceClientProvider.overrideWithValue(motionClient),
        runSettingsRepositoryProvider.overrideWithValue(
          TestRunSettingsRepository(
            const RunSettingsState(autoPauseEnabled: true),
          ),
        ),
        runPlaybackClockProvider.overrideWithValue(() => now),
      ],
    );
    addTearDown(() async {
      await streamClient.close();
      await motionClient.close();
      container.dispose();
    });

    await _startRun(container, streamClient, startedAt);
    await motionClient.emit(_motionEvidence(startedAt));
    await _emitStationaryWindow(
      streamClient,
      startedAt,
      updateNow: (value) {
        now = value;
      },
    );

    now = startedAt.add(const Duration(seconds: 20));
    await motionClient.emit(_motionEvidence(now, stepDelta: 1));
    await streamClient.emit(
      playbackSample(
        latitude: 37.00025,
        longitude: 127,
        capturedAt: now,
        speedMps: 1.4,
        horizontalAccuracyM: 6,
      ),
    );
    now = startedAt.add(const Duration(seconds: 25));
    await motionClient.emit(_motionEvidence(now, stepDelta: 1));
    await streamClient.emit(
      playbackSample(
        latitude: 37.00045,
        longitude: 127,
        capturedAt: now,
        speedMps: 1.4,
        horizontalAccuracyM: 6,
      ),
    );

    final playbackState = container.read(runPlaybackControllerProvider);
    expect(playbackState.status, RunScreenStatus.running);
    expect(playbackState.recordedPoints, hasLength(2));
  });

  test('recent step evidence prevents false auto pause', () async {
    final startedAt = DateTime(2026, 4, 20, 6, 0, 0);
    var now = startedAt;
    final streamClient = TrackingLocationStreamClient();
    final motionClient = TrackingMotionEvidenceClient();
    final container = ProviderContainer(
      overrides: [
        deviceLocationClientProvider.overrideWithValue(
          TestDeviceLocationClient(),
        ),
        locationStreamClientProvider.overrideWithValue(streamClient),
        runMotionEvidenceClientProvider.overrideWithValue(motionClient),
        runSettingsRepositoryProvider.overrideWithValue(
          TestRunSettingsRepository(
            const RunSettingsState(autoPauseEnabled: true),
          ),
        ),
        runPlaybackClockProvider.overrideWithValue(() => now),
      ],
    );
    addTearDown(() async {
      await streamClient.close();
      await motionClient.close();
      container.dispose();
    });

    await _startRun(container, streamClient, startedAt);
    await motionClient.emit(_motionEvidence(startedAt));
    for (var index = 1; index <= 3; index += 1) {
      now = startedAt.add(Duration(seconds: index * 5));
      if (index == 2) {
        await motionClient.emit(_motionEvidence(now, stepDelta: 1));
      }
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

    final playbackState = container.read(runPlaybackControllerProvider);
    expect(playbackState.status, RunScreenStatus.running);
    expect(playbackState.pauseReason, isNull);
  });

  test(
    'auto pause off still blocks stationary unlock without motion',
    () async {
      final startedAt = DateTime(2026, 4, 20, 6, 0, 0);
      var now = startedAt;
      final streamClient = TrackingLocationStreamClient();
      final motionClient = TrackingMotionEvidenceClient();
      final container = ProviderContainer(
        overrides: [
          deviceLocationClientProvider.overrideWithValue(
            TestDeviceLocationClient(),
          ),
          locationStreamClientProvider.overrideWithValue(streamClient),
          runMotionEvidenceClientProvider.overrideWithValue(motionClient),
          runSettingsRepositoryProvider.overrideWithValue(
            TestRunSettingsRepository(const RunSettingsState()),
          ),
          runPlaybackClockProvider.overrideWithValue(() => now),
        ],
      );
      addTearDown(() async {
        await streamClient.close();
        await motionClient.close();
        container.dispose();
      });

      await _startRun(container, streamClient, startedAt);
      await motionClient.emit(_motionEvidence(startedAt));
      await _emitStationaryWindow(
        streamClient,
        startedAt,
        updateNow: (value) {
          now = value;
        },
      );

      now = startedAt.add(const Duration(seconds: 25));
      await streamClient.emit(
        playbackSample(
          latitude: 37.00045,
          longitude: 127,
          capturedAt: now,
          speedMps: 1.4,
          horizontalAccuracyM: 6,
        ),
      );

      final playbackState = container.read(runPlaybackControllerProvider);
      expect(playbackState.status, RunScreenStatus.running);
      expect(playbackState.recordedPoints, hasLength(1));
    },
  );
}

Future<void> _startRun(
  ProviderContainer container,
  TrackingLocationStreamClient streamClient,
  DateTime startedAt,
) async {
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
    final now = startedAt.add(Duration(seconds: index * 5));
    updateNow(now);
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
}

RunMotionEvidence _motionEvidence(DateTime timestamp, {int stepDelta = 0}) {
  return RunMotionEvidence(
    timestamp: timestamp,
    stepDelta: stepDelta,
    sourceAvailability: RunMotionEvidenceSourceAvailability.available,
  );
}
