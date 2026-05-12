// 기록 레이스 출발 확인 조건을 검증하는 테스트
import 'package:flutter_test/flutter_test.dart';
import 'package:runlini/features/record_race/service/record_race_gap_service.dart';
import 'package:runlini/features/run_tracking/types/run_point.dart';
import 'package:runlini/features/run_tracking/types/run_session.dart';

void main() {
  group('RecordRaceGapService start decision', () {
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

    test(
      'confirms recordRace start after two forward points near route start',
      () {
        final first = service.evaluateStart(
          runnerPoints: const [
            RunPoint(
              latitude: 0,
              longitude: 0,
              timestampRelMs: 0,
              source: RunPointSource.simulated,
            ),
            RunPoint(
              latitude: 0,
              longitude: 0.0003,
              timestampRelMs: 10000,
              source: RunPointSource.simulated,
            ),
          ],
          recordRaceSession: recordRaceSession,
        );
        expect(first.isConfirmed, isFalse);
        expect(first.candidateCount, 1);

        final second = service.evaluateStart(
          runnerPoints: const [
            RunPoint(
              latitude: 0,
              longitude: 0,
              timestampRelMs: 0,
              source: RunPointSource.simulated,
            ),
            RunPoint(
              latitude: 0,
              longitude: 0.0003,
              timestampRelMs: 10000,
              source: RunPointSource.simulated,
            ),
            RunPoint(
              latitude: 0,
              longitude: 0.0006,
              timestampRelMs: 20000,
              source: RunPointSource.simulated,
            ),
          ],
          recordRaceSession: recordRaceSession,
        );
        expect(second.isConfirmed, isTrue);
        expect(second.candidateCount, 2);
      },
    );

    test('confirms start from a later route-start anchor', () {
      final decision = service.evaluateStart(
        runnerPoints: const [
          RunPoint(
            latitude: 0.002,
            longitude: 0,
            timestampRelMs: 0,
            source: RunPointSource.simulated,
          ),
          RunPoint(
            latitude: 0,
            longitude: 0,
            timestampRelMs: 10000,
            source: RunPointSource.simulated,
          ),
          RunPoint(
            latitude: 0,
            longitude: 0.0003,
            timestampRelMs: 20000,
            source: RunPointSource.simulated,
          ),
          RunPoint(
            latitude: 0,
            longitude: 0.0006,
            timestampRelMs: 30000,
            source: RunPointSource.simulated,
          ),
        ],
        recordRaceSession: recordRaceSession,
      );

      expect(decision.isConfirmed, isTrue);
      expect(decision.candidateCount, 2);
    });

    test('confirms start from accepted distance fallback on early route', () {
      final decision = service.evaluateStart(
        runnerPoints: const [
          RunPoint(
            latitude: 0,
            longitude: 0.0006,
            timestampRelMs: 10000,
            source: RunPointSource.simulated,
          ),
          RunPoint(
            latitude: 0,
            longitude: 0.0008,
            timestampRelMs: 20000,
            source: RunPointSource.simulated,
          ),
        ],
        recordRaceSession: recordRaceSession,
        runnerDistanceM: 90,
      );

      expect(decision.isConfirmed, isTrue);
    });

    test('does not fallback-confirm start while off route', () {
      final decision = service.evaluateStart(
        runnerPoints: const [
          RunPoint(
            latitude: 0.002,
            longitude: 0.0006,
            timestampRelMs: 10000,
            source: RunPointSource.simulated,
          ),
          RunPoint(
            latitude: 0.002,
            longitude: 0.0008,
            timestampRelMs: 20000,
            source: RunPointSource.simulated,
          ),
        ],
        recordRaceSession: recordRaceSession,
        runnerDistanceM: 90,
      );

      expect(decision.isConfirmed, isFalse);
    });
  });
}
