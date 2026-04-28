import 'package:flutter_test/flutter_test.dart';
import 'package:health/health.dart';
import 'package:runlini/core/health/health_run_session_mapper.dart';
import 'package:runlini/features/run_tracking/types/run_point.dart';

void main() {
  const mapper = HealthRunSessionMapper();

  test('maps a Health Connect running workout into a RunSession', () {
    final startedAt = DateTime.utc(2026, 4, 20, 6);
    final endedAt = startedAt.add(const Duration(minutes: 10));
    final sessions = mapper.map(
      workouts: [
        _workout(
          startedAt: startedAt,
          endedAt: endedAt,
          activityType: HealthWorkoutActivityType.RUNNING,
        ),
      ],
      routes: [_route(startedAt: startedAt, endedAt: endedAt)],
      heartRates: [_heartRate(at: endedAt, bpm: 151)],
    );

    expect(sessions, hasLength(1));
    final session = sessions.single;
    expect(session.id, 'healthconnect-workout-1');
    expect(session.distanceM, 1000);
    expect(session.durationMs, 600000);
    expect(session.caloriesKcal, 80);
    expect(session.averageCadenceSpm, 170);
    expect(session.sourceSummary, 'Health Connect · com.example.run');
    expect(session.points, hasLength(2));
    expect(session.points.last.source, RunPointSource.healthConnect);
    expect(session.points.last.heartRateBpm, 151);
    expect(session.points.last.elevationM, 12);
  });

  test('filters non-running workouts', () {
    final startedAt = DateTime.utc(2026, 4, 20, 6);
    final sessions = mapper.map(
      workouts: [
        _workout(
          startedAt: startedAt,
          endedAt: startedAt.add(const Duration(minutes: 10)),
          activityType: HealthWorkoutActivityType.BIKING,
        ),
      ],
      routes: const <HealthDataPoint>[],
      heartRates: const <HealthDataPoint>[],
    );

    expect(sessions, isEmpty);
  });
}

HealthDataPoint _workout({
  required DateTime startedAt,
  required DateTime endedAt,
  required HealthWorkoutActivityType activityType,
}) {
  return HealthDataPoint(
    uuid: 'workout-1',
    value: WorkoutHealthValue(
      workoutActivityType: activityType,
      totalDistance: 1000,
      totalDistanceUnit: HealthDataUnit.METER,
      totalEnergyBurned: 80,
      totalEnergyBurnedUnit: HealthDataUnit.KILOCALORIE,
      totalSteps: 1700,
      totalStepsUnit: HealthDataUnit.COUNT,
    ),
    type: HealthDataType.WORKOUT,
    unit: HealthDataUnit.NO_UNIT,
    dateFrom: startedAt,
    dateTo: endedAt,
    sourcePlatform: HealthPlatformType.googleHealthConnect,
    sourceDeviceId: 'device',
    sourceId: 'com.example.run',
    sourceName: 'com.example.run',
  );
}

HealthDataPoint _route({
  required DateTime startedAt,
  required DateTime endedAt,
}) {
  return HealthDataPoint(
    uuid: 'workout-1',
    value: WorkoutRouteHealthValue(
      workoutUuid: 'workout-1',
      locations: [
        WorkoutRouteLocation(
          latitude: 34.6645939,
          longitude: 135.5000968,
          timestamp: startedAt,
          altitude: 10,
          speed: 1.8,
        ),
        WorkoutRouteLocation(
          latitude: 34.6655939,
          longitude: 135.5010968,
          timestamp: endedAt,
          altitude: 12,
          speed: 2.2,
        ),
      ],
    ),
    type: HealthDataType.WORKOUT_ROUTE,
    unit: HealthDataUnit.NO_UNIT,
    dateFrom: startedAt,
    dateTo: endedAt,
    sourcePlatform: HealthPlatformType.googleHealthConnect,
    sourceDeviceId: 'device',
    sourceId: 'com.example.run',
    sourceName: 'com.example.run',
  );
}

HealthDataPoint _heartRate({required DateTime at, required int bpm}) {
  return HealthDataPoint(
    uuid: 'hr-1',
    value: NumericHealthValue(numericValue: bpm),
    type: HealthDataType.HEART_RATE,
    unit: HealthDataUnit.BEATS_PER_MINUTE,
    dateFrom: at,
    dateTo: at,
    sourcePlatform: HealthPlatformType.googleHealthConnect,
    sourceDeviceId: 'device',
    sourceId: 'com.example.run',
    sourceName: 'com.example.run',
  );
}
