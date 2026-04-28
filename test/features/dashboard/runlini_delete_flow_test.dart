import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:runlini/app/runlini_app.dart';
import 'package:runlini/core/health/health_route_client.dart';
import 'package:runlini/core/health/health_workout_deleter.dart';
import 'package:runlini/core/location/location_stream_client.dart';
import 'package:runlini/features/health_sync/state/health_sync_providers.dart';
import 'package:runlini/features/run_tracking/state/run_session_providers.dart';
import 'package:runlini/features/run_tracking/types/run_point.dart';
import 'package:runlini/features/run_tracking/types/run_session.dart';

import '../../helpers/runlini_widget_harness.dart';

void main() {
  testWidgets('deletes a run locally by default', (WidgetTester tester) async {
    final repository = FakeRunSessionRepository();
    final healthDeleter = _FakeHealthWorkoutDeleter();
    await _pumpImportedHealthRun(tester, repository, healthDeleter);
    await _openDeleteDialog(tester);

    expect(find.text('기록을 삭제할까요?'), findsOneWidget);
    expect(
      find.byKey(const Key('delete-health-source-checkbox')),
      findsOneWidget,
    );

    await tester.tap(find.byKey(const Key('confirm-delete-run-button')));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    expect(repository.savedSessions, isEmpty);
    expect(healthDeleter.deleteCalls, 0);
  });

  testWidgets('can permanently delete a synced run from Health', (
    WidgetTester tester,
  ) async {
    final repository = FakeRunSessionRepository();
    final healthDeleter = _FakeHealthWorkoutDeleter();
    await _pumpImportedHealthRun(tester, repository, healthDeleter);
    await _openDeleteDialog(tester);

    await tester.tap(find.byKey(const Key('delete-health-source-checkbox')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('confirm-delete-run-button')));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    expect(repository.savedSessions, isEmpty);
    expect(healthDeleter.deleteCalls, 1);
    expect(healthDeleter.lastExternalId, 'healthconnect-widget');
  });
}

Future<void> _pumpImportedHealthRun(
  WidgetTester tester,
  FakeRunSessionRepository repository,
  _FakeHealthWorkoutDeleter healthDeleter,
) async {
  await tester.binding.setSurfaceSize(const Size(1100, 800));
  addTearDown(() => tester.binding.setSurfaceSize(null));
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        disableStartupWeightPromptOverride,
        runSessionRepositoryProvider.overrideWithValue(repository),
        healthWorkoutDeleterProvider.overrideWithValue(healthDeleter),
        healthRouteClientProvider.overrideWithValue(
          _HealthRoute([_healthSession()]),
        ),
        locationStreamClientProvider.overrideWithValue(
          const SilentLocationStreamClient(),
        ),
      ],
      child: const RunliniApp(),
    ),
  );
  await pumpUntilFound(tester, find.byKey(const Key('history-list')));
  final restoreButton = find.byKey(const Key('health-restore-settings-button'));
  await tester.ensureVisible(restoreButton);
  await tester.pumpAndSettle();
  await tester.tap(restoreButton);
  await pumpUntilFound(
    tester,
    find.byKey(const Key('history-session-healthconnect-widget')),
  );
}

Future<void> _openDeleteDialog(WidgetTester tester) async {
  final sessionTile = find.byKey(
    const Key('history-session-healthconnect-widget'),
  );
  await tester.ensureVisible(sessionTile);
  await tester.pumpAndSettle();
  await tester.tap(sessionTile);
  await pumpUntilFound(
    tester,
    find.byKey(const Key('run-finish-review-panel')),
  );
  await tester.tap(find.byKey(const Key('run-detail-more-button')));
  await tester.pumpAndSettle();
}

class _HealthRoute implements HealthRouteClient {
  const _HealthRoute(this.sessions);

  final List<RunSession> sessions;

  @override
  Future<HealthRouteImportResult> importRecentSessions({
    required bool requestAuthorization,
  }) async {
    if (!requestAuthorization) {
      return const HealthRouteImportResult.authorizationRequired();
    }
    return HealthRouteImportResult.success(sessions);
  }
}

class _FakeHealthWorkoutDeleter implements HealthWorkoutDeleter {
  int deleteCalls = 0;
  String? lastExternalId;

  @override
  Future<bool> deleteWorkout({
    required String? externalId,
    required DateTime startedAt,
    required DateTime endedAt,
  }) async {
    deleteCalls += 1;
    lastExternalId = externalId;
    return true;
  }
}

RunSession _healthSession() {
  final startedAt = DateTime.utc(2026, 4, 21, 7);
  return RunSession(
    id: 'healthconnect-widget',
    startedAt: startedAt,
    endedAt: startedAt.add(const Duration(minutes: 8)),
    distanceM: 1200,
    durationMs: 480000,
    sourceSummary: 'Health Connect',
    caloriesKcal: 90,
    recordSource: RunSessionRecordSource.healthConnect,
    externalId: 'healthconnect-widget',
    points: const <RunPoint>[
      RunPoint(
        latitude: 37.51,
        longitude: 127.01,
        timestampRelMs: 0,
        source: RunPointSource.healthConnect,
      ),
      RunPoint(
        latitude: 37.512,
        longitude: 127.012,
        timestampRelMs: 480000,
        source: RunPointSource.healthConnect,
      ),
    ],
  );
}
