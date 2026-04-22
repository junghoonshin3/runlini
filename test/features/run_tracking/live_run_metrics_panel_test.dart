import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:runlini/core/map/map_coordinate.dart';
import 'package:runlini/features/ghost_racer/types/ghost_race_frame.dart';
import 'package:runlini/features/run_tracking/types/live_run_metrics.dart';
import 'package:runlini/features/run_tracking/ui/live_run_metrics_panel.dart';

void main() {
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
              caloriesLabel: '-- kcal',
              isPaused: false,
            ),
            ghostRace: GhostRaceFrame(
              status: GhostRaceStatus.offRoute,
              timeGapMs: 0,
              distanceGapM: 0,
              ghostMarkerPoint: MapCoordinate(latitude: 0, longitude: 0),
              isOffRoute: true,
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
