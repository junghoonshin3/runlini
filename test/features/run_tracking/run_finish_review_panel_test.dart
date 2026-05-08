import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:runlini/features/run_tracking/types/run_point.dart';
import 'package:runlini/features/run_tracking/types/run_session.dart';
import 'package:runlini/features/run_tracking/types/run_session_ghost_summary.dart';
import 'package:runlini/features/run_tracking/types/run_settings.dart';
import 'package:runlini/features/run_tracking/ui/detail/run_finish_review_panel.dart';

void main() {
  testWidgets('hides ghost comparison for a normal run', (tester) async {
    await _pumpPanel(tester, _session());

    expect(find.byKey(const Key('detail-ghost-compare')), findsNothing);
    expect(find.byKey(const Key('detail-chart-pace')), findsOneWidget);
  });

  testWidgets('shows ghost comparison for a ghost-enabled run', (tester) async {
    await _pumpPanel(
      tester,
      _session(
        ghostSummary: const RunSessionGhostSummary(
          result: RunSessionGhostResult.ahead,
          timeGapMs: 12000,
          distanceGapM: 42,
          ghostSessionId: 'ghost-a',
          ghostLabel: 'Morning Ghost',
        ),
      ),
    );

    expect(find.byKey(const Key('detail-ghost-compare')), findsOneWidget);
    expect(find.text('고스트 비교'), findsOneWidget);
    expect(find.text('12초 빨랐어요'), findsOneWidget);
  });

  testWidgets('uses display units in metrics, charts, and ghost gap', (
    tester,
  ) async {
    const displaySettings = RunDisplaySettings(
      distanceUnit: RunDistanceUnit.mi,
      paceUnit: RunPaceUnit.minPerMi,
      speedUnit: RunSpeedUnit.mph,
    );
    await _pumpPanel(
      tester,
      _session(
        ghostSummary: const RunSessionGhostSummary(
          result: RunSessionGhostResult.ahead,
          timeGapMs: 12000,
          distanceGapM: 42,
          ghostSessionId: 'ghost-a',
          ghostLabel: 'Morning Ghost',
        ),
      ),
      displaySettings: displaySettings,
    );

    expect(find.text('Distance (mi)'), findsWidgets);
    expect(find.text('Avg. Pace (min/mi)'), findsOneWidget);
    expect(find.text('Avg. Speed (mph)'), findsOneWidget);
    expect(find.text('Pace (min/mi)'), findsWidgets);
    expect(find.text('거리 차이'), findsOneWidget);
  });

  testWidgets('can move primary metrics from header into metric strip', (
    tester,
  ) async {
    const displaySettings = RunDisplaySettings(
      distanceUnit: RunDistanceUnit.mi,
      paceUnit: RunPaceUnit.minPerMi,
      speedUnit: RunSpeedUnit.mph,
    );
    await _pumpPanel(
      tester,
      _session(),
      displaySettings: displaySettings,
      showHeaderSummaryMetrics: false,
    );

    expect(find.byKey(const Key('run-detail-header-summary')), findsNothing);
    expect(find.text('Distance (mi)'), findsOneWidget);
    expect(find.text('Time'), findsOneWidget);
    expect(find.text('Avg. Pace (min/mi)'), findsOneWidget);
    expect(find.text('Avg. Speed (mph)'), findsOneWidget);
    expect(find.text('Calories (kcal)'), findsOneWidget);
  });

  testWidgets('moves sync status to bottom', (tester) async {
    await _pumpPanel(tester, _session());

    final syncFinder = find.byKey(const Key('detail-sync-status-section'));
    final paceFinder = find.byKey(const Key('detail-chart-pace'));

    expect(
      tester.getTopLeft(syncFinder).dy,
      greaterThan(tester.getTopLeft(paceFinder).dy),
    );
  });

  testWidgets('lays out split rows on a narrow mobile screen', (tester) async {
    tester.view.physicalSize = const Size(320, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await _pumpPanel(tester, _splitSession());

    expect(tester.takeException(), isNull);
    expect(find.byKey(const Key('detail-splits-table')), findsOneWidget);
    expect(find.text('Split'), findsOneWidget);
    expect(find.text('Pace (min/km)'), findsWidgets);
    expect(find.byKey(const Key('split-row-1')), findsOneWidget);
    expect(find.textContaining('Elev. -- m'), findsWidgets);
    expect(find.textContaining('HR -- bpm'), findsWidgets);
  });

  testWidgets('split rows hide heart rate in the meta line', (tester) async {
    await _pumpPanel(
      tester,
      _splitSession(),
      privacySettings: const RunPrivacySettings(hideHeartRate: true),
    );

    expect(find.byKey(const Key('split-row-1')), findsOneWidget);
    expect(find.textContaining('HR -- bpm'), findsWidgets);
  });

  testWidgets('applies privacy settings to route and sensitive values', (
    tester,
  ) async {
    await _pumpPanel(
      tester,
      _session(),
      privacySettings: const RunPrivacySettings(
        hideRouteMap: true,
        hideStartEndArea: true,
        hideHeartRate: true,
        hideCalories: true,
      ),
    );

    expect(find.byKey(const Key('detail-route-hidden')), findsOneWidget);
    expect(find.byKey(const Key('start-end-privacy-badge')), findsOneWidget);
    expect(find.text('Heart Rate Hidden'), findsOneWidget);
    expect(find.text('Hidden'), findsWidgets);
  });

  testWidgets('shows empty elevation chart for invalid elevation sentinels', (
    tester,
  ) async {
    await _pumpPanel(tester, _badElevationSession());

    expect(find.text('고도 데이터가 아직 없어요.'), findsOneWidget);
    expect(find.textContaining('Infinity'), findsNothing);
    expect(find.textContaining('e+308'), findsNothing);
  });
}

Future<void> _pumpPanel(
  WidgetTester tester,
  RunSession session, {
  RunDisplaySettings displaySettings = const RunDisplaySettings(),
  RunPrivacySettings privacySettings = const RunPrivacySettings(),
  bool includePrimaryMetrics = true,
  bool showHeaderSummaryMetrics = true,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: RunFinishReviewPanel(
          session: session,
          displaySettings: displaySettings,
          privacySettings: privacySettings,
          includePrimaryMetrics: includePrimaryMetrics,
          showHeaderSummaryMetrics: showHeaderSummaryMetrics,
        ),
      ),
    ),
  );
  await tester.pump();
}

