import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:runlini/core/map/map_coordinate.dart';
import 'package:runlini/features/ghost_racer/types/ghost_race_frame.dart';
import 'package:runlini/features/run_tracking/service/run_interval_workout_calculator.dart';
import 'package:runlini/features/run_tracking/types/live_run_metrics.dart';
import 'package:runlini/features/run_tracking/types/run_interval_workout.dart';
import 'package:runlini/features/run_tracking/types/run_settings.dart';
import 'package:runlini/features/run_tracking/ui/running/live_run_dashboard_overlay.dart';

void main() {
  testWidgets('starts collapsed with ghost judgment when racing a ghost', (
    tester,
  ) async {
    await _pumpOverlay(tester, ghostRace: _ghostFrame());

    expect(
      find.byKey(const Key('live-run-dashboard-collapsed')),
      findsOneWidget,
    );
    expect(find.byKey(const Key('live-run-dashboard-expanded')), findsNothing);
    expect(find.byKey(const Key('live-run-ghost-collapsed')), findsOneWidget);
    expect(
      find.byKey(const Key('live-run-ghost-status-collapsed')),
      findsOneWidget,
    );
    expect(find.text('1.20 km'), findsOneWidget);
    expect(find.text('5:00 /km'), findsOneWidget);
    expect(find.byKey(const Key('ghost-race-panel')), findsNothing);
    expect(find.text('12.0 km/h'), findsNothing);
    expect(find.text('84 kcal'), findsNothing);
  });

  testWidgets('toggle expands and collapses detailed run information', (
    tester,
  ) async {
    await _pumpOverlay(
      tester,
      ghostRace: _ghostFrame(),
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
    expect(find.byKey(const Key('ghost-race-panel')), findsOneWidget);
    expect(find.byKey(const Key('ghost-race-progress-value')), findsOneWidget);
    expect(
      find.byKey(const Key('ghost-race-remaining-distance-value')),
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
    expect(find.byKey(const Key('ghost-race-panel')), findsNothing);
    expect(find.byKey(const Key('live-run-interval-step-label')), findsNothing);
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
  GhostRaceFrame? ghostRace,
  RunIntervalFrame? intervalFrame,
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
              ghostRace: ghostRace,
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

GhostRaceFrame _ghostFrame() {
  return const GhostRaceFrame(
    status: GhostRaceStatus.ahead,
    timeGapMs: 12000,
    distanceGapM: 42,
    ghostMarkerPoint: MapCoordinate(latitude: 0, longitude: 0),
    isOffRoute: false,
    routeProgress: 0.5,
    distanceToFinishM: 500,
    distanceFromRouteM: 4,
    totalRouteDistanceM: 1000,
    distanceToFinishPointM: 500,
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
