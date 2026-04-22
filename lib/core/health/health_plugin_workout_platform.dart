import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:health/health.dart';
import 'package:runlini/core/health/health_workout_platform.dart';

class HealthPluginWorkoutPlatform implements HealthWorkoutPlatform {
  static const _workoutTypes = <HealthDataType>[
    HealthDataType.WORKOUT,
    HealthDataType.WORKOUT_ROUTE,
  ];
  static const _workoutPermissions = <HealthDataAccess>[
    HealthDataAccess.READ_WRITE,
    HealthDataAccess.READ_WRITE,
  ];
  static const _androidWorkoutLookupTypes = <HealthDataType>[
    HealthDataType.DISTANCE_DELTA,
    HealthDataType.TOTAL_CALORIES_BURNED,
    HealthDataType.STEPS,
  ];
  static const _androidWorkoutLookupPermissions = <HealthDataAccess>[
    HealthDataAccess.READ,
    HealthDataAccess.READ,
    HealthDataAccess.READ,
  ];

  HealthPluginWorkoutPlatform({Health? health}) : _health = health ?? Health();

  final Health _health;
  bool _configured = false;

  @override
  Future<void> configure() async {
    if (_configured) {
      return;
    }
    await _health.configure();
    _configured = true;
  }

  @override
  Future<bool> isAvailable() async {
    if (!Platform.isAndroid && !Platform.isIOS) {
      return false;
    }
    if (!Platform.isAndroid) {
      return true;
    }

    return await _health.getHealthConnectSdkStatus() ==
        HealthConnectSdkStatus.sdkAvailable;
  }

  @override
  Future<bool> requestRunPermissions() {
    final isAndroid = Platform.isAndroid;
    return _health.requestAuthorization(
      permissionTypesForPlatform(isAndroid: isAndroid),
      permissions: permissionAccessesForPlatform(isAndroid: isAndroid),
    );
  }

  @visibleForTesting
  static List<HealthDataType> permissionTypesForPlatform({
    required bool isAndroid,
  }) {
    return List<HealthDataType>.unmodifiable(
      isAndroid
          ? <HealthDataType>[..._workoutTypes, ..._androidWorkoutLookupTypes]
          : _workoutTypes,
    );
  }

  @visibleForTesting
  static List<HealthDataAccess> permissionAccessesForPlatform({
    required bool isAndroid,
  }) {
    return List<HealthDataAccess>.unmodifiable(
      isAndroid
          ? <HealthDataAccess>[
              ..._workoutPermissions,
              ..._androidWorkoutLookupPermissions,
            ]
          : _workoutPermissions,
    );
  }

  @override
  Future<String> startWorkoutRoute() {
    return _health.startWorkoutRoute();
  }

  @override
  Future<bool> writeRunningWorkout({
    required DateTime startedAt,
    required DateTime endedAt,
    required int? totalDistanceMeters,
  }) {
    return _health.writeWorkoutData(
      activityType: HealthWorkoutActivityType.RUNNING,
      start: startedAt,
      end: endedAt,
      totalDistance: totalDistanceMeters,
      title: 'Runlini Run',
      recordingMethod: Platform.isAndroid
          ? RecordingMethod.active
          : RecordingMethod.automatic,
    );
  }

  @override
  Future<String?> findWorkoutUuid({
    required DateTime startedAt,
    required DateTime endedAt,
  }) async {
    final workouts = await _health.getHealthDataFromTypes(
      types: const <HealthDataType>[HealthDataType.WORKOUT],
      startTime: startedAt.subtract(const Duration(minutes: 5)),
      endTime: endedAt.add(const Duration(minutes: 5)),
    );
    if (workouts.isEmpty) {
      return null;
    }

    HealthDataPoint? closestMatch;
    Duration? smallestDelta;
    for (final workout in workouts) {
      final delta =
          workout.dateFrom.difference(startedAt).abs() +
          workout.dateTo.difference(endedAt).abs();
      if (smallestDelta == null || delta < smallestDelta) {
        closestMatch = workout;
        smallestDelta = delta;
      }
    }

    return closestMatch?.uuid;
  }

  @override
  Future<bool> insertWorkoutRouteData({
    required String builderId,
    required List<WorkoutRouteLocation> locations,
  }) {
    return _health.insertWorkoutRouteData(
      builderId: builderId,
      locations: locations,
    );
  }

  @override
  Future<void> finishWorkoutRoute({
    required String builderId,
    required String workoutUuid,
  }) async {
    await _health.finishWorkoutRoute(
      builderId: builderId,
      workoutUuid: workoutUuid,
      metadata: const <String, dynamic>{'source': 'runlini'},
    );
  }

  @override
  Future<void> discardWorkoutRoute(String builderId) async {
    await _health.discardWorkoutRoute(builderId);
  }
}
