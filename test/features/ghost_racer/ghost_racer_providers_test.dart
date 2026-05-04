import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:runlini/core/map/map_coordinate.dart';
import 'package:runlini/core/wear/watch_ghost_config_client.dart';
import 'package:runlini/features/ghost_racer/state/ghost_racer_providers.dart';
import 'package:runlini/features/run_tracking/repo/run_session_repository.dart';
import 'package:runlini/features/run_tracking/state/run_session_providers.dart';
import 'package:runlini/features/run_tracking/state/run_watch_providers.dart';
import 'package:runlini/features/run_tracking/types/run_point.dart';
import 'package:runlini/features/run_tracking/types/run_session.dart';
import 'package:runlini/features/run_tracking/types/run_session_summary.dart';
import 'package:runlini/features/run_tracking/types/watch_ghost_config.dart';

void main() {
  test('builds ghost polyline points from the selected session id', () async {
    final session = RunSession(
      id: 'ghost-selected',
      startedAt: DateTime.utc(2026, 4, 19, 6, 30),
      endedAt: DateTime.utc(2026, 4, 19, 6, 42),
      distanceM: 2400,
      durationMs: 720000,
      sourceSummary: 'device:gps',
      points: const [
        RunPoint(
          latitude: 37.0,
          longitude: 127.0,
          timestampRelMs: 0,
          paceSecPerKm: 300,
          source: RunPointSource.simulated,
        ),
        RunPoint(
          latitude: 37.0002,
          longitude: 127.0002,
          timestampRelMs: 1000,
          paceSecPerKm: 300,
          source: RunPointSource.simulated,
        ),
      ],
    );
    final summary = RunSessionSummary.fromSession(session);
    final container = ProviderContainer(
      overrides: [
        runSessionRepositoryProvider.overrideWithValue(_Repository([session])),
      ],
    );
    addTearDown(container.dispose);

    container.read(ghostSettingsProvider.notifier).selectSession(summary);
    final polylinePoints = await container.read(
      selectedGhostPolylinePointsProvider.future,
    );

    expect(polylinePoints, hasLength(2));
    expect(
      polylinePoints.first,
      const MapCoordinate(latitude: 37.0, longitude: 127.0),
    );
  });

  test('syncs selected ghost session to the watch config client', () async {
    final session = _session();
    final client = _FakeWatchGhostConfigClient();
    final container = ProviderContainer(
      overrides: [
        runSessionRepositoryProvider.overrideWithValue(_Repository([session])),
        watchGhostConfigClientProvider.overrideWithValue(client),
      ],
    );
    addTearDown(container.dispose);

    container
        .read(ghostSettingsProvider.notifier)
        .selectSession(RunSessionSummary.fromSession(session));
    await pumpEventQueue();

    expect(client.activeId, 'ghost-selected');
    expect(client.sentConfigs.single.id, 'ghost-selected');
  });

  test(
    'refreshes recent watch ghost configs when ghost mode is disabled',
    () async {
      final client = _FakeWatchGhostConfigClient();
      final container = ProviderContainer(
        overrides: [
          runSessionRepositoryProvider.overrideWithValue(
            _Repository([_session()]),
          ),
          watchGhostConfigClientProvider.overrideWithValue(client),
        ],
      );
      addTearDown(container.dispose);

      container.read(ghostSettingsProvider.notifier).disable();
      await pumpEventQueue();

      expect(client.clearCount, 0);
      expect(client.sentConfigs.single.id, 'ghost-selected');
    },
  );
}

RunSession _session() {
  return RunSession(
    id: 'ghost-selected',
    startedAt: DateTime.utc(2026, 4, 19, 6, 30),
    endedAt: DateTime.utc(2026, 4, 19, 6, 42),
    distanceM: 2400,
    durationMs: 720000,
    sourceSummary: 'device:gps',
    points: const [
      RunPoint(
        latitude: 37.0,
        longitude: 127.0,
        timestampRelMs: 0,
        paceSecPerKm: 300,
        source: RunPointSource.simulated,
      ),
      RunPoint(
        latitude: 37.0002,
        longitude: 127.0002,
        timestampRelMs: 1000,
        paceSecPerKm: 300,
        source: RunPointSource.simulated,
      ),
    ],
  );
}

class _Repository implements RunSessionRepository {
  const _Repository(this.sessions);

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

class _FakeWatchGhostConfigClient implements WatchGhostConfigClient {
  WatchGhostConfig? sentConfig;
  String? activeId;
  List<WatchGhostConfig> sentConfigs = const [];
  int clearCount = 0;

  @override
  Future<void> sendGhostConfig(WatchGhostConfig config) async {
    sentConfig = config;
  }

  @override
  Future<void> sendGhostConfigs({
    required String? activeId,
    required List<WatchGhostConfig> configs,
  }) async {
    this.activeId = activeId;
    sentConfigs = configs;
  }

  @override
  Future<void> clearGhostConfig() async {
    clearCount += 1;
  }
}
