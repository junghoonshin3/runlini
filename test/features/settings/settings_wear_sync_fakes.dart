part of 'settings_wear_sync_test.dart';

class _FakeWearDraftSyncService extends WearDraftSyncService {
  _FakeWearDraftSyncService(this.result)
    : super(
        inboxClient: _NoopWearDraftInboxClient(),
        importService: WatchRunSessionImportService(
          repository: _NoopRunSessionRepository(),
        ),
      );

  final WearDraftSyncResult result;
  int calls = 0;

  @override
  Future<WearDraftSyncResult> syncPendingDrafts() async {
    calls += 1;
    return result;
  }
}

class _NoopWearDraftInboxClient implements WearDraftInboxClient {
  @override
  Future<void> ackWearDraft(String id) async {}

  @override
  Future<List<WearDraftEnvelope>> pendingWearDrafts() async =>
      const <WearDraftEnvelope>[];
}

class _FakeWatchConnectionClient implements WatchConnectionClient {
  const _FakeWatchConnectionClient(this.status);

  final WatchConnectionStatus status;

  @override
  Future<WatchConnectionStatus> connectionStatus() async => status;
}

class _NoopRunSessionRepository implements RunSessionRepository {
  @override
  Future<void> deleteSession(String id) async {}

  @override
  Future<RunSession?> findById(String id) async => null;

  @override
  Future<bool> isDeletedExternalSession(RunSession session) async => false;

  @override
  Future<List<RunSession>> listSessions() async => const <RunSession>[];

  @override
  Future<List<RunSessionSummary>> listSessionSummaries() async =>
      const <RunSessionSummary>[];

  @override
  Future<void> saveSession(RunSession session) async {}
}

class _MemoryRunSessionRepository implements RunSessionRepository {
  const _MemoryRunSessionRepository(this.sessions);

  final List<RunSession> sessions;

  @override
  Future<void> deleteSession(String id) async {}

  @override
  Future<RunSession?> findById(String id) async {
    for (final session in sessions) {
      if (session.id == id) {
        return session;
      }
    }
    return null;
  }

  @override
  Future<bool> isDeletedExternalSession(RunSession session) async => false;

  @override
  Future<List<RunSession>> listSessions() async => sessions;

  @override
  Future<List<RunSessionSummary>> listSessionSummaries() async =>
      sessions.map(RunSessionSummary.fromSession).toList(growable: false);

  @override
  Future<void> saveSession(RunSession session) async {}
}

class _FakeRunSettingsRepository implements RunSettingsRepository {
  @override
  Future<void> deleteShoe(String id) async {}

  @override
  Future<RunSettingsState> loadSettings() async => const RunSettingsState();

  @override
  Future<List<RunShoe>> listShoes() async => const <RunShoe>[];

  @override
  Future<void> retireShoe(String id) async {}

  @override
  Future<void> saveSettings(RunSettingsState settings) async {}

  @override
  Future<void> saveShoe(RunShoe shoe) async {}
}

class _FakeWatchGhostConfigClient implements WatchGhostConfigClient {
  List<WatchGhostConfig> sentConfigs = const [];

  @override
  Future<void> clearGhostConfig() async {}

  @override
  Future<void> sendGhostConfig(WatchGhostConfig config) async {}

  @override
  Future<void> sendGhostConfigs({
    required String? activeId,
    required List<WatchGhostConfig> configs,
  }) async {
    sentConfigs = configs;
  }
}
