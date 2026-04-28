import 'package:flutter_test/flutter_test.dart';
import 'package:health/health.dart';
import 'package:runlini/core/health/health_plugin_workout_platform.dart';

void main() {
  test('android permission request uses one combined run health scope', () {
    expect(
      HealthPluginWorkoutPlatform.permissionTypesForPlatform(isAndroid: true),
      const <HealthDataType>[
        HealthDataType.WORKOUT,
        HealthDataType.WORKOUT_ROUTE,
        HealthDataType.DISTANCE_DELTA,
        HealthDataType.TOTAL_CALORIES_BURNED,
        HealthDataType.STEPS,
        HealthDataType.HEART_RATE,
      ],
    );
    expect(
      HealthPluginWorkoutPlatform.permissionAccessesForPlatform(
        isAndroid: true,
      ),
      const <HealthDataAccess>[
        HealthDataAccess.READ_WRITE,
        HealthDataAccess.READ_WRITE,
        HealthDataAccess.READ_WRITE,
        HealthDataAccess.READ,
        HealthDataAccess.READ,
        HealthDataAccess.READ,
      ],
    );
  });

  test('non-android permission request uses the same run health scope', () {
    expect(
      HealthPluginWorkoutPlatform.permissionTypesForPlatform(isAndroid: false),
      const <HealthDataType>[
        HealthDataType.WORKOUT,
        HealthDataType.WORKOUT_ROUTE,
        HealthDataType.DISTANCE_DELTA,
        HealthDataType.TOTAL_CALORIES_BURNED,
        HealthDataType.STEPS,
        HealthDataType.HEART_RATE,
      ],
    );
    expect(
      HealthPluginWorkoutPlatform.permissionAccessesForPlatform(
        isAndroid: false,
      ),
      const <HealthDataAccess>[
        HealthDataAccess.READ_WRITE,
        HealthDataAccess.READ_WRITE,
        HealthDataAccess.READ_WRITE,
        HealthDataAccess.READ,
        HealthDataAccess.READ,
        HealthDataAccess.READ,
      ],
    );
  });
}
