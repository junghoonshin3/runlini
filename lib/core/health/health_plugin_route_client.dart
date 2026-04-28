import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:health/health.dart';
import 'package:runlini/core/health/health_route_client.dart';
import 'package:runlini/core/health/health_run_permission_scope.dart';
import 'package:runlini/core/health/health_run_session_mapper.dart';

class HealthPluginRouteClient implements HealthRouteClient {
  HealthPluginRouteClient({
    Health? health,
    HealthRunSessionMapper mapper = const HealthRunSessionMapper(),
    this.lookback = const Duration(days: 30),
  }) : _health = health ?? Health(),
       _mapper = mapper;

  final Health _health;
  final HealthRunSessionMapper _mapper;
  final Duration lookback;

  @override
  Future<HealthRouteImportResult> importRecentSessions({
    required bool requestAuthorization,
  }) async {
    if (!Platform.isAndroid && !Platform.isIOS) {
      return const HealthRouteImportResult.unavailable(
        'Health import is only available on Android and iOS.',
      );
    }

    try {
      await _health.configure();
      if (Platform.isAndroid) {
        final status = await _health.getHealthConnectSdkStatus();
        if (status != HealthConnectSdkStatus.sdkAvailable) {
          if (requestAuthorization &&
              status ==
                  HealthConnectSdkStatus.sdkUnavailableProviderUpdateRequired) {
            await _health.installHealthConnect();
          }
          return const HealthRouteImportResult.unavailable(
            'Health Connect is not available.',
          );
        }
      }

      final permissionTypes =
          HealthRunPermissionScope.permissionTypesForPlatform(
            isAndroid: Platform.isAndroid,
          );
      final permissionAccesses =
          HealthRunPermissionScope.permissionAccessesForPlatform(
            isAndroid: Platform.isAndroid,
          );
      final hasPermissions = await _health.hasPermissions(
        permissionTypes,
        permissions: permissionAccesses,
      );
      var authorized = hasPermissions == true;
      if (requestAuthorization) {
        authorized = await _health.requestAuthorization(
          permissionTypes,
          permissions: permissionAccesses,
        );
      }
      if (!authorized) {
        return const HealthRouteImportResult.authorizationRequired(
          'Health permissions are required.',
        );
      }

      final endTime = DateTime.now();
      final startTime = endTime.subtract(lookback);
      final workouts = await _read(
        types: const <HealthDataType>[HealthDataType.WORKOUT],
        startTime: startTime,
        endTime: endTime,
      );
      final routes = await _read(
        types: const <HealthDataType>[HealthDataType.WORKOUT_ROUTE],
        startTime: startTime,
        endTime: endTime,
      );
      final heartRates = await _read(
        types: const <HealthDataType>[HealthDataType.HEART_RATE],
        startTime: startTime,
        endTime: endTime,
      );

      return HealthRouteImportResult.success(
        _mapper.map(workouts: workouts, routes: routes, heartRates: heartRates),
      );
    } catch (error) {
      debugPrint('Runlini health history import failed: $error');
      return HealthRouteImportResult.failed(error.toString());
    }
  }

  Future<List<HealthDataPoint>> _read({
    required List<HealthDataType> types,
    required DateTime startTime,
    required DateTime endTime,
  }) {
    return _health.getHealthDataFromTypes(
      types: types,
      startTime: startTime,
      endTime: endTime,
    );
  }
}
