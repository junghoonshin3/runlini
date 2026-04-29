import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:runlini/app/theme/app_theme.dart';
import 'package:runlini/features/health_sync/service/health_sync_service.dart';
import 'package:runlini/features/health_sync/state/health_sync_providers.dart';
import 'package:runlini/features/health_sync/types/health_sync_status.dart';
import 'package:runlini/features/run_tracking/service/wear_draft_sync_service.dart';
import 'package:runlini/features/run_tracking/state/run_session_providers.dart';
import 'package:runlini/features/run_tracking/state/run_watch_providers.dart';
import 'package:runlini/features/run_tracking/types/run_session.dart';
import 'package:runlini/features/run_tracking/ui/history/history_tab_screen.dart';

void main() {
  testWidgets('opens history on today and returns date selection to today', (
    WidgetTester tester,
  ) async {
    final today = DateTime(2026, 4, 28, 12);
    final todaySession = _session('today-run', DateTime(2026, 4, 28, 7));
    final yesterdaySession = _session(
      'yesterday-run',
      DateTime(2026, 4, 27, 7),
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          runSessionListProvider.overrideWith(
            (Ref ref) async => [todaySession, yesterdaySession],
          ),
        ],
        child: MaterialApp(
          theme: AppTheme.dark(),
          home: Scaffold(body: HistoryTabScreen(now: today)),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('최근 기록'), findsNothing);
    expect(find.text('4월 28일 기록'), findsOneWidget);
    expect(find.byKey(const Key('history-session-today-run')), findsOneWidget);
    expect(
      find.byKey(const Key('history-session-yesterday-run')),
      findsNothing,
    );
    expect(
      find.byKey(const Key('history-calendar-clear-selection-button')),
      findsNothing,
    );

    final yesterdayCell = find.byKey(
      const Key('history-calendar-day-2026-04-27'),
    );
    await tester.ensureVisible(yesterdayCell);
    await tester.pumpAndSettle();
    await tester.tap(yesterdayCell);
    await tester.pumpAndSettle();

    expect(find.text('4월 27일 기록'), findsOneWidget);
    expect(find.byKey(const Key('history-session-today-run')), findsNothing);
    expect(
      find.byKey(const Key('history-session-yesterday-run')),
      findsOneWidget,
    );
    expect(find.text('오늘 보기'), findsOneWidget);

    await tester.tap(
      find.byKey(const Key('history-calendar-clear-selection-button')),
    );
    await tester.pumpAndSettle();

    expect(find.text('4월 28일 기록'), findsOneWidget);
    expect(find.byKey(const Key('history-session-today-run')), findsOneWidget);
    expect(
      find.byKey(const Key('history-session-yesterday-run')),
      findsNothing,
    );
  });

  testWidgets('shows a UTC Wear session on its local calendar day', (
    WidgetTester tester,
  ) async {
    final localStart = DateTime(2026, 4, 29, 0, 30);
    final utcStartedAt = localStart.toUtc();
    final wearSession = _session('wear-utc-run', utcStartedAt);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          runSessionListProvider.overrideWith((Ref ref) async => [wearSession]),
        ],
        child: MaterialApp(
          theme: AppTheme.dark(),
          home: Scaffold(body: HistoryTabScreen(now: localStart)),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(utcStartedAt.isUtc, isTrue);
    expect(find.text('4월 29일 기록'), findsOneWidget);
    expect(
      find.byKey(const Key('history-session-wear-utc-run')),
      findsOneWidget,
    );
  });

  testWidgets('pull to refresh also syncs pending Wear drafts', (
    WidgetTester tester,
  ) async {
    final today = DateTime(2026, 4, 28, 12);
    final wearSync = _FakeWearDraftSyncService(
      const WearDraftSyncResult(
        pendingCount: 1,
        importedCount: 1,
        ackedCount: 1,
        failedCount: 0,
      ),
    );
    final healthSync = _FakeHealthSyncService();
    var historyBuilds = 0;

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          healthSyncServiceProvider.overrideWithValue(healthSync),
          wearDraftSyncServiceProvider.overrideWithValue(wearSync),
          runSessionListProvider.overrideWith((Ref ref) async {
            historyBuilds += 1;
            return [_session('today-run', DateTime(2026, 4, 28, 7))];
          }),
        ],
        child: MaterialApp(
          theme: AppTheme.dark(),
          home: Scaffold(body: HistoryTabScreen(now: today)),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final indicator = tester.widget<RefreshIndicator>(
      find.byKey(const Key('history-refresh-indicator')),
    );
    await indicator.onRefresh();
    await tester.pumpAndSettle();

    expect(healthSync.requestAuthorizationValues, <bool>[false]);
    expect(wearSync.calls, 1);
    expect(historyBuilds, greaterThan(1));
  });

  testWidgets('pull to refresh survives a Wear draft sync failure', (
    WidgetTester tester,
  ) async {
    final today = DateTime(2026, 4, 28, 12);
    final wearSync = _FakeWearDraftSyncService(
      const WearDraftSyncResult.failed(),
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          healthSyncServiceProvider.overrideWithValue(_FakeHealthSyncService()),
          wearDraftSyncServiceProvider.overrideWithValue(wearSync),
          runSessionListProvider.overrideWith(
            (Ref ref) async => [
              _session('today-run', DateTime(2026, 4, 28, 7)),
            ],
          ),
        ],
        child: MaterialApp(
          theme: AppTheme.dark(),
          home: Scaffold(body: HistoryTabScreen(now: today)),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final indicator = tester.widget<RefreshIndicator>(
      find.byKey(const Key('history-refresh-indicator')),
    );
    await indicator.onRefresh();
    await tester.pumpAndSettle();

    expect(wearSync.calls, 1);
    expect(find.byKey(const Key('history-session-today-run')), findsOneWidget);
    expect(find.text('기록을 불러오지 못했어요.'), findsNothing);
  });
}

RunSession _session(String id, DateTime startedAt) {
  return RunSession(
    id: id,
    startedAt: startedAt,
    distanceM: 1000,
    durationMs: 600000,
    sourceSummary: 'test',
    points: const [],
  );
}

class _FakeHealthSyncService implements HealthSyncService {
  final List<bool> requestAuthorizationValues = <bool>[];

  @override
  Future<RunSession?> hydrateSession(RunSession primarySession) async {
    return primarySession;
  }

  @override
  Future<HealthSyncStatus> syncRecentSessions({
    required bool requestAuthorization,
  }) async {
    requestAuthorizationValues.add(requestAuthorization);
    return const HealthSyncStatus.synced(0);
  }
}

class _FakeWearDraftSyncService implements WearDraftSyncService {
  _FakeWearDraftSyncService(this.result);

  final WearDraftSyncResult result;
  int calls = 0;

  @override
  Future<WearDraftSyncResult> syncPendingDrafts() async {
    calls += 1;
    return result;
  }
}
