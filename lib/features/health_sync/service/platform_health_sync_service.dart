import 'package:runlini/core/health/health_route_client.dart';
import 'package:runlini/features/health_sync/service/health_sync_service.dart';
import 'package:runlini/features/health_sync/types/health_sync_status.dart';
import 'package:runlini/features/run_tracking/repo/run_session_repository.dart';
import 'package:runlini/features/run_tracking/types/run_session.dart';

class PlatformHealthSyncService implements HealthSyncService {
  const PlatformHealthSyncService({
    required HealthRouteClient routeClient,
    required RunSessionRepository repository,
    DateTime Function()? clock,
  }) : _routeClient = routeClient,
       _repository = repository,
       _clock = clock ?? DateTime.now;

  final HealthRouteClient _routeClient;
  final RunSessionRepository _repository;
  final DateTime Function() _clock;

  @override
  Future<RunSession?> hydrateSession(RunSession primarySession) async {
    return primarySession;
  }

  @override
  Future<HealthSyncStatus> syncRecentSessions({
    required bool requestAuthorization,
  }) async {
    final importResult = await _routeClient.importRecentSessions(
      requestAuthorization: requestAuthorization,
    );
    switch (importResult.status) {
      case HealthRouteImportStatus.success:
        final count = await _upsert(importResult.sessions);
        return HealthSyncStatus.synced(count);
      case HealthRouteImportStatus.authorizationRequired:
        return HealthSyncStatus.connectionNeeded(importResult.message);
      case HealthRouteImportStatus.unavailable:
        return HealthSyncStatus.unavailable(importResult.message);
      case HealthRouteImportStatus.failed:
        return HealthSyncStatus.failed(importResult.message);
    }
  }

  Future<int> _upsert(List<RunSession> importedSessions) async {
    final existingSessions = (await _repository.listSessions()).toList();
    var upsertedCount = 0;
    for (final imported in importedSessions) {
      if (await _repository.isDeletedExternalSession(imported)) {
        continue;
      }
      final match = _findMatch(imported, existingSessions);
      final merged = _merge(imported: imported, existing: match);
      await _repository.saveSession(merged);
      existingSessions.removeWhere((session) => session.id == merged.id);
      existingSessions.add(merged);
      upsertedCount += 1;
    }
    return upsertedCount;
  }

  RunSession? _findMatch(RunSession imported, List<RunSession> sessions) {
    for (final session in sessions) {
      if (_sameExternalRecord(session, imported) ||
          session.id == imported.id ||
          _isLikelySameSession(session, imported)) {
        return session;
      }
    }
    return null;
  }

  bool _sameExternalRecord(RunSession left, RunSession right) {
    return left.externalId != null &&
        right.externalId != null &&
        left.recordSource == right.recordSource &&
        left.externalId == right.externalId;
  }

  RunSession _merge({required RunSession imported, RunSession? existing}) {
    final base = _shouldKeepExistingDetail(existing, imported)
        ? existing!
        : imported;
    return base.copyWith(
      id: existing?.id ?? imported.id,
      sourceSummary: existing?.recordSource == RunSessionRecordSource.appLocal
          ? base.sourceSummary
          : imported.sourceSummary,
      averageCadenceSpm: imported.averageCadenceSpm ?? base.averageCadenceSpm,
      caloriesKcal: imported.caloriesKcal ?? base.caloriesKcal,
      recordSource: existing?.recordSource == RunSessionRecordSource.appLocal
          ? RunSessionRecordSource.appLocal
          : imported.recordSource,
      externalId: imported.externalId ?? existing?.externalId,
      lastSyncedAt: _clock(),
      syncStatus: RunSessionSyncStatus.synced,
      ghostSummary: existing?.ghostSummary ?? imported.ghostSummary,
    );
  }

  bool _shouldKeepExistingDetail(RunSession? existing, RunSession imported) {
    if (existing == null || existing.points.isEmpty) {
      return false;
    }
    return existing.recordSource == RunSessionRecordSource.appLocal &&
        existing.points.length >= imported.points.length;
  }

  bool _isLikelySameSession(RunSession local, RunSession imported) {
    final startDeltaMs = local.startedAt
        .difference(imported.startedAt)
        .inMilliseconds
        .abs();
    final durationDeltaMs = (local.durationMs - imported.durationMs).abs();
    final distanceDeltaM = (local.distanceM - imported.distanceM).abs();
    final distanceToleranceM = (local.distanceM * 0.05)
        .clamp(50, 250)
        .toDouble();
    return startDeltaMs <= const Duration(minutes: 2).inMilliseconds &&
        durationDeltaMs <= const Duration(minutes: 2).inMilliseconds &&
        distanceDeltaM <= distanceToleranceM;
  }
}
