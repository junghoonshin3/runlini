import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:runlini/core/fixtures/fake_run_fixture_loader.dart';
import 'package:runlini/core/performance/startup_trace.dart';
import 'package:runlini/core/persistence/runlini_database.dart';
import 'package:runlini/features/run_tracking/repo/run_session_repository.dart';
import 'package:runlini/features/run_tracking/repo/sqflite_run_session_repository.dart';
import 'package:runlini/features/run_tracking/types/run_session.dart';
import 'package:runlini/features/run_tracking/types/run_session_summary.dart';

final fakeRunFixtureLoaderProvider = Provider<FakeRunFixtureLoader>(
  (Ref ref) => const FakeRunFixtureLoader(),
);

final runliniDatabaseProvider = Provider<RunliniDatabase>((Ref ref) {
  final database = RunliniDatabase();
  ref.onDispose(database.close);
  return database;
});

final runSessionRepositoryProvider = Provider<RunSessionRepository>((Ref ref) {
  return SqfliteRunSessionRepository(
    database: ref.watch(runliniDatabaseProvider),
  );
});

final runSessionListProvider = FutureProvider<List<RunSession>>((
  Ref ref,
) async {
  final sessions = await StartupTrace.measure(
    'full session list load',
    () => ref.watch(runSessionRepositoryProvider).listSessions(),
  );
  final visibleSessions = sessions.where(_isUserVisibleLocalSession).toList()
    ..sort((left, right) => right.startedAt.compareTo(left.startedAt));
  return List<RunSession>.unmodifiable(visibleSessions);
});

final runSessionSummaryListProvider = FutureProvider<List<RunSessionSummary>>((
  Ref ref,
) async {
  final summaries = await StartupTrace.measure(
    'session summary list load',
    () => ref.watch(runSessionRepositoryProvider).listSessionSummaries(),
  );
  final visibleSummaries =
      summaries
          .where((summary) => !summary.sourceSummary.startsWith('fixture:'))
          .toList()
        ..sort((left, right) => right.startedAt.compareTo(left.startedAt));
  return List<RunSessionSummary>.unmodifiable(visibleSummaries);
});

final runSessionByIdProvider = FutureProvider.family<RunSession?, String>((
  Ref ref,
  String id,
) async {
  return StartupTrace.measure(
    'session detail load',
    () => ref.watch(runSessionRepositoryProvider).findById(id),
  );
});

bool _isUserVisibleLocalSession(RunSession session) {
  return !session.sourceSummary.startsWith('fixture:');
}
