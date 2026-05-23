// 저장된 러닝 경로 색상 segment가 명시적 경로 단절을 지키는지 검증한다.
import 'package:flutter_test/flutter_test.dart';
import 'package:runlini/features/run_tracking/service/pace_colored_route_segment_builder.dart';
import 'package:runlini/features/run_tracking/types/run_point.dart';
import 'package:runlini/features/run_tracking/types/run_session.dart';

void main() {
  test('does not merge saved route chunks across explicit segment starts', () {
    const builder = PaceColoredRouteSegmentBuilder();
    final session = RunSession(
      id: 'record-race-explicit-break',
      startedAt: DateTime.utc(2026, 4, 21, 6),
      distanceM: 222,
      durationMs: 80000,
      sourceSummary: 'fixture:test',
      points: const <RunPoint>[
        RunPoint(
          latitude: 0,
          longitude: 0,
          timestampRelMs: 0,
          source: RunPointSource.deviceGps,
        ),
        RunPoint(
          latitude: 0,
          longitude: 0.001,
          timestampRelMs: 20000,
          source: RunPointSource.deviceGps,
        ),
        RunPoint(
          latitude: 0,
          longitude: 0.02,
          timestampRelMs: 60000,
          source: RunPointSource.deviceGps,
          startsNewSegment: true,
        ),
        RunPoint(
          latitude: 0,
          longitude: 0.021,
          timestampRelMs: 80000,
          source: RunPointSource.deviceGps,
        ),
      ],
    );

    final segments = builder.buildRecordRaceSegments(session);

    expect(segments, hasLength(2));
    for (final segment in segments) {
      final longitudes = segment.points.map((point) => point.longitude);
      expect(
        longitudes.any((longitude) => longitude < 0.005) &&
            longitudes.any((longitude) => longitude > 0.015),
        isFalse,
      );
    }
  });
}
