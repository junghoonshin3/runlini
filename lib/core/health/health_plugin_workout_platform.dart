import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:health/health.dart';
import 'package:runlini/core/health/health_run_permission_scope.dart';
import 'package:runlini/core/health/health_workout_platform.dart';

class HealthPluginWorkoutPlatform implements HealthWorkoutPlatform {
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
  Future<HealthConnectAvailability> checkAvailability() async {
    if (!Platform.isAndroid && !Platform.isIOS) {
      return HealthConnectAvailability.unavailable;
    }
    if (!Platform.isAndroid) {
      return HealthConnectAvailability.available;
    }

    final status = await _health.getHealthConnectSdkStatus();
    return switch (status) {
      HealthConnectSdkStatus.sdkAvailable =>
        HealthConnectAvailability.available,
      HealthConnectSdkStatus.sdkUnavailableProviderUpdateRequired =>
        HealthConnectAvailability.providerUpdateRequired,
      _ => HealthConnectAvailability.unavailable,
    };
  }

  @override
  Future<void> installHealthConnect() {
    return _health.installHealthConnect();
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
    return HealthRunPermissionScope.permissionTypesForPlatform(
      isAndroid: isAndroid,
    );
  }

  @visibleForTesting
  static List<HealthDataAccess> permissionAccessesForPlatform({
    required bool isAndroid,
  }) {
    return HealthRunPermissionScope.permissionAccessesForPlatform(
      isAndroid: isAndroid,
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

  @override
  Future<bool> deleteWorkoutByUuid({required String uuid}) {
    return _health.deleteByUUID(uuid: uuid, type: HealthDataType.WORKOUT);
  }
}
