import 'package:health/health.dart';

enum HealthConnectAvailability {
  available,
  providerUpdateRequired,
  unavailable,
}

abstract class HealthWorkoutPlatform {
  Future<void> configure();

  Future<HealthConnectAvailability> checkAvailability();

  Future<void> installHealthConnect();

  Future<bool> requestRunPermissions();

  Future<String> startWorkoutRoute();

  Future<bool> writeRunningWorkout({
    required DateTime startedAt,
    required DateTime endedAt,
    required int? totalDistanceMeters,
  });

  Future<String?> findWorkoutUuid({
    required DateTime startedAt,
    required DateTime endedAt,
  });

  Future<bool> insertWorkoutRouteData({
    required String builderId,
    required List<WorkoutRouteLocation> locations,
  });

  Future<void> finishWorkoutRoute({
    required String builderId,
    required String workoutUuid,
  });

  Future<void> discardWorkoutRoute(String builderId);

  Future<bool> deleteWorkoutByUuid({required String uuid});
}
