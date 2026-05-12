import 'package:path/path.dart' as p;
import 'package:runlini/core/performance/startup_trace.dart';
import 'package:sqflite/sqflite.dart';

class RunliniDatabase {
  RunliniDatabase({
    DatabaseFactory? databaseFactory,
    String databaseName = 'runlini.db',
    String? databasePath,
  }) : _databaseFactory = databaseFactory ?? databaseFactorySqflitePlugin,
       _databaseName = databaseName,
       _databasePath = databasePath;

  static const int version = 9;

  final DatabaseFactory _databaseFactory;
  final String _databaseName;
  final String? _databasePath;
  Database? _database;

  Future<Database> get database async {
    final openDatabase = _database;
    if (openDatabase != null) {
      return openDatabase;
    }

    final path =
        _databasePath ??
        p.join(await _databaseFactory.getDatabasesPath(), _databaseName);
    final database = await StartupTrace.measure(
      'database open',
      () => _databaseFactory.openDatabase(
        path,
        options: OpenDatabaseOptions(
          version: version,
          onCreate: _create,
          onUpgrade: _upgrade,
        ),
      ),
    );
    _database = database;
    return database;
  }

  Future<void> close() async {
    final openDatabase = _database;
    _database = null;
    await openDatabase?.close();
  }

  Future<void> _create(Database db, int version) async {
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
  record_race_summary_json TEXT,
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
  PRIMARY KEY (session_id, sequence_index),
  FOREIGN KEY (session_id) REFERENCES run_sessions(id) ON DELETE CASCADE
)
''');
    await db.execute(
      'CREATE INDEX idx_run_sessions_started_at ON run_sessions(started_at)',
    );
    await db.execute(
      'CREATE INDEX idx_run_sessions_external '
      'ON run_sessions(record_source, external_id)',
    );
    await _createDeletedRunSessionTable(db);
    await _createSettingsTables(db);
  }

  Future<void> _upgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await _addColumnIfMissing(db, 'run_sessions', 'shoe_id TEXT');
      await _createSettingsTables(db);
    }
    if (oldVersion < 3) {
      await _createDeletedRunSessionTable(db);
    }
    if (oldVersion < 4) {
      await _addColumnIfMissing(
        db,
        'run_shoes',
        'deleted INTEGER NOT NULL DEFAULT 0',
      );
    }
    if (oldVersion < 5) {
      await _addColumnIfMissing(db, 'run_shoes', 'image_path TEXT');
    }
    if (oldVersion < 6) {
      await _addColumnIfMissing(
        db,
        'run_sessions',
        "capture_source TEXT NOT NULL DEFAULT 'phoneGps'",
      );
    }
    if (oldVersion < 7) {
      await _addColumnIfMissing(db, 'run_points', 'cadence_spm REAL');
    }
    if (oldVersion < 8) {
      await _addColumnIfMissing(db, 'run_points', 'horizontal_accuracy_m REAL');
      await _addColumnIfMissing(db, 'run_points', 'speed_accuracy_mps REAL');
    }
    if (oldVersion < 9) {
      await _addColumnIfMissing(
        db,
        'run_sessions',
        'record_race_summary_json TEXT',
      );
      if (await _hasColumn(db, 'run_sessions', 'ghost_summary_json')) {
        await db.execute('''
UPDATE run_sessions
SET record_race_summary_json = ghost_summary_json
WHERE record_race_summary_json IS NULL
  AND ghost_summary_json IS NOT NULL
''');
      }
    }
  }

  Future<void> _createDeletedRunSessionTable(Database db) async {
    await db.execute('''
CREATE TABLE IF NOT EXISTS deleted_run_sessions (
  session_id TEXT PRIMARY KEY,
  record_source TEXT NOT NULL,
  external_id TEXT,
  started_at TEXT NOT NULL,
  duration_ms INTEGER NOT NULL,
  distance_m REAL NOT NULL,
  deleted_at TEXT NOT NULL
)
''');
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_deleted_run_sessions_external '
      'ON deleted_run_sessions(record_source, external_id)',
    );
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_deleted_run_sessions_started_at '
      'ON deleted_run_sessions(started_at)',
    );
  }

  Future<void> _createSettingsTables(Database db) async {
    await db.execute('''
CREATE TABLE IF NOT EXISTS app_settings (
  key TEXT PRIMARY KEY,
  value TEXT NOT NULL
)
''');
    await db.execute('''
CREATE TABLE IF NOT EXISTS run_shoes (
  id TEXT PRIMARY KEY,
  name TEXT NOT NULL,
  brand TEXT NOT NULL,
  distance_limit_km REAL NOT NULL,
  retired INTEGER NOT NULL,
  deleted INTEGER NOT NULL DEFAULT 0,
  image_path TEXT,
  created_at TEXT NOT NULL
)
''');
  }

  Future<void> _addColumnIfMissing(
    Database db,
    String table,
    String columnDefinition,
  ) async {
    try {
      await db.execute('ALTER TABLE $table ADD COLUMN $columnDefinition');
    } on DatabaseException catch (error) {
      if (!error.isDuplicateColumnError()) {
        rethrow;
      }
    }
  }

  Future<bool> _hasColumn(Database db, String table, String column) async {
    final rows = await db.rawQuery('PRAGMA table_info($table)');
    return rows.any((row) => row['name'] == column);
  }
}
