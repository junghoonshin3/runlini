import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:runlini/core/wear/wear_draft_inbox_client.dart';
import 'package:runlini/features/run_tracking/repo/run_session_repository.dart';
import 'package:runlini/features/run_tracking/service/watch_run_session_import_service.dart';
import 'package:runlini/features/run_tracking/service/wear_draft_sync_service.dart';
import 'package:runlini/features/run_tracking/state/run_session_providers.dart';
import 'package:runlini/features/run_tracking/state/run_watch_providers.dart';
import 'package:runlini/features/run_tracking/types/run_point.dart';
import 'package:runlini/features/run_tracking/types/run_session.dart';
import 'package:runlini/features/run_tracking/types/run_session_summary.dart';
import 'package:runlini/features/run_tracking/types/watch_run_draft.dart';
import 'package:runlini/features/run_tracking/types/watch_run_platform.dart';

void main() {
  test('drains one Wear draft into a Wear OS captured run', () async {
    final repository = _FakeRunSessionRepository();
    final inbox = _FakeWearDraftInboxClient()
      ..add(WearDraftEnvelope(id: 'draft-1', draft: _draft()));
    final service = _service(repository: repository, inbox: inbox);

    final result = await service.syncPendingDrafts();

    expect(result.pendingCount, 1);
    expect(result.importedCount, 1);
    expect(result.ackedCount, 1);
    expect(inbox.ackedIds, <String>['draft-1']);
    expect(repository.sessions, hasLength(1));
    expect(
      repository.sessions.single.captureSource,
      RunSessionCaptureSource.wearOs,
    );
  });

  test('duplicate draft delivery updates the existing run', () async {
    final repository = _FakeRunSessionRepository();
    final inbox = _FakeWearDraftInboxClient()
      ..add(WearDraftEnvelope(id: 'draft-1', draft: _draft(distanceM: 1000)));
    final service = _service(repository: repository, inbox: inbox);

    await service.syncPendingDrafts();
    inbox.add(WearDraftEnvelope(id: 'draft-1', draft: _draft(distanceM: 1200)));
    await service.syncPendingDrafts();

    expect(repository.sessions, hasLength(1));
    expect(repository.sessions.single.distanceM, 1200);
    expect(inbox.ackedIds, <String>['draft-1', 'draft-1']);
  });

  test('failed native inbox call does not break startup sync', () async {
    final repository = _FakeRunSessionRepository();
    final inbox = _FakeWearDraftInboxClient()..failPending = true;
    final service = _service(repository: repository, inbox: inbox);

    final result = await service.syncPendingDrafts();

    expect(result.failedCount, 1);
    expect(repository.sessions, isEmpty);
  });

  test('controller manual sync invalidates history after import', () async {
    final repository = _FakeRunSessionRepository();
    final inbox = _FakeWearDraftInboxClient()
      ..add(WearDraftEnvelope(id: 'draft-1', draft: _draft()));
    final service = _service(repository: repository, inbox: inbox);
    var historyBuilds = 0;
    final container = ProviderContainer(
      overrides: [
        wearDraftSyncServiceProvider.overrideWithValue(service),
        runSessionListProvider.overrideWith((Ref ref) async {
          historyBuilds += 1;
          return const <RunSession>[];
        }),
      ],
    );
    addTearDown(container.dispose);

    await container.read(runSessionListProvider.future);
    final result = await container
        .read(wearDraftSyncControllerProvider.notifier)
        .syncPendingDrafts();
    await container.read(runSessionListProvider.future);

    expect(result.importedCount, 1);
    expect(historyBuilds, 2);
  });
}

WearDraftSyncService _service({
  required _FakeRunSessionRepository repository,
  required _FakeWearDraftInboxClient inbox,
}) {
  return WearDraftSyncService(
    inboxClient: inbox,
    importService: WatchRunSessionImportService(repository: repository),
  );
}

WatchRunDraft _draft({double distanceM = 1000}) {
  return WatchRunDraft(
    id: 'wear-draft-1',
    platform: WatchRunPlatform.wearOs,
    startedAt: DateTime.utc(2026, 4, 28, 9),
    endedAt: DateTime.utc(2026, 4, 28, 9, 6),
    durationMs: 360000,
    distanceM: distanceM,
    externalWorkoutId: 'wear-workout-1',
    sourceDeviceName: 'Wear emulator',
    caloriesKcal: 70,
    points: const <RunPoint>[
      RunPoint(
        latitude: 37.5,
        longitude: 127,
        timestampRelMs: 0,
        source: RunPointSource.deviceGps,
      ),
      RunPoint(
        latitude: 37.501,
        longitude: 127.001,
        timestampRelMs: 360000,
        source: RunPointSource.deviceGps,
      ),
    ],
  );
}

class _FakeWearDraftInboxClient implements WearDraftInboxClient {
  final List<WearDraftEnvelope> _pending = <WearDraftEnvelope>[];
  final List<String> ackedIds = <String>[];
  bool failPending = false;

  void add(WearDraftEnvelope envelope) {
    _pending.add(envelope);
  }

  @override
  Future<List<WearDraftEnvelope>> pendingWearDrafts() async {
    if (failPending) {
      throw StateError('native inbox unavailable');
    }
    return List<WearDraftEnvelope>.unmodifiable(_pending);
  }

  @override
  Future<void> ackWearDraft(String id) async {
    ackedIds.add(id);
    _pending.removeWhere((envelope) => envelope.id == id);
  }
}

class _FakeRunSessionRepository implements RunSessionRepository {
  final List<RunSession> sessions = <RunSession>[];

  @override
  Future<void> saveSession(RunSession session) async {
    sessions.removeWhere((existing) => existing.id == session.id);
    sessions.add(session);
  }

  @override
  Future<void> deleteSession(String id) async {
    sessions.removeWhere((session) => session.id == id);
  }

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
  Future<List<RunSession>> listSessions() async {
    return List<RunSession>.unmodifiable(sessions);
  }

  @override
  Future<List<RunSessionSummary>> listSessionSummaries() async =>
      sessions.map(RunSessionSummary.fromSession).toList(growable: false);

  @override
  Future<bool> isDeletedExternalSession(RunSession session) async {
    return false;
  }
}
