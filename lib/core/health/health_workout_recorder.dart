import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:health/health.dart';
import 'package:latlong2/latlong.dart';
import 'package:runlini/core/health/health_plugin_workout_platform.dart';
import 'package:runlini/core/health/health_workout_export_result.dart';
import 'package:runlini/core/health/health_workout_platform.dart';
import 'package:runlini/features/run_tracking/types/run_point.dart';

export 'package:runlini/core/health/health_workout_export_result.dart';
export 'package:runlini/core/health/health_workout_platform.dart';

enum HealthRunPreparationResult {
  ready,
  installRequired,
  unavailable,
  permissionDenied,
}

abstract class HealthWorkoutRecorder {
  Future<HealthRunPreparationResult> prepareRunCapture();

  Future<void> openHealthConnectInstall();

  Future<void> beginRunCapture();

  Future<HealthWorkoutExportResult> finishRunCapture({
    required DateTime startedAt,
    required DateTime endedAt,
    required List<RunPoint> recordedPoints,
  });

  Future<void> cancelRunCapture();
}

class PlatformHealthWorkoutRecorder implements HealthWorkoutRecorder {
  PlatformHealthWorkoutRecorder({required HealthWorkoutPlatform platform})
    : _platform = platform;

  static const Distance _distance = Distance();

  final HealthWorkoutPlatform _platform;
  String? _activeRouteBuilderId;
  bool _hasPreparedRunPermissions = false;
  HealthRunPreparationResult _preparedRunPermissionsResult =
      HealthRunPreparationResult.unavailable;

  @override
  Future<HealthRunPreparationResult> prepareRunCapture() async {
    await cancelRunCapture();
    try {
      _preparedRunPermissionsResult = await _requestRunPermissions();
      _hasPreparedRunPermissions = true;
      return _preparedRunPermissionsResult;
    } catch (error) {
      debugPrint('Runlini health export permission prep skipped: $error');
      _preparedRunPermissionsResult = HealthRunPreparationResult.unavailable;
      _hasPreparedRunPermissions = true;
      return _preparedRunPermissionsResult;
    }
  }

  @override
  Future<void> openHealthConnectInstall() async {
    try {
      await _platform.installHealthConnect();
    } catch (error) {
      debugPrint('Runlini Health Connect install prompt skipped: $error');
    }
  }

  @override
  Future<void> beginRunCapture() async {
    await cancelRunCapture();
    try {
      final permissionResult = _hasPreparedRunPermissions
          ? _preparedRunPermissionsResult
          : await _requestRunPermissions();
      _hasPreparedRunPermissions = false;
      _preparedRunPermissionsResult = HealthRunPreparationResult.unavailable;
      if (permissionResult != HealthRunPreparationResult.ready) {
        return;
      }

      _activeRouteBuilderId = await _platform.startWorkoutRoute();
    } catch (error) {
      debugPrint('Runlini health export start skipped: $error');
      _activeRouteBuilderId = null;
    }
  }

  Future<HealthRunPreparationResult> _requestRunPermissions() async {
    final availability = await _platform.checkAvailability();
    if (availability == HealthConnectAvailability.providerUpdateRequired) {
      return HealthRunPreparationResult.installRequired;
    }
    if (availability != HealthConnectAvailability.available) {
      return HealthRunPreparationResult.unavailable;
    }

    await _platform.configure();
    final granted = await _platform.requestRunPermissions();
    return granted
        ? HealthRunPreparationResult.ready
        : HealthRunPreparationResult.permissionDenied;
  }

