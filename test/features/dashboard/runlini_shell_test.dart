import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:runlini/app/runlini_app.dart';
import 'package:runlini/core/health/health_route_client.dart';
import 'package:runlini/core/location/location_stream_client.dart';
import 'package:runlini/features/health_sync/state/health_sync_providers.dart';
import 'package:runlini/features/run_tracking/state/run_session_providers.dart';
import 'package:runlini/features/run_tracking/types/run_point.dart';
import 'package:runlini/features/run_tracking/types/run_session.dart';

import '../../helpers/runlini_widget_harness.dart';

void main() {
  testWidgets('switches between history, running, and settings tabs', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          disableStartupWeightPromptOverride,
          runSessionRepositoryProvider.overrideWithValue(
            FakeRunSessionRepository(),
          ),
          locationStreamClientProvider.overrideWithValue(
            const SilentLocationStreamClient(),
          ),
        ],
        child: const RunliniApp(),
      ),
    );
    await pumpUntilFound(tester, find.byKey(const Key('history-list')));

    expect(find.byKey(const Key('history-list')), findsOneWidget);
    expect(find.byKey(const Key('history-settings-button')), findsNothing);
    expect(
      find.byKey(const Key('history-session-fixture_morning_tempo')),
      findsNothing,
    );
    expect(find.byKey(const Key('health-settings-button')), findsNothing);

    await tester.tap(find.byKey(const Key('history-change-goals-button')));
    await pumpUntilFound(tester, find.byKey(const Key('settings-tab-screen')));

    expect(find.byKey(const Key('settings-tab-screen')), findsOneWidget);
    expect(find.text('위치 업데이트'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('기록 목표와 표시'),
      160,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    expect(find.text('기록 목표와 표시'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.directions_run_rounded));
    await pumpUntilFound(tester, find.byKey(const Key('run-map')));

    expect(find.byKey(const Key('run-map')), findsOneWidget);
    expect(find.byKey(const Key('current-location-button')), findsOneWidget);
    expect(find.text('START'), findsOneWidget);
  });

  testWidgets('opens a saved run detail from the history tab', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          disableStartupWeightPromptOverride,
          runSessionRepositoryProvider.overrideWithValue(
            FakeRunSessionRepository(sampleRunSessions()),
          ),
          locationStreamClientProvider.overrideWithValue(
            const SilentLocationStreamClient(),
          ),
        ],
        child: const RunliniApp(),
      ),
    );
    await pumpUntilFound(tester, find.byKey(const Key('history-list')));

    final firstSession = find.byKey(
      const Key('history-session-fixture_morning_tempo'),
    );
    await tester.ensureVisible(firstSession);
    await tester.pumpAndSettle();
    await tester.tap(firstSession);
    await pumpUntilFound(
      tester,
      find.byKey(const Key('run-finish-review-panel')),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('finish-route-preview')), findsOneWidget);
    expect(find.byKey(const Key('detail-chart-pace')), findsOneWidget);
    expect(find.text('Run Detail'), findsOneWidget);
    expect(find.byKey(const Key('save-run-button')), findsNothing);
    expect(find.byKey(const Key('discard-run-button')), findsNothing);

    await tester.tap(find.byKey(const Key('run-detail-close-button')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('run-finish-review-panel')), findsNothing);
    expect(find.byKey(const Key('history-list')), findsOneWidget);
  });

  testWidgets('imports health records into the history tab', (
    WidgetTester tester,
  ) async {
    final healthSession = _healthSession();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          disableStartupWeightPromptOverride,
          runSessionRepositoryProvider.overrideWithValue(
            FakeRunSessionRepository(),
          ),
          healthRouteClientProvider.overrideWithValue(
            _HealthRoute([healthSession]),
          ),
          locationStreamClientProvider.overrideWithValue(
            const SilentLocationStreamClient(),
          ),
        ],
        child: const RunliniApp(),
      ),
    );
    await pumpUntilFound(tester, find.byKey(const Key('history-list')));
    final restoreButton = find.byKey(
      const Key('health-restore-settings-button'),
    );
    await tester.ensureVisible(restoreButton);
    await tester.pumpAndSettle();
    await tester.tap(restoreButton);
    await pumpUntilFound(
      tester,
      find.byKey(const Key('history-session-healthconnect-widget')),
    );

    expect(find.text('Health 기록 가져오기를 마쳤어요.'), findsOneWidget);
    expect(
      find.byKey(const Key('history-session-fixture_morning_tempo')),
      findsNothing,
    );
    expect(
      find.byKey(const Key('history-session-healthconnect-widget')),
      findsOneWidget,
    );
  });

  testWidgets(
    'pull to refresh silently checks Health without permission prompt',
    (WidgetTester tester) async {
      final healthRoute = _TrackingHealthRoute();
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            disableStartupWeightPromptOverride,
            runSessionRepositoryProvider.overrideWithValue(
              FakeRunSessionRepository(),
            ),
            healthRouteClientProvider.overrideWithValue(healthRoute),
            locationStreamClientProvider.overrideWithValue(
              const SilentLocationStreamClient(),
            ),
          ],
          child: const RunliniApp(),
        ),
      );
      await pumpUntilFound(tester, find.byKey(const Key('history-list')));

      final indicator = tester.widget<RefreshIndicator>(
        find.byKey(const Key('history-refresh-indicator')),
      );
      await indicator.onRefresh();
      await tester.pumpAndSettle();

      expect(healthRoute.requestAuthorizationValues, [false]);
    },
  );
}

class _HealthRoute implements HealthRouteClient {
  const _HealthRoute(this.sessions);

  final List<RunSession> sessions;

  @override
  Future<HealthRouteConnectionStatus> checkConnection() async {
    return const HealthRouteConnectionStatus.connectionNeeded();
  }

  @override
  Future<HealthRouteConnectionStatus> requestConnection() async {
    return const HealthRouteConnectionStatus.connected();
  }

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

class _TrackingHealthRoute implements HealthRouteClient {
  final List<bool> requestAuthorizationValues = <bool>[];

  @override
  Future<HealthRouteConnectionStatus> checkConnection() async {
    return const HealthRouteConnectionStatus.connectionNeeded();
  }

  @override
  Future<HealthRouteConnectionStatus> requestConnection() async {
    return const HealthRouteConnectionStatus.connectionNeeded();
  }

  @override
  Future<HealthRouteImportResult> importRecentSessions({
    required bool requestAuthorization,
  }) async {
    requestAuthorizationValues.add(requestAuthorization);
    return const HealthRouteImportResult.authorizationRequired();
  }
}

RunSession _healthSession() {
  final now = DateTime.now();
  final startedAt = DateTime(now.year, now.month, now.day, 7);
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
