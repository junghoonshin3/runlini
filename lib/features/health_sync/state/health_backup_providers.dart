import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:runlini/core/health/health_workout_recorder.dart';
import 'package:runlini/features/health_sync/service/health_backup_service.dart';
import 'package:runlini/features/run_tracking/service/run_health_export_status_mapper.dart';
import 'package:runlini/features/run_tracking/state/run_session_providers.dart';
import 'package:runlini/features/run_tracking/types/run_session.dart';

final healthBackupServiceProvider = Provider<HealthBackupService>((Ref ref) {
  return HealthBackupService(
    recorder: ref.watch(healthWorkoutRecorderProvider),
    repository: ref.watch(runSessionRepositoryProvider),
    statusMapper: const RunHealthExportStatusMapper(),
  );
});

class HealthBackupController extends AsyncNotifier<HealthWorkoutExportResult?> {
  @override
  FutureOr<HealthWorkoutExportResult?> build() => null;

  Future<HealthWorkoutExportResult> retrySession(RunSession session) async {
    state = const AsyncValue<HealthWorkoutExportResult?>.loading();
    final result = await AsyncValue.guard(
      () => ref.read(healthBackupServiceProvider).backupSession(session),
    );
    if (result.hasValue) {
      _invalidateRunSessions(session.id);
      state = AsyncValue<HealthWorkoutExportResult?>.data(result.requireValue);
      return result.requireValue;
    }

    state = AsyncValue<HealthWorkoutExportResult?>.error(
      result.error!,
      result.stackTrace!,
    );
    return HealthWorkoutExportResult.failed(result.error.toString());
  }

  Future<int> retryFailedSessions() async {
    state = const AsyncValue<HealthWorkoutExportResult?>.loading();
    final result = await AsyncValue.guard(
      () => ref.read(healthBackupServiceProvider).retryFailedSessions(),
    );
    ref.invalidate(runSessionListProvider);
    ref.invalidate(runSessionSummaryListProvider);
    if (result.hasValue) {
      state = const AsyncValue<HealthWorkoutExportResult?>.data(null);
      return result.requireValue;
    }

    state = AsyncValue<HealthWorkoutExportResult?>.error(
      result.error!,
      result.stackTrace!,
    );
    return 0;
  }

  Future<int> backupUnsyncedAppSessions() async {
    state = const AsyncValue<HealthWorkoutExportResult?>.loading();
    final result = await AsyncValue.guard(
      () => ref.read(healthBackupServiceProvider).backupUnsyncedAppSessions(),
    );
    ref.invalidate(runSessionListProvider);
    ref.invalidate(runSessionSummaryListProvider);
    if (result.hasValue) {
      state = const AsyncValue<HealthWorkoutExportResult?>.data(null);
      return result.requireValue;
    }

    state = AsyncValue<HealthWorkoutExportResult?>.error(
      result.error!,
      result.stackTrace!,
    );
    return 0;
  }

  void _invalidateRunSessions(String id) {
    ref.invalidate(runSessionListProvider);
    ref.invalidate(runSessionSummaryListProvider);
    ref.invalidate(runSessionByIdProvider(id));
  }
}

final healthBackupControllerProvider =
    AsyncNotifierProvider<HealthBackupController, HealthWorkoutExportResult?>(
      HealthBackupController.new,
    );
