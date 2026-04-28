import 'package:runlini/features/health_sync/types/health_sync_status.dart';
import 'package:runlini/features/run_tracking/types/run_session.dart';

abstract class HealthSyncService {
  Future<RunSession?> hydrateSession(RunSession primarySession);
  Future<HealthSyncStatus> syncRecentSessions({
    required bool requestAuthorization,
  });
}
