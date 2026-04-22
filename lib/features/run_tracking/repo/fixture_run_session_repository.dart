import 'package:runlini/core/fixtures/fake_run_fixture_loader.dart';
import 'package:runlini/features/run_tracking/repo/run_session_repository.dart';
import 'package:runlini/features/run_tracking/types/run_session.dart';

class FixtureRunSessionRepository implements RunSessionRepository {
  FixtureRunSessionRepository({required FakeRunFixtureLoader loader})
    : _loader = loader;

  final FakeRunFixtureLoader _loader;
  List<RunSession>? _cachedSessions;

  @override
  Future<RunSession?> findById(String id) async {
    final sessions = await listSessions();
    for (final session in sessions) {
      if (session.id == id) {
        return session;
      }
    }

    return null;
  }

  @override
  Future<List<RunSession>> listSessions() async {
    final sessions = _cachedSessions ??= await _loader.loadAll();
    sessions.sort(
      (RunSession left, RunSession right) =>
          right.startedAt.compareTo(left.startedAt),
    );
    return List<RunSession>.unmodifiable(sessions);
  }

  @override
  Future<void> saveSession(RunSession session) async {
    final sessions = List<RunSession>.from(await listSessions());
    sessions.removeWhere((existing) => existing.id == session.id);
    sessions.add(session);
    sessions.sort(
      (RunSession left, RunSession right) =>
          right.startedAt.compareTo(left.startedAt),
    );
    _cachedSessions = sessions;
  }

  @override
  Future<void> deleteSession(String id) async {
    final sessions = List<RunSession>.from(await listSessions());
    sessions.removeWhere((existing) => existing.id == id);
    _cachedSessions = sessions;
  }
}
