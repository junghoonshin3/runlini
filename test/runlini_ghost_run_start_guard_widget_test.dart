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
  testWidgets('ghost run requires high accuracy before countdown starts', (
    WidgetTester tester,
  ) async {
    await _pumpGhostRunApp(
      tester,
      settings: const RunSettingsState(
        locationTrackingPreset: RunLocationTrackingPreset.balanced,
      ),
    );

    await tester.tap(find.byKey(const Key('start-stop-button')));
    await tester.pump();

    expect(find.byKey(const Key('ghost-run-accuracy-dialog')), findsOneWidget);
    expect(find.text('고스트런은 정확한 위치가 필요해요'), findsOneWidget);
    expect(find.byKey(const Key('run-start-countdown-overlay')), findsNothing);

    await tester.tap(
      find.byKey(const Key('ghost-run-accuracy-settings-button')),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('settings-tab-screen')), findsOneWidget);
    expect(
      find.byKey(const Key('location-preset-highAccuracy-button')),
      findsOneWidget,
    );
  });

  testWidgets('ghost run starts and shows race feedback with high accuracy', (
    WidgetTester tester,
  ) async {
    await _pumpGhostRunApp(
      tester,
      settings: const RunSettingsState(
        locationTrackingPreset: RunLocationTrackingPreset.highAccuracy,
      ),
    );

    expect(find.byKey(const Key('ghost-race-panel')), findsNothing);
    expect(find.byKey(const Key('ghost-marker-layer')), findsNothing);

    await tester.tap(find.byKey(const Key('start-stop-button')));
    await tester.pump();

    expect(
      find.byKey(const Key('run-start-countdown-overlay')),
      findsOneWidget,
    );
    expect(find.byKey(const Key('ghost-run-accuracy-dialog')), findsNothing);

    await tester.pump(const Duration(milliseconds: 30));
    await tester.pump();

    expect(find.byKey(const Key('live-run-dashboard-overlay')), findsOneWidget);
    expect(find.byKey(const Key('ghost-race-panel')), findsNothing);

    await tester.tap(find.byKey(const Key('live-run-dashboard-toggle')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('ghost-race-panel')), findsOneWidget);
    expect(find.byKey(const Key('ghost-race-status-label')), findsOneWidget);
    expect(find.text('접전'), findsOneWidget);
    expect(find.byKey(const Key('ghost-race-time-gap-value')), findsOneWidget);
    expect(find.text('0:00'), findsOneWidget);
    expect(find.text('고스트와 같은 위치'), findsOneWidget);
    expect(find.byKey(const Key('ghost-marker-layer')), findsNothing);
  });
}

Future<void> _pumpGhostRunApp(
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
          selectedGhostSession: ghostSession(),
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
