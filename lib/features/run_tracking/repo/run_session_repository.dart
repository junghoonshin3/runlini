import 'package:runlini/features/run_tracking/types/run_session.dart';

abstract class RunSessionRepository {
  Future<void> saveSession(RunSession session);
  Future<void> deleteSession(String id);
  Future<RunSession?> findById(String id);
  Future<List<RunSession>> listSessions();
}
