import 'package:flutter_test/flutter_test.dart';
import 'package:health/health.dart';
import 'package:runlini/core/health/health_plugin_workout_platform.dart';

void main() {
  test('android permission request includes workout lookup read types', () {
    expect(
      HealthPluginWorkoutPlatform.permissionTypesForPlatform(isAndroid: true),
      const <HealthDataType>[
        HealthDataType.WORKOUT,
        HealthDataType.WORKOUT_ROUTE,
        HealthDataType.DISTANCE_DELTA,
        HealthDataType.TOTAL_CALORIES_BURNED,
        HealthDataType.STEPS,
      ],
    );
    expect(
      HealthPluginWorkoutPlatform.permissionAccessesForPlatform(
        isAndroid: true,
      ),
      const <HealthDataAccess>[
        HealthDataAccess.READ_WRITE,
        HealthDataAccess.READ_WRITE,
        HealthDataAccess.READ,
        HealthDataAccess.READ,
        HealthDataAccess.READ,
      ],
    );
  });

  test('non-android permission request stays scoped to workout export', () {
    expect(
      HealthPluginWorkoutPlatform.permissionTypesForPlatform(isAndroid: false),
      const <HealthDataType>[
        HealthDataType.WORKOUT,
        HealthDataType.WORKOUT_ROUTE,
      ],
    );
    expect(
      HealthPluginWorkoutPlatform.permissionAccessesForPlatform(
        isAndroid: false,
      ),
      const <HealthDataAccess>[
        HealthDataAccess.READ_WRITE,
        HealthDataAccess.READ_WRITE,
      ],
    );
  });
}
