import 'package:runlini/core/wear/watch_ghost_config_client.dart';
import 'package:runlini/features/run_tracking/types/run_session.dart';
import 'package:runlini/features/run_tracking/types/watch_ghost_config.dart';

class WatchGhostConfigSyncService {
  const WatchGhostConfigSyncService({required WatchGhostConfigClient client})
    : _client = client;

  final WatchGhostConfigClient _client;

  Future<void> syncSession(RunSession? session) async {
    if (session == null) {
      await clear();
      return;
    }

    final config = WatchGhostConfig.fromSession(session);
    if (!config.canRunOnWatch) {
      await clear();
      return;
    }

    await _client.sendGhostConfig(config);
  }

  Future<void> syncRecentSessions(
    List<RunSession> sessions, {
    String? selectedSessionId,
  }) async {
    final runnableConfigs =
        sessions
            .map(WatchGhostConfig.fromSession)
            .where((WatchGhostConfig config) => config.canRunOnWatch)
            .toList(growable: false)
          ..sort((WatchGhostConfig left, WatchGhostConfig right) {
            return right.startedAt.compareTo(left.startedAt);
          });
    final selectedConfig = selectedSessionId == null
        ? null
        : _firstWhereOrNull(
            runnableConfigs,
            (WatchGhostConfig config) => config.id == selectedSessionId,
          );
    final configs = <WatchGhostConfig>[
      ...(selectedConfig == null
          ? const <WatchGhostConfig>[]
          : <WatchGhostConfig>[selectedConfig]),
      ...runnableConfigs.where(
        (WatchGhostConfig config) => config.id != selectedConfig?.id,
      ),
    ].take(3).toList(growable: false);
    final activeId =
        selectedConfig?.id ?? (configs.isEmpty ? null : configs.first.id);

    await _client.sendGhostConfigs(activeId: activeId, configs: configs);
  }

  Future<void> clear() {
    return _client.clearGhostConfig();
  }
}

WatchGhostConfig? _firstWhereOrNull(
  List<WatchGhostConfig> configs,
  bool Function(WatchGhostConfig config) test,
) {
  for (final config in configs) {
    if (test(config)) {
      return config;
    }
  }
  return null;
}
