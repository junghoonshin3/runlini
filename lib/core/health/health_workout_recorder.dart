import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:health/health.dart';
import 'package:latlong2/latlong.dart';
import 'package:runlini/core/health/health_plugin_workout_platform.dart';
import 'package:runlini/core/health/health_workout_platform.dart';
import 'package:runlini/features/run_tracking/types/run_point.dart';

export 'package:runlini/core/health/health_workout_platform.dart';

abstract class HealthWorkoutRecorder {
  Future<void> prepareRunCapture();

  Future<void> beginRunCapture();

  Future<void> finishRunCapture({
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
  bool _preparedRunPermissionsGranted = false;

  @override
  Future<void> prepareRunCapture() async {
    await cancelRunCapture();
    try {
      _preparedRunPermissionsGranted = await _requestRunPermissions();
      _hasPreparedRunPermissions = true;
    } catch (error) {
      debugPrint('Runlini health export permission prep skipped: $error');
      _preparedRunPermissionsGranted = false;
      _hasPreparedRunPermissions = true;
    }
  }

  @override
  Future<void> beginRunCapture() async {
    await cancelRunCapture();
    try {
      final permissionsGranted = _hasPreparedRunPermissions
          ? _preparedRunPermissionsGranted
          : await _requestRunPermissions();
      _hasPreparedRunPermissions = false;
      _preparedRunPermissionsGranted = false;
      if (!permissionsGranted) {
        return;
      }

      _activeRouteBuilderId = await _platform.startWorkoutRoute();
    } catch (error) {
      debugPrint('Runlini health export start skipped: $error');
      _activeRouteBuilderId = null;
    }
  }

  Future<bool> _requestRunPermissions() async {
    if (!await _platform.isAvailable()) {
      return false;
    }
    await _platform.configure();
    return _platform.requestRunPermissions();
  }

  @override
  Future<void> finishRunCapture({
    required DateTime startedAt,
    required DateTime endedAt,
    required List<RunPoint> recordedPoints,
  }) async {
    final builderId = _activeRouteBuilderId;
    _activeRouteBuilderId = null;
    if (builderId == null) {
      return;
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
        return;
      }

      final workoutUuid = await _platform.findWorkoutUuid(
        startedAt: startedAt,
        endedAt: endedAt,
      );
      if (workoutUuid == null) {
        await _platform.discardWorkoutRoute(builderId);
        return;
      }

      final routeLocations = _toWorkoutRouteLocations(
        startedAt: startedAt,
        recordedPoints: recordedPoints,
      );
      if (routeLocations.isEmpty) {
        await _platform.discardWorkoutRoute(builderId);
        return;
      }

      final inserted = await _platform.insertWorkoutRouteData(
        builderId: builderId,
        locations: routeLocations,
      );
      if (!inserted) {
        await _platform.discardWorkoutRoute(builderId);
        return;
      }

      await _platform.finishWorkoutRoute(
        builderId: builderId,
        workoutUuid: workoutUuid,
      );
    } catch (error) {
      debugPrint('Runlini health export finish skipped: $error');
      await _platform.discardWorkoutRoute(builderId);
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
