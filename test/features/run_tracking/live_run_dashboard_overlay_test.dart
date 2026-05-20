import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:runlini/core/map/map_coordinate.dart';
import 'package:runlini/features/record_race/types/record_race_frame.dart';
import 'package:runlini/features/run_tracking/service/run_interval_workout_calculator.dart';
import 'package:runlini/features/run_tracking/types/live_run_metrics.dart';
import 'package:runlini/features/run_tracking/types/run_interval_workout.dart';
import 'package:runlini/features/run_tracking/types/run_settings.dart';
import 'package:runlini/features/run_tracking/ui/running/live_run_dashboard_overlay.dart';

void main() {
  testWidgets(
    'starts collapsed with recordRace judgment when racing a recordRace',
    (tester) async {
      await _pumpOverlay(tester, recordRace: _recordRaceFrame());

      expect(
        find.byKey(const Key('live-run-dashboard-collapsed')),
        findsOneWidget,
      );
      expect(
        find.byKey(const Key('live-run-dashboard-expanded')),
        findsNothing,
      );
      expect(
        find.byKey(const Key('live-run-record-race-collapsed')),
        findsOneWidget,
      );
      expect(
        find.byKey(const Key('live-run-record-race-status-collapsed')),
        findsOneWidget,
      );
      expect(find.text('1.20 km'), findsOneWidget);
      expect(find.text('5:00 /km'), findsOneWidget);
      expect(find.byKey(const Key('record-race-panel')), findsNothing);
      expect(find.text('12.0 km/h'), findsNothing);
      expect(find.text('84 kcal'), findsNothing);
    },
  );

  testWidgets(
    'shows recordRace comparison with a compact start confirmation badge',
    (tester) async {
      await _pumpOverlay(
        tester,
        recordRace: _recordRaceFrame(startConfirmed: false),
      );

      expect(
        find.byKey(const Key('record-race-start-pending-badge')),
        findsOneWidget,
      );
      expect(find.text('확인 중'), findsOneWidget);
      expect(find.text('이기는 중'), findsOneWidget);
      expect(find.text('+0:12'), findsOneWidget);

      await tester.tap(find.byKey(const Key('live-run-dashboard-toggle')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('record-race-panel')), findsOneWidget);
      expect(find.text('기록 레이스 42m 뒤'), findsOneWidget);
      expect(find.text('+0:12'), findsWidgets);
    },
  );

  testWidgets('toggle expands and collapses detailed run information', (
    tester,
  ) async {
    await _pumpOverlay(
      tester,
      recordRace: _recordRaceFrame(),
      intervalFrame: _intervalFrame(),
    );

    await tester.tap(find.byKey(const Key('live-run-dashboard-toggle')));
    await tester.pumpAndSettle();

    expect(
      find.byKey(const Key('live-run-dashboard-expanded')),
      findsOneWidget,
    );
    expect(
      find.byKey(const Key('live-run-interval-step-label')),
      findsOneWidget,
    );
    expect(find.byKey(const Key('record-race-panel')), findsOneWidget);
    expect(find.byKey(const Key('record-race-progress-value')), findsOneWidget);
    expect(
      find.byKey(const Key('record-race-remaining-distance-value')),
      findsOneWidget,
    );
    expect(find.text('12.0 km/h'), findsOneWidget);
    expect(find.text('84 kcal'), findsOneWidget);

    await tester.tap(find.byKey(const Key('live-run-dashboard-toggle')));
    await tester.pumpAndSettle();

    expect(
      find.byKey(const Key('live-run-dashboard-collapsed')),
      findsOneWidget,
    );
    expect(find.byKey(const Key('record-race-panel')), findsNothing);
    expect(find.byKey(const Key('live-run-interval-step-label')), findsNothing);
  });

  testWidgets('recordRace progress stays below 100 before completion', (
    tester,
  ) async {
    await _pumpOverlay(
      tester,
      recordRace: _recordRaceFrame(routeProgress: 0.995),
    );

    await tester.tap(find.byKey(const Key('live-run-dashboard-toggle')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('record-race-progress-value')), findsOneWidget);
    expect(find.text('99%'), findsOneWidget);
    expect(find.text('100%'), findsNothing);
  });

  testWidgets('recordRace progress shows 100 after completion', (tester) async {
    await _pumpOverlay(
      tester,
      recordRace: _recordRaceFrame(routeProgress: 0.995),
      recordRaceCompleted: true,
    );

    await tester.tap(find.byKey(const Key('live-run-dashboard-toggle')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('record-race-progress-value')), findsOneWidget);
    expect(find.text('100%'), findsOneWidget);
  });

  testWidgets('paused state keeps a compact paused marker', (tester) async {
    await _pumpOverlay(tester, metrics: _metrics(isPaused: true));

    expect(find.byKey(const Key('live-run-paused-label')), findsOneWidget);
    expect(
      find.byKey(const Key('live-run-dashboard-collapsed')),
      findsOneWidget,
    );
  });

  testWidgets('new active session resets the dashboard to collapsed', (
    tester,
  ) async {
    await _pumpOverlay(tester, sessionId: 'run-a');
    await tester.tap(find.byKey(const Key('live-run-dashboard-toggle')));
    await tester.pumpAndSettle();
    expect(
      find.byKey(const Key('live-run-dashboard-expanded')),
      findsOneWidget,
    );

    await _pumpOverlay(tester, sessionId: 'run-b');

    expect(
      find.byKey(const Key('live-run-dashboard-collapsed')),
      findsOneWidget,
    );
    expect(find.byKey(const Key('live-run-dashboard-expanded')), findsNothing);
  });
}

