import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:runlini/app/theme/app_theme.dart';
import 'package:runlini/features/run_tracking/types/run_session.dart';
import 'package:runlini/features/run_tracking/types/run_session_summary.dart';
import 'package:runlini/features/run_tracking/ui/history/run_session_summary_tile.dart';

void main() {
  testWidgets('history tile does not show Health/source status badges', (
    tester,
  ) async {
    await _pumpTile(
      tester,
      recordSource: RunSessionRecordSource.healthConnect,
      syncStatus: RunSessionSyncStatus.synced,
      sourceSummary: 'Samsung Health',
    );

    expect(find.byKey(const Key('run-sync-status-badge')), findsNothing);
    expect(find.text('Samsung Health에서 가져옴'), findsNothing);
    expect(find.text('Health Connect에서 가져옴'), findsNothing);
    expect(find.text('거리'), findsOneWidget);
  });

  testWidgets('history tile keeps app-local records in the same list style', (
    tester,
  ) async {
    await _pumpTile(
      tester,
      recordSource: RunSessionRecordSource.appLocal,
      syncStatus: RunSessionSyncStatus.localOnly,
    );

    expect(find.byKey(const Key('run-sync-status-badge')), findsNothing);
    expect(find.text('앱에만 저장됨'), findsNothing);
    expect(find.text('거리'), findsOneWidget);
  });
}

Future<void> _pumpTile(
  WidgetTester tester, {
  required RunSessionRecordSource recordSource,
  required RunSessionSyncStatus syncStatus,
  String sourceSummary = 'device:gps',
}) async {
  final summary = RunSessionSummary(
    id: 'run-1',
    startedAt: DateTime(2026, 4, 30, 7, 30),
    distanceM: 1000,
    durationMs: 360000,
    averagePaceSecPerKm: 360,
    sourceSummary: sourceSummary,
    recordSource: recordSource,
    captureSource: RunSessionCaptureSource.phoneGps,
    syncStatus: syncStatus,
  );

  await tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.dark(),
      home: Scaffold(body: RunSessionSummaryTile(summary: summary)),
    ),
  );
}
