import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:runlini/app/runlini_app.dart';
import 'package:runlini/core/health/health_workout_recorder.dart';
import 'package:runlini/core/location/location_stream_client.dart';
import 'package:runlini/core/map/map_coordinate.dart';
import 'package:runlini/features/run_tracking/state/run_session_providers.dart';
import 'package:runlini/features/run_tracking/state/run_settings_providers.dart';
import 'package:runlini/features/run_tracking/state/run_start_countdown_providers.dart';
import 'package:runlini/features/run_tracking/types/run_settings.dart';

import 'helpers/runlini_widget_harness.dart';

void main() {
  testWidgets('stop shows finish review and save returns to idle controls', (
    WidgetTester tester,
  ) async {
    final healthRecorder = FakeHealthWorkoutRecorder();
    final sessionRepository = FakeRunSessionRepository(sampleRunSessions());
    await _pumpRunningApp(
      tester,
      healthRecorder: healthRecorder,
      sessionRepository: sessionRepository,
      displaySettings: const RunDisplaySettings(
        distanceUnit: RunDistanceUnit.mi,
        paceUnit: RunPaceUnit.minPerMi,
        speedUnit: RunSpeedUnit.mph,
      ),
    );

    await _startAndStopRun(tester);

    expect(find.byKey(const Key('run-finish-review-panel')), findsOneWidget);
    expect(find.text('Run Detail'), findsOneWidget);
    expect(find.text('Distance (mi)'), findsWidgets);
    expect(find.text('Avg. Pace (min/mi)'), findsOneWidget);
    expect(find.text('Avg. Speed (mph)'), findsOneWidget);
    expect(find.text('Pace (min/mi)'), findsWidgets);
    expect(find.byKey(const Key('finish-route-preview')), findsOneWidget);
    expect(find.byKey(const Key('detail-chart-empty-speed')), findsOneWidget);
    expect(
      find.byKey(const Key('detail-chart-empty-heart rate')),
      findsOneWidget,
    );
    expect(find.byKey(const Key('settings-button')), findsNothing);
    expect(find.byKey(const Key('ghost-control-chip')), findsNothing);
    expect(find.byKey(const Key('pause-run-button')), findsNothing);
    expect(find.byKey(const Key('current-location-button')), findsNothing);
    expect(healthRecorder.finishCalls, 0);

    await tester.tap(find.byKey(const Key('save-run-button')));
    await tester.pump();

    expect(find.byKey(const Key('run-finish-review-panel')), findsNothing);
    expect(find.byKey(const Key('settings-button')), findsOneWidget);
    expect(find.byKey(const Key('ghost-control-chip')), findsOneWidget);
    expect(find.text('START'), findsOneWidget);
    expect(sessionRepository.savedSessions.length, 3);
    expect(healthRecorder.finishCalls, 0);

    final savedSession = sessionRepository.savedSessions.last;
    await openHistoryTab(tester);
    await pumpUntilFound(tester, find.byKey(const Key('history-list')));

    expect(
      find.byKey(Key('history-session-${savedSession.id}')),
      findsOneWidget,
    );
    expect(
      find.byKey(const Key('history-session-fixture_morning_tempo')),
      findsNothing,
    );
  });

  testWidgets('discard asks for confirmation before dropping the draft', (
    WidgetTester tester,
  ) async {
    final healthRecorder = FakeHealthWorkoutRecorder();
    final sessionRepository = FakeRunSessionRepository(sampleRunSessions());
    await _pumpRunningApp(
      tester,
      healthRecorder: healthRecorder,
      sessionRepository: sessionRepository,
    );

    await _startAndStopRun(tester);
    await tester.tap(find.byKey(const Key('discard-run-button')));
    await tester.pump();

    expect(find.text('기록을 버릴까요?'), findsOneWidget);
    expect(find.byKey(const Key('run-finish-review-panel')), findsOneWidget);

    await tester.tap(find.byKey(const Key('cancel-discard-run-button')));
    await tester.pump();
    expect(find.text('기록을 버릴까요?'), findsNothing);
    expect(find.byKey(const Key('run-finish-review-panel')), findsOneWidget);

    await tester.tap(find.byKey(const Key('discard-run-button')));
    await tester.pump();
    await tester.tap(find.byKey(const Key('confirm-discard-run-button')));
    await tester.pump();

    expect(find.byKey(const Key('run-finish-review-panel')), findsNothing);
    expect(find.byKey(const Key('settings-button')), findsOneWidget);
    expect(find.byKey(const Key('ghost-control-chip')), findsOneWidget);
    expect(sessionRepository.savedSessions.length, 2);
    expect(healthRecorder.cancelCalls, 1);
    expect(healthRecorder.finishCalls, 0);
  });
}

Future<void> _pumpRunningApp(
  WidgetTester tester, {
  required FakeHealthWorkoutRecorder healthRecorder,
  required FakeRunSessionRepository sessionRepository,
  RunDisplaySettings displaySettings = const RunDisplaySettings(),
}) async {
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
        runSessionRepositoryProvider.overrideWithValue(sessionRepository),
        runDisplaySettingsProvider.overrideWithValue(displaySettings),
        runPrivacySettingsProvider.overrideWithValue(
          const RunPrivacySettings(),
        ),
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

Future<void> _startAndStopRun(WidgetTester tester) async {
  await tester.tap(find.byKey(const Key('start-stop-button')));
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 30));
  await tester.pump();
  await tester.tap(find.byKey(const Key('start-stop-button')));
  await tester.pump();
}
