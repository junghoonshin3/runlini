import 'package:flutter_test/flutter_test.dart';
import 'package:runlini/features/run_tracking/types/run_point.dart';
import 'package:runlini/features/run_tracking/types/run_session.dart';
import 'package:runlini/features/run_tracking/types/run_session_record_race_summary.dart';

void main() {
  test('reads old run session json without recordRace summary', () {
    final session = RunSession.fromJson({
      'id': 'old-session',
      'startedAt': '2026-04-21T06:00:00.000Z',
      'distanceM': 1200,
      'durationMs': 420000,
      'sourceSummary': 'fixture:old',
      'points': [
        {'lat': 37.0, 'lng': 127.0, 'timestampRelMs': 0, 'source': 'simulated'},
      ],
    });

    expect(session.recordRaceSummary, isNull);
    expect(session.captureSource, RunSessionCaptureSource.phoneGps);
  });

  test('round trips recordRace summary metadata', () {
    final session = RunSession(
      id: 'record-race-run',
      startedAt: DateTime.utc(2026, 4, 21, 6),
      distanceM: 2000,
      durationMs: 720000,
      sourceSummary: 'device:gps',
      points: const [
        RunPoint(
          latitude: 37.0,
          longitude: 127.0,
          timestampRelMs: 0,
          source: RunPointSource.watchOs,
        ),
      ],
      captureSource: RunSessionCaptureSource.watchOs,
      recordRaceSummary: const RunSessionRecordRaceSummary(
        result: RunSessionRecordRaceResult.ahead,
        timeGapMs: 12000,
        distanceGapM: 42,
        recordRaceSessionId: 'fixture-record-race',
        recordRaceLabel: 'fixture:recordRace',
      ),
    );

    final restored = RunSession.fromJson(session.toJson());

    expect(
      restored.recordRaceSummary?.result,
      RunSessionRecordRaceResult.ahead,
    );
    expect(restored.captureSource, RunSessionCaptureSource.watchOs);
    expect(restored.points.single.source, RunPointSource.watchOs);
    expect(restored.recordRaceSummary?.timeGapMs, 12000);
    expect(restored.recordRaceSummary?.distanceGapM, 42);
    expect(
      restored.recordRaceSummary?.recordRaceSessionId,
      'fixture-record-race',
    );
  });

  test('reads legacy ghost summary metadata', () {
    final session = RunSession.fromJson({
      'id': 'legacy-ghost-run',
      'startedAt': '2026-04-21T06:00:00.000Z',
      'distanceM': 1200,
      'durationMs': 420000,
      'sourceSummary': 'fixture:old',
      'ghostSummary': {
        'result': 'behind',
        'timeGapMs': -8000,
        'distanceGapM': 30,
        'ghostSessionId': 'old-record',
        'ghostLabel': 'old label',
      },
      'points': [
        {'lat': 37.0, 'lng': 127.0, 'timestampRelMs': 0, 'source': 'simulated'},
      ],
    });

    expect(
      session.recordRaceSummary?.result,
      RunSessionRecordRaceResult.behind,
    );
    expect(session.recordRaceSummary?.timeGapMs, -8000);
    expect(session.recordRaceSummary?.recordRaceSessionId, 'old-record');
    expect(session.recordRaceSummary?.recordRaceLabel, 'old label');
  });
}
