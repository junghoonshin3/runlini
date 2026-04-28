import 'package:health/health.dart';
import 'package:latlong2/latlong.dart';
import 'package:runlini/features/run_tracking/types/run_point.dart';
import 'package:runlini/features/run_tracking/types/run_session.dart';

class HealthRunSessionMapper {
  const HealthRunSessionMapper();

  static const Distance _distance = Distance();
  static const int _heartRateMatchWindowMs = 15000;

  List<RunSession> map({
    required List<HealthDataPoint> workouts,
    required List<HealthDataPoint> routes,
    required List<HealthDataPoint> heartRates,
  }) {
    final sessions = <RunSession>[];
    for (final workout in workouts) {
      final value = workout.value;
      if (value is! WorkoutHealthValue || !_isRunning(value)) {
        continue;
      }

      final route = _routeFor(workout: workout, routes: routes);
      final points = _pointsFor(
        workout: workout,
        route: route,
        heartRates: heartRates,
      );
      final durationMs = _durationMs(workout.dateFrom, workout.dateTo);
      final distanceM =
          _distanceFromWorkout(value) ?? _distanceFromPoints(points);

      sessions.add(
        RunSession(
          id: _sessionId(workout),
          startedAt: workout.dateFrom,
          endedAt: workout.dateTo,
          distanceM: distanceM,
          durationMs: durationMs,
          sourceSummary: _sourceSummary(workout),
          points: points,
          averageCadenceSpm: _averageCadence(value.totalSteps, durationMs),
          caloriesKcal: _caloriesFromWorkout(value),
          recordSource: _recordSource(workout.sourcePlatform),
          externalId: workout.uuid.isEmpty ? null : workout.uuid,
          syncStatus: RunSessionSyncStatus.synced,
        ),
      );
    }

    sessions.sort((left, right) => right.startedAt.compareTo(left.startedAt));
    return sessions;
  }

  bool _isRunning(WorkoutHealthValue value) {
    return value.workoutActivityType == HealthWorkoutActivityType.RUNNING ||
        value.workoutActivityType ==
            HealthWorkoutActivityType.RUNNING_TREADMILL;
  }

  HealthDataPoint? _routeFor({
    required HealthDataPoint workout,
    required List<HealthDataPoint> routes,
  }) {
    for (final route in routes) {
      if (route.value is! WorkoutRouteHealthValue) {
        continue;
      }
      if (_sameWorkout(workout: workout, route: route)) {
        return route;
      }
    }
    return null;
  }

  bool _sameWorkout({
    required HealthDataPoint workout,
    required HealthDataPoint route,
  }) {
    final routeValue = route.value as WorkoutRouteHealthValue;
    if (route.uuid == workout.uuid || routeValue.workoutUuid == workout.uuid) {
      return true;
    }

    final metadataUuid = route.metadata?['workout_uuid'];
    if (metadataUuid is String && metadataUuid == workout.uuid) {
      return true;
    }

    return route.dateFrom.difference(workout.dateFrom).abs() <
            const Duration(minutes: 2) &&
        route.dateTo.difference(workout.dateTo).abs() <
            const Duration(minutes: 2);
  }

  List<RunPoint> _pointsFor({
    required HealthDataPoint workout,
    required HealthDataPoint? route,
    required List<HealthDataPoint> heartRates,
  }) {
    final routeValue = route?.value;
    if (routeValue is! WorkoutRouteHealthValue) {
      return const <RunPoint>[];
    }

    final source = _pointSource(workout.sourcePlatform);
    final locations = List<WorkoutRouteLocation>.from(routeValue.locations)
      ..sort((left, right) => left.timestamp.compareTo(right.timestamp));
    return locations
        .map((location) {
          final elapsedMs = location.timestamp
              .difference(workout.dateFrom)
              .inMilliseconds
              .clamp(0, _durationMs(workout.dateFrom, workout.dateTo))
              .toInt();
          return RunPoint(
            latitude: location.latitude,
            longitude: location.longitude,
            timestampRelMs: elapsedMs,
            paceSecPerKm: _paceFromSpeed(location.speed),
            speedMps: location.speed,
            horizontalAccuracyM: location.horizontalAccuracy,
            speedAccuracyMps: location.speedAccuracy,
            elevationM: location.altitude,
            heartRateBpm: _nearestHeartRate(
              timestamp: location.timestamp,
              workout: workout,
              heartRates: heartRates,
            ),
            source: source,
          );
        })
        .toList(growable: false);
  }

