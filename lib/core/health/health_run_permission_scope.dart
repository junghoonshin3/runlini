import 'package:health/health.dart';

class HealthRunPermissionScope {
  const HealthRunPermissionScope._();

  static const _runTypes = <HealthDataType>[
    HealthDataType.WORKOUT,
    HealthDataType.WORKOUT_ROUTE,
    HealthDataType.DISTANCE_DELTA,
    HealthDataType.TOTAL_CALORIES_BURNED,
    HealthDataType.STEPS,
    HealthDataType.HEART_RATE,
  ];

  static const _runAccesses = <HealthDataAccess>[
    HealthDataAccess.READ_WRITE,
    HealthDataAccess.READ_WRITE,
    HealthDataAccess.READ_WRITE,
    HealthDataAccess.READ,
    HealthDataAccess.READ,
    HealthDataAccess.READ,
  ];

  static List<HealthDataType> permissionTypesForPlatform({
    required bool isAndroid,
  }) {
    return List<HealthDataType>.unmodifiable(_runTypes);
  }

  static List<HealthDataAccess> permissionAccessesForPlatform({
    required bool isAndroid,
  }) {
    return List<HealthDataAccess>.unmodifiable(_runAccesses);
  }
}
