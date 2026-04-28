import 'package:flutter/foundation.dart';
import 'package:runlini/core/health/health_workout_recorder.dart';
import 'package:runlini/features/run_tracking/repo/run_session_repository.dart';
import 'package:runlini/features/run_tracking/service/run_health_export_status_mapper.dart';
import 'package:runlini/features/run_tracking/types/run_session.dart';

class HealthBackupService {
  const HealthBackupService({
    required HealthWorkoutRecorder recorder,
    required RunSessionRepository repository,
    required RunHealthExportStatusMapper statusMapper,
    DateTime Function()? clock,
  }) : _recorder = recorder,
       _repository = repository,
       _statusMapper = statusMapper,
       _clock = clock ?? DateTime.now;

  final HealthWorkoutRecorder _recorder;
  final RunSessionRepository _repository;
  final RunHealthExportStatusMapper _statusMapper;
  final DateTime Function() _clock;

  Future<HealthWorkoutExportResult> backupSession(RunSession session) async {
    final preparation = await _prepare();
    if (preparation != HealthRunPreparationResult.ready) {
      final result = HealthWorkoutExportResult.skipped(
        _preparationMessage(preparation),
      );
      await _saveExportStatus(session, result);
      return result;
    }

    try {
      await _recorder.beginRunCapture();
      final result = await _recorder.finishRunCapture(
        startedAt: session.startedAt,
        endedAt: _endedAt(session),
        recordedPoints: session.points,
      );
      await _saveExportStatus(session, result);
      return result;
    } catch (error) {
      debugPrint('Runlini health backup retry failed: $error');
      final result = HealthWorkoutExportResult.failed(error.toString());
      await _saveExportStatus(session, result);
      return result;
    }
  }

  Future<int> retryFailedSessions() async {
    final sessions = await _repository.listSessions();
    var syncedCount = 0;
    for (final session in sessions) {
      if (session.syncStatus != RunSessionSyncStatus.syncFailed) {
        continue;
      }
      final result = await backupSession(session);
      if (result.kind == HealthWorkoutExportResultKind.synced) {
        syncedCount += 1;
      }
    }
    return syncedCount;
  }

  Future<int> backupUnsyncedAppSessions() async {
    final sessions = await _repository.listSessions();
    var syncedCount = 0;
    for (final session in sessions) {
      if (session.recordSource != RunSessionRecordSource.appLocal ||
          session.syncStatus == RunSessionSyncStatus.synced) {
        continue;
      }
      final result = await backupSession(session);
      if (result.kind == HealthWorkoutExportResultKind.synced) {
        syncedCount += 1;
      }
    }
    return syncedCount;
  }

  Future<HealthRunPreparationResult> _prepare() async {
    try {
      return _recorder.prepareRunCapture();
    } catch (error) {
      debugPrint('Runlini health backup preparation failed: $error');
      return HealthRunPreparationResult.unavailable;
    }
  }

  Future<void> _saveExportStatus(
    RunSession session,
    HealthWorkoutExportResult result,
  ) async {
    final updated = _statusMapper.apply(
      session: session,
      result: result,
      now: _clock(),
    );
    await _repository.saveSession(updated);
  }

  DateTime _endedAt(RunSession session) {
    return session.endedAt ??
        session.startedAt.add(Duration(milliseconds: session.durationMs));
  }

  String _preparationMessage(HealthRunPreparationResult result) {
    return switch (result) {
      HealthRunPreparationResult.ready => 'Health backup is ready.',
      HealthRunPreparationResult.installRequired =>
        'Health Connect installation is required.',
      HealthRunPreparationResult.unavailable =>
        'Health backup is unavailable on this device.',
      HealthRunPreparationResult.permissionDenied =>
        'Health backup permission was denied.',
    };
  }
}
