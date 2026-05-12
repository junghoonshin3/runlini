import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:runlini/app/runlini_app.dart';
import 'package:runlini/core/location/location_stream_client.dart';
import 'package:runlini/core/map/map_coordinate.dart';
import 'package:runlini/features/run_tracking/state/run_settings_providers.dart';
import 'package:runlini/features/run_tracking/state/run_start_countdown_providers.dart';
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
}

Future<void> _pumpRecordRaceRunApp(
  WidgetTester tester, {
  required RunSettingsState settings,
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
          FakeDeviceLocationClient(
            lastKnownSample: sample(latitude: 0, longitude: 0),
          ),
        ),
        locationStreamClientProvider.overrideWithValue(
          const SilentLocationStreamClient(),
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
