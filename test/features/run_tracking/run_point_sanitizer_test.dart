import 'package:flutter_test/flutter_test.dart';
import 'package:runlini/features/run_tracking/service/run_point_sanitizer.dart';
import 'package:runlini/features/run_tracking/types/run_point.dart';

void main() {
  group('RunPointSanitizer', () {
    const sanitizer = RunPointSanitizer();

    test('drops an implausible GPS spike', () {
      final filtered = sanitizer.filter(const [
        RunPoint(
          latitude: 37.0,
          longitude: 127.0,
          timestampRelMs: 0,
          paceSecPerKm: 300,
          source: RunPointSource.simulated,
        ),
        RunPoint(
          latitude: 37.0001,
          longitude: 127.0001,
          timestampRelMs: 5000,
          paceSecPerKm: 300,
          source: RunPointSource.simulated,
        ),
        RunPoint(
          latitude: 37.01,
          longitude: 127.01,
          timestampRelMs: 6000,
          paceSecPerKm: 120,
          source: RunPointSource.simulated,
        ),
      ]);

      expect(filtered, hasLength(2));
    });
  });
}
