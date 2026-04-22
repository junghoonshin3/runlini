import 'package:flutter_test/flutter_test.dart';
import 'package:runlini/features/health_sync/service/route_merge_policy.dart';
import 'package:runlini/features/run_tracking/types/run_point.dart';

void main() {
  group('RouteMergePolicy', () {
    const policy = RouteMergePolicy();

    test('prefers secondary samples for matching timestamps', () {
      final merged = policy.merge(
        primaryPoints: const [
          RunPoint(
            latitude: 37.0,
            longitude: 127.0,
            timestampRelMs: 0,
            paceSecPerKm: 300,
            source: RunPointSource.deviceGps,
          ),
          RunPoint(
            latitude: 37.0001,
            longitude: 127.0001,
            timestampRelMs: 5000,
            paceSecPerKm: 295,
            source: RunPointSource.deviceGps,
          ),
        ],
        secondaryPoints: const [
          RunPoint(
            latitude: 37.0002,
            longitude: 127.0002,
            timestampRelMs: 5000,
            paceSecPerKm: 290,
            source: RunPointSource.healthConnect,
          ),
        ],
      );

      expect(merged, hasLength(2));
      expect(merged.last.source, RunPointSource.healthConnect);
      expect(merged.last.paceSecPerKm, 290);
    });
  });
}
