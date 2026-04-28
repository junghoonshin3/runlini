import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:runlini/app/theme/app_colors.dart';
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
    expect(find.text('Ghost Compare'), findsOneWidget);
    expect(find.text('You beat the ghost'), findsOneWidget);
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
    expect(find.text('Distance Gap · 0.03 mi'), findsOneWidget);
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

  testWidgets('chart touch indicator uses ring dot without guide line', (
    tester,
  ) async {
    await _pumpPanel(tester, _session());

    final chart = tester.widget<LineChart>(find.byType(LineChart).first);
    final barData = chart.data.lineBarsData.single;
    final indicator = chart.data.lineTouchData.getTouchedSpotIndicator(
      barData,
      const [0],
    ).single!;
    final dotPainter = indicator.touchedSpotDotData.getDotPainter(
      barData.spots.first,
      0,
      barData,
      0,
    );

    expect(indicator.indicatorBelowLine.strokeWidth, 0);
    expect(indicator.indicatorBelowLine.color, Colors.transparent);
    expect(dotPainter, isA<FlDotCirclePainter>());
    final circlePainter = dotPainter as FlDotCirclePainter;
    expect(circlePainter.radius, 7);
    expect(circlePainter.strokeWidth, 3);
    expect(circlePainter.strokeColor, AppColors.chalk);
    expect(chart.data.lineTouchData.touchSpotThreshold, 18);
  });
}

Future<void> _pumpPanel(
  WidgetTester tester,
  RunSession session, {
  RunDisplaySettings displaySettings = const RunDisplaySettings(),
  RunPrivacySettings privacySettings = const RunPrivacySettings(),
}) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: RunFinishReviewPanel(
          session: session,
          displaySettings: displaySettings,
          privacySettings: privacySettings,
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
