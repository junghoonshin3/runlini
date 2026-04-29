import 'package:flutter_test/flutter_test.dart';
import 'package:runlini/features/health_sync/service/health_backup_service.dart';
import 'package:runlini/features/run_tracking/service/run_health_export_status_mapper.dart';
import 'package:runlini/features/run_tracking/types/run_point.dart';
import 'package:runlini/features/run_tracking/types/run_session.dart';

import '../../helpers/runlini_widget_harness.dart';

void main() {
  test('retryFailedSessions only retries failed app-local records', () async {
    final repository = FakeRunSessionRepository([
      _session(id: 'local-failed', syncStatus: RunSessionSyncStatus.syncFailed),
      _session(
        id: 'health-failed',
        recordSource: RunSessionRecordSource.healthConnect,
        syncStatus: RunSessionSyncStatus.syncFailed,
      ),
      _session(
        id: 'local-skipped',
        syncStatus: RunSessionSyncStatus.syncSkipped,
      ),
    ]);
    final recorder = FakeHealthWorkoutRecorder();
    final service = HealthBackupService(
      recorder: recorder,
      repository: repository,
      statusMapper: const RunHealthExportStatusMapper(),
      clock: () => DateTime(2026, 4, 20, 8),
    );

    final syncedCount = await service.retryFailedSessions();

    expect(syncedCount, 1);
    expect(recorder.finishCalls, 1);
    expect(
      (await repository.findById('local-failed'))!.syncStatus,
      RunSessionSyncStatus.synced,
    );
    expect(
      (await repository.findById('health-failed'))!.syncStatus,
      RunSessionSyncStatus.syncFailed,
    );
    expect(
      (await repository.findById('local-skipped'))!.syncStatus,
      RunSessionSyncStatus.syncSkipped,
    );
  });
}

RunSession _session({
  required String id,
  RunSessionRecordSource recordSource = RunSessionRecordSource.appLocal,
  RunSessionSyncStatus syncStatus = RunSessionSyncStatus.localOnly,
}) {
  final startedAt = DateTime(2026, 4, 20, 7);
  return RunSession(
    id: id,
    startedAt: startedAt,
    endedAt: startedAt.add(const Duration(minutes: 10)),
    distanceM: 1000,
    durationMs: 600000,
    sourceSummary: 'test',
    recordSource: recordSource,
    syncStatus: syncStatus,
    points: const <RunPoint>[
      RunPoint(
        latitude: 37.51,
        longitude: 127.01,
        timestampRelMs: 0,
        source: RunPointSource.deviceGps,
      ),
      RunPoint(
        latitude: 37.52,
        longitude: 127.02,
        timestampRelMs: 600000,
        source: RunPointSource.deviceGps,
      ),
    ],
  );
}
