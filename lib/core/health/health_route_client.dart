import 'package:runlini/features/run_tracking/types/run_session.dart';

abstract class HealthRouteClient {
  Future<List<RunSession>> importRecentSessions();
}
