import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:runlini/app/runlini_app.dart';
import 'package:runlini/core/health/health_workout_recorder.dart';
import 'package:runlini/core/location/location_stream_client.dart';
import 'package:runlini/core/map/map_coordinate.dart';
import 'package:runlini/features/run_tracking/state/run_start_countdown_providers.dart';

import 'helpers/runlini_widget_harness.dart';

void main() {
  testWidgets('start does not request Health permissions before countdown', (
    WidgetTester tester,
  ) async {
    final healthRecorder = FakeHealthWorkoutRecorder(
      prepareResult: HealthRunPreparationResult.installRequired,
    );

    await _pumpApp(tester, healthRecorder);
    await tester.tap(find.byKey(const Key('start-stop-button')));
    await tester.pump();

    expect(healthRecorder.prepareCalls, 0);
    expect(healthRecorder.installCalls, 0);
    expect(healthRecorder.beginCalls, 0);
    expect(
      find.byKey(const Key('run-start-countdown-overlay')),
      findsOneWidget,
    );

    await tester.pump(const Duration(milliseconds: 30));
    await tester.pump();

    expect(healthRecorder.prepareCalls, 0);
    expect(healthRecorder.beginCalls, 0);
    expect(find.byKey(const Key('live-run-metrics-panel')), findsOneWidget);
  });
}

Future<void> _pumpApp(
  WidgetTester tester,
  FakeHealthWorkoutRecorder healthRecorder,
) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        disableStartupWeightPromptOverride,
        staticMapStateOverride(
          fallbackMapCenter: const MapCoordinate(
            latitude: 37.0,
            longitude: 127.0,
          ),
        ),
        deviceLocationClientProvider.overrideWithValue(
          FakeDeviceLocationClient(
            lastKnownSample: sample(latitude: 37.55, longitude: 126.97),
          ),
        ),
        locationStreamClientProvider.overrideWithValue(
          const SilentLocationStreamClient(),
        ),
        healthWorkoutRecorderProvider.overrideWithValue(healthRecorder),
        runStartCountdownStepDurationProvider.overrideWithValue(
          const Duration(milliseconds: 10),
        ),
      ],
      child: const RunliniApp(),
    ),
  );
  await tester.pump();
  await openRunningTab(tester);
  await pumpUntilFound(tester, find.byKey(const Key('run-map')));
}
