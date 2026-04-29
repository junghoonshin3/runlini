import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:health/health.dart';
import 'package:runlini/core/health/health_plugin_workout_platform.dart';
import 'package:runlini/core/health/health_workout_export_result.dart';
import 'package:runlini/core/health/health_workout_platform.dart';
import 'package:runlini/core/health/health_workout_route_sanitizer.dart';
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

  static const HealthWorkoutRouteSanitizer _routeSanitizer =
      HealthWorkoutRouteSanitizer();

  final HealthWorkoutPlatform _platform;
  String? _activeRouteBuilderId;
  bool _hasActiveHealthExport = false;
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

      _hasActiveHealthExport = true;
      try {
        _activeRouteBuilderId = await _platform.startWorkoutRoute();
      } catch (error) {
        debugPrint('Runlini health route export start skipped: $error');
        _activeRouteBuilderId = null;
      }
    } catch (error) {
      debugPrint('Runlini health export start skipped: $error');
      _activeRouteBuilderId = null;
      _hasActiveHealthExport = false;
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
    final hasActiveHealthExport = _hasActiveHealthExport;
    _activeRouteBuilderId = null;
    _hasActiveHealthExport = false;
    if (!hasActiveHealthExport) {
      await _discardRouteQuietly(builderId);
      return const HealthWorkoutExportResult.skipped(
        'Health export was not started.',
      );
    }

    if (!endedAt.isAfter(startedAt)) {
      await _discardRouteQuietly(builderId);
      return const HealthWorkoutExportResult.skipped(
        'Health workout time was invalid.',
      );
    }

    final routePoints = _routeSanitizer.sanitize(
      recordedPoints,
      maxTimestampRelMs: endedAt.difference(startedAt).inMilliseconds,
    );
    final totalDistanceMeters = _routeSanitizer.calculateDistanceMeters(
      routePoints,
    );
    final wroteWorkout = await _writeWorkout(
      builderId: builderId,
      startedAt: startedAt,
      endedAt: endedAt,
      totalDistanceMeters: totalDistanceMeters,
    );
    if (wroteWorkout.kind != HealthWorkoutExportResultKind.synced) {
      return wroteWorkout;
    }

    final workoutUuid = await _findWorkoutUuid(startedAt, endedAt);
    if (workoutUuid == null) {
      await _discardRouteQuietly(builderId);
      return const HealthWorkoutExportResult.synced(
        message: 'Health workout was written, but record id was unavailable.',
      );
    }

    if (builderId == null) {
      return HealthWorkoutExportResult.synced(
        externalId: workoutUuid,
        message: 'Health workout was sent without route data.',
      );
    }

    final routeLocations = _toWorkoutRouteLocations(
      startedAt: startedAt,
      recordedPoints: routePoints,
    );
    if (routeLocations.isEmpty) {
      await _discardRouteQuietly(builderId);
      return HealthWorkoutExportResult.synced(externalId: workoutUuid);
    }

    try {
      final inserted = await _platform.insertWorkoutRouteData(
        builderId: builderId,
        locations: routeLocations,
      );
      if (!inserted) {
        await _discardRouteQuietly(builderId);
        return HealthWorkoutExportResult.synced(
          externalId: workoutUuid,
          message: 'Health workout was sent without route data.',
        );
      }

      await _platform.finishWorkoutRoute(
        builderId: builderId,
        workoutUuid: workoutUuid,
      );
      return HealthWorkoutExportResult.synced(externalId: workoutUuid);
    } catch (error) {
      debugPrint('Runlini health route export skipped: $error');
      await _discardRouteQuietly(builderId);
      return HealthWorkoutExportResult.synced(
        externalId: workoutUuid,
        message: 'Health workout was sent without route data.',
      );
    }
  }

  Future<HealthWorkoutExportResult> _writeWorkout({
    required String? builderId,
    required DateTime startedAt,
    required DateTime endedAt,
    required int? totalDistanceMeters,
  }) async {
    try {
      final wroteWorkout = await _platform.writeRunningWorkout(
        startedAt: startedAt,
        endedAt: endedAt,
        totalDistanceMeters: totalDistanceMeters,
      );
      if (!wroteWorkout) {
        await _discardRouteQuietly(builderId);
        return const HealthWorkoutExportResult.failed(
          'Health workout write failed.',
        );
      }
      return const HealthWorkoutExportResult.synced();
    } catch (error) {
      debugPrint('Runlini health export finish skipped: $error');
      await _discardRouteQuietly(builderId);
      return HealthWorkoutExportResult.failed(error.toString());
    }
  }

  Future<String?> _findWorkoutUuid(DateTime startedAt, DateTime endedAt) async {
    try {
      return _platform.findWorkoutUuid(startedAt: startedAt, endedAt: endedAt);
    } catch (error) {
      debugPrint('Runlini health workout lookup skipped: $error');
      return null;
    }
  }

  @override
  Future<void> cancelRunCapture() async {
    final builderId = _activeRouteBuilderId;
    _activeRouteBuilderId = null;
    _hasActiveHealthExport = false;
    await _discardRouteQuietly(builderId);
  }

  Future<void> _discardRouteQuietly(String? builderId) async {
    if (builderId == null) {
      return;
    }

    try {
      await _platform.discardWorkoutRoute(builderId);
    } catch (error) {
      debugPrint('Runlini health export cleanup skipped: $error');
    }
  }

  List<WorkoutRouteLocation> _toWorkoutRouteLocations({
    required DateTime startedAt,
    required List<RunPoint> recordedPoints,
  }) {
    if (recordedPoints.length < 2) {
      return const <WorkoutRouteLocation>[];
    }

    return recordedPoints
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
