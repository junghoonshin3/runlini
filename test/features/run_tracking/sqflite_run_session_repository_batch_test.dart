// 많은 러닝 포인트 저장을 검증하는 테스트
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

  test('persists many run points in order', () async {
    final tempDir = await Directory.systemTemp.createTemp('runlini-db-test');
    addTearDown(() => tempDir.delete(recursive: true));
    final database = RunliniDatabase(
      databaseFactory: databaseFactoryFfi,
      databasePath: p.join(tempDir.path, 'runlini.db'),
    );
    addTearDown(database.close);
    final repository = SqfliteRunSessionRepository(database: database);
    final points = List<RunPoint>.generate(
      720,
      (index) => RunPoint(
        latitude: 37.5 + index * 0.00001,
        longitude: 127.0 + index * 0.00001,
        timestampRelMs: index * 5000,
        paceSecPerKm: 330,
        speedMps: 3.03,
        source: RunPointSource.deviceGps,
      ),
    );

    await repository.saveSession(
      _session(id: 'many-points-run', points: points),
    );

    final saved = await repository.findById('many-points-run');

    expect(saved, isNotNull);
    expect(saved!.points, hasLength(points.length));
    expect(saved.points.first.timestampRelMs, 0);
    expect(saved.points[357].timestampRelMs, points[357].timestampRelMs);
    expect(saved.points.last.timestampRelMs, points.last.timestampRelMs);
    expect(saved.points.last.latitude, closeTo(points.last.latitude, 0.000001));
    expect(
      saved.points.last.longitude,
      closeTo(points.last.longitude, 0.000001),
    );
  });
}

RunSession _session({required String id, required List<RunPoint> points}) {
  final startedAt = DateTime.utc(2026, 4, 22, 6);
  return RunSession(
    id: id,
    startedAt: startedAt,
    endedAt: startedAt.add(const Duration(minutes: 10)),
    distanceM: 4000,
    durationMs: 600000,
    sourceSummary: 'device:gps',
    recordSource: RunSessionRecordSource.appLocal,
    syncStatus: RunSessionSyncStatus.localOnly,
    points: points,
  );
}
