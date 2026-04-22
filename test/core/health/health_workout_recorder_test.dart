import 'package:flutter_test/flutter_test.dart';
import 'package:health/health.dart';
import 'package:runlini/core/health/health_workout_recorder.dart';
import 'package:runlini/features/run_tracking/types/run_point.dart';

class _FakeHealthWorkoutPlatform implements HealthWorkoutPlatform {
  bool available = true;
  bool permissionsGranted = true;
  bool writeWorkoutSucceeded = true;
  bool insertRouteSucceeded = true;
  String startedBuilderId = 'builder-1';
  String? workoutUuid = 'workout-1';

  int configureCalls = 0;
  int permissionCalls = 0;
  int startRouteCalls = 0;
  int writeWorkoutCalls = 0;
  int finishRouteCalls = 0;
  int discardRouteCalls = 0;
  int? lastTotalDistanceMeters;
  List<WorkoutRouteLocation> lastInsertedLocations = <WorkoutRouteLocation>[];

  @override
  Future<void> configure() async {
    configureCalls += 1;
  }

  @override
  Future<void> discardWorkoutRoute(String builderId) async {
    discardRouteCalls += 1;
  }

  @override
  Future<String?> findWorkoutUuid({
    required DateTime startedAt,
    required DateTime endedAt,
  }) async {
    return workoutUuid;
  }

  @override
  Future<void> finishWorkoutRoute({
    required String builderId,
    required String workoutUuid,
  }) async {
    finishRouteCalls += 1;
  }

  @override
  Future<bool> insertWorkoutRouteData({
    required String builderId,
    required List<WorkoutRouteLocation> locations,
  }) async {
    lastInsertedLocations = locations;
    return insertRouteSucceeded;
  }

  @override
  Future<bool> isAvailable() async => available;

  @override
  Future<bool> requestRunPermissions() async {
    permissionCalls += 1;
    return permissionsGranted;
  }

  @override
  Future<String> startWorkoutRoute() async {
    startRouteCalls += 1;
    return startedBuilderId;
  }

  @override
  Future<bool> writeRunningWorkout({
    required DateTime startedAt,
    required DateTime endedAt,
    required int? totalDistanceMeters,
  }) async {
    writeWorkoutCalls += 1;
    lastTotalDistanceMeters = totalDistanceMeters;
    return writeWorkoutSucceeded;
  }
}

void main() {
  test(
    'prepare run capture requests permissions without starting a route',
    () async {
      final platform = _FakeHealthWorkoutPlatform();
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
      final platform = _FakeHealthWorkoutPlatform();
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
      final platform = _FakeHealthWorkoutPlatform()..permissionsGranted = false;
      final recorder = PlatformHealthWorkoutRecorder(platform: platform);

      await recorder.prepareRunCapture();
      await recorder.beginRunCapture();

      expect(platform.configureCalls, 1);
      expect(platform.permissionCalls, 1);
      expect(platform.startRouteCalls, 0);
    },
  );

  test('finish run writes workout and route from recorded points', () async {
    final platform = _FakeHealthWorkoutPlatform();
    final recorder = PlatformHealthWorkoutRecorder(platform: platform);
    final startedAt = DateTime(2026, 4, 20, 6, 0, 0);

    await recorder.beginRunCapture();
    await recorder.finishRunCapture(
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

  test('cancel run discards an active route builder', () async {
    final platform = _FakeHealthWorkoutPlatform();
    final recorder = PlatformHealthWorkoutRecorder(platform: platform);

    await recorder.beginRunCapture();
    await recorder.cancelRunCapture();

    expect(platform.startRouteCalls, 1);
    expect(platform.discardRouteCalls, 1);
  });
}
