import 'dart:convert';

import 'package:runlini/core/persistence/runlini_database.dart';
import 'package:runlini/features/run_tracking/repo/run_session_repository.dart';
import 'package:runlini/features/run_tracking/types/run_point.dart';
import 'package:runlini/features/run_tracking/types/run_session.dart';
import 'package:runlini/features/run_tracking/types/run_session_ghost_summary.dart';
import 'package:sqflite/sqflite.dart';

class SqfliteRunSessionRepository implements RunSessionRepository {
  const SqfliteRunSessionRepository({required RunliniDatabase database})
    : _database = database;

  final RunliniDatabase _database;

  @override
  Future<void> saveSession(RunSession session) async {
    final db = await _database.database;
    await db.transaction((txn) async {
      await txn.insert(
        'run_sessions',
        _sessionRow(session),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      await txn.delete(
        'run_points',
        where: 'session_id = ?',
        whereArgs: <Object?>[session.id],
      );
      for (var index = 0; index < session.points.length; index += 1) {
        await txn.insert(
          'run_points',
          _pointRow(session.id, index, session.points[index]),
        );
      }
    });
  }

  @override
  Future<void> deleteSession(String id) async {
    final db = await _database.database;
    await db.transaction((txn) async {
      final rows = await txn.query(
        'run_sessions',
        where: 'id = ?',
        whereArgs: <Object?>[id],
        limit: 1,
      );
      if (rows.isNotEmpty) {
        await txn.insert(
          'deleted_run_sessions',
          _deletedSessionRow(rows.single),
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
      await txn.delete(
        'run_points',
        where: 'session_id = ?',
        whereArgs: <Object?>[id],
      );
      await txn.delete('run_sessions', where: 'id = ?', whereArgs: [id]);
    });
  }

  @override
  Future<bool> isDeletedExternalSession(RunSession session) async {
    final db = await _database.database;
    final exactRows = await db.query(
      'deleted_run_sessions',
      where:
          'session_id = ? OR '
          '(external_id IS NOT NULL AND record_source = ? AND external_id = ?)',
      whereArgs: <Object?>[
        session.id,
        session.recordSource.name,
        session.externalId,
      ],
      limit: 1,
    );
    if (exactRows.isNotEmpty) {
      return true;
    }

    final deletedRows = await db.query('deleted_run_sessions');
    for (final row in deletedRows) {
      if (_isLikelyDeletedSession(row, session)) {
        return true;
      }
    }
    return false;
  }

  @override
  Future<RunSession?> findById(String id) async {
    final db = await _database.database;
    final rows = await db.query(
      'run_sessions',
      where: 'id = ?',
      whereArgs: <Object?>[id],
      limit: 1,
    );
    if (rows.isEmpty) {
      return null;
    }
    return _sessionFromRows(db, rows.single);
  }

  @override
  Future<List<RunSession>> listSessions() async {
    final db = await _database.database;
    final rows = await db.query('run_sessions', orderBy: 'started_at DESC');
    final sessions = <RunSession>[];
    for (final row in rows) {
      sessions.add(await _sessionFromRows(db, row));
    }
    return List<RunSession>.unmodifiable(sessions);
  }

  Future<RunSession> _sessionFromRows(
    DatabaseExecutor db,
    Map<String, Object?> row,
  ) async {
    final pointRows = await db.query(
      'run_points',
      where: 'session_id = ?',
      whereArgs: <Object?>[row['id']],
      orderBy: 'sequence_index ASC',
    );
    return RunSession(
      id: row['id']! as String,
      startedAt: DateTime.parse(row['started_at']! as String),
      endedAt: _date(row['ended_at']),
      distanceM: _double(row['distance_m']),
      durationMs: _int(row['duration_ms']),
      sourceSummary: row['source_summary']! as String,
      points: pointRows.map(_pointFromRow).toList(growable: false),
      averageCadenceSpm: _nullableDouble(row['average_cadence_spm']),
      caloriesKcal: _nullableDouble(row['calories_kcal']),
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
      externalId: row['external_id'] as String?,
      lastSyncedAt: _date(row['last_synced_at']),
      syncStatus: _enumByName(
        RunSessionSyncStatus.values,
        row['sync_status'] as String?,
        RunSessionSyncStatus.localOnly,
      ),
      ghostSummary: _ghostSummary(row['ghost_summary_json']),
      shoeId: row['shoe_id'] as String?,
    );
  }

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
      'ghost_summary_json': session.ghostSummary == null
          ? null
          : jsonEncode(session.ghostSummary!.toJson()),
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
      source: RunPointSource.values.byName(row['source']! as String),
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
    final durationDeltaMs =
        (_int(deletedRow['duration_ms']) - session.durationMs).abs();
    final distanceDeltaM =
        (_double(deletedRow['distance_m']) - session.distanceM).abs();
    final distanceToleranceM = (session.distanceM * 0.05)
        .clamp(50, 250)
        .toDouble();
    return startDeltaMs <= const Duration(minutes: 2).inMilliseconds &&
        durationDeltaMs <= const Duration(minutes: 2).inMilliseconds &&
        distanceDeltaM <= distanceToleranceM;
  }

  RunSessionGhostSummary? _ghostSummary(Object? value) {
    if (value == null) {
      return null;
    }
    return RunSessionGhostSummary.fromJson(
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
}
