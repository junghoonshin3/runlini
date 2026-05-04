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

    test('drops points with poor horizontal accuracy', () {
      final filtered = sanitizer.filter(const [
        RunPoint(
          latitude: 37.0,
          longitude: 127.0,
          timestampRelMs: 0,
          horizontalAccuracyM: 8,
          source: RunPointSource.simulated,
        ),
        RunPoint(
          latitude: 37.0002,
          longitude: 127.0,
          timestampRelMs: 10 * 1000,
          horizontalAccuracyM: 50,
          source: RunPointSource.simulated,
        ),
      ]);

      expect(filtered, hasLength(1));
    });

    test('drops stationary GPS drift inside the accuracy radius', () {
      final filtered = sanitizer.filter(const [
        RunPoint(
          latitude: 37.0,
          longitude: 127.0,
          timestampRelMs: 0,
          speedMps: 0,
          horizontalAccuracyM: 8,
          source: RunPointSource.simulated,
        ),
        RunPoint(
          latitude: 37.00009,
          longitude: 127.0,
          timestampRelMs: 10 * 1000,
          speedMps: 0,
          horizontalAccuracyM: 8,
          source: RunPointSource.simulated,
        ),
      ]);

      expect(filtered, hasLength(1));
    });

    test(
      'drops a long stationary drift cluster outside single-point radius',
      () {
        final points = <RunPoint>[
          const RunPoint(
            latitude: 37.0,
            longitude: 127.0,
            timestampRelMs: 0,
            speedMps: 0,
            horizontalAccuracyM: 8,
            source: RunPointSource.simulated,
          ),
          for (var index = 1; index <= 6; index += 1)
            RunPoint(
              latitude: 37.0 + (0.00002 * index),
              longitude: 127.0,
              timestampRelMs: index * 5000,
              speedMps: 0,
              horizontalAccuracyM: 8,
              source: RunPointSource.simulated,
            ),
        ];

        final filtered = sanitizer.filter(points);

        expect(filtered, hasLength(1));
      },
    );

    test('accepts stable movement after stationary drift', () {
      final filtered = sanitizer.filter(const [
        RunPoint(
          latitude: 37.0,
          longitude: 127.0,
          timestampRelMs: 0,
          speedMps: 0,
          horizontalAccuracyM: 8,
          source: RunPointSource.simulated,
        ),
        RunPoint(
          latitude: 37.00004,
          longitude: 127.0,
          timestampRelMs: 5000,
          speedMps: 0,
          horizontalAccuracyM: 8,
          source: RunPointSource.simulated,
        ),
        RunPoint(
          latitude: 37.00008,
          longitude: 127.0,
          timestampRelMs: 10000,
          speedMps: 0,
          horizontalAccuracyM: 8,
          source: RunPointSource.simulated,
        ),
        RunPoint(
          latitude: 37.00025,
          longitude: 127.0,
          timestampRelMs: 15000,
          speedMps: 1.4,
          horizontalAccuracyM: 6,
          source: RunPointSource.simulated,
        ),
        RunPoint(
          latitude: 37.00045,
          longitude: 127.0,
          timestampRelMs: 20000,
          speedMps: 1.4,
          horizontalAccuracyM: 6,
          source: RunPointSource.simulated,
        ),
      ]);

      expect(filtered, hasLength(2));
      expect(filtered.last.latitude, 37.00045);
    });

    test('accepts movement once it escapes the stationary noise radius', () {
      final filtered = sanitizer.filter(const [
        RunPoint(
          latitude: 37.0,
          longitude: 127.0,
          timestampRelMs: 0,
          speedMps: 0,
          horizontalAccuracyM: 8,
          source: RunPointSource.simulated,
        ),
        RunPoint(
          latitude: 37.00009,
          longitude: 127.0,
          timestampRelMs: 10 * 1000,
          speedMps: 0,
          horizontalAccuracyM: 8,
          source: RunPointSource.simulated,
        ),
        RunPoint(
          latitude: 37.0002,
          longitude: 127.0,
          timestampRelMs: 20 * 1000,
          speedMps: 0,
          horizontalAccuracyM: 8,
          source: RunPointSource.simulated,
        ),
        RunPoint(
          latitude: 37.00028,
          longitude: 127.0,
          timestampRelMs: 25 * 1000,
          speedMps: 0,
          horizontalAccuracyM: 8,
          source: RunPointSource.simulated,
        ),
      ]);

      expect(filtered, hasLength(2));
      expect(filtered.last.latitude, 37.00028);
    });

    test('loads legacy point json without accuracy fields', () {
      final point = RunPoint.fromJson(const <String, dynamic>{
        'lat': 37.0,
        'lng': 127.0,
        'timestampRelMs': 0,
        'source': 'simulated',
      });

      expect(point.horizontalAccuracyM, isNull);
      expect(point.speedAccuracyMps, isNull);
    });
  });
}