Future<void> _pumpOverlay(
  WidgetTester tester, {
  String sessionId = 'run-a',
  LiveRunMetrics? metrics,
  RecordRaceFrame? recordRace,
  RunIntervalFrame? intervalFrame,
  bool recordRaceCompleted = false,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: Center(
          child: SizedBox(
            width: 360,
            child: LiveRunDashboardOverlay(
              sessionId: sessionId,
              metrics: metrics ?? _metrics(),
              displaySettings: const RunDisplaySettings(),
              recordRaceCompleted: recordRaceCompleted,
              recordRace: recordRace,
              intervalFrame: intervalFrame,
              onAdvanceInterval: () {},
            ),
          ),
        ),
      ),
    ),
  );
}

LiveRunMetrics _metrics({bool isPaused = false}) {
  return LiveRunMetrics(
    distanceKm: 1.2,
    elapsedMs: 360000,
    averagePaceSecPerKm: 300,
    averageSpeedKmh: 12,
    caloriesKcal: 84,
    isPaused: isPaused,
  );
}

RecordRaceFrame _recordRaceFrame({
  bool startConfirmed = true,
  double routeProgress = 0.5,
}) {
  return RecordRaceFrame(
    status: RecordRaceStatus.ahead,
    timeGapMs: 12000,
    distanceGapM: 42,
    recordRaceMarkerPoint: const MapCoordinate(latitude: 0, longitude: 0),
    isOffRoute: false,
    routeProgress: routeProgress,
    distanceToFinishM: 500,
    distanceFromRouteM: 4,
    totalRouteDistanceM: 1000,
    distanceToFinishPointM: 500,
    startConfirmed: startConfirmed,
  );
}

RunIntervalFrame _intervalFrame() {
  return const RunIntervalFrame(
    step: RunIntervalStep(
      kind: RunIntervalStepKind.work,
      target: RunIntervalTarget.time(60000),
      repeatIndex: 1,
      repeatCount: 8,
    ),
    nextStep: RunIntervalStep(
      kind: RunIntervalStepKind.recovery,
      target: RunIntervalTarget.time(60000),
      repeatIndex: 1,
      repeatCount: 8,
    ),
    remainingMs: 42000,
    remainingM: null,
    progress: 0.3,
  );
}
