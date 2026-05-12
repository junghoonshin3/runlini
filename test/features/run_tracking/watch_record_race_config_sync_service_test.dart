import 'package:flutter_test/flutter_test.dart';
import 'package:runlini/core/wear/watch_record_race_config_client.dart';
import 'package:runlini/features/run_tracking/service/watch_record_race_config_sync_service.dart';
import 'package:runlini/features/run_tracking/types/run_point.dart';
import 'package:runlini/features/run_tracking/types/run_session.dart';
import 'package:runlini/features/run_tracking/types/watch_record_race_config.dart';

void main() {
  test('syncs the three most recent runnable sessions', () async {
    final client = _FakeWatchRecordRaceConfigClient();
    final service = WatchRecordRaceConfigSyncService(client: client);

    await service.syncRecentSessions([
      _session('old', startedAt: DateTime.utc(2026, 4, 1)),
      _session('recent-1', startedAt: DateTime.utc(2026, 4, 4)),
      _session('recent-2', startedAt: DateTime.utc(2026, 4, 3)),
      _session('recent-3', startedAt: DateTime.utc(2026, 4, 2)),
      _session(
        'no-route',
        startedAt: DateTime.utc(2026, 4, 5),
        points: const [],
      ),
    ]);

    expect(client.activeId, 'recent-1');
    expect(
      client.sentConfigs.map((WatchRecordRaceConfig config) => config.id),
      ['recent-1', 'recent-2', 'recent-3'],
    );
  });

  test(
    'keeps selected runnable session active even when it is older',
    () async {
      final client = _FakeWatchRecordRaceConfigClient();
      final service = WatchRecordRaceConfigSyncService(client: client);

      await service.syncRecentSessions([
        _session('selected', startedAt: DateTime.utc(2026, 4, 1)),
        _session('recent-1', startedAt: DateTime.utc(2026, 4, 4)),
        _session('recent-2', startedAt: DateTime.utc(2026, 4, 3)),
        _session('recent-3', startedAt: DateTime.utc(2026, 4, 2)),
      ], selectedSessionId: 'selected');

      expect(client.activeId, 'selected');
      expect(
        client.sentConfigs.map((WatchRecordRaceConfig config) => config.id),
        ['selected', 'recent-1', 'recent-2'],
      );
    },
  );

  test('sends an empty batch when no sessions can run on watch', () async {
    final client = _FakeWatchRecordRaceConfigClient();
    final service = WatchRecordRaceConfigSyncService(client: client);

    await service.syncRecentSessions([
      _session('no-route', points: const []),
      _session('one-point', points: [_point(0)]),
    ]);

    expect(client.activeId, isNull);
    expect(client.sentConfigs, isEmpty);
  });

  test('skips corrupt route candidates when syncing recent sessions', () async {
    final client = _FakeWatchRecordRaceConfigClient();
    final service = WatchRecordRaceConfigSyncService(client: client);

    await service.syncRecentSessions([
      _session('good', startedAt: DateTime.utc(2026, 4, 1)),
      _session(
        'zero-timestamps',
        startedAt: DateTime.utc(2026, 4, 4),
        points: [_point(0), _point(0)],
      ),
      _session(
        'bad-elevation',
        startedAt: DateTime.utc(2026, 4, 3),
        points: [
          _point(0),
          _point(600000, elevationM: double.maxFinite),
        ],
      ),
      _session(
        'split-world',
        startedAt: DateTime.utc(2026, 4, 2),
        points: [
          _point(0, latitude: 34.6684485, longitude: 135.4968788),
          _point(600000, latitude: 37.4222104, longitude: -122.084079),
        ],
      ),
    ]);

    expect(client.activeId, 'good');
    expect(
      client.sentConfigs.map((WatchRecordRaceConfig config) => config.id),
      ['good'],
    );
  });
}

RunSession _session(String id, {DateTime? startedAt, List<RunPoint>? points}) {
  return RunSession(
    id: id,
    startedAt: startedAt ?? DateTime.utc(2026, 4, 1),
    durationMs: 600000,
    distanceM: 2000,
    sourceSummary: 'test',
    points: points ?? [_point(0), _point(600000)],
  );
}

RunPoint _point(
  int timestampRelMs, {
  double? latitude,
  double? longitude,
  double? elevationM,
}) {
  return RunPoint(
    latitude: latitude ?? 37.0 + timestampRelMs / 1000000000,
    longitude: longitude ?? 127.0 + timestampRelMs / 1000000000,
    timestampRelMs: timestampRelMs,
    elevationM: elevationM,
    source: RunPointSource.deviceGps,
  );
}

class _FakeWatchRecordRaceConfigClient implements WatchRecordRaceConfigClient {
  String? activeId;
  List<WatchRecordRaceConfig> sentConfigs = const [];
  int clearCount = 0;

  @override
  Future<void> clearRecordRaceConfig() async {
    clearCount += 1;
  }

  @override
  Future<void> sendRecordRaceConfig(WatchRecordRaceConfig config) async {}

  @override
  Future<void> sendRecordRaceConfigs({
    required String? activeId,
    required List<WatchRecordRaceConfig> configs,
  }) async {
    this.activeId = activeId;
    sentConfigs = configs;
  }
}