RunSession _session({RunSessionGhostSummary? ghostSummary}) {
  return RunSession(
    id: 'panel-session',
    startedAt: DateTime.utc(2026, 4, 21, 6),
    endedAt: DateTime.utc(2026, 4, 21, 6, 10),
    distanceM: 1000,
    durationMs: 600000,
    sourceSummary: 'fixture:test',
    ghostSummary: ghostSummary,
    points: const [
      RunPoint(
        latitude: 37.0,
        longitude: 127.0,
        timestampRelMs: 0,
        paceSecPerKm: 420,
        source: RunPointSource.simulated,
      ),
      RunPoint(
        latitude: 37.001,
        longitude: 127.001,
        timestampRelMs: 600000,
        paceSecPerKm: 410,
        source: RunPointSource.simulated,
      ),
    ],
  );
}

RunSession _splitSession() {
  return RunSession(
    id: 'split-session',
    startedAt: DateTime.utc(2026, 4, 21, 6),
    endedAt: DateTime.utc(2026, 4, 21, 6, 20),
    distanceM: 2200,
    durationMs: 1200000,
    sourceSummary: 'fixture:test',
    points: const [
      RunPoint(
        latitude: 37.0,
        longitude: 127.0,
        timestampRelMs: 0,
        paceSecPerKm: 420,
        source: RunPointSource.simulated,
      ),
      RunPoint(
        latitude: 37.01,
        longitude: 127.0,
        timestampRelMs: 600000,
        paceSecPerKm: 410,
        source: RunPointSource.simulated,
      ),
      RunPoint(
        latitude: 37.02,
        longitude: 127.0,
        timestampRelMs: 1200000,
        paceSecPerKm: 430,
        source: RunPointSource.simulated,
      ),
    ],
  );
}

RunSession _badElevationSession() {
  return RunSession(
    id: 'bad-elevation-session',
    startedAt: DateTime.utc(2026, 4, 21, 6),
    endedAt: DateTime.utc(2026, 4, 21, 6, 1),
    distanceM: 120,
    durationMs: 60000,
    sourceSummary: 'fixture:test',
    points: const [
      RunPoint(
        latitude: 37.0,
        longitude: 127.0,
        timestampRelMs: 0,
        elevationM: double.maxFinite,
        source: RunPointSource.deviceGps,
      ),
      RunPoint(
        latitude: 37.001,
        longitude: 127.001,
        timestampRelMs: 60000,
        elevationM: double.maxFinite,
        source: RunPointSource.deviceGps,
      ),
    ],
  );
}
