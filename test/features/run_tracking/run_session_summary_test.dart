import 'package:flutter_test/flutter_test.dart';
import 'package:runlini/features/run_tracking/types/run_point.dart';
import 'package:runlini/features/run_tracking/types/run_session.dart';
import 'package:runlini/features/run_tracking/types/run_session_summary.dart';

void main() {
  test('creates a stable summary from a run session', () {
    final session = RunSession(
      id: 'summary-session',
      startedAt: DateTime.utc(2026, 4, 19, 6, 30),
      endedAt: DateTime.utc(2026, 4, 19, 6, 42),
      distanceM: 2400,
      durationMs: 720000,
      sourceSummary: 'fixture:test',
      averageCadenceSpm: 170,
      points: const [
        RunPoint(
          latitude: 37.0,
          longitude: 127.0,
          timestampRelMs: 0,
          paceSecPerKm: 300,
          source: RunPointSource.simulated,
        ),
      ],
    );

    final summary = RunSessionSummary.fromSession(session);

    expect(summary.id, session.id);
    expect(summary.distanceKm, closeTo(2.4, 0.001));
    expect(summary.averagePaceSecPerKm, closeTo(300, 0.001));
    expect(summary.averageCadenceSpm, 170);
  });
}
