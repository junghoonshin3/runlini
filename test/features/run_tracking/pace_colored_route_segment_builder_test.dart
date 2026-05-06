import 'package:flutter_test/flutter_test.dart';
import 'package:runlini/app/theme/app_colors.dart';
import 'package:runlini/features/run_tracking/service/pace_colored_route_segment_builder.dart';
import 'package:runlini/features/run_tracking/types/run_point.dart';
import 'package:runlini/features/run_tracking/types/run_session.dart';

void main() {
  test('resamples sparse route points into interpolated gradient chunks', () {
    const builder = PaceColoredRouteSegmentBuilder();
    final session = RunSession(
      id: 'ghost-sparse',
      startedAt: DateTime.utc(2026, 4, 21, 6),
      distanceM: 222,
      durationMs: 80000,
      sourceSummary: 'fixture:test',
      points: const <RunPoint>[
        RunPoint(
          latitude: 0,
          longitude: 0,
          timestampRelMs: 0,
          source: RunPointSource.simulated,
        ),
        RunPoint(
          latitude: 0,
          longitude: 0.002,
          timestampRelMs: 80000,
          source: RunPointSource.simulated,
        ),
      ],
    );

    final segments = builder.buildGhostSegments(session);

    expect(segments, hasLength(1));
    expect(segments.single.color, AppColors.amber);
    expect(segments.single.points.length, greaterThan(5));
    expect(segments.single.points.first.longitude, 0);
    expect(segments.single.points[1].longitude, greaterThan(0));
    expect(segments.single.points.last.longitude, closeTo(0.002, 0.00001));
  });

  test(
    'creates fine-grained colors for fast, steady, and slow route sections',
    () {
      const builder = PaceColoredRouteSegmentBuilder();
      final session = RunSession(
        id: 'ghost-gradient',
        startedAt: DateTime.utc(2026, 4, 21, 6),
        distanceM: 333,
        durationMs: 130000,
        sourceSummary: 'fixture:test',
        points: const <RunPoint>[
          RunPoint(
            latitude: 0,
            longitude: 0,
            timestampRelMs: 0,
            source: RunPointSource.simulated,
          ),
          RunPoint(
            latitude: 0,
            longitude: 0.001,
            timestampRelMs: 20000,
            source: RunPointSource.simulated,
          ),
          RunPoint(
            latitude: 0,
            longitude: 0.002,
            timestampRelMs: 60000,
            source: RunPointSource.simulated,
          ),
          RunPoint(
            latitude: 0,
            longitude: 0.003,
            timestampRelMs: 130000,
            source: RunPointSource.simulated,
          ),
        ],
      );

      final segments = builder.buildGhostSegments(session);
      final colors = segments.map((segment) => segment.color).toSet();

      expect(segments.length, greaterThan(3));
      expect(colors.length, greaterThan(3));
      expect(segments.first.color, AppColors.voltGreen);
      expect(segments.last.color, AppColors.electricRed);
    },
  );

  test('builds colored detail route sections from verified route segments', () {
    const builder = PaceColoredRouteSegmentBuilder();
    const routeSegments = <List<RunPoint>>[
      <RunPoint>[
        RunPoint(
          latitude: 0,
          longitude: 0,
          timestampRelMs: 0,
          source: RunPointSource.simulated,
        ),
        RunPoint(
          latitude: 0,
          longitude: 0.001,
          timestampRelMs: 20000,
          source: RunPointSource.simulated,
        ),
        RunPoint(
          latitude: 0,
          longitude: 0.002,
          timestampRelMs: 60000,
          source: RunPointSource.simulated,
        ),
        RunPoint(
          latitude: 0,
          longitude: 0.003,
          timestampRelMs: 130000,
          source: RunPointSource.simulated,
        ),
      ],
    ];

    final segments = builder.buildRouteSegments(routeSegments);
    final colors = segments.map((segment) => segment.color).toSet();

    expect(segments.length, greaterThan(3));
    expect(colors.length, greaterThan(3));
    expect(segments.first.color, AppColors.voltGreen);
    expect(segments.last.color, AppColors.electricRed);
  });

  test('does not merge same-color chunks across route breaks', () {
    const builder = PaceColoredRouteSegmentBuilder();
    const routeSegments = <List<RunPoint>>[
      <RunPoint>[
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
      ],
      <RunPoint>[
        RunPoint(
          latitude: 0,
          longitude: 0.02,
          timestampRelMs: 60000,
          source: RunPointSource.deviceGps,
        ),
        RunPoint(
          latitude: 0,
          longitude: 0.021,
          timestampRelMs: 80000,
          source: RunPointSource.deviceGps,
        ),
      ],
    ];

    final segments = builder.buildRouteSegments(routeSegments);

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

  test('merges adjacent chunks that quantize to the same gradient color', () {
    const builder = PaceColoredRouteSegmentBuilder();
    final session = RunSession(
      id: 'ghost-merged-gradient',
      startedAt: DateTime.utc(2026, 4, 21, 6),
      distanceM: 222,
      durationMs: 80000,
      sourceSummary: 'fixture:test',
      points: const <RunPoint>[
        RunPoint(
          latitude: 0,
          longitude: 0,
          timestampRelMs: 0,
          source: RunPointSource.simulated,
        ),
        RunPoint(
          latitude: 0,
          longitude: 0.002,
          timestampRelMs: 80000,
          source: RunPointSource.simulated,
        ),
      ],
    );

    final segments = builder.buildGhostSegments(session);

    expect(segments, hasLength(1));
    expect(segments.single.points.length, greaterThan(5));
  });

  test('uses chalk fallback when route timing cannot produce valid pace', () {
    const builder = PaceColoredRouteSegmentBuilder();
    final session = RunSession(
      id: 'ghost-invalid-time',
      startedAt: DateTime.utc(2026, 4, 21, 6),
      distanceM: 0,
      durationMs: 0,
      sourceSummary: 'fixture:test',
      points: const <RunPoint>[
        RunPoint(
          latitude: 0,
          longitude: 0,
          timestampRelMs: 0,
          source: RunPointSource.simulated,
        ),
        RunPoint(
          latitude: 0,
          longitude: 0.002,
          timestampRelMs: 0,
          source: RunPointSource.simulated,
        ),
      ],
    );

    final segments = builder.buildGhostSegments(session);

    expect(segments, hasLength(1));
    expect(segments.single.color, AppColors.chalk);
  });

  test('returns no segments for routes without enough geometry', () {
    const builder = PaceColoredRouteSegmentBuilder();
    final session = RunSession(
      id: 'ghost-empty',
      startedAt: DateTime.utc(2026, 4, 21, 6),
      distanceM: 0,
      durationMs: 0,
      sourceSummary: 'fixture:test',
      points: const <RunPoint>[
        RunPoint(
          latitude: 0,
          longitude: 0,
          timestampRelMs: 0,
          source: RunPointSource.simulated,
        ),
      ],
    );

    expect(builder.buildGhostSegments(session), isEmpty);
  });
}
