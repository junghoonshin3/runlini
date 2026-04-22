import 'package:flutter_test/flutter_test.dart';
import 'package:runlini/features/ghost_racer/service/ghost_projection_service.dart';
import 'package:runlini/features/ghost_racer/types/ghost_frame.dart';
import 'package:runlini/features/run_tracking/types/run_point.dart';
import 'package:runlini/features/run_tracking/types/run_session.dart';

void main() {
  group('TimeBasedGhostProjectionService', () {
    const service = TimeBasedGhostProjectionService();
    final session = RunSession(
      id: 'ghost',
      startedAt: DateTime.utc(2026, 4, 19),
      endedAt: DateTime.utc(2026, 4, 19, 0, 10),
      distanceM: 1000,
      durationMs: 10000,
      sourceSummary: 'test',
      points: const [
        RunPoint(
          latitude: 37.0,
          longitude: 127.0,
          timestampRelMs: 0,
          paceSecPerKm: 300,
          source: RunPointSource.simulated,
        ),
        RunPoint(
          latitude: 37.0004,
          longitude: 127.0004,
          timestampRelMs: 5000,
          paceSecPerKm: 290,
          source: RunPointSource.simulated,
        ),
        RunPoint(
          latitude: 37.0008,
          longitude: 127.0008,
          timestampRelMs: 10000,
          paceSecPerKm: 280,
          source: RunPointSource.simulated,
        ),
      ],
    );

    test('marks runner ahead when runner timestamp is later', () {
      const runnerPoint = RunPoint(
        latitude: 37.0007,
        longitude: 127.0007,
        timestampRelMs: 9000,
        paceSecPerKm: 280,
        source: RunPointSource.simulated,
      );

      final frame = service.project(
        runnerPoint: runnerPoint,
        ghostSession: session,
        elapsedMs: 6000,
      );

      expect(frame.relativeState, GhostRelativeState.ahead);
      expect(frame.gapMeters, greaterThan(0));
    });

    test('marks runner behind when runner timestamp is earlier', () {
      const runnerPoint = RunPoint(
        latitude: 37.0001,
        longitude: 127.0001,
        timestampRelMs: 2000,
        paceSecPerKm: 305,
        source: RunPointSource.simulated,
      );

      final frame = service.project(
        runnerPoint: runnerPoint,
        ghostSession: session,
        elapsedMs: 6000,
      );

      expect(frame.relativeState, GhostRelativeState.behind);
    });
  });
}
