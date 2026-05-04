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
  testWidgets(
    'start shows countdown immediately without Health permission preflight',
    (WidgetTester tester) async {
      final healthRecorder = FakeHealthWorkoutRecorder();

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

      await tester.tap(find.byKey(const Key('start-stop-button')));
      await tester.pump();

      expect(healthRecorder.prepareCalls, 0);
      expect(healthRecorder.beginCalls, 0);
      expect(
        find.byKey(const Key('run-start-countdown-overlay')),
        findsOneWidget,
      );
      expect(find.text('3'), findsOneWidget);

      await tester.pump(const Duration(milliseconds: 30));
      await tester.pump();

      expect(
        find.byKey(const Key('run-start-countdown-overlay')),
        findsNothing,
      );
      expect(find.byKey(const Key('live-run-metrics-panel')), findsOneWidget);
      expect(healthRecorder.beginCalls, 0);
    },
  );

  testWidgets(
    'start shows a full countdown overlay and only enters running after it completes',
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

      expect(
        find.byKey(const Key('run-start-countdown-overlay')),
        findsOneWidget,
      );
      expect(
        find.byKey(const Key('run-start-countdown-number')),
        findsOneWidget,
      );
      expect(find.text('3'), findsOneWidget);
      expect(find.text('RUNNING'), findsNothing);

      for (final label in const <String>['3', '2', '1']) {
        await tester.pump(const Duration(milliseconds: 500));
        expect(
          find.byKey(const Key('run-start-countdown-overlay')),
          findsOneWidget,
        );
        expect(find.text(label), findsOneWidget);
        expect(find.text('RUNNING'), findsNothing);
        await tester.pump(const Duration(milliseconds: 500));
      }
      await tester.pump();

      expect(
        find.byKey(const Key('run-start-countdown-overlay')),
        findsNothing,
      );
      expect(find.byKey(const Key('live-run-metrics-panel')), findsOneWidget);
      expect(find.byKey(const Key('run-status-label')), findsNothing);
      expect(find.byKey(const Key('ghost-status-label')), findsNothing);
      expect(find.byKey(const Key('pause-run-button')), findsOneWidget);
      expect(find.byKey(const Key('settings-button')), findsNothing);
      expect(find.byKey(const Key('ghost-control-chip')), findsNothing);
      expect(find.text('STOP'), findsOneWidget);
    },
  );

  testWidgets(
    'countdown blocks bottom navigation and underlying running-tab actions',
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

      expect(find.byKey(const Key('ghost-control-chip')), findsNothing);
      await tester.tapAt(tester.getCenter(find.text('기록')));
      await tester.pump();
      expect(find.byKey(const Key('history-list')), findsNothing);
      expect(
        find.byKey(const Key('run-start-countdown-overlay')),
        findsOneWidget,
      );

      expect(find.byKey(const Key('settings-button')), findsNothing);
      expect(find.byKey(const Key('run-interval-button')), findsNothing);
      await tester.pump();
      expect(find.byKey(const Key('settings-tab-screen')), findsNothing);
      expect(
        find.byKey(const Key('run-start-countdown-overlay')),
        findsOneWidget,
      );

      await tester.pump(const Duration(seconds: 3));
      await tester.pump();
    },
  );

  testWidgets(
    'countdown disappears and shows the start error snackbar when no location is available',
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
              SequencedDeviceLocationClient(),
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

      await tester.tap(find.byKey(const Key('start-stop-button')));
      await tester.pump();

      expect(
        find.byKey(const Key('run-start-countdown-overlay')),
        findsOneWidget,
      );
      expect(
        find.byKey(const Key('run-start-countdown-number')),
        findsOneWidget,
      );

      await tester.pump(const Duration(milliseconds: 30));
      await tester.pump();

      expect(
        find.byKey(const Key('run-start-countdown-overlay')),
        findsNothing,
      );
      expect(
        find.text('러닝 위치 추적을 시작하지 못했어요. GPS와 위치 권한을 확인해 주세요.'),
        findsOneWidget,
      );
      expect(find.text('RUNNING'), findsNothing);
    },
  );
}