  int? _nearestHeartRate({
    required DateTime timestamp,
    required HealthDataPoint workout,
    required List<HealthDataPoint> heartRates,
  }) {
    HealthDataPoint? nearest;
    int? nearestDeltaMs;
    for (final point in heartRates) {
      if (point.type != HealthDataType.HEART_RATE ||
          point.dateFrom.isBefore(workout.dateFrom) ||
          point.dateFrom.isAfter(workout.dateTo)) {
        continue;
      }

      final deltaMs = point.dateFrom.difference(timestamp).inMilliseconds.abs();
      if (nearestDeltaMs == null || deltaMs < nearestDeltaMs) {
        nearest = point;
        nearestDeltaMs = deltaMs;
      }
    }

    if (nearest == null ||
        nearestDeltaMs == null ||
        nearestDeltaMs > _heartRateMatchWindowMs) {
      return null;
    }
    return _numericValue(nearest).round();
  }

  double? _distanceFromWorkout(WorkoutHealthValue value) {
    final distance = value.totalDistance;
    if (distance == null || distance <= 0) {
      return null;
    }
    return distance.toDouble();
  }

  double _distanceFromPoints(List<RunPoint> points) {
    if (points.length < 2) {
      return 0;
    }
    var meters = 0.0;
    for (var index = 1; index < points.length; index += 1) {
      meters += _distance.as(
        LengthUnit.Meter,
        LatLng(points[index - 1].latitude, points[index - 1].longitude),
        LatLng(points[index].latitude, points[index].longitude),
      );
    }
    return meters;
  }

  double? _caloriesFromWorkout(WorkoutHealthValue value) {
    final calories = value.totalEnergyBurned;
    if (calories == null || calories <= 0) {
      return null;
    }
    return calories.toDouble();
  }

  double? _averageCadence(int? steps, int durationMs) {
    if (steps == null || steps <= 0 || durationMs <= 0) {
      return null;
    }
    return steps / (durationMs / Duration.millisecondsPerMinute);
  }

  double? _paceFromSpeed(double? speedMps) {
    if (speedMps == null || speedMps <= 0 || !speedMps.isFinite) {
      return null;
    }
    return 1000 / speedMps;
  }

  double _numericValue(HealthDataPoint point) {
    final value = point.value;
    if (value is NumericHealthValue) {
      return value.numericValue.toDouble();
    }
    return 0;
  }

  RunPointSource _pointSource(HealthPlatformType platform) {
    return switch (platform) {
      HealthPlatformType.appleHealth => RunPointSource.healthKit,
      HealthPlatformType.googleHealthConnect => RunPointSource.healthConnect,
    };
  }

  RunSessionRecordSource _recordSource(HealthPlatformType platform) {
    return switch (platform) {
      HealthPlatformType.appleHealth => RunSessionRecordSource.healthKit,
      HealthPlatformType.googleHealthConnect =>
        RunSessionRecordSource.healthConnect,
    };
  }

  int _durationMs(DateTime startedAt, DateTime endedAt) {
    return endedAt
        .difference(startedAt)
        .inMilliseconds
        .clamp(0, 1 << 31)
        .toInt();
  }

  String _sessionId(HealthDataPoint workout) {
    final source = workout.sourcePlatform == HealthPlatformType.appleHealth
        ? 'healthkit'
        : 'healthconnect';
    final suffix = workout.uuid.isEmpty
        ? workout.dateFrom.millisecondsSinceEpoch.toString()
        : workout.uuid;
    return '$source-$suffix';
  }

  String _sourceSummary(HealthDataPoint workout) {
    final platform = workout.sourcePlatform == HealthPlatformType.appleHealth
        ? 'Apple Health'
        : 'Health Connect';
    if (workout.sourceName.isEmpty) {
      return platform;
    }
    return '$platform · ${workout.sourceName}';
  }
}
