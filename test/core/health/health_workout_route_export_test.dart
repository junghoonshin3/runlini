import 'package:flutter_test/flutter_test.dart';
import 'package:runlini/core/health/health_workout_recorder.dart';
import 'package:runlini/features/run_tracking/types/run_point.dart';

import 'fake_health_workout_platform.dart';

void main() {
  test('finish run writes workout when route builder start fails', () async {
    final platform = FakeHealthWorkoutPlatform()..throwStartRoute = true;
    final recorder = PlatformHealthWorkoutRecorder(platform: platform);
    final startedAt = DateTime(2026, 4, 20, 6, 0, 0);

    await recorder.beginRunCapture();
    final result = await recorder.finishRunCapture(
      startedAt: startedAt,
      endedAt: startedAt.add(const Duration(minutes: 10)),
      recordedPoints: _simpleRoute,
    );

    expect(result.kind, HealthWorkoutExportResultKind.synced);
    expect(result.externalId, 'workout-1');
    expect(platform.startRouteCalls, 1);
    expect(platform.writeWorkoutCalls, 1);
    expect(platform.finishRouteCalls, 0);
    expect(platform.discardRouteCalls, 0);
  });

  test('finish run treats route insert failure as workout-only sync', () async {
    final platform = FakeHealthWorkoutPlatform()..throwInsertRoute = true;
    final recorder = PlatformHealthWorkoutRecorder(platform: platform);
    final startedAt = DateTime(2026, 4, 20, 6, 0, 0);

    await recorder.beginRunCapture();
    final result = await recorder.finishRunCapture(
      startedAt: startedAt,
      endedAt: startedAt.add(const Duration(minutes: 10)),
      recordedPoints: _simpleRoute,
    );

    expect(result.kind, HealthWorkoutExportResultKind.synced);
    expect(result.externalId, 'workout-1');
    expect(platform.writeWorkoutCalls, 1);
    expect(platform.finishRouteCalls, 0);
    expect(platform.discardRouteCalls, 1);
  });

  test('finish run treats route finish failure as workout-only sync', () async {
    final platform = FakeHealthWorkoutPlatform()..throwFinishRoute = true;
    final recorder = PlatformHealthWorkoutRecorder(platform: platform);
    final startedAt = DateTime(2026, 4, 20, 6, 0, 0);

    await recorder.beginRunCapture();
    final result = await recorder.finishRunCapture(
      startedAt: startedAt,
      endedAt: startedAt.add(const Duration(minutes: 10)),
      recordedPoints: _simpleRoute,
    );

    expect(result.kind, HealthWorkoutExportResultKind.synced);
    expect(result.externalId, 'workout-1');
    expect(platform.writeWorkoutCalls, 1);
    expect(platform.finishRouteCalls, 1);
    expect(platform.discardRouteCalls, 1);
  });

  test('finish run sanitizes invalid route values before export', () async {
    final platform = FakeHealthWorkoutPlatform();
    final recorder = PlatformHealthWorkoutRecorder(platform: platform);
    final startedAt = DateTime(2026, 4, 20, 6, 0, 0);

    await recorder.beginRunCapture();
    final result = await recorder.finishRunCapture(
      startedAt: startedAt,
      endedAt: startedAt.add(const Duration(minutes: 10)),
      recordedPoints: const <RunPoint>[
        RunPoint(
          latitude: 37.0,
          longitude: 127.0,
          timestampRelMs: 0,
          speedMps: double.infinity,
          horizontalAccuracyM: double.nan,
          speedAccuracyMps: -1,
          elevationM: double.maxFinite,
          source: RunPointSource.deviceGps,
        ),
        RunPoint(
          latitude: 91,
          longitude: 127.0,
          timestampRelMs: 1000,
          source: RunPointSource.deviceGps,
        ),
        RunPoint(
          latitude: 37.0004,
          longitude: 127.0004,
          timestampRelMs: 5000,
          speedMps: 3.2,
          horizontalAccuracyM: 5,
          speedAccuracyMps: 0.8,
          elevationM: 42,
          source: RunPointSource.deviceGps,
        ),
        RunPoint(
          latitude: 37.0005,
          longitude: 127.0005,
          timestampRelMs: 700000,
          source: RunPointSource.deviceGps,
        ),
      ],
    );

    expect(result.kind, HealthWorkoutExportResultKind.synced);
    expect(platform.lastInsertedLocations, hasLength(2));
    expect(platform.lastInsertedLocations.first.altitude, isNull);
    expect(platform.lastInsertedLocations.first.speed, isNull);
    expect(platform.lastInsertedLocations.first.horizontalAccuracy, isNull);
    expect(platform.lastInsertedLocations.first.speedAccuracy, isNull);
    expect(platform.lastInsertedLocations.last.altitude, 42);
    expect(platform.lastInsertedLocations.last.speed, 3.2);
    expect(platform.lastInsertedLocations.last.horizontalAccuracy, 5);
    expect(platform.lastInsertedLocations.last.speedAccuracy, 0.8);
  });
}

const _simpleRoute = <RunPoint>[
  RunPoint(
    latitude: 37.0,
    longitude: 127.0,
    timestampRelMs: 0,
    source: RunPointSource.deviceGps,
  ),
  RunPoint(
    latitude: 37.0005,
    longitude: 127.0005,
    timestampRelMs: 5000,
    source: RunPointSource.deviceGps,
  ),
];
