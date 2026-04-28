import 'package:flutter_test/flutter_test.dart';
import 'package:health/health.dart';
import 'package:runlini/core/health/health_workout_deleter.dart';
import 'package:runlini/core/health/health_workout_platform.dart';

class _FakeHealthWorkoutPlatform implements HealthWorkoutPlatform {
  HealthConnectAvailability availability = HealthConnectAvailability.available;
  int configureCalls = 0;
  int deleteCalls = 0;
  String? deletedUuid;

  @override
  Future<HealthConnectAvailability> checkAvailability() async => availability;

  @override
  Future<void> configure() async {
    configureCalls += 1;
  }

  @override
  Future<bool> deleteWorkoutByUuid({required String uuid}) async {
    deleteCalls += 1;
    deletedUuid = uuid;
    return true;
  }

  @override
  Future<void> discardWorkoutRoute(String builderId) async {}

  @override
  Future<String?> findWorkoutUuid({
    required DateTime startedAt,
    required DateTime endedAt,
  }) async => null;

  @override
  Future<void> finishWorkoutRoute({
    required String builderId,
    required String workoutUuid,
  }) async {}

  @override
  Future<void> installHealthConnect() async {}

  @override
  Future<bool> insertWorkoutRouteData({
    required String builderId,
    required List<WorkoutRouteLocation> locations,
  }) async => false;

  @override
  Future<bool> requestRunPermissions() async => false;

  @override
  Future<String> startWorkoutRoute() async => 'builder';

  @override
  Future<bool> writeRunningWorkout({
    required DateTime startedAt,
    required DateTime endedAt,
    required int? totalDistanceMeters,
  }) async => false;
}

void main() {
  test('deletes a Health workout by external uuid', () async {
    final platform = _FakeHealthWorkoutPlatform();
    final deleter = PlatformHealthWorkoutDeleter(platform: platform);

    final deleted = await deleter.deleteWorkout(
      externalId: 'workout-uuid',
      startedAt: DateTime.utc(2026, 4, 20, 6),
      endedAt: DateTime.utc(2026, 4, 20, 7),
    );

    expect(deleted, isTrue);
    expect(platform.configureCalls, 1);
    expect(platform.deleteCalls, 1);
    expect(platform.deletedUuid, 'workout-uuid');
  });

  test('skips Health delete when no external uuid is available', () async {
    final platform = _FakeHealthWorkoutPlatform();
    final deleter = PlatformHealthWorkoutDeleter(platform: platform);

    final deleted = await deleter.deleteWorkout(
      externalId: null,
      startedAt: DateTime.utc(2026, 4, 20, 6),
      endedAt: DateTime.utc(2026, 4, 20, 7),
    );

    expect(deleted, isFalse);
    expect(platform.configureCalls, 0);
    expect(platform.deleteCalls, 0);
  });
}
