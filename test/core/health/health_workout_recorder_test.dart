import 'package:flutter_test/flutter_test.dart';
import 'package:runlini/core/health/health_workout_recorder.dart';
import 'package:runlini/features/run_tracking/types/run_point.dart';

import 'fake_health_workout_platform.dart';

void main() {
  test(
    'prepare run capture requests permissions without starting a route',
    () async {
      final platform = FakeHealthWorkoutPlatform();
      final recorder = PlatformHealthWorkoutRecorder(platform: platform);

      await recorder.prepareRunCapture();

      expect(platform.configureCalls, 1);
      expect(platform.permissionCalls, 1);
      expect(platform.startRouteCalls, 0);
    },
  );

  test(
    'begin run capture consumes prepared permissions without requesting again',
    () async {
      final platform = FakeHealthWorkoutPlatform();
      final recorder = PlatformHealthWorkoutRecorder(platform: platform);

      await recorder.prepareRunCapture();
      await recorder.beginRunCapture();

      expect(platform.configureCalls, 1);
      expect(platform.permissionCalls, 1);
      expect(platform.startRouteCalls, 1);
    },
  );

  test(
    'begin run capture does not start a route after prepared permission denial',
    () async {
      final platform = FakeHealthWorkoutPlatform()..permissionsGranted = false;
      final recorder = PlatformHealthWorkoutRecorder(platform: platform);

      await recorder.prepareRunCapture();
      await recorder.beginRunCapture();

      expect(platform.configureCalls, 1);
      expect(platform.permissionCalls, 1);
      expect(platform.startRouteCalls, 0);
    },
  );

  test(
    'prepare run capture reports Health Connect install requirement',
    () async {
      final platform = FakeHealthWorkoutPlatform()
        ..availability = HealthConnectAvailability.providerUpdateRequired;
      final recorder = PlatformHealthWorkoutRecorder(platform: platform);

      final result = await recorder.prepareRunCapture();

      expect(result, HealthRunPreparationResult.installRequired);
      expect(platform.configureCalls, 0);
      expect(platform.permissionCalls, 0);
      await recorder.openHealthConnectInstall();
      expect(platform.installCalls, 1);
    },
  );

  test('finish run writes workout and route from recorded points', () async {
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
          source: RunPointSource.deviceGps,
        ),
        RunPoint(
          latitude: 37.0005,
          longitude: 127.0005,
          timestampRelMs: 5000,
          source: RunPointSource.deviceGps,
        ),
      ],
    );

    expect(result.kind, HealthWorkoutExportResultKind.synced);
    expect(result.externalId, 'workout-1');
    expect(platform.configureCalls, 1);
    expect(platform.permissionCalls, 1);
    expect(platform.startRouteCalls, 1);
    expect(platform.writeWorkoutCalls, 1);
    expect(platform.lastTotalDistanceMeters, greaterThan(0));
    expect(platform.lastInsertedLocations, hasLength(2));
    expect(platform.lastInsertedLocations.first.timestamp, startedAt);
    expect(
      platform.lastInsertedLocations.last.timestamp,
      startedAt.add(const Duration(seconds: 5)),
    );
    expect(platform.finishRouteCalls, 1);
    expect(platform.discardRouteCalls, 0);
  });

  test('finish run reports skipped when no route capture started', () async {
    final platform = FakeHealthWorkoutPlatform();
    final recorder = PlatformHealthWorkoutRecorder(platform: platform);
    final startedAt = DateTime(2026, 4, 20, 6, 0, 0);

    final result = await recorder.finishRunCapture(
      startedAt: startedAt,
      endedAt: startedAt.add(const Duration(minutes: 10)),
      recordedPoints: const <RunPoint>[],
    );

    expect(result.kind, HealthWorkoutExportResultKind.skipped);
    expect(platform.writeWorkoutCalls, 0);
  });

  test('finish run skips invalid workout time without writing', () async {
    final platform = FakeHealthWorkoutPlatform();
    final recorder = PlatformHealthWorkoutRecorder(platform: platform);
    final startedAt = DateTime(2026, 4, 20, 6, 0, 0);

    await recorder.beginRunCapture();
    final result = await recorder.finishRunCapture(
      startedAt: startedAt,
      endedAt: startedAt,
      recordedPoints: const <RunPoint>[],
    );

    expect(result.kind, HealthWorkoutExportResultKind.skipped);
    expect(platform.writeWorkoutCalls, 0);
    expect(platform.discardRouteCalls, 1);
  });

  test('cancel run discards an active route builder', () async {
    final platform = FakeHealthWorkoutPlatform();
    final recorder = PlatformHealthWorkoutRecorder(platform: platform);

    await recorder.beginRunCapture();
    await recorder.cancelRunCapture();

    expect(platform.startRouteCalls, 1);
    expect(platform.discardRouteCalls, 1);
  });
}
