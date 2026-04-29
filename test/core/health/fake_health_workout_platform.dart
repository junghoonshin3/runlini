import 'package:health/health.dart';
import 'package:runlini/core/health/health_workout_platform.dart';

class FakeHealthWorkoutPlatform implements HealthWorkoutPlatform {
  HealthConnectAvailability availability = HealthConnectAvailability.available;
  bool permissionsGranted = true;
  bool writeWorkoutSucceeded = true;
  bool insertRouteSucceeded = true;
  bool throwStartRoute = false;
  bool throwInsertRoute = false;
  bool throwFinishRoute = false;
  String startedBuilderId = 'builder-1';
  String? workoutUuid = 'workout-1';

  int configureCalls = 0;
  int permissionCalls = 0;
  int startRouteCalls = 0;
  int writeWorkoutCalls = 0;
  int finishRouteCalls = 0;
  int discardRouteCalls = 0;
  int installCalls = 0;
  int deleteWorkoutCalls = 0;
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
  Future<bool> deleteWorkoutByUuid({required String uuid}) async {
    deleteWorkoutCalls += 1;
    return true;
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
    if (throwFinishRoute) {
      throw StateError('finish route failed');
    }
  }

  @override
  Future<bool> insertWorkoutRouteData({
    required String builderId,
    required List<WorkoutRouteLocation> locations,
  }) async {
    lastInsertedLocations = locations;
    if (throwInsertRoute) {
      throw StateError('insert route failed');
    }
    return insertRouteSucceeded;
  }

  @override
  Future<HealthConnectAvailability> checkAvailability() async => availability;

  @override
  Future<void> installHealthConnect() async {
    installCalls += 1;
  }

  @override
  Future<bool> requestRunPermissions() async {
    permissionCalls += 1;
    return permissionsGranted;
  }

  @override
  Future<String> startWorkoutRoute() async {
    startRouteCalls += 1;
    if (throwStartRoute) {
      throw StateError('route unavailable');
    }
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
