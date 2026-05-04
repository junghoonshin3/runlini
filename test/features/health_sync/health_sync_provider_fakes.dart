part of 'health_sync_providers_test.dart';

class _HealthRoute implements HealthRouteClient {
  _HealthRoute(this.sessions, {this.silentResult});

  final List<RunSession> sessions;
  final HealthRouteImportResult? silentResult;
  final List<bool> requestAuthorizationValues = <bool>[];

  @override
  Future<HealthRouteConnectionStatus> checkConnection() async =>
      const HealthRouteConnectionStatus.connected();

  @override
  Future<HealthRouteConnectionStatus> requestConnection() async =>
      const HealthRouteConnectionStatus.connected();

  @override
  Future<HealthRouteImportResult> importRecentSessions({
    required bool requestAuthorization,
  }) async {
    requestAuthorizationValues.add(requestAuthorization);
    if (!requestAuthorization && silentResult != null) {
      return silentResult!;
    }
    return HealthRouteImportResult.success(sessions);
  }
}

class _Repository implements RunSessionRepository {
  _Repository(this.sessions);

  final List<RunSession> sessions;
  final List<RunSession> deletedSessions = <RunSession>[];

  @override
  Future<void> deleteSession(String id) async {
    final session = await findById(id);
    if (session != null) {
      deletedSessions.add(session);
    }
    sessions.removeWhere((session) => session.id == id);
  }

  @override
  Future<RunSession?> findById(String id) async {
    return sessions.cast<RunSession?>().firstWhere(
      (session) => session?.id == id,
      orElse: () => null,
    );
  }

  @override
  Future<List<RunSession>> listSessions() async => sessions;

  @override
  Future<List<RunSessionSummary>> listSessionSummaries() async =>
      sessions.map(RunSessionSummary.fromSession).toList(growable: false);

  @override
  Future<void> saveSession(RunSession session) async {
    sessions.removeWhere((existing) => existing.id == session.id);
    sessions.add(session);
  }

  @override
  Future<bool> isDeletedExternalSession(RunSession session) async {
    for (final deleted in deletedSessions) {
      final sameExternalRecord =
          deleted.externalId != null &&
          session.externalId != null &&
          deleted.recordSource == session.recordSource &&
          deleted.externalId == session.externalId;
      if (deleted.id == session.id ||
          sameExternalRecord ||
          _isLikelySameSession(deleted, session)) {
        return true;
      }
    }
    return false;
  }

  bool _isLikelySameSession(RunSession deleted, RunSession imported) {
    final startDeltaMs = deleted.startedAt
        .difference(imported.startedAt)
        .inMilliseconds
        .abs();
    final durationDeltaMs = (deleted.durationMs - imported.durationMs).abs();
    final distanceDeltaM = (deleted.distanceM - imported.distanceM).abs();
    final distanceToleranceM = (deleted.distanceM * 0.05)
        .clamp(50, 250)
        .toDouble();
    return startDeltaMs <= const Duration(minutes: 2).inMilliseconds &&
        durationDeltaMs <= const Duration(minutes: 2).inMilliseconds &&
        distanceDeltaM <= distanceToleranceM;
  }
}
