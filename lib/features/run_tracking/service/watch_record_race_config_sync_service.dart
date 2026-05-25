import 'package:runlini/core/wear/watch_record_race_config_client.dart';
import 'package:runlini/features/run_tracking/types/run_session.dart';
import 'package:runlini/features/run_tracking/types/watch_record_race_config.dart';

class WatchRecordRaceConfigSyncService {
  const WatchRecordRaceConfigSyncService({
    required WatchRecordRaceConfigClient client,
  }) : _client = client;

  final WatchRecordRaceConfigClient _client;

  Future<void> syncSession(RunSession? session) async {
    if (session == null) {
      await clear();
      return;
    }

    final config = WatchRecordRaceConfig.fromSession(session);
    if (!config.canRunOnWatch) {
      await clear();
      return;
    }

    await _client.sendRecordRaceConfig(config);
  }

  Future<void> syncRecentSessions(
    List<RunSession> sessions, {
    String? selectedSessionId,
  }) async {
    final runnableConfigs =
        sessions
            .map(WatchRecordRaceConfig.fromSession)
            .where((WatchRecordRaceConfig config) => config.canRunOnWatch)
            .toList(growable: false)
          ..sort((WatchRecordRaceConfig left, WatchRecordRaceConfig right) {
            return right.startedAt.compareTo(left.startedAt);
          });
    final selectedConfig = selectedSessionId == null
        ? null
        : _firstWhereOrNull(
            runnableConfigs,
            (WatchRecordRaceConfig config) => config.id == selectedSessionId,
          );
    final configs = <WatchRecordRaceConfig>[
      ...(selectedConfig == null
          ? const <WatchRecordRaceConfig>[]
          : <WatchRecordRaceConfig>[selectedConfig]),
      ...runnableConfigs.where(
        (WatchRecordRaceConfig config) => config.id != selectedConfig?.id,
      ),
    ].take(3).toList(growable: false);
    final activeId =
        selectedConfig?.id ?? (configs.isEmpty ? null : configs.first.id);

    await _client.sendRecordRaceConfigs(activeId: activeId, configs: configs);
  }

  Future<void> clear() {
    return _client.clearRecordRaceConfig();
  }
}

WatchRecordRaceConfig? _firstWhereOrNull(
  List<WatchRecordRaceConfig> configs,
  bool Function(WatchRecordRaceConfig config) test,
) {
  for (final config in configs) {
    if (test(config)) {
      return config;
    }
  }
  return null;
}
