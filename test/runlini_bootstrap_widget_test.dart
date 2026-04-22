import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:runlini/app/runlini_app.dart';
import 'package:runlini/core/location/location_stream_client.dart';
import 'package:runlini/core/map/map_coordinate.dart';
import 'package:runlini/features/run_tracking/state/run_playback_providers.dart';
import 'package:runlini/features/run_tracking/state/run_session_providers.dart';
import 'package:runlini/features/run_tracking/types/live_location_sample.dart';

import 'helpers/runlini_widget_harness.dart';

void main() {
  testWidgets('shows the running tab by default', (WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          runSessionListProvider.overrideWith(
            (Ref ref) async => sampleRunSessions(),
          ),
          locationStreamClientProvider.overrideWithValue(
            const SilentLocationStreamClient(),
          ),
        ],
        child: const RunliniApp(),
      ),
    );
    await pumpUntilFound(tester, find.byKey(const Key('run-map')));

    expect(find.text('기록'), findsOneWidget);
    expect(find.text('러닝'), findsOneWidget);
    expect(find.byKey(const Key('run-map')), findsOneWidget);
    expect(find.byKey(const Key('settings-button')), findsOneWidget);
    expect(find.byKey(const Key('current-location-button')), findsOneWidget);
    expect(find.byKey(const Key('start-stop-button')), findsOneWidget);
    expect(find.text('START'), findsOneWidget);
    expect(find.byKey(const Key('run-status-label')), findsNothing);
    expect(find.byKey(const Key('ghost-status-label')), findsNothing);
    expect(find.byKey(const Key('live-run-metrics-panel')), findsNothing);
    expect(find.byKey(const Key('pause-run-button')), findsNothing);
    expect(find.byKey(const Key('resume-run-button')), findsNothing);
  });

  testWidgets(
    'waits for the initial location bootstrap before mounting the map',
    (WidgetTester tester) async {
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
                  delayedCurrentSample.future,
                ],
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

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.byKey(const Key('run-map')), findsNothing);

      delayedCurrentSample.complete(sample(latitude: 37.55, longitude: 126.97));
      await pumpUntilFound(tester, find.byKey(const Key('run-map')));

      expect(find.byKey(const Key('run-map')), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsNothing);
    },
  );

  testWidgets('shows the runner marker when a cached device location exists', (
    WidgetTester tester,
  ) async {
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
    await pumpUntilFound(tester, find.byKey(const Key('runner-marker-layer')));

    expect(find.byKey(const Key('run-map')), findsOneWidget);
    expect(find.byKey(const Key('runner-marker-layer')), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsNothing);
  });

  testWidgets(
    'falls back to the fixture center only after the startup timeout',
    (WidgetTester tester) async {
      final pendingCurrentSample = Completer<LiveLocationSample?>();

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
                  pendingCurrentSample.future,
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

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.byKey(const Key('run-map')), findsNothing);

      await tester.pump(const Duration(milliseconds: 20));

      expect(find.byKey(const Key('run-map')), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsNothing);
      expect(find.byKey(const Key('runner-marker-layer')), findsNothing);
    },
  );

  testWidgets('shows the map fallback when initial location bootstrap fails', (
    WidgetTester tester,
  ) async {
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
            const ThrowingDeviceLocationClient(),
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

    expect(find.byKey(const Key('run-map')), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsNothing);
    expect(find.byKey(const Key('runner-marker-layer')), findsNothing);
  });
}
