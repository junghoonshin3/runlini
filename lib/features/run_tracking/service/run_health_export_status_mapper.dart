import 'package:runlini/core/health/health_workout_export_result.dart';
import 'package:runlini/features/run_tracking/types/run_session.dart';

class RunHealthExportStatusMapper {
  const RunHealthExportStatusMapper();

  RunSession apply({
    required RunSession session,
    required HealthWorkoutExportResult result,
    required DateTime now,
  }) {
    return switch (result.kind) {
      HealthWorkoutExportResultKind.synced => session.copyWith(
        externalId: result.externalId ?? session.externalId,
        lastSyncedAt: now,
        syncStatus: RunSessionSyncStatus.synced,
      ),
      HealthWorkoutExportResultKind.skipped => session.copyWith(
        syncStatus: RunSessionSyncStatus.syncSkipped,
      ),
      HealthWorkoutExportResultKind.failed => session.copyWith(
        syncStatus: RunSessionSyncStatus.syncFailed,
      ),
    };
  }
}
