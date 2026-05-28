import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:runlini/app/theme/app_theme.dart';
import 'package:runlini/core/health/health_route_client.dart';
import 'package:runlini/core/health/health_workout_recorder.dart';
import 'package:runlini/features/health_sync/state/health_sync_providers.dart';
import 'package:runlini/features/run_tracking/repo/run_settings_repository.dart';
import 'package:runlini/features/run_tracking/state/run_session_providers.dart';
import 'package:runlini/features/run_tracking/state/run_settings_providers.dart';
import 'package:runlini/features/run_tracking/types/run_point.dart';
import 'package:runlini/features/run_tracking/types/run_session.dart';
import 'package:runlini/features/run_tracking/types/run_settings.dart';
import 'package:runlini/features/run_tracking/types/run_shoe.dart';
import 'package:runlini/features/settings/ui/settings_section_panel.dart';
import 'package:runlini/features/settings/ui/settings_sync_card.dart';
import 'package:runlini/features/settings/ui/settings_sync_section.dart';
import 'package:runlini/features/settings/ui/settings_tab_screen.dart';

import '../../helpers/runlini_widget_harness.dart';

void main() {
  testWidgets('sync status uses skeleton while connection state loads', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.dark(),
        home: const Scaffold(
          body: SettingsSyncCard(
            title: 'Health Connect',
            status: '확인 중',
            statusLoading: true,
            actionKey: Key('settings-health-import-button'),
            actionLabel: 'Health Connect 연결',
          ),
        ),
      ),
    );
    await tester.pump();

    expect(find.byKey(const Key('settings-status-skeleton')), findsOneWidget);
    expect(find.text('확인 중'), findsNothing);
    expect(
      find.byKey(const Key('settings-health-import-button')),
      findsOneWidget,
    );
  });

  testWidgets('Android Health card connects through Health Connect', (
    tester,
  ) async {
    final route = _HealthRoute();
    await _pumpSettings(tester, route, TargetPlatform.android);

    expect(find.text('Health Connect 연결'), findsOneWidget);

    await tester.tap(find.byKey(const Key('settings-health-import-button')));
    await tester.pumpAndSettle();

    expect(route.connectionRequests, 1);
    expect(route.requestAuthorizationValues, [false]);
    expect(find.text('연결됨'), findsWidgets);
    expect(find.text('Health Connect 연결됨'), findsOneWidget);
    expect(find.text('백업'), findsNothing);
    expect(find.textContaining('앱 기록 백업'), findsNothing);
    expect(find.textContaining('백업 실패'), findsNothing);
  });

  testWidgets('Health import button keeps its label on one line', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.dark(),
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: 112,
              child: SettingsCompactButton(
                key: const Key('settings-health-import-button'),
                label: '최근 기록 가져오기',
                onPressed: () {},
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    final buttonFinder = find.byKey(const Key('settings-health-import-button'));
    final labelFinder = find.descendant(
      of: buttonFinder,
      matching: find.text('최근 기록 가져오기'),
    );
    final label = tester.widget<Text>(labelFinder);

    expect(buttonFinder, findsOneWidget);
    expect(label.maxLines, 1);
    expect(label.softWrap, isFalse);
    expect(
      find.descendant(of: buttonFinder, matching: find.byType(FittedBox)),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('iOS Health card uses the user-facing Health app name', (
    tester,
  ) async {
    await _pumpSettings(tester, _HealthRoute(), TargetPlatform.iOS);

    expect(find.text('건강 앱 연결'), findsOneWidget);
    expect(find.byKey(const Key('settings-wear-sync-button')), findsNothing);
  });

  testWidgets('failed backups appear only inside the Health item', (
    tester,
  ) async {
    final recorder = FakeHealthWorkoutRecorder();
    await _pumpSettings(
      tester,
      _HealthRoute(),
      TargetPlatform.android,
      repository: FakeRunSessionRepository([_failedRun()]),
      recorder: recorder,
    );

    expect(find.text('백업'), findsNothing);
    expect(find.text('Health Connect 전송 실패 1개'), findsOneWidget);
    expect(find.text('다시 보내기'), findsOneWidget);
    expect(find.textContaining('앱 기록 백업'), findsNothing);
    expect(find.textContaining('백업 실패'), findsNothing);

    await tester.tap(
      find.byKey(const Key('settings-health-retry-failed-button')),
    );
    await tester.pumpAndSettle();

    expect(recorder.finishCalls, 1);
    expect(find.text('1개의 기록을 Health Connect로 보냈어요.'), findsOneWidget);
  });

  testWidgets('iOS failed backups use Health app send labels', (tester) async {
    await _pumpSettings(
      tester,
      _HealthRoute(),
      TargetPlatform.iOS,
      repository: FakeRunSessionRepository([_failedRun()]),
      recorder: FakeHealthWorkoutRecorder(),
    );

    expect(find.text('건강 앱 전송 실패 1개'), findsOneWidget);
    expect(find.text('다시 보내기'), findsOneWidget);
    expect(find.byKey(const Key('settings-wear-sync-button')), findsNothing);
  });

  testWidgets(
    'failed backup retry does not report success when nothing syncs',
    (tester) async {
      final recorder = FakeHealthWorkoutRecorder(
        finishResult: const HealthWorkoutExportResult.failed('write failed'),
      );
      await _pumpSettings(
        tester,
        _HealthRoute(),
        TargetPlatform.android,
        repository: FakeRunSessionRepository([_failedRun()]),
        recorder: recorder,
      );

      await tester.tap(
        find.byKey(const Key('settings-health-retry-failed-button')),
      );
      await tester.pumpAndSettle();

      expect(recorder.finishCalls, 1);
      expect(find.text('Health Connect로 다시 보내지 못했어요.'), findsOneWidget);
      expect(find.textContaining('0개의 기록'), findsNothing);
    },
  );
}

Future<void> _pumpSettings(
  WidgetTester tester,
  HealthRouteClient route,
  TargetPlatform platform, {
  FakeRunSessionRepository? repository,
  HealthWorkoutRecorder? recorder,
}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        settingsTargetPlatformProvider.overrideWithValue(platform),
        runSettingsRepositoryProvider.overrideWithValue(
          _FakeRunSettingsRepository(),
        ),
        runSessionRepositoryProvider.overrideWithValue(
          repository ?? FakeRunSessionRepository(),
        ),
        healthRouteClientProvider.overrideWithValue(route),
        if (recorder != null)
          healthWorkoutRecorderProvider.overrideWithValue(recorder),
      ],
      child: MaterialApp(
        theme: AppTheme.dark(),
        home: const Scaffold(body: SettingsTabScreen()),
      ),
    ),
  );
  await pumpUntilFound(tester, find.byKey(const Key('settings-tab-screen')));
  await tester.scrollUntilVisible(
    find.byKey(const Key('settings-health-import-button')),
    300,
    scrollable: find.byType(Scrollable).first,
  );
  await tester.pumpAndSettle();
}

