import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:runlini/core/health/health_plugin_workout_platform.dart';
import 'package:runlini/core/health/health_workout_platform.dart';

abstract class HealthWorkoutDeleter {
  Future<bool> deleteWorkout({
    required String? externalId,
    required DateTime startedAt,
    required DateTime endedAt,
  });
}

class PlatformHealthWorkoutDeleter implements HealthWorkoutDeleter {
  const PlatformHealthWorkoutDeleter({required HealthWorkoutPlatform platform})
    : _platform = platform;

  final HealthWorkoutPlatform _platform;

  @override
  Future<bool> deleteWorkout({
    required String? externalId,
    required DateTime startedAt,
    required DateTime endedAt,
  }) async {
    if (externalId == null || externalId.isEmpty) {
      return false;
    }
    try {
      final availability = await _platform.checkAvailability();
      if (availability != HealthConnectAvailability.available) {
        return false;
      }
      await _platform.configure();
      return _platform.deleteWorkoutByUuid(uuid: externalId);
    } catch (error) {
      debugPrint('Runlini Health workout delete skipped: $error');
      return false;
    }
  }
}

final healthWorkoutDeleterProvider = Provider<HealthWorkoutDeleter>((Ref ref) {
  return PlatformHealthWorkoutDeleter(platform: HealthPluginWorkoutPlatform());
});
