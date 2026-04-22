import 'package:runlini/features/run_tracking/types/run_session.dart';

abstract class HealthSyncService {
  Future<RunSession?> hydrateSession(RunSession primarySession);
  Future<List<RunSession>> importRecentSessions();
}
