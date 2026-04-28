import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:runlini/core/health/health_route_client.dart';
import 'package:runlini/features/health_sync/state/health_sync_providers.dart';
import 'package:runlini/features/run_tracking/repo/run_session_repository.dart';
import 'package:runlini/features/run_tracking/state/run_session_providers.dart';
import 'package:runlini/features/run_tracking/types/run_point.dart';
import 'package:runlini/features/run_tracking/types/run_session.dart';

void main() {
  test(
    'history list hides fixture sessions but keeps saved app-local runs',
    () async {
      final local = _session(
        id: 'local',
        startedAt: DateTime.utc(2026, 4, 20, 6),
        sourceSummary: 'device:gps',
      );
      final fixture = _session(
        id: 'fixture',
        startedAt: DateTime.utc(2026, 4, 20, 5),
        sourceSummary: 'fixture:test',
      );
      final health = _session(
        id: 'healthconnect-1',
        startedAt: DateTime.utc(2026, 4, 20, 7),
        sourceSummary: 'Health Connect',
      );
      final container = ProviderContainer(
        overrides: [
          runSessionRepositoryProvider.overrideWithValue(
            _Repository([local, fixture]),
          ),
          healthRouteClientProvider.overrideWithValue(_HealthRoute([health])),
        ],
      );
      addTearDown(container.dispose);

      expect(
        (await container.read(runSessionListProvider.future)).map((s) => s.id),
        ['local'],
      );

      await container
          .read(healthSyncControllerProvider.notifier)
          .syncWithUserAction();

      expect(
        (await container.read(runSessionListProvider.future)).map((s) => s.id),
        ['healthconnect-1', 'local'],
      );
    },
  );
  test('matching app-local sessions are merged after health sync', () async {
    final startedAt = DateTime.utc(2026, 4, 20, 6);
    final local = _session(
      id: 'local',
      startedAt: startedAt,
      sourceSummary: 'device:gps',
    );
    final duplicate = _session(
      id: 'healthconnect-duplicate',
      startedAt: startedAt.add(const Duration(seconds: 30)),
      sourceSummary: 'Health Connect',
      recordSource: RunSessionRecordSource.healthConnect,
      externalId: 'external-1',
    );
    final repository = _Repository([local]);
    final container = ProviderContainer(
      overrides: [
        runSessionRepositoryProvider.overrideWithValue(repository),
        healthRouteClientProvider.overrideWithValue(_HealthRoute([duplicate])),
      ],
    );
    addTearDown(container.dispose);

    await container
        .read(healthSyncControllerProvider.notifier)
        .syncWithUserAction();

    final sessions = await container.read(runSessionListProvider.future);
    expect(sessions, hasLength(1));
    expect(sessions.single.id, 'local');
    expect(sessions.single.recordSource, RunSessionRecordSource.appLocal);
    expect(sessions.single.externalId, 'external-1');
    expect(sessions.single.syncStatus, RunSessionSyncStatus.synced);
  });

  test(
    'health sync does not restore a locally deleted health record',
    () async {
      final health = _session(
        id: 'healthconnect-deleted',
        startedAt: DateTime.utc(2026, 4, 20, 7),
        sourceSummary: 'Health Connect',
        recordSource: RunSessionRecordSource.healthConnect,
        externalId: 'external-deleted',
      );
      final repository = _Repository([health]);
      await repository.deleteSession(health.id);
      final container = ProviderContainer(
        overrides: [
          runSessionRepositoryProvider.overrideWithValue(repository),
          healthRouteClientProvider.overrideWithValue(_HealthRoute([health])),
        ],
      );
      addTearDown(container.dispose);

      await container
          .read(healthSyncControllerProvider.notifier)
          .syncWithUserAction();

      expect(await container.read(runSessionListProvider.future), isEmpty);
    },
  );

  test('health sync skips records matching a deleted app-local run', () async {
    final startedAt = DateTime.utc(2026, 4, 20, 6);
    final local = _session(
      id: 'local-deleted',
      startedAt: startedAt,
      sourceSummary: 'device:gps',
    );
    final imported = _session(
      id: 'healthconnect-restored',
      startedAt: startedAt.add(const Duration(seconds: 30)),
      sourceSummary: 'Health Connect',
      recordSource: RunSessionRecordSource.healthConnect,
      externalId: 'external-restored',
    );
    final repository = _Repository([local]);
    await repository.deleteSession(local.id);
    final container = ProviderContainer(
      overrides: [
        runSessionRepositoryProvider.overrideWithValue(repository),
        healthRouteClientProvider.overrideWithValue(_HealthRoute([imported])),
      ],
    );
    addTearDown(container.dispose);

    await container
        .read(healthSyncControllerProvider.notifier)
        .syncWithUserAction();

    expect(await container.read(runSessionListProvider.future), isEmpty);
  });

  test('startup sync skips when permission is not already granted', () async {
    final local = _session(
      id: 'local',
      startedAt: DateTime.utc(2026, 4, 20, 6),
      sourceSummary: 'device:gps',
    );
    final route = _HealthRoute([
      _session(id: 'health', startedAt: DateTime.utc(2026, 4, 20, 7)),
    ], silentResult: const HealthRouteImportResult.authorizationRequired());
    final container = ProviderContainer(
      overrides: [
        runSessionRepositoryProvider.overrideWithValue(_Repository([local])),
        healthRouteClientProvider.overrideWithValue(route),
      ],
    );
    addTearDown(container.dispose);

    await container
        .read(healthSyncControllerProvider.notifier)
        .syncIfAuthorized();

    expect(route.requestAuthorizationValues, [false]);
    expect(
      (await container.read(runSessionListProvider.future)).map((s) => s.id),
      ['local'],
    );
  });
}

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

RunSession _session({
  required String id,
  required DateTime startedAt,
  String sourceSummary = 'local',
  RunSessionRecordSource recordSource = RunSessionRecordSource.appLocal,
  String? externalId,
}) {
  return RunSession(
    id: id,
    startedAt: startedAt,
    endedAt: startedAt.add(const Duration(minutes: 10)),
    distanceM: 1000,
    durationMs: 600000,
    sourceSummary: sourceSummary,
    recordSource: recordSource,
    externalId: externalId,
    points: const <RunPoint>[
      RunPoint(
        latitude: 37.5,
        longitude: 127,
        timestampRelMs: 0,
        source: RunPointSource.simulated,
      ),
      RunPoint(
        latitude: 37.501,
        longitude: 127.001,
        timestampRelMs: 600000,
        source: RunPointSource.simulated,
      ),
    ],
  );
}