RunSession _failedRun() {
  final startedAt = DateTime(2026, 4, 20, 7);
  return RunSession(
    id: 'failed-backup',
    startedAt: startedAt,
    endedAt: startedAt.add(const Duration(minutes: 12)),
    distanceM: 2400,
    durationMs: 720000,
    sourceSummary: 'device:gps',
    syncStatus: RunSessionSyncStatus.syncFailed,
    points: const <RunPoint>[
      RunPoint(
        latitude: 37.51,
        longitude: 127.01,
        timestampRelMs: 0,
        source: RunPointSource.deviceGps,
      ),
      RunPoint(
        latitude: 37.52,
        longitude: 127.02,
        timestampRelMs: 720000,
        source: RunPointSource.deviceGps,
      ),
    ],
  );
}

class _HealthRoute implements HealthRouteClient {
  int connectionRequests = 0;
  final List<bool> requestAuthorizationValues = <bool>[];

  @override
  Future<HealthRouteConnectionStatus> checkConnection() async {
    return const HealthRouteConnectionStatus.connectionNeeded();
  }

  @override
  Future<HealthRouteConnectionStatus> requestConnection() async {
    connectionRequests += 1;
    return const HealthRouteConnectionStatus.connected();
  }

  @override
  Future<HealthRouteImportResult> importRecentSessions({
    required bool requestAuthorization,
  }) async {
    requestAuthorizationValues.add(requestAuthorization);
    return const HealthRouteImportResult.success([]);
  }
}

class _FakeRunSettingsRepository implements RunSettingsRepository {
  @override
  Future<void> deleteShoe(String id) async {}

  @override
  Future<RunSettingsState> loadSettings() async => const RunSettingsState();

  @override
  Future<List<RunShoe>> listShoes() async => const <RunShoe>[];

  @override
  Future<void> retireShoe(String id) async {}

  @override
  Future<void> saveSettings(RunSettingsState settings) async {}

  @override
  Future<void> saveShoe(RunShoe shoe) async {}
}
