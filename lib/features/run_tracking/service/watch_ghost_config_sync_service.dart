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

  Future<void> clear() {
    return _client.clearGhostConfig();
  }
}
