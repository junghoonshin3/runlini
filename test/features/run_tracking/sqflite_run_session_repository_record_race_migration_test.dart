// 기록 레이스 DB 마이그레이션 호환성을 검증하는 테스트.
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:runlini/core/persistence/runlini_database.dart';
import 'package:runlini/features/run_tracking/repo/sqflite_run_session_repository.dart';
import 'package:runlini/features/run_tracking/types/run_point.dart';
import 'package:runlini/features/run_tracking/types/run_session.dart';
import 'package:runlini/features/run_tracking/types/run_session_record_race_summary.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  setUpAll(sqfliteFfiInit);

  test('migrates legacy ghost summary into recordRace summary', () async {
    final tempDir = await Directory.systemTemp.createTemp('runlini-db-test');
    addTearDown(() => tempDir.delete(recursive: true));
    final dbPath = p.join(tempDir.path, 'runlini.db');
    final oldDb = await databaseFactoryFfi.openDatabase(
      dbPath,
      options: OpenDatabaseOptions(
        version: 8,
        onCreate: (db, version) async {
          await db.execute('''
CREATE TABLE run_sessions (
  id TEXT PRIMARY KEY,
  started_at TEXT NOT NULL,
  ended_at TEXT,
  distance_m REAL NOT NULL,
  duration_ms INTEGER NOT NULL,
  source_summary TEXT NOT NULL,
  average_cadence_spm REAL,
  calories_kcal REAL,
  record_source TEXT NOT NULL,
  capture_source TEXT NOT NULL DEFAULT 'phoneGps',
  external_id TEXT,
  last_synced_at TEXT,
  sync_status TEXT NOT NULL,
  ghost_summary_json TEXT,
  shoe_id TEXT
)
''');
          await db.execute('''
CREATE TABLE run_points (
  session_id TEXT NOT NULL,
  sequence_index INTEGER NOT NULL,
  lat REAL NOT NULL,
  lng REAL NOT NULL,
  timestamp_rel_ms INTEGER NOT NULL,
  pace_sec_per_km REAL,
  speed_mps REAL,
  elevation_m REAL,
  heart_rate_bpm INTEGER,
  cadence_spm REAL,
  horizontal_accuracy_m REAL,
  speed_accuracy_mps REAL,
  source TEXT NOT NULL,
  PRIMARY KEY (session_id, sequence_index)
)
''');
        },
      ),
    );
    await oldDb.insert('run_sessions', {
      'id': 'legacy-ghost-run',
      'started_at': DateTime.utc(2026, 4, 22, 6).toIso8601String(),
      'distance_m': 1200,
      'duration_ms': 600000,
      'source_summary': 'device:gps',
      'record_source': RunSessionRecordSource.appLocal.name,
      'capture_source': RunSessionCaptureSource.phoneGps.name,
      'sync_status': RunSessionSyncStatus.localOnly.name,
      'ghost_summary_json': jsonEncode({
        'result': RunSessionRecordRaceResult.ahead.name,
        'timeGapMs': 12000,
        'distanceGapM': 42,
        'ghostSessionId': 'old-record',
        'ghostLabel': 'old label',
      }),
    });
    await oldDb.insert('run_points', {
      'session_id': 'legacy-ghost-run',
      'sequence_index': 0,
      'lat': 37.5,
      'lng': 127.0,
      'timestamp_rel_ms': 0,
      'source': RunPointSource.deviceGps.name,
    });
    await oldDb.close();

    final database = RunliniDatabase(
      databaseFactory: databaseFactoryFfi,
      databasePath: dbPath,
    );
    addTearDown(database.close);

    final session = await SqfliteRunSessionRepository(
      database: database,
    ).findById('legacy-ghost-run');

    expect(
      session?.recordRaceSummary?.result,
      RunSessionRecordRaceResult.ahead,
    );
    expect(session?.recordRaceSummary?.timeGapMs, 12000);
    expect(session?.recordRaceSummary?.distanceGapM, 42);
    expect(session?.recordRaceSummary?.recordRaceSessionId, 'old-record');
    expect(session?.recordRaceSummary?.recordRaceLabel, 'old label');
  });
}
