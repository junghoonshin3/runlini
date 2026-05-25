import 'package:flutter_test/flutter_test.dart';
import 'package:runlini/features/run_tracking/repo/run_session_repository.dart';
import 'package:runlini/features/run_tracking/service/watch_run_session_import_service.dart';
import 'package:runlini/features/run_tracking/types/run_point.dart';
import 'package:runlini/features/run_tracking/types/run_session.dart';
import 'package:runlini/features/run_tracking/types/run_session_record_race_summary.dart';
import 'package:runlini/features/run_tracking/types/run_session_summary.dart';
import 'package:runlini/features/run_tracking/types/watch_run_draft.dart';
import 'package:runlini/features/run_tracking/types/watch_run_platform.dart';

void main() {
  test(
    'imports a Wear OS draft as an app-local watch-captured session',
    () async {
      final repository = _FakeRunSessionRepository();
      final service = WatchRunSessionImportService(repository: repository);

      final session = await service.importDraft(_draft());

      expect(session, isNotNull);
      expect(session!.recordSource, RunSessionRecordSource.appLocal);
      expect(session.captureSource, RunSessionCaptureSource.wearOs);
      expect(session.externalId, 'wear-workout-1');
      expect(session.sourceSummary, 'Wear OS · Galaxy Watch');
      expect(session.syncStatus, RunSessionSyncStatus.localOnly);
      expect(
        session.points.every((point) => point.source == RunPointSource.wearOs),
        isTrue,
      );
    },
  );

  test('updates an existing watch run instead of duplicating it', () async {
    final repository = _FakeRunSessionRepository();
    final service = WatchRunSessionImportService(repository: repository);

    final first = await service.importDraft(_draft(distanceM: 1000));
    final second = await service.importDraft(_draft(distanceM: 1200));

    expect(repository.sessions, hasLength(1));
    expect(second!.id, first!.id);
    expect(repository.sessions.single.distanceM, 1200);
  });

  test('imports optional recordRace summary from a Wear OS draft', () async {
    final repository = _FakeRunSessionRepository();
    final service = WatchRunSessionImportService(repository: repository);

    final session = await service.importDraft(
      _draft(
        recordRaceSummary: const RunSessionRecordRaceSummary(
          result: RunSessionRecordRaceResult.behind,
          timeGapMs: -8000,
          distanceGapM: -24,
          recordRaceSessionId: 'record-race-1',
          recordRaceLabel: '한강 5K',
        ),
      ),
    );

    expect(
      session?.recordRaceSummary?.result,
      RunSessionRecordRaceResult.behind,
    );
    expect(session?.recordRaceSummary?.recordRaceSessionId, 'record-race-1');
    expect(repository.sessions.single.recordRaceSummary?.timeGapMs, -8000);
  });

  test('skips a watch draft blocked by a local tombstone', () async {
    final repository = _FakeRunSessionRepository(
      deletedExternalIds: {'wear-workout-1'},
    );
    final service = WatchRunSessionImportService(repository: repository);

    final session = await service.importDraft(_draft());

    expect(session, isNull);
    expect(repository.sessions, isEmpty);
  });
}

WatchRunDraft _draft({
  double distanceM = 1000,
  RunSessionRecordRaceSummary? recordRaceSummary,
}) {
  return WatchRunDraft(
    id: 'wear-draft-1',
    platform: WatchRunPlatform.wearOs,
    startedAt: DateTime.utc(2026, 4, 28, 9),
    endedAt: DateTime.utc(2026, 4, 28, 9, 6),
    durationMs: 360000,
    distanceM: distanceM,
    externalWorkoutId: 'wear-workout-1',
    sourceDeviceName: 'Galaxy Watch',
    caloriesKcal: 70,
    recordRaceSummary: recordRaceSummary,
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

class _FakeRunSessionRepository implements RunSessionRepository {
  _FakeRunSessionRepository({Set<String> deletedExternalIds = const {}})
    : _deletedExternalIds = deletedExternalIds;

  final Set<String> _deletedExternalIds;
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
    return _deletedExternalIds.contains(session.externalId);
  }
}
