import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:runlini/app/theme/app_theme.dart';
import 'package:runlini/core/wear/watch_ghost_config_client.dart';
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
import 'package:runlini/features/run_tracking/types/run_settings.dart';
import 'package:runlini/features/run_tracking/types/run_shoe.dart';
import 'package:runlini/features/run_tracking/types/watch_ghost_config.dart';
import 'package:runlini/features/settings/ui/settings_tab_screen.dart';

import '../../helpers/runlini_widget_harness.dart';

void main() {
  testWidgets('manual Wear sync button shows imported result', (tester) async {
    final settingsRepository = _FakeRunSettingsRepository();
    final wearSyncService = _FakeWearDraftSyncService(
      const WearDraftSyncResult(
        pendingCount: 1,
        importedCount: 1,
        ackedCount: 1,
        failedCount: 0,
      ),
    );
    final ghostClient = _FakeWatchGhostConfigClient();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          runSettingsRepositoryProvider.overrideWithValue(settingsRepository),
          runSessionListProvider.overrideWith((ref) async => [_session()]),
          wearDraftSyncServiceProvider.overrideWithValue(wearSyncService),
          watchGhostConfigClientProvider.overrideWithValue(ghostClient),
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
    expect(ghostClient.sentConfigs.single.id, 'ghost-ready');
    expect(find.text('1개의 워치 기록을 가져왔어요.'), findsOneWidget);
  });
}

RunSession _session() {
  return RunSession(
    id: 'ghost-ready',
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

class _FakeWearDraftSyncService extends WearDraftSyncService {
  _FakeWearDraftSyncService(this.result)
    : super(
        inboxClient: _NoopWearDraftInboxClient(),
        importService: WatchRunSessionImportService(
          repository: _NoopRunSessionRepository(),
        ),
      );

  final WearDraftSyncResult result;
  int calls = 0;

  @override
  Future<WearDraftSyncResult> syncPendingDrafts() async {
    calls += 1;
    return result;
  }
}

class _NoopWearDraftInboxClient implements WearDraftInboxClient {
  @override
  Future<void> ackWearDraft(String id) async {}

  @override
  Future<List<WearDraftEnvelope>> pendingWearDrafts() async {
    return const <WearDraftEnvelope>[];
  }
}

class _NoopRunSessionRepository implements RunSessionRepository {
  @override
  Future<void> deleteSession(String id) async {}

  @override
  Future<RunSession?> findById(String id) async => null;

  @override
  Future<bool> isDeletedExternalSession(RunSession session) async => false;

  @override
  Future<List<RunSession>> listSessions() async => const <RunSession>[];

  @override
  Future<void> saveSession(RunSession session) async {}
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

class _FakeWatchGhostConfigClient implements WatchGhostConfigClient {
  List<WatchGhostConfig> sentConfigs = const [];

  @override
  Future<void> clearGhostConfig() async {}

  @override
  Future<void> sendGhostConfig(WatchGhostConfig config) async {}

  @override
  Future<void> sendGhostConfigs({
    required String? activeId,
    required List<WatchGhostConfig> configs,
  }) async {
    sentConfigs = configs;
  }
}
