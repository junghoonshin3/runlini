import 'package:flutter_test/flutter_test.dart';
import 'package:runlini/features/run_tracking/service/run_session_detail_calculator.dart';
import 'package:runlini/features/run_tracking/types/run_point.dart';
import 'package:runlini/features/run_tracking/types/run_session.dart';

void main() {
  test('builds split, pace, speed, elevation, and heart-rate detail data', () {
    final session = RunSession(
      id: 'detail-session',
      startedAt: DateTime.utc(2026, 4, 21, 6),
      endedAt: DateTime.utc(2026, 4, 21, 6, 12),
      distanceM: 2000,
      durationMs: 720000,
      sourceSummary: 'test',
      points: const [
        RunPoint(
          latitude: 0,
          longitude: 0,
          timestampRelMs: 0,
          paceSecPerKm: 370,
          speedMps: 2.8,
          elevationM: 3,
          heartRateBpm: 140,
          source: RunPointSource.deviceGps,
        ),
        RunPoint(
          latitude: 0,
          longitude: 0.009,
          timestampRelMs: 360000,
          paceSecPerKm: 360,
          speedMps: 2.9,
          elevationM: 8,
          heartRateBpm: 150,
          source: RunPointSource.deviceGps,
        ),
        RunPoint(
          latitude: 0,
          longitude: 0.018,
          timestampRelMs: 720000,
          paceSecPerKm: 350,
          speedMps: 3.0,
          elevationM: 6,
          heartRateBpm: 160,
          source: RunPointSource.deviceGps,
        ),
      ],
    );

    final detail = const RunSessionDetailCalculator().calculate(session);

    expect(detail.averageSpeedKmh, closeTo(10, 0.1));
    expect(detail.averageHeartRateBpm, 150);
    expect(detail.elevationGainM, closeTo(5, 0.1));
    expect(detail.paceSamplesSecPerKm.map((sample) => sample.value), [
      370,
      360,
      350,
    ]);
    expect(detail.paceSamplesSecPerKm.map((sample) => sample.elapsedMs), [
      0,
      360000,
      720000,
    ]);
    expect(detail.speedSamplesKmh, hasLength(3));
    expect(detail.speedSamplesKmh.last.elapsedMs, 720000);
    expect(detail.elevationSamplesM, hasLength(3));
    expect(detail.elevationSamplesM.first.elapsedMs, 0);
    expect(detail.heartRateSamplesBpm, hasLength(3));
    expect(detail.heartRateSamplesBpm.last.value, 160);
    expect(detail.splits.length, greaterThanOrEqualTo(2));
    expect(detail.splits.first.paceSecPerKm, greaterThan(0));
  });

  test('uses custom split distance when provided', () {
    final session = RunSession(
      id: 'mile-split-session',
      startedAt: DateTime.utc(2026, 4, 21, 6),
      endedAt: DateTime.utc(2026, 4, 21, 6, 12),
      distanceM: 2000,
      durationMs: 720000,
      sourceSummary: 'test',
      points: const [
        RunPoint(
          latitude: 0,
          longitude: 0,
          timestampRelMs: 0,
          source: RunPointSource.deviceGps,
        ),
        RunPoint(
          latitude: 0,
          longitude: 0.018,
          timestampRelMs: 720000,
          source: RunPointSource.deviceGps,
        ),
      ],
    );

    final detail = const RunSessionDetailCalculator().calculate(
      session,
      splitDistanceM: 1609.344,
    );

    expect(detail.splits.first.distanceM, closeTo(1609.344, 0.1));
    expect(detail.splits.first.paceSecPerKm, greaterThan(0));
  });

  test('ignores impossible elevation sentinel values', () {
    final session = RunSession(
      id: 'bad-elevation-session',
      startedAt: DateTime.utc(2026, 4, 21, 6),
      endedAt: DateTime.utc(2026, 4, 21, 6, 1),
      distanceM: 100,
      durationMs: 60000,
      sourceSummary: 'test',
      points: const [
        RunPoint(
          latitude: 0,
          longitude: 0,
          timestampRelMs: 0,
          elevationM: double.maxFinite,
          source: RunPointSource.deviceGps,
        ),
        RunPoint(
          latitude: 0,
          longitude: 0.001,
          timestampRelMs: 60000,
          elevationM: -double.maxFinite,
          source: RunPointSource.deviceGps,
        ),
      ],
    );

    final detail = const RunSessionDetailCalculator().calculate(session);

    expect(detail.elevationGainM, isNull);
    expect(detail.elevationSamplesM, isEmpty);
  });
}
