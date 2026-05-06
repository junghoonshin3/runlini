import 'package:flutter_test/flutter_test.dart';
import 'package:runlini/app/theme/app_colors.dart';
import 'package:runlini/features/run_tracking/service/route_speed_insight_builder.dart';
import 'package:runlini/features/run_tracking/service/run_route_segmenter.dart';
import 'package:runlini/features/run_tracking/types/run_point.dart';

void main() {
  test('groups route speed insights into fast average and slow buckets', () {
    final insights = const RouteSpeedInsightBuilder().build(
      const <List<RunPoint>>[
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
      ],
    );

    expect(insights.map((insight) => insight.bucket), <RouteSpeedInsightBucket>[
      RouteSpeedInsightBucket.fast,
      RouteSpeedInsightBucket.average,
      RouteSpeedInsightBucket.slow,
    ]);
    expect(RouteSpeedInsightBucket.fast.color, AppColors.voltGreen);
    expect(RouteSpeedInsightBucket.average.color, AppColors.amber);
    expect(RouteSpeedInsightBucket.slow.color, AppColors.electricRed);
  });

  test('does not include long GPS break bridge in speed insight distance', () {
    const points = <RunPoint>[
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
      ),
      RunPoint(
        latitude: 0,
        longitude: 0.021,
        timestampRelMs: 80000,
        source: RunPointSource.deviceGps,
      ),
    ];
    final route = const RunRouteSegmenter().segment(points);

    final insights = const RouteSpeedInsightBuilder().build(route.segments);
    final distanceM = insights.fold<double>(
      0,
      (total, insight) => total + insight.distanceM,
    );

    expect(distanceM, lessThan(300));
  });

  test('returns empty insight when route timing cannot produce speed', () {
    final insights = const RouteSpeedInsightBuilder().build(
      const <List<RunPoint>>[
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
            timestampRelMs: 0,
            source: RunPointSource.simulated,
          ),
        ],
      ],
    );

    expect(insights, isEmpty);
  });
}
