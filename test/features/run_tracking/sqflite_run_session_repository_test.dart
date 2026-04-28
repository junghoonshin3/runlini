import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:runlini/core/persistence/runlini_database.dart';
import 'package:runlini/features/run_tracking/repo/sqflite_run_session_repository.dart';
import 'package:runlini/features/run_tracking/types/run_point.dart';
import 'package:runlini/features/run_tracking/types/run_session.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  setUpAll(sqfliteFfiInit);

  test('persists app-local sessions across repository restarts', () async {
    final tempDir = await Directory.systemTemp.createTemp('runlini-db-test');
    addTearDown(() => tempDir.delete(recursive: true));
    final dbPath = p.join(tempDir.path, 'runlini.db');
    final session = _session(
      id: 'local-run',
      recordSource: RunSessionRecordSource.appLocal,
      captureSource: RunSessionCaptureSource.wearOs,
      syncStatus: RunSessionSyncStatus.localOnly,
    );

    final firstDb = RunliniDatabase(
      databaseFactory: databaseFactoryFfi,
      databasePath: dbPath,
    );
    await SqfliteRunSessionRepository(database: firstDb).saveSession(session);
    await firstDb.close();

    final secondDb = RunliniDatabase(
      databaseFactory: databaseFactoryFfi,
      databasePath: dbPath,
    );
    addTearDown(secondDb.close);

    final sessions = await SqfliteRunSessionRepository(
      database: secondDb,
    ).listSessions();

    expect(sessions, hasLength(1));
    expect(sessions.single.id, 'local-run');
    expect(sessions.single.points, hasLength(2));
    expect(sessions.single.recordSource, RunSessionRecordSource.appLocal);
    expect(sessions.single.captureSource, RunSessionCaptureSource.wearOs);
    expect(sessions.single.syncStatus, RunSessionSyncStatus.localOnly);
    expect(sessions.single.shoeId, 'shoe-1');
  });

  test('updates a health synced session without creating duplicates', () async {
    final tempDir = await Directory.systemTemp.createTemp('runlini-db-test');
    addTearDown(() => tempDir.delete(recursive: true));
    final database = RunliniDatabase(
      databaseFactory: databaseFactoryFfi,
      databasePath: p.join(tempDir.path, 'runlini.db'),
    );
    addTearDown(database.close);
    final repository = SqfliteRunSessionRepository(database: database);

    await repository.saveSession(_session(id: 'health-1', caloriesKcal: 80));
    await repository.saveSession(_session(id: 'health-1', caloriesKcal: 92));

    final sessions = await repository.listSessions();

    expect(sessions, hasLength(1));
    expect(sessions.single.caloriesKcal, 92);
  });

  test('deleted health sessions leave a marker for future imports', () async {
    final tempDir = await Directory.systemTemp.createTemp('runlini-db-test');
    addTearDown(() => tempDir.delete(recursive: true));
    final database = RunliniDatabase(
      databaseFactory: databaseFactoryFfi,
      databasePath: p.join(tempDir.path, 'runlini.db'),
    );
    addTearDown(database.close);
    final repository = SqfliteRunSessionRepository(database: database);
    final original = _session(id: 'health-1', externalId: 'external-health-1');
    final reimported = _session(
      id: 'health-1-from-health',
      externalId: 'external-health-1',
    );

    await repository.saveSession(original);
    await repository.deleteSession(original.id);

    expect(await repository.listSessions(), isEmpty);
    expect(await repository.isDeletedExternalSession(reimported), isTrue);
  });

  test(
    'deleted app-local sessions can block matching health imports',
    () async {
      final tempDir = await Directory.systemTemp.createTemp('runlini-db-test');
      addTearDown(() => tempDir.delete(recursive: true));
      final database = RunliniDatabase(
        databaseFactory: databaseFactoryFfi,
        databasePath: p.join(tempDir.path, 'runlini.db'),
      );
      addTearDown(database.close);
      final repository = SqfliteRunSessionRepository(database: database);
      final original = _session(
        id: 'local-1',
        recordSource: RunSessionRecordSource.appLocal,
        syncStatus: RunSessionSyncStatus.localOnly,
        clearExternalId: true,
      );
      final reimported = _session(
        id: 'health-1',
        externalId: 'external-health-1',
      );

      await repository.saveSession(original);
      await repository.deleteSession(original.id);

      expect(await repository.listSessions(), isEmpty);
      expect(await repository.isDeletedExternalSession(reimported), isTrue);
    },
  );
}

RunSession _session({
  required String id,
  RunSessionRecordSource recordSource = RunSessionRecordSource.healthConnect,
  RunSessionCaptureSource captureSource = RunSessionCaptureSource.phoneGps,
  RunSessionSyncStatus syncStatus = RunSessionSyncStatus.synced,
  double? caloriesKcal,
  String? externalId,
  bool clearExternalId = false,
}) {
  final startedAt = DateTime.utc(2026, 4, 22, 6);
  return RunSession(
    id: id,
    startedAt: startedAt,
    endedAt: startedAt.add(const Duration(minutes: 10)),
    distanceM: 1200,
    durationMs: 600000,
    sourceSummary: 'Health Connect',
    recordSource: recordSource,
    externalId: clearExternalId ? null : externalId ?? '$id-external',
    lastSyncedAt: DateTime.utc(2026, 4, 22, 7),
    syncStatus: syncStatus,
    shoeId: 'shoe-1',
    caloriesKcal: caloriesKcal,
    captureSource: captureSource,
    points: const <RunPoint>[
      RunPoint(
        latitude: 37.5,
        longitude: 127,
        timestampRelMs: 0,
        source: RunPointSource.healthConnect,
      ),
      RunPoint(
        latitude: 37.501,
        longitude: 127.001,
        timestampRelMs: 600000,
        source: RunPointSource.healthConnect,
      ),
    ],
  );
}
