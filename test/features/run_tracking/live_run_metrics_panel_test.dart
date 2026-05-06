import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:runlini/core/map/map_coordinate.dart';
import 'package:runlini/features/ghost_racer/types/ghost_race_frame.dart';
import 'package:runlini/features/run_tracking/types/live_run_metrics.dart';
import 'package:runlini/features/run_tracking/types/run_settings.dart';
import 'package:runlini/features/run_tracking/ui/running/live_run_metrics_panel.dart';

void main() {
  testWidgets(
    'live run metrics panel uses metric display settings by default',
    (WidgetTester tester) async {
      await _pumpPanel(tester);

      expect(find.text('1.20 km'), findsOneWidget);
      expect(find.text('5:00 /km'), findsOneWidget);
      expect(find.text('12.0 km/h'), findsOneWidget);
      expect(find.text('84 kcal'), findsOneWidget);
    },
  );

  testWidgets('live run metrics panel uses mile display settings', (
    WidgetTester tester,
  ) async {
    await _pumpPanel(
      tester,
      displaySettings: const RunDisplaySettings(
        distanceUnit: RunDistanceUnit.mi,
        paceUnit: RunPaceUnit.minPerMi,
        speedUnit: RunSpeedUnit.mph,
      ),
    );

    expect(find.text('0.75 mi'), findsOneWidget);
    expect(find.text('8:03 /mi'), findsOneWidget);
    expect(find.text('7.5 mph'), findsOneWidget);
  });

  testWidgets('live run metrics panel shows off-route ghost state', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: LiveRunMetricsPanel(
            metrics: LiveRunMetrics(
              distanceKm: 1.2,
              elapsedMs: 360000,
              averagePaceSecPerKm: 300,
              averageSpeedKmh: 12,
              caloriesKcal: 84,
              isPaused: false,
            ),
            ghostRace: GhostRaceFrame(
              status: GhostRaceStatus.offRoute,
              timeGapMs: 0,
              distanceGapM: 0,
              ghostMarkerPoint: MapCoordinate(latitude: 0, longitude: 0),
              isOffRoute: true,
              routeProgress: 0.5,
              distanceToFinishM: 500,
              distanceFromRouteM: 40,
              totalRouteDistanceM: 1000,
              distanceToFinishPointM: 500,
            ),
          ),
        ),
      ),
    );

    expect(find.byKey(const Key('ghost-race-panel')), findsOneWidget);
    expect(find.text('경로 이탈'), findsOneWidget);
    expect(find.text('--:--'), findsOneWidget);
    expect(find.text('고스트 비교를 잠시 멈췄어요'), findsOneWidget);
  });
}

Future<void> _pumpPanel(
  WidgetTester tester, {
  RunDisplaySettings displaySettings = const RunDisplaySettings(),
}) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: LiveRunMetricsPanel(
          metrics: const LiveRunMetrics(
            distanceKm: 1.2,
            elapsedMs: 360000,
            averagePaceSecPerKm: 300,
            averageSpeedKmh: 12,
            caloriesKcal: 84,
            isPaused: false,
          ),
          displaySettings: displaySettings,
        ),
      ),
    ),
  );
}
