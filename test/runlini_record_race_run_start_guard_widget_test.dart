import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:runlini/app/runlini_app.dart';
import 'package:runlini/core/location/location_stream_client.dart';
import 'package:runlini/core/map/map_coordinate.dart';
import 'package:runlini/features/run_tracking/state/run_playback_providers.dart';
import 'package:runlini/features/run_tracking/state/run_settings_providers.dart';
import 'package:runlini/features/run_tracking/state/run_start_countdown_providers.dart';
import 'package:runlini/features/run_tracking/types/run_session_record_race_summary.dart';
import 'package:runlini/features/run_tracking/types/run_settings.dart';

import 'helpers/fake_run_settings_repository.dart';
import 'helpers/runlini_widget_harness.dart';

void main() {
  testWidgets('recordRace run requires high accuracy before countdown starts', (
    WidgetTester tester,
  ) async {
    await _pumpRecordRaceRunApp(
      tester,
      settings: const RunSettingsState(
        locationTrackingPreset: RunLocationTrackingPreset.balanced,
      ),
    );

    await tester.tap(find.byKey(const Key('start-stop-button')));
    await tester.pump();

    expect(
      find.byKey(const Key('record-race-run-accuracy-dialog')),
      findsOneWidget,
    );
    expect(find.text('기록 레이스는 정확한 위치가 필요해요'), findsOneWidget);
    expect(find.byKey(const Key('run-start-countdown-overlay')), findsNothing);

    await tester.tap(
      find.byKey(const Key('record-race-run-accuracy-settings-button')),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('settings-tab-screen')), findsOneWidget);
    expect(
      find.byKey(const Key('location-preset-highAccuracy-button')),
      findsOneWidget,
    );
  });

  testWidgets(
    'recordRace run starts and shows race feedback with high accuracy',
    (WidgetTester tester) async {
      await _pumpRecordRaceRunApp(
        tester,
        settings: const RunSettingsState(
          locationTrackingPreset: RunLocationTrackingPreset.highAccuracy,
        ),
      );

      expect(find.byKey(const Key('record-race-panel')), findsNothing);
      expect(find.byKey(const Key('record-race-marker-layer')), findsNothing);

      await tester.tap(find.byKey(const Key('start-stop-button')));
      await tester.pump();

      expect(
        find.byKey(const Key('run-start-countdown-overlay')),
        findsOneWidget,
      );
      expect(
        find.byKey(const Key('record-race-run-accuracy-dialog')),
        findsNothing,
      );

      await tester.pump(const Duration(milliseconds: 30));
      await tester.pump();

      expect(
        find.byKey(const Key('live-run-dashboard-overlay')),
        findsOneWidget,
      );
      expect(find.byKey(const Key('record-race-panel')), findsNothing);

      await tester.tap(find.byKey(const Key('live-run-dashboard-toggle')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('record-race-panel')), findsOneWidget);
      expect(find.byKey(const Key('record-race-status-label')), findsOneWidget);
      expect(
        find.byKey(const Key('record-race-start-pending-badge')),
        findsOneWidget,
      );
      expect(find.text('확인 중'), findsOneWidget);
      expect(
        find.byKey(const Key('record-race-time-gap-value')),
        findsOneWidget,
      );
      expect(
        find.byKey(const Key('record-race-distance-gap-value')),
        findsOneWidget,
      );
      expect(find.byKey(const Key('record-race-marker-layer')), findsOneWidget);
    },
  );

  testWidgets(
    'recordRace completion shows result dialog and continue keeps run active',
    (WidgetTester tester) async {
      final startedAt = DateTime(2026, 4, 20, 6);

      await _pumpRecordRaceRunApp(
        tester,
        settings: const RunSettingsState(
          locationTrackingPreset: RunLocationTrackingPreset.highAccuracy,
        ),
        deviceLocationClient: FakeDeviceLocationClient(
          lastKnownSample: sample(
            latitude: 0,
            longitude: 0,
            capturedAt: startedAt,
          ),
        ),
        clock: () => startedAt,
      );

      await tester.tap(find.byKey(const Key('start-stop-button')));
      await tester.pump();
      await pumpUntilFound(
        tester,
        find.byKey(const Key('live-run-dashboard-overlay')),
        maxPumps: 20,
        step: const Duration(milliseconds: 10),
      );
      expect(
        find.byKey(const Key('live-run-dashboard-overlay')),
        findsOneWidget,
      );

      final container = ProviderScope.containerOf(
        tester.element(find.byKey(const Key('live-run-dashboard-overlay'))),
        listen: false,
      );
      container
          .read(runPlaybackControllerProvider.notifier)
          .updateRecordRaceCompletion(
            candidateCount: 2,
            completedSummary: _recordRaceSummary(),
          );
      await tester.pump();

      await pumpUntilFound(
        tester,
        find.byKey(const Key('record-race-run-completion-dialog')),
      );

      expect(
        find.byKey(const Key('record-race-run-completion-dialog')),
        findsOneWidget,
      );
      expect(find.text('기록 레이스 완료'), findsOneWidget);
      expect(find.text('실시간 결과'), findsOneWidget);
      expect(find.text('기록 레이스보다 12초 빨랐어요'), findsOneWidget);
      expect(find.text('러닝 기록은 계속 중입니다.'), findsOneWidget);

      await tester.tap(find.text('계속 달리기'));
      await tester.pump();
      await tester.pump();

      expect(
        find.byKey(const Key('record-race-run-completion-dialog')),
        findsNothing,
      );
      expect(
        find.byKey(const Key('live-run-dashboard-overlay')),
        findsOneWidget,
      );
    },
  );
}

Future<void> _pumpRecordRaceRunApp(
  WidgetTester tester, {
  required RunSettingsState settings,
  LocationStreamClient? locationStreamClient,
  DeviceLocationClient? deviceLocationClient,
  DateTime Function()? clock,
}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        disableStartupWeightPromptOverride,
        runSettingsRepositoryProvider.overrideWithValue(
          FakeRunSettingsRepository(settings),
        ),
        staticMapStateOverride(
          fallbackMapCenter: const MapCoordinate(latitude: 0, longitude: 0),
          selectedRecordRaceSession: recordRaceSession(),
        ),
        deviceLocationClientProvider.overrideWithValue(
          deviceLocationClient ??
              FakeDeviceLocationClient(
                lastKnownSample: sample(latitude: 0, longitude: 0),
              ),
        ),
        locationStreamClientProvider.overrideWithValue(
          locationStreamClient ?? const SilentLocationStreamClient(),
        ),
        runStartCountdownStepDurationProvider.overrideWithValue(
          const Duration(milliseconds: 10),
        ),
        if (clock != null) runPlaybackClockProvider.overrideWithValue(clock),
      ],
      child: const RunliniApp(),
    ),
  );
  await tester.pump();
  await openRunningTab(tester);
  await pumpUntilFound(tester, find.byKey(const Key('run-map')));
}

RunSessionRecordRaceSummary _recordRaceSummary() {
  return const RunSessionRecordRaceSummary(
    recordRaceSessionId: 'record-race-route',
    recordRaceLabel: 'Morning RecordRace',
    result: RunSessionRecordRaceResult.ahead,
    timeGapMs: 12000,
    distanceGapM: 42,
  );
}