  @override
  Future<HealthWorkoutExportResult> finishRunCapture({
    required DateTime startedAt,
    required DateTime endedAt,
    required List<RunPoint> recordedPoints,
  }) async {
    final builderId = _activeRouteBuilderId;
    _activeRouteBuilderId = null;
    if (builderId == null) {
      return const HealthWorkoutExportResult.skipped(
        'Health export was not started.',
      );
    }

    try {
      final totalDistanceMeters = _calculateDistanceMeters(recordedPoints);
      final wroteWorkout = await _platform.writeRunningWorkout(
        startedAt: startedAt,
        endedAt: endedAt,
        totalDistanceMeters: totalDistanceMeters == 0
            ? null
            : totalDistanceMeters,
      );
      if (!wroteWorkout) {
        await _platform.discardWorkoutRoute(builderId);
        return const HealthWorkoutExportResult.failed(
          'Health workout write failed.',
        );
      }

      final workoutUuid = await _platform.findWorkoutUuid(
        startedAt: startedAt,
        endedAt: endedAt,
      );
      if (workoutUuid == null) {
        await _platform.discardWorkoutRoute(builderId);
        return const HealthWorkoutExportResult.synced(
          message: 'Health workout was written, but record id was unavailable.',
        );
      }

      final routeLocations = _toWorkoutRouteLocations(
        startedAt: startedAt,
        recordedPoints: recordedPoints,
      );
      if (routeLocations.isEmpty) {
        await _platform.discardWorkoutRoute(builderId);
        return HealthWorkoutExportResult.synced(externalId: workoutUuid);
      }

      final inserted = await _platform.insertWorkoutRouteData(
        builderId: builderId,
        locations: routeLocations,
      );
      if (!inserted) {
        await _platform.discardWorkoutRoute(builderId);
        return HealthWorkoutExportResult.synced(
          externalId: workoutUuid,
          message: 'Health workout was backed up without route data.',
        );
      }

      await _platform.finishWorkoutRoute(
        builderId: builderId,
        workoutUuid: workoutUuid,
      );
      return HealthWorkoutExportResult.synced(externalId: workoutUuid);
    } catch (error) {
      debugPrint('Runlini health export finish skipped: $error');
      await _platform.discardWorkoutRoute(builderId);
      return HealthWorkoutExportResult.failed(error.toString());
    }
  }

  @override
  Future<void> cancelRunCapture() async {
    final builderId = _activeRouteBuilderId;
    _activeRouteBuilderId = null;
    if (builderId == null) {
      return;
    }

    try {
      await _platform.discardWorkoutRoute(builderId);
    } catch (error) {
      debugPrint('Runlini health export cleanup skipped: $error');
    }
  }

  int _calculateDistanceMeters(List<RunPoint> recordedPoints) {
    if (recordedPoints.length < 2) {
      return 0;
    }

    var totalMeters = 0.0;
    for (var index = 1; index < recordedPoints.length; index += 1) {
      final previous = recordedPoints[index - 1];
      final current = recordedPoints[index];
      totalMeters += _distance.as(
        LengthUnit.Meter,
        LatLng(previous.latitude, previous.longitude),
        LatLng(current.latitude, current.longitude),
      );
    }

    return totalMeters.round();
  }

  List<WorkoutRouteLocation> _toWorkoutRouteLocations({
    required DateTime startedAt,
    required List<RunPoint> recordedPoints,
  }) {
    if (recordedPoints.isEmpty) {
      return const <WorkoutRouteLocation>[];
    }

    final sortedPoints = List<RunPoint>.from(recordedPoints)
      ..sort(
        (RunPoint left, RunPoint right) =>
            left.timestampRelMs.compareTo(right.timestampRelMs),
      );
    return sortedPoints
        .map(
          (RunPoint point) => WorkoutRouteLocation(
            latitude: point.latitude,
            longitude: point.longitude,
            timestamp: startedAt.add(
              Duration(milliseconds: point.timestampRelMs),
            ),
            horizontalAccuracy: point.horizontalAccuracyM,
            speed: point.speedMps,
            speedAccuracy: point.speedAccuracyMps,
            altitude: point.elevationM,
          ),
        )
        .toList(growable: false);
  }
}

final healthWorkoutRecorderProvider = Provider<HealthWorkoutRecorder>((
  Ref ref,
) {
  return PlatformHealthWorkoutRecorder(platform: HealthPluginWorkoutPlatform());
});
