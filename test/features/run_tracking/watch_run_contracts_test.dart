import 'package:flutter_test/flutter_test.dart';
import 'package:runlini/features/run_tracking/types/run_point.dart';
import 'package:runlini/features/run_tracking/types/run_session.dart';
import 'package:runlini/features/run_tracking/types/run_session_record_race_summary.dart';
import 'package:runlini/features/run_tracking/types/watch_record_race_config.dart';
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
      recordRaceStatus: WatchRecordRaceStatus.ahead,
      recordRaceTimeGapMs: 12000,
      phoneConnected: true,
    );

    final restored = WatchRunSnapshot.fromJson(snapshot.toJson());

    expect(restored.phase, WatchRunPhase.running);
    expect(restored.recordRaceStatus, WatchRecordRaceStatus.ahead);
    expect(restored.heartRateBpm, 151);
    expect(restored.phoneConnected, isTrue);
  });

  test('round trips watch events', () {
    final event = WatchRunEvent(
      sessionId: 'watch-live-1',
      type: WatchRunEventType.recordRace,
      elapsedMs: 180000,
      createdAt: DateTime.utc(2026, 4, 28, 9),
      message: '이기는 중',
      recordRaceTimeGapMs: 8000,
    );

    final restored = WatchRunEvent.fromJson(event.toJson());

    expect(restored.type, WatchRunEventType.recordRace);
    expect(restored.message, '이기는 중');
    expect(restored.recordRaceTimeGapMs, 8000);
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
      recordRaceSummary: const RunSessionRecordRaceSummary(
        result: RunSessionRecordRaceResult.ahead,
        timeGapMs: 12000,
        distanceGapM: 42,
        recordRaceSessionId: 'record-race-1',
        recordRaceLabel: '한강 5K',
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
    expect(
      restored.recordRaceSummary?.result,
      RunSessionRecordRaceResult.ahead,
    );
    expect(restored.recordRaceSummary?.recordRaceSessionId, 'record-race-1');
  });

  test('reads legacy ghost summary from completed watch run draft', () {
    final draft = WatchRunDraft.fromJson({
      'id': 'legacy-draft',
      'platform': WatchRunPlatform.wearOs.name,
      'startedAt': '2026-04-28T09:00:00.000Z',
      'durationMs': 1800000,
      'distanceM': 5000,
      'ghostSummary': {
        'result': 'ahead',
        'timeGapMs': 12000,
        'distanceGapM': 42,
        'ghostSessionId': 'old-record',
        'ghostLabel': 'old label',
      },
      'points': [
        {'lat': 37.5, 'lng': 127.0, 'timestampRelMs': 0, 'source': 'watchOs'},
      ],
    });

    expect(draft.recordRaceSummary?.result, RunSessionRecordRaceResult.ahead);
    expect(draft.recordRaceSummary?.recordRaceSessionId, 'old-record');
    expect(draft.recordRaceSummary?.recordRaceLabel, 'old label');
  });

  test('maps selected run session into watch recordRace config', () {
    final session = RunSession(
      id: 'record-race-1',
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

    final config = WatchRecordRaceConfig.fromSession(session);
    final restored = WatchRecordRaceConfig.fromJson(config.toJson());

    expect(restored.id, 'record-race-1');
    expect(restored.sourceSummary, '한강 2K');
    expect(restored.canRunOnWatch, isTrue);
    expect(restored.points, hasLength(2));
  });
}
