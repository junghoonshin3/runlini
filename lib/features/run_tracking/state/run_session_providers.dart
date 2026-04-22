import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:runlini/core/fixtures/fake_run_fixture_loader.dart';
import 'package:runlini/features/run_tracking/repo/fixture_run_session_repository.dart';
import 'package:runlini/features/run_tracking/repo/run_session_repository.dart';
import 'package:runlini/features/run_tracking/types/run_session.dart';
import 'package:runlini/features/run_tracking/types/run_session_summary.dart';

final fakeRunFixtureLoaderProvider = Provider<FakeRunFixtureLoader>(
  (Ref ref) => const FakeRunFixtureLoader(),
);

final runSessionRepositoryProvider = Provider<RunSessionRepository>((Ref ref) {
  return FixtureRunSessionRepository(
    loader: ref.watch(fakeRunFixtureLoaderProvider),
  );
});

final runSessionListProvider = FutureProvider<List<RunSession>>((Ref ref) {
  return ref.watch(runSessionRepositoryProvider).listSessions();
});

final runSessionSummaryListProvider = FutureProvider<List<RunSessionSummary>>((
  Ref ref,
) async {
  final sessions = await ref.watch(runSessionListProvider.future);
  return sessions.map(RunSessionSummary.fromSession).toList(growable: false);
});
