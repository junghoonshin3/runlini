import 'dart:convert';

import 'package:runlini/core/persistence/runlini_database.dart';
import 'package:runlini/features/run_tracking/repo/run_session_repository.dart';
import 'package:runlini/features/run_tracking/types/run_point.dart';
import 'package:runlini/features/run_tracking/types/run_session.dart';
import 'package:runlini/features/run_tracking/types/run_session_record_race_summary.dart';
import 'package:runlini/features/run_tracking/types/run_session_summary.dart';
import 'package:sqflite/sqflite.dart';

part 'sqflite_run_session_repository_rows.dart';

class SqfliteRunSessionRepository implements RunSessionRepository {
  const SqfliteRunSessionRepository({required RunliniDatabase database})
    : _database = database;

  final RunliniDatabase _database;

  @override
  Future<void> saveSession(RunSession session) async {
    final db = await _database.database;
    await db.transaction((txn) async {
      final batch = txn.batch();
      batch.insert(
        'run_sessions',
        _sessionRow(session),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      batch.delete(
        'run_points',
        where: 'session_id = ?',
        whereArgs: <Object?>[session.id],
      );
      for (var index = 0; index < session.points.length; index += 1) {
        batch.insert(
          'run_points',
          _pointRow(session.id, index, session.points[index]),
        );
      }
      await batch.commit(noResult: true);
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

  @override
  Future<List<RunSessionSummary>> listSessionSummaries() async {
    final db = await _database.database;
    final rows = await db.rawQuery('''
SELECT
  id,
  started_at,
  distance_m,
  duration_ms,
  source_summary,
  average_cadence_spm,
  record_source,
  capture_source,
  sync_status,
  shoe_id,
  (
    SELECT COUNT(*)
    FROM run_points
    WHERE run_points.session_id = run_sessions.id
  ) AS point_count
FROM run_sessions
ORDER BY started_at DESC
''');
    return List<RunSessionSummary>.unmodifiable(rows.map(_summaryFromRow));
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
      recordRaceSummary: _recordRaceSummary(
        row['record_race_summary_json'] ?? row['ghost_summary_json'],
      ),
      shoeId: row['shoe_id'] as String?,
    );
  }
}
