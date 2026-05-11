// 고스트런 provider 순환 갱신 방지를 검증하는 테스트
import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:runlini/core/health/health_workout_recorder.dart';
import 'package:runlini/core/location/location_stream_client.dart';
import 'package:runlini/core/map/map_coordinate.dart';
import 'package:runlini/features/ghost_racer/types/ghost_race_frame.dart';
import 'package:runlini/features/run_tracking/state/run_ghost_race_providers.dart';
import 'package:runlini/features/run_tracking/state/run_live_metrics_providers.dart';
import 'package:runlini/features/run_tracking/state/run_playback_providers.dart';
import 'package:runlini/features/run_tracking/types/run_map_static_state.dart';
import 'package:runlini/features/run_tracking/types/run_point.dart';
import 'package:runlini/features/run_tracking/types/run_session.dart';

import 'run_playback_provider_harness.dart';

void main() {
  test(
    'candidate-only completion updates do not write playback state',
    () async {
      final harness = _GhostProviderHarness();
      addTearDown(harness.dispose);

      var completionWrites = 0;
      final frameSubscription = harness.container.listen<GhostRaceFrame?>(
        ghostRaceFrameProvider,
        (GhostRaceFrame? previous, GhostRaceFrame? next) {
          if (next == null || completionWrites > 0) {
            return;
          }
          completionWrites += 1;
          harness.container
              .read(runPlaybackControllerProvider.notifier)
              .updateGhostCompletion(candidateCount: 1);
        },
      );
      final mapSubscription = harness.container.listen(
        ghostAwareRunMapViewStateProvider,
        (_, _) {},
      );
      addTearDown(frameSubscription.close);
      addTearDown(mapSubscription.close);

      await harness.start();
      await harness.moveToEarlyRoute();

      expect(completionWrites, 1);
      expect(
        harness.container
            .read(runPlaybackControllerProvider)
            .ghostCompletionCandidateCount,
        0,
      );
      expect(frameSubscription.read(), isNotNull);
      expect(
        harness.container
            .read(ghostAwareRunMapViewStateProvider)
            .ghostMarkerPoint,
        frameSubscription.read()!.ghostMarkerPoint,
      );
    },
  );

  test('ghost race frame freezes while playback is paused', () async {
    final harness = _GhostProviderHarness();
    addTearDown(harness.dispose);
    final frameSubscription = harness.container.listen<GhostRaceFrame?>(
      ghostRaceFrameProvider,
      (GhostRaceFrame? previous, GhostRaceFrame? next) {},
    );
    addTearDown(frameSubscription.close);

    await harness.start();
    await harness.moveToEarlyRoute();
    final beforePause = frameSubscription.read()!;

    await harness.container
        .read(runPlaybackControllerProvider.notifier)
        .pause();
    harness.now = harness.startedAt.add(const Duration(minutes: 5));
    harness.tickerController.add(2);
    await settleAsync();

    final pausedFrame = frameSubscription.read()!;
    expect(pausedFrame.status, beforePause.status);
    expect(pausedFrame.timeGapMs, beforePause.timeGapMs);
    expect(pausedFrame.distanceGapM, beforePause.distanceGapM);
    expect(pausedFrame.ghostMarkerPoint, beforePause.ghostMarkerPoint);
  });
}

class _GhostProviderHarness {
  _GhostProviderHarness() {
    container = ProviderContainer(
      overrides: [
        deviceLocationClientProvider.overrideWithValue(
          TestDeviceLocationClient(),
        ),
        locationStreamClientProvider.overrideWithValue(streamClient),
        healthWorkoutRecorderProvider.overrideWithValue(
          TestHealthWorkoutRecorder(),
        ),
        runPlaybackClockProvider.overrideWithValue(() => now),
        liveRunMetricsTickerProvider.overrideWith(
          (Ref ref) => tickerController.stream,
        ),
        runMapStaticStateProvider.overrideWith((Ref ref) async {
          return RunMapStaticState(
            fallbackMapCenter: const MapCoordinate(latitude: 0, longitude: 0),
            ghostPolylinePoints: const <MapCoordinate>[
              MapCoordinate(latitude: 0, longitude: 0),
              MapCoordinate(latitude: 0, longitude: 0.009),
            ],
            selectedGhostSession: _ghostSession(),
          );
        }),
      ],
    );
  }

  final DateTime startedAt = DateTime(2026, 4, 20, 6);
  late DateTime now = startedAt;
  final tickerController = StreamController<int>.broadcast();
  final streamClient = TrackingLocationStreamClient();
  late final ProviderContainer container;

  Future<void> start() async {
    await container.read(runMapStaticStateProvider.future);
    await startVisibleLiveTracking(container);
    await streamClient.emit(
      playbackSample(latitude: 0, longitude: 0, capturedAt: startedAt),
    );
    await container.read(runPlaybackControllerProvider.notifier).start();
  }

  Future<void> moveToEarlyRoute() async {
    now = startedAt.add(const Duration(seconds: 10));
    await streamClient.emit(
      playbackSample(latitude: 0, longitude: 0.0003, capturedAt: now),
    );
    now = startedAt.add(const Duration(seconds: 20));
    await streamClient.emit(
      playbackSample(latitude: 0, longitude: 0.0006, capturedAt: now),
    );
    now = startedAt.add(const Duration(seconds: 25));
    await streamClient.emit(
      playbackSample(latitude: 0, longitude: 0.0008, capturedAt: now),
    );
    tickerController.add(1);
    await settleAsync();
  }

  Future<void> dispose() async {
    container.dispose();
    await tickerController.close();
    await streamClient.close();
  }
}

RunSession _ghostSession() {
  return RunSession(
    id: 'ghost-route',
    startedAt: DateTime.utc(2026, 4, 19, 6),
    endedAt: DateTime.utc(2026, 4, 19, 6, 10),
    distanceM: 1000,
    durationMs: 600000,
    sourceSummary: 'test',
    points: const [
      RunPoint(
        latitude: 0,
        longitude: 0,
        timestampRelMs: 0,
        source: RunPointSource.simulated,
      ),
      RunPoint(
        latitude: 0,
        longitude: 0.009,
        timestampRelMs: 600000,
        source: RunPointSource.simulated,
      ),
    ],
  );
}
