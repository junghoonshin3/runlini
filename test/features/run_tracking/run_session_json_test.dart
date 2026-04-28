import 'package:flutter_test/flutter_test.dart';
import 'package:runlini/features/run_tracking/types/run_point.dart';
import 'package:runlini/features/run_tracking/types/run_session.dart';
import 'package:runlini/features/run_tracking/types/run_session_ghost_summary.dart';

void main() {
  test('reads old run session json without ghost summary', () {
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

    expect(session.ghostSummary, isNull);
    expect(session.captureSource, RunSessionCaptureSource.phoneGps);
  });

  test('round trips ghost summary metadata', () {
    final session = RunSession(
      id: 'ghost-run',
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
      ghostSummary: const RunSessionGhostSummary(
        result: RunSessionGhostResult.ahead,
        timeGapMs: 12000,
        distanceGapM: 42,
        ghostSessionId: 'fixture-ghost',
        ghostLabel: 'fixture:ghost',
      ),
    );

    final restored = RunSession.fromJson(session.toJson());

    expect(restored.ghostSummary?.result, RunSessionGhostResult.ahead);
    expect(restored.captureSource, RunSessionCaptureSource.watchOs);
    expect(restored.points.single.source, RunPointSource.watchOs);
    expect(restored.ghostSummary?.timeGapMs, 12000);
    expect(restored.ghostSummary?.distanceGapM, 42);
    expect(restored.ghostSummary?.ghostSessionId, 'fixture-ghost');
  });
}
