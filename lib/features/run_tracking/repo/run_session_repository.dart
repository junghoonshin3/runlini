import 'package:runlini/features/run_tracking/types/run_session.dart';
import 'package:runlini/features/run_tracking/types/run_session_summary.dart';

abstract class RunSessionRepository {
  Future<void> saveSession(RunSession session);
  Future<void> deleteSession(String id);
  Future<RunSession?> findById(String id);
  Future<List<RunSession>> listSessions();
  Future<List<RunSessionSummary>> listSessionSummaries() async {
    final sessions = await listSessions();
    return sessions.map(RunSessionSummary.fromSession).toList(growable: false);
  }

  Future<bool> isDeletedExternalSession(RunSession session) async => false;
}
