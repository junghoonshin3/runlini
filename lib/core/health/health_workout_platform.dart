import 'package:health/health.dart';

abstract class HealthWorkoutPlatform {
  Future<void> configure();

  Future<bool> isAvailable();

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
}
