import 'dart:async';

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
  testWidgets('empty history CTA requests Health authorization', (
    WidgetTester tester,
  ) async {
    final route = _HealthRoute(HealthRouteImportResult.success([_healthRun()]));
    await _pumpEmptyHistory(tester, route);

    await _tapRestoreButton(tester);
    await pumpUntilFound(
      tester,
      find.byKey(const Key('history-session-healthconnect-widget')),
    );

    expect(route.requestAuthorizationValues, [false, true]);
    expect(find.text('Health 기록 가져오기를 마쳤어요.'), findsOneWidget);
  });

  testWidgets('empty history CTA disables while Health sync is running', (
    WidgetTester tester,
  ) async {
    final completer = Completer<HealthRouteImportResult>();
    final route = _HealthRoute.deferred(completer);
    await _pumpEmptyHistory(tester, route);

    await _tapRestoreButton(tester);
    await tester.pump();

    final button = tester.widget<OutlinedButton>(
      find.byKey(const Key('health-restore-settings-button')),
    );
    expect(button.onPressed, isNull);
    expect(find.text('처리 중...'), findsOneWidget);

    completer.complete(HealthRouteImportResult.success([_healthRun()]));
    await pumpUntilFound(
      tester,
      find.byKey(const Key('history-session-healthconnect-widget')),
    );
  });

  testWidgets('empty history CTA shows permission-needed feedback', (
    WidgetTester tester,
  ) async {
    await _expectRestoreMessage(
      tester,
      const HealthRouteImportResult.authorizationRequired(),
      'Health 권한이 필요해요.',
    );
  });

  testWidgets('empty history CTA shows unavailable feedback', (
    WidgetTester tester,
  ) async {
    await _expectRestoreMessage(
      tester,
      const HealthRouteImportResult.unavailable(),
      'Health Connect 설치 또는 지원이 필요해요.',
    );
  });

  testWidgets('empty history CTA shows failure feedback', (
    WidgetTester tester,
  ) async {
    await _expectRestoreMessage(
      tester,
      const HealthRouteImportResult.failed(),
      'Health 기록을 가져오지 못했어요.',
    );
  });
}

Future<void> _expectRestoreMessage(
  WidgetTester tester,
  HealthRouteImportResult result,
  String message,
) async {
  await _pumpEmptyHistory(tester, _HealthRoute(result));

  await _tapRestoreButton(tester);
  await tester.pumpAndSettle();

  expect(find.text(message), findsOneWidget);
}

Future<void> _pumpEmptyHistory(
  WidgetTester tester,
  HealthRouteClient routeClient,
) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        disableStartupWeightPromptOverride,
        runSessionRepositoryProvider.overrideWithValue(
          FakeRunSessionRepository(),
        ),
        healthRouteClientProvider.overrideWithValue(routeClient),
        locationStreamClientProvider.overrideWithValue(
          const SilentLocationStreamClient(),
        ),
      ],
      child: const RunliniApp(),
    ),
  );
  await pumpUntilFound(
    tester,
    find.byKey(const Key('health-restore-settings-button')),
  );
}

Future<void> _tapRestoreButton(WidgetTester tester) async {
  final button = find.byKey(const Key('health-restore-settings-button'));
  await tester.ensureVisible(button);
  await tester.pumpAndSettle();
  await tester.tap(button);
}

class _HealthRoute implements HealthRouteClient {
  _HealthRoute(this.result) : completer = null;

  _HealthRoute.deferred(this.completer)
    : result = const HealthRouteImportResult.authorizationRequired();

  final HealthRouteImportResult result;
  final Completer<HealthRouteImportResult>? completer;
  final List<bool> requestAuthorizationValues = <bool>[];

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
  }) {
    requestAuthorizationValues.add(requestAuthorization);
    if (!requestAuthorization) {
      return Future<HealthRouteImportResult>.value(
        const HealthRouteImportResult.authorizationRequired(),
      );
    }
    return completer?.future ?? Future<HealthRouteImportResult>.value(result);
  }
}

RunSession _healthRun() {
  final startedAt = DateTime.utc(2026, 4, 21, 7);
  return RunSession(
    id: 'healthconnect-widget',
    startedAt: startedAt,
    endedAt: startedAt.add(const Duration(minutes: 8)),
    distanceM: 1200,
    durationMs: 480000,
    sourceSummary: 'Health Connect',
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
