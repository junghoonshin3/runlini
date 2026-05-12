part of 'sqflite_run_session_repository.dart';

Map<String, Object?> _sessionRow(RunSession session) {
  return <String, Object?>{
    'id': session.id,
    'started_at': session.startedAt.toIso8601String(),
    'ended_at': session.endedAt?.toIso8601String(),
    'distance_m': session.distanceM,
    'duration_ms': session.durationMs,
    'source_summary': session.sourceSummary,
    'average_cadence_spm': session.averageCadenceSpm,
    'calories_kcal': session.caloriesKcal,
    'record_source': session.recordSource.name,
    'capture_source': session.captureSource.name,
    'external_id': session.externalId,
    'last_synced_at': session.lastSyncedAt?.toIso8601String(),
    'sync_status': session.syncStatus.name,
    'record_race_summary_json': session.recordRaceSummary == null
        ? null
        : jsonEncode(session.recordRaceSummary!.toJson()),
    'shoe_id': session.shoeId,
  };
}

Map<String, Object?> _deletedSessionRow(Map<String, Object?> row) {
  return <String, Object?>{
    'session_id': row['id'],
    'record_source': row['record_source'],
    'external_id': row['external_id'],
    'started_at': row['started_at'],
    'duration_ms': row['duration_ms'],
    'distance_m': row['distance_m'],
    'deleted_at': DateTime.now().toIso8601String(),
  };
}

Map<String, Object?> _pointRow(String sessionId, int index, RunPoint point) {
  return <String, Object?>{
    'session_id': sessionId,
    'sequence_index': index,
    'lat': point.latitude,
    'lng': point.longitude,
    'timestamp_rel_ms': point.timestampRelMs,
    'pace_sec_per_km': point.paceSecPerKm,
    'speed_mps': point.speedMps,
    'elevation_m': point.elevationM,
    'heart_rate_bpm': point.heartRateBpm,
    'cadence_spm': point.cadenceSpm,
    'horizontal_accuracy_m': point.horizontalAccuracyM,
    'speed_accuracy_mps': point.speedAccuracyMps,
    'source': point.source.name,
  };
}

RunPoint _pointFromRow(Map<String, Object?> row) {
  return RunPoint(
    latitude: _double(row['lat']),
    longitude: _double(row['lng']),
    timestampRelMs: _int(row['timestamp_rel_ms']),
    paceSecPerKm: _nullableDouble(row['pace_sec_per_km']),
    speedMps: _nullableDouble(row['speed_mps']),
    elevationM: _nullableDouble(row['elevation_m']),
    heartRateBpm: _nullableInt(row['heart_rate_bpm']),
    cadenceSpm: _nullableDouble(row['cadence_spm']),
    horizontalAccuracyM: _nullableDouble(row['horizontal_accuracy_m']),
    speedAccuracyMps: _nullableDouble(row['speed_accuracy_mps']),
    source: RunPointSource.values.byName(row['source']! as String),
  );
}

RunSessionSummary _summaryFromRow(Map<String, Object?> row) {
  final distanceM = _double(row['distance_m']);
  final distanceKm = distanceM / 1000;
  return RunSessionSummary(
    id: row['id']! as String,
    startedAt: DateTime.parse(row['started_at']! as String),
    distanceM: distanceM,
    durationMs: _int(row['duration_ms']),
    averagePaceSecPerKm: distanceKm <= 0
        ? 0
        : (_int(row['duration_ms']) / 1000) / distanceKm,
    sourceSummary: row['source_summary']! as String,
    recordSource: _enumByName(
      RunSessionRecordSource.values,
      row['record_source'] as String?,
      RunSessionRecordSource.appLocal,
    ),
    captureSource: _enumByName(
      RunSessionCaptureSource.values,
      row['capture_source'] as String?,
      RunSessionCaptureSource.phoneGps,
    ),
    syncStatus: _enumByName(
      RunSessionSyncStatus.values,
      row['sync_status'] as String?,
      RunSessionSyncStatus.localOnly,
    ),
    averageCadenceSpm: _nullableDouble(row['average_cadence_spm']),
    shoeId: row['shoe_id'] as String?,
    pointCount: _int(row['point_count']),
  );
}

double _double(Object? value) {
  return (value! as num).toDouble();
}

double? _nullableDouble(Object? value) {
  return value == null ? null : (value as num).toDouble();
}

int _int(Object? value) {
  return (value! as num).toInt();
}

int? _nullableInt(Object? value) {
  return value == null ? null : (value as num).toInt();
}

DateTime? _date(Object? value) {
  return value == null ? null : DateTime.parse(value as String);
}

bool _isLikelyDeletedSession(
  Map<String, Object?> deletedRow,
  RunSession session,
) {
  final startDeltaMs = DateTime.parse(
    deletedRow['started_at']! as String,
  ).difference(session.startedAt).inMilliseconds.abs();
  final durationDeltaMs = (_int(deletedRow['duration_ms']) - session.durationMs)
      .abs();
  final distanceDeltaM = (_double(deletedRow['distance_m']) - session.distanceM)
      .abs();
  final distanceToleranceM = (session.distanceM * 0.05)
      .clamp(50, 250)
      .toDouble();
  return startDeltaMs <= const Duration(minutes: 2).inMilliseconds &&
      durationDeltaMs <= const Duration(minutes: 2).inMilliseconds &&
      distanceDeltaM <= distanceToleranceM;
}

RunSessionRecordRaceSummary? _recordRaceSummary(Object? value) {
  if (value == null) {
    return null;
  }
  return RunSessionRecordRaceSummary.fromJson(
    jsonDecode(value as String) as Map<String, dynamic>,
  );
}

T _enumByName<T extends Enum>(List<T> values, String? name, T fallback) {
  if (name == null) {
    return fallback;
  }
  for (final value in values) {
    if (value.name == name) {
      return value;
    }
  }
  return fallback;
}
