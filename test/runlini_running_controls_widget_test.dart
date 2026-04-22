import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:runlini/app/runlini_app.dart';
import 'package:runlini/core/location/location_stream_client.dart';
import 'package:runlini/core/map/map_coordinate.dart';
import 'package:runlini/features/run_tracking/state/run_playback_providers.dart';
import 'package:runlini/features/run_tracking/state/run_session_providers.dart';
import 'package:runlini/features/run_tracking/state/run_start_countdown_providers.dart';
import 'package:runlini/features/run_tracking/types/live_location_sample.dart';

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
            runStartCountdownStepDurationProvider.overrideWithValue(
              const Duration(milliseconds: 10),
            ),
            runPlaybackClockProvider.overrideWithValue(() => now),
          ],
          child: const RunliniApp(),
        ),
      );
      await tester.pump();
      await pumpUntilFound(tester, find.byKey(const Key('run-map')));

      expect(find.byKey(const Key('live-run-metrics-panel')), findsNothing);
      expect(find.byKey(const Key('settings-button')), findsOneWidget);
      expect(find.byKey(const Key('pause-run-button')), findsNothing);
      expect(find.byKey(const Key('resume-run-button')), findsNothing);

      await tester.tap(find.byKey(const Key('start-stop-button')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 30));
      await tester.pump();

      expect(find.byKey(const Key('live-run-metrics-panel')), findsOneWidget);
      expect(find.byKey(const Key('run-status-label')), findsNothing);
      expect(find.byKey(const Key('ghost-status-label')), findsNothing);
      expect(find.byKey(const Key('settings-button')), findsNothing);
      expect(find.byKey(const Key('pause-run-button')), findsOneWidget);
      expect(find.text('0.00 km'), findsOneWidget);
      expect(find.text('0:00:00'), findsOneWidget);
      expect(find.text('--:-- /km'), findsOneWidget);
      expect(find.text('0.0 km/h'), findsOneWidget);
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

      expect(find.byKey(const Key('live-run-metrics-panel')), findsNothing);
      expect(find.byKey(const Key('run-finish-review-panel')), findsOneWidget);
      expect(find.byKey(const Key('settings-button')), findsNothing);
      await tester.tap(find.byKey(const Key('save-run-button')));
      await tester.pump();

      expect(find.byKey(const Key('settings-button')), findsOneWidget);
      expect(find.text('START'), findsOneWidget);
    },
  );

  testWidgets('running with a selected ghost shows race feedback and marker', (
    WidgetTester tester,
  ) async {
    final selectedGhostSession = ghostSession();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          staticMapStateOverride(
            fallbackMapCenter: const MapCoordinate(latitude: 0, longitude: 0),
            selectedGhostSession: selectedGhostSession,
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
    await pumpUntilFound(tester, find.byKey(const Key('run-map')));

    expect(find.byKey(const Key('ghost-race-panel')), findsNothing);
    expect(find.byKey(const Key('ghost-marker-layer')), findsNothing);

    await tester.tap(find.byKey(const Key('start-stop-button')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 30));
    await tester.pump();

    expect(find.byKey(const Key('live-run-metrics-panel')), findsOneWidget);
    expect(find.byKey(const Key('ghost-race-panel')), findsOneWidget);
    expect(find.byKey(const Key('ghost-race-status-label')), findsOneWidget);
    expect(find.text('LEVEL'), findsOneWidget);
    expect(find.byKey(const Key('ghost-race-time-gap-value')), findsOneWidget);
    expect(find.text('0:00'), findsOneWidget);
    expect(find.text('고스트와 같은 위치'), findsOneWidget);
    expect(find.byKey(const Key('ghost-marker-layer')), findsOneWidget);
  });

  testWidgets(
    'stop from paused shows review and does not show the countdown overlay',
    (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
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
      await pumpUntilFound(tester, find.byKey(const Key('run-map')));

      await tester.tap(find.byKey(const Key('start-stop-button')));
      await tester.pump();
      await tester.pump(const Duration(seconds: 3));
      await tester.pump();

      await tester.tap(find.byKey(const Key('pause-run-button')));
      await tester.pump();

      expect(find.byKey(const Key('resume-run-button')), findsOneWidget);
      expect(find.byKey(const Key('live-run-metrics-panel')), findsOneWidget);
      expect(find.text('STOP'), findsOneWidget);

      await tester.tap(find.byKey(const Key('start-stop-button')));
      await tester.pump();

      expect(
        find.byKey(const Key('run-start-countdown-overlay')),
        findsNothing,
      );
      expect(find.byKey(const Key('live-run-metrics-panel')), findsNothing);
      expect(find.byKey(const Key('run-finish-review-panel')), findsOneWidget);
      expect(find.byKey(const Key('settings-button')), findsNothing);
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
