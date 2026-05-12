import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:runlini/app/theme/app_theme.dart';
import 'package:runlini/core/wear/watch_connection_client.dart';
import 'package:runlini/core/wear/watch_record_race_config_client.dart';
import 'package:runlini/core/wear/wear_draft_inbox_client.dart';
import 'package:runlini/features/run_tracking/repo/run_session_repository.dart';
import 'package:runlini/features/run_tracking/repo/run_settings_repository.dart';
import 'package:runlini/features/run_tracking/service/watch_run_session_import_service.dart';
import 'package:runlini/features/run_tracking/service/wear_draft_sync_service.dart';
import 'package:runlini/features/run_tracking/state/run_session_providers.dart';
import 'package:runlini/features/run_tracking/state/run_settings_providers.dart';
import 'package:runlini/features/run_tracking/state/run_watch_providers.dart';
import 'package:runlini/features/run_tracking/types/run_point.dart';
import 'package:runlini/features/run_tracking/types/run_session.dart';
import 'package:runlini/features/run_tracking/types/run_session_summary.dart';
import 'package:runlini/features/run_tracking/types/run_settings.dart';
import 'package:runlini/features/run_tracking/types/run_shoe.dart';
import 'package:runlini/features/run_tracking/types/watch_record_race_config.dart';
import 'package:runlini/features/settings/ui/settings_tab_screen.dart';

import '../../helpers/runlini_widget_harness.dart';

part 'settings_wear_sync_fakes.dart';

void main() {
  testWidgets('manual Wear sync button shows imported result', (tester) async {
    final wearSyncService = _FakeWearDraftSyncService(
      const WearDraftSyncResult(
        pendingCount: 1,
        importedCount: 1,
        ackedCount: 1,
        failedCount: 0,
      ),
    );
    final recordRaceClient = _FakeWatchRecordRaceConfigClient();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          runSettingsRepositoryProvider.overrideWithValue(
            _FakeRunSettingsRepository(),
          ),
          runSessionRepositoryProvider.overrideWithValue(
            _MemoryRunSessionRepository([_session()]),
          ),
          wearDraftSyncServiceProvider.overrideWithValue(wearSyncService),
          watchConnectionClientProvider.overrideWithValue(
            const _FakeWatchConnectionClient(
              WatchConnectionStatus.disconnected,
            ),
          ),
          watchRecordRaceConfigClientProvider.overrideWithValue(
            recordRaceClient,
          ),
        ],
        child: MaterialApp(
          theme: AppTheme.dark(),
          home: const Scaffold(body: SettingsTabScreen()),
        ),
      ),
    );
    await pumpUntilFound(tester, find.byKey(const Key('settings-tab-screen')));

    final button = find.byKey(const Key('settings-wear-sync-button'));
    await tester.scrollUntilVisible(
      button,
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    await tester.tap(button);
    await tester.pumpAndSettle();

    expect(wearSyncService.calls, 1);
    expect(recordRaceClient.sentConfigs.single.id, 'record-race-ready');
    expect(find.text('워치 기록 가져오기'), findsOneWidget);
    expect(find.text('1개의 워치 기록을 가져왔어요.'), findsOneWidget);
  });

  testWidgets('manual Wear import reports no records when connected', (
    tester,
  ) async {
    final wearSyncService = _FakeWearDraftSyncService(
      const WearDraftSyncResult(
        pendingCount: 0,
        importedCount: 0,
        ackedCount: 0,
        failedCount: 0,
      ),
    );
    await _pumpSyncSection(
      tester,
      wearSyncService: wearSyncService,
      connectionStatus: WatchConnectionStatus.connected,
    );

    await _tapWearImportButton(tester);

    expect(find.text('가져올 워치 기록이 없어요.'), findsOneWidget);
  });

  testWidgets('manual Wear import asks to reconnect when disconnected', (
    tester,
  ) async {
    final wearSyncService = _FakeWearDraftSyncService(
      const WearDraftSyncResult(
        pendingCount: 0,
        importedCount: 0,
        ackedCount: 0,
        failedCount: 0,
      ),
    );
    await _pumpSyncSection(
      tester,
      wearSyncService: wearSyncService,
      connectionStatus: WatchConnectionStatus.disconnected,
    );

    await _tapWearImportButton(tester);

    expect(find.text('워치가 연결되면 다시 시도해 주세요.'), findsOneWidget);
  });

  testWidgets('manual Wear import reports failures first', (tester) async {
    final wearSyncService = _FakeWearDraftSyncService(
      const WearDraftSyncResult(
        pendingCount: 1,
        importedCount: 0,
        ackedCount: 0,
        failedCount: 1,
      ),
    );
    await _pumpSyncSection(
      tester,
      wearSyncService: wearSyncService,
      connectionStatus: WatchConnectionStatus.connected,
    );

    await _tapWearImportButton(tester);

    expect(find.text('일부 워치 기록을 가져오지 못했어요.'), findsOneWidget);
  });
}

Future<void> _pumpSyncSection(
  WidgetTester tester, {
  required _FakeWearDraftSyncService wearSyncService,
  required WatchConnectionStatus connectionStatus,
}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        runSettingsRepositoryProvider.overrideWithValue(
          _FakeRunSettingsRepository(),
        ),
        runSessionRepositoryProvider.overrideWithValue(
          _MemoryRunSessionRepository([_session()]),
        ),
        wearDraftSyncServiceProvider.overrideWithValue(wearSyncService),
        watchConnectionClientProvider.overrideWithValue(
          _FakeWatchConnectionClient(connectionStatus),
        ),
        watchRecordRaceConfigClientProvider.overrideWithValue(
          _FakeWatchRecordRaceConfigClient(),
        ),
      ],
      child: MaterialApp(
        theme: AppTheme.dark(),
        home: const Scaffold(body: SettingsTabScreen()),
      ),
    ),
  );
  await pumpUntilFound(tester, find.byKey(const Key('settings-tab-screen')));
}

Future<void> _tapWearImportButton(WidgetTester tester) async {
  final button = find.byKey(const Key('settings-wear-sync-button'));
  await tester.scrollUntilVisible(
    button,
    300,
    scrollable: find.byType(Scrollable).first,
  );
  await tester.pumpAndSettle();
  await tester.tap(button);
  await tester.pumpAndSettle();
}

RunSession _session() {
  return RunSession(
    id: 'record-race-ready',
    startedAt: DateTime.utc(2026, 4, 30, 7),
    durationMs: 600000,
    distanceM: 2000,
    sourceSummary: 'test',
    points: const [
      RunPoint(
        latitude: 37,
        longitude: 127,
        timestampRelMs: 0,
        source: RunPointSource.deviceGps,
      ),
      RunPoint(
        latitude: 37.001,
        longitude: 127.001,
        timestampRelMs: 600000,
        source: RunPointSource.deviceGps,
      ),
    ],
  );
}
