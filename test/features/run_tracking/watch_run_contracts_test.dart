import 'package:flutter_test/flutter_test.dart';
import 'package:runlini/features/run_tracking/types/run_point.dart';
import 'package:runlini/features/run_tracking/types/run_session.dart';
import 'package:runlini/features/run_tracking/types/run_session_ghost_summary.dart';
import 'package:runlini/features/run_tracking/types/watch_ghost_config.dart';
import 'package:runlini/features/run_tracking/types/watch_run_draft.dart';
import 'package:runlini/features/run_tracking/types/watch_run_event.dart';
import 'package:runlini/features/run_tracking/types/watch_run_platform.dart';
import 'package:runlini/features/run_tracking/types/watch_run_snapshot.dart';

void main() {
  test('round trips live watch snapshot data', () {
    const snapshot = WatchRunSnapshot(
      sessionId: 'watch-live-1',
      phase: WatchRunPhase.running,
      elapsedMs: 64000,
      distanceM: 240,
      averagePaceSecPerKm: 360,
      currentPaceSecPerKm: 342,
      heartRateBpm: 151,
      caloriesKcal: 18,
      ghostStatus: WatchGhostStatus.ahead,
      ghostTimeGapMs: 12000,
      phoneConnected: true,
    );

    final restored = WatchRunSnapshot.fromJson(snapshot.toJson());

    expect(restored.phase, WatchRunPhase.running);
    expect(restored.ghostStatus, WatchGhostStatus.ahead);
    expect(restored.heartRateBpm, 151);
    expect(restored.phoneConnected, isTrue);
  });

  test('round trips watch events', () {
    final event = WatchRunEvent(
      sessionId: 'watch-live-1',
      type: WatchRunEventType.ghost,
      elapsedMs: 180000,
      createdAt: DateTime.utc(2026, 4, 28, 9),
      message: '이기는 중',
      ghostTimeGapMs: 8000,
    );

    final restored = WatchRunEvent.fromJson(event.toJson());

    expect(restored.type, WatchRunEventType.ghost);
    expect(restored.message, '이기는 중');
    expect(restored.ghostTimeGapMs, 8000);
  });

  test('round trips completed watch run draft', () {
    final draft = WatchRunDraft(
      id: 'draft-1',
      platform: WatchRunPlatform.watchOs,
      startedAt: DateTime.utc(2026, 4, 28, 9),
      endedAt: DateTime.utc(2026, 4, 28, 9, 30),
      durationMs: 1800000,
      distanceM: 5000,
      externalWorkoutId: 'apple-workout-1',
      sourceDeviceName: 'Apple Watch',
      caloriesKcal: 350,
      ghostSummary: const RunSessionGhostSummary(
        result: RunSessionGhostResult.ahead,
        timeGapMs: 12000,
        distanceGapM: 42,
        ghostSessionId: 'ghost-1',
        ghostLabel: '한강 5K',
      ),
      points: const <RunPoint>[
        RunPoint(
          latitude: 37.5,
          longitude: 127,
          timestampRelMs: 0,
          source: RunPointSource.watchOs,
          heartRateBpm: 145,
          cadenceSpm: 172,
        ),
      ],
    );

    final restored = WatchRunDraft.fromJson(draft.toJson());

    expect(restored.platform, WatchRunPlatform.watchOs);
    expect(restored.externalWorkoutId, 'apple-workout-1');
    expect(restored.points.single.heartRateBpm, 145);
    expect(restored.points.single.cadenceSpm, 172);
    expect(restored.ghostSummary?.result, RunSessionGhostResult.ahead);
    expect(restored.ghostSummary?.ghostSessionId, 'ghost-1');
  });

  test('maps selected run session into watch ghost config', () {
    final session = RunSession(
      id: 'ghost-1',
      startedAt: DateTime.utc(2026, 4, 28, 7),
      durationMs: 600000,
      distanceM: 2000,
      sourceSummary: '한강 2K',
      points: const <RunPoint>[
        RunPoint(
          latitude: 37,
          longitude: 127,
          timestampRelMs: 0,
          source: RunPointSource.deviceGps,
        ),
        RunPoint(
          latitude: 37.001,
          longitude: 127.001,
          timestampRelMs: 600000,
          source: RunPointSource.deviceGps,
        ),
      ],
    );

    final config = WatchGhostConfig.fromSession(session);
    final restored = WatchGhostConfig.fromJson(config.toJson());

    expect(restored.id, 'ghost-1');
    expect(restored.sourceSummary, '한강 2K');
    expect(restored.canRunOnWatch, isTrue);
    expect(restored.points, hasLength(2));
  });
}
