import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:runlini/app/runlini_app.dart';
import 'package:runlini/core/location/location_stream_client.dart';
import 'package:runlini/core/map/map_coordinate.dart';
import 'package:runlini/features/run_tracking/state/run_playback_providers.dart';
import 'package:runlini/features/run_tracking/state/run_session_providers.dart';
import 'package:runlini/features/run_tracking/state/run_settings_providers.dart';
import 'package:runlini/features/run_tracking/state/run_start_countdown_providers.dart';
import 'package:runlini/features/run_tracking/types/live_location_sample.dart';
import 'package:runlini/features/run_tracking/types/run_settings.dart';

import 'helpers/runlini_widget_harness.dart';

void main() {
  testWidgets(
    'running swaps in the live metrics panel, pause freezes elapsed time, and resume continues without countdown',
    (WidgetTester tester) async {
      final startedAt = DateTime(2026, 4, 20, 6, 0, 0);
      var now = startedAt;
      final sessionRepository = FakeRunSessionRepository(sampleRunSessions());

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
                lastKnownSample: sample(
                  latitude: 37.55,
                  longitude: 126.97,
                  capturedAt: startedAt,
                ),
              ),
            ),
            locationStreamClientProvider.overrideWithValue(
              const SilentLocationStreamClient(),
            ),
            runSessionRepositoryProvider.overrideWithValue(sessionRepository),
            runDisplaySettingsProvider.overrideWithValue(
              const RunDisplaySettings(
                distanceUnit: RunDistanceUnit.mi,
                paceUnit: RunPaceUnit.minPerMi,
                speedUnit: RunSpeedUnit.mph,
              ),
            ),
            runStartCountdownStepDurationProvider.overrideWithValue(
              const Duration(milliseconds: 10),
            ),
            runPlaybackClockProvider.overrideWithValue(() => now),
          ],
          child: const RunliniApp(),
        ),
      );
      await tester.pump();
      await openRunningTab(tester);
      await pumpUntilFound(tester, find.byKey(const Key('run-map')));

      expect(find.byKey(const Key('live-run-dashboard-overlay')), findsNothing);
      expect(find.byKey(const Key('settings-button')), findsNothing);
      expect(find.byKey(const Key('run-interval-button')), findsOneWidget);
      expect(find.byKey(const Key('ghost-control-chip')), findsOneWidget);
      expect(find.byKey(const Key('pause-run-button')), findsNothing);
      expect(find.byKey(const Key('resume-run-button')), findsNothing);

      await tester.tap(find.byKey(const Key('start-stop-button')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 30));
      await tester.pump();
      expect(
        find.byKey(const Key('live-run-dashboard-overlay')),
        findsOneWidget,
      );
      expect(
        find.byKey(const Key('live-run-dashboard-collapsed')),
        findsOneWidget,
      );
      expect(
        find.byKey(const Key('live-run-dashboard-expanded')),
        findsNothing,
      );
      expect(find.byKey(const Key('run-status-label')), findsNothing);
      expect(find.byKey(const Key('ghost-status-label')), findsNothing);
      expect(find.byKey(const Key('settings-button')), findsNothing);
      expect(find.byKey(const Key('run-interval-button')), findsNothing);
      expect(find.byKey(const Key('ghost-control-chip')), findsNothing);
      expect(find.byKey(const Key('pause-run-button')), findsOneWidget);
      expect(find.text('0.00 mi'), findsOneWidget);
      expect(find.text('0:00:00'), findsOneWidget);
      expect(find.text('--:-- /mi'), findsOneWidget);
      expect(find.text('0.0 mph'), findsNothing);
      expect(find.text('-- kcal'), findsNothing);

      await tester.tap(find.byKey(const Key('live-run-dashboard-toggle')));
      await tester.pumpAndSettle();
      expect(
        find.byKey(const Key('live-run-dashboard-expanded')),
        findsOneWidget,
      );
      expect(find.text('0.0 mph'), findsOneWidget);
      expect(find.text('-- kcal'), findsOneWidget);

      now = startedAt.add(const Duration(seconds: 1));
      await tester.pump(const Duration(seconds: 1));
      expect(find.text('0:00:01'), findsOneWidget);

      await tester.tap(find.byKey(const Key('pause-run-button')));
      await tester.pump();

      expect(find.byKey(const Key('live-run-paused-label')), findsOneWidget);
      expect(find.byKey(const Key('pause-run-button')), findsNothing);
      expect(find.byKey(const Key('resume-run-button')), findsOneWidget);

      now = startedAt.add(const Duration(seconds: 5));
      await tester.pump(const Duration(seconds: 1));
      expect(find.text('0:00:01'), findsOneWidget);

      await tester.tap(find.byKey(const Key('resume-run-button')));
      await tester.pump();

      expect(
        find.byKey(const Key('run-start-countdown-overlay')),
        findsNothing,
      );
      expect(find.byKey(const Key('live-run-paused-label')), findsNothing);
      expect(find.byKey(const Key('pause-run-button')), findsOneWidget);

      now = startedAt.add(const Duration(seconds: 6));
      await tester.pump(const Duration(seconds: 1));
      expect(find.text('0:00:02'), findsOneWidget);

      await tester.tap(find.byKey(const Key('start-stop-button')));
      await tester.pump();

      expect(find.byKey(const Key('live-run-dashboard-overlay')), findsNothing);
      expect(find.byKey(const Key('run-finish-review-panel')), findsOneWidget);
      expect(find.byKey(const Key('settings-button')), findsNothing);
      expect(find.byKey(const Key('ghost-control-chip')), findsNothing);
      await tester.tap(find.byKey(const Key('save-run-button')));
      await tester.pump();

      expect(find.byKey(const Key('settings-button')), findsNothing);
      expect(find.byKey(const Key('run-interval-button')), findsOneWidget);
      expect(find.byKey(const Key('ghost-control-chip')), findsOneWidget);
      expect(find.text('START'), findsOneWidget);
    },
  );

  testWidgets(
    'stop from paused shows review and does not show the countdown overlay',
    (WidgetTester tester) async {
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
          ],
          child: const RunliniApp(),
        ),
      );
      await tester.pump();
      await openRunningTab(tester);
      await pumpUntilFound(tester, find.byKey(const Key('run-map')));

      await tester.tap(find.byKey(const Key('start-stop-button')));
      await tester.pump();
      await tester.pump(const Duration(seconds: 3));
      await tester.pump();

      await tester.tap(find.byKey(const Key('pause-run-button')));
      await tester.pump();

      expect(find.byKey(const Key('resume-run-button')), findsOneWidget);
      expect(
        find.byKey(const Key('live-run-dashboard-overlay')),
        findsOneWidget,
      );
      expect(find.text('STOP'), findsOneWidget);

      await tester.tap(find.byKey(const Key('start-stop-button')));
      await tester.pump();

      expect(
        find.byKey(const Key('run-start-countdown-overlay')),
        findsNothing,
      );
      expect(find.byKey(const Key('live-run-dashboard-overlay')), findsNothing);
      expect(find.byKey(const Key('run-finish-review-panel')), findsOneWidget);
      expect(find.byKey(const Key('settings-button')), findsNothing);
      expect(find.byKey(const Key('ghost-control-chip')), findsNothing);
      expect(find.byKey(const Key('resume-run-button')), findsNothing);
      expect(find.byKey(const Key('save-run-button')), findsOneWidget);
    },
  );

  testWidgets(
    'current location button falls back to a one-shot current sample fetch',
    (WidgetTester tester) async {
      final pendingBootstrapSample = Completer<LiveLocationSample?>();
      final delayedCurrentSample = Completer<LiveLocationSample?>();

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
              SequencedDeviceLocationClient(
                currentResponses: <Future<LiveLocationSample?>>[
                  pendingBootstrapSample.future,
                  delayedCurrentSample.future,
                ],
              ),
            ),
            locationStreamClientProvider.overrideWithValue(
              const SilentLocationStreamClient(),
            ),
            startupCurrentLocationTimeoutProvider.overrideWithValue(
              const Duration(milliseconds: 10),
            ),
          ],
          child: const RunliniApp(),
        ),
      );
      await tester.pump();
      await openRunningTab(tester);
      await tester.pump(const Duration(milliseconds: 20));

      expect(find.byKey(const Key('run-map')), findsOneWidget);
      expect(find.byKey(const Key('runner-marker-layer')), findsNothing);

      await tester.tap(find.byKey(const Key('current-location-button')));
      await tester.pump();

      delayedCurrentSample.complete(
        sample(latitude: 37.551, longitude: 126.971),
      );
      await pumpUntilFound(
        tester,
        find.byKey(const Key('runner-marker-layer')),
      );

      expect(find.byKey(const Key('run-map')), findsOneWidget);
      expect(find.byKey(const Key('runner-marker-layer')), findsOneWidget);
    },
  );
}
