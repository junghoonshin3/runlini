import 'package:flutter_test/flutter_test.dart';
import 'package:runlini/features/ghost_racer/service/ghost_race_gap_service.dart';
import 'package:runlini/features/ghost_racer/types/ghost_race_frame.dart';
import 'package:runlini/features/run_tracking/types/run_point.dart';
import 'package:runlini/features/run_tracking/types/run_session.dart';

void main() {
  group('GhostRaceGapService', () {
    const service = GhostRaceGapService();
    final ghostSession = RunSession(
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

    test('marks the runner ahead by time at the same route progress', () {
      const runnerPoint = RunPoint(
        latitude: 0,
        longitude: 0.0045,
        timestampRelMs: 240000,
        source: RunPointSource.simulated,
      );

      final frame = service.calculate(
        runnerPoint: runnerPoint,
        ghostSession: ghostSession,
        runnerElapsedMs: 240000,
      );

      expect(frame.status, GhostRaceStatus.ahead);
      expect(frame.timeGapMs, closeTo(60000, 1000));
      expect(frame.distanceGapM, greaterThan(90));
      expect(frame.ghostMarkerPoint, isNotNull);
      expect(frame.ghostMarkerPoint!.longitude, closeTo(0.0036, 0.0001));
    });

    test('marks the runner behind by time at the same route progress', () {
      const runnerPoint = RunPoint(
        latitude: 0,
        longitude: 0.0045,
        timestampRelMs: 360000,
        source: RunPointSource.simulated,
      );

      final frame = service.calculate(
        runnerPoint: runnerPoint,
        ghostSession: ghostSession,
        runnerElapsedMs: 360000,
      );

      expect(frame.status, GhostRaceStatus.behind);
      expect(frame.timeGapMs, closeTo(-60000, 1000));
      expect(frame.distanceGapM, lessThan(-90));
    });

    test('treats a small time gap as level', () {
      const runnerPoint = RunPoint(
        latitude: 0,
        longitude: 0.0045,
        timestampRelMs: 302000,
        source: RunPointSource.simulated,
      );

      final frame = service.calculate(
        runnerPoint: runnerPoint,
        ghostSession: ghostSession,
        runnerElapsedMs: 302000,
      );

      expect(frame.status, GhostRaceStatus.level);
      expect(frame.timeGapMs.abs(), lessThanOrEqualTo(3000));
    });

    test('marks the frame off route when the runner is far from the path', () {
      const runnerPoint = RunPoint(
        latitude: 0.001,
        longitude: 0.0045,
        timestampRelMs: 300000,
        source: RunPointSource.simulated,
      );

      final frame = service.calculate(
        runnerPoint: runnerPoint,
        ghostSession: ghostSession,
        runnerElapsedMs: 300000,
      );

      expect(frame.status, GhostRaceStatus.offRoute);
      expect(frame.isOffRoute, isTrue);
      expect(frame.ghostMarkerPoint, isNotNull);
    });
  });
}
