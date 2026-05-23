// 기록 레이스 경로가 명시적 segment break를 따르는지 검증하는 테스트.
import 'package:flutter_test/flutter_test.dart';
import 'package:runlini/features/record_race/service/record_race_gap_service.dart';
import 'package:runlini/features/run_tracking/types/run_point.dart';
import 'package:runlini/features/run_tracking/types/run_session.dart';

void main() {
  const service = RecordRaceGapService();
  final recordRaceSession = RunSession(
    id: 'record-race-route',
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

  test('does not confirm start across an explicit runner segment break', () {
    final decision = service.evaluateStart(
      runnerPoints: const [
        RunPoint(
          latitude: 0,
          longitude: 0,
          timestampRelMs: 0,
          source: RunPointSource.simulated,
        ),
        RunPoint(
          latitude: 0,
          longitude: 0.001,
          timestampRelMs: 5000,
          source: RunPointSource.simulated,
          startsNewSegment: true,
        ),
        RunPoint(
          latitude: 0,
          longitude: 0.002,
          timestampRelMs: 10000,
          source: RunPointSource.simulated,
        ),
      ],
      recordRaceSession: recordRaceSession,
      runnerDistanceM: 0,
    );

    expect(decision.isConfirmed, isFalse);
    expect(decision.candidateCount, 1);
  });

  test('excludes explicit target route breaks from route distance', () {
    final pausedRecordRaceSession = RunSession(
      id: 'paused-record-race-route',
      startedAt: DateTime.utc(2026, 4, 19, 6),
      endedAt: DateTime.utc(2026, 4, 19, 6, 10),
      distanceM: 500,
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
          longitude: 0.0045,
          timestampRelMs: 300000,
          source: RunPointSource.simulated,
          startsNewSegment: true,
        ),
        RunPoint(
          latitude: 0,
          longitude: 0.009,
          timestampRelMs: 600000,
          source: RunPointSource.simulated,
        ),
      ],
    );
    const runnerAtFinish = RunPoint(
      latitude: 0,
      longitude: 0.009,
      timestampRelMs: 600000,
      source: RunPointSource.simulated,
    );

    final frame = service.calculate(
      runnerPoint: runnerAtFinish,
      recordRaceSession: pausedRecordRaceSession,
      runnerElapsedMs: 600000,
      runnerDistanceM: 500,
    );

    expect(frame.totalRouteDistanceM, closeTo(500, 20));
    expect(frame.distanceToFinishM, closeTo(0, 1));
  });
}
