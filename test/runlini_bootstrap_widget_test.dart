import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:runlini/app/runlini_app.dart';
import 'package:runlini/core/location/location_stream_client.dart';
import 'package:runlini/core/map/map_config_client.dart';
import 'package:runlini/core/map/map_coordinate.dart';
import 'package:runlini/features/run_tracking/state/run_playback_providers.dart';
import 'package:runlini/features/run_tracking/state/run_session_providers.dart';
import 'package:runlini/features/run_tracking/types/live_location_sample.dart';

import 'helpers/runlini_widget_harness.dart';

void main() {
  testWidgets('shows the history tab by default', (WidgetTester tester) async {
    final deviceLocationClient = _CountingDeviceLocationClient();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          disableStartupWeightPromptOverride,
          runSessionRepositoryProvider.overrideWithValue(
            FakeRunSessionRepository(sampleRunSessions()),
          ),
          locationStreamClientProvider.overrideWithValue(
            const SilentLocationStreamClient(),
          ),
          deviceLocationClientProvider.overrideWithValue(deviceLocationClient),
        ],
        child: const RunliniApp(),
      ),
    );
    await pumpUntilFound(tester, find.byKey(const Key('history-list')));

    expect(find.text('기록'), findsWidgets);
    expect(find.text('러닝'), findsOneWidget);
    expect(find.text('설정'), findsOneWidget);
    expect(find.byKey(const Key('history-list')), findsOneWidget);
    expect(
      find.byKey(const Key('history-session-fixture_morning_tempo')),
      findsOneWidget,
    );
    expect(find.byKey(const Key('run-map')), findsNothing);
    expect(find.byKey(const Key('settings-button')), findsNothing);
    expect(find.byKey(const Key('ghost-control-chip')), findsNothing);
    expect(find.byKey(const Key('current-location-button')), findsNothing);
    expect(find.byKey(const Key('start-stop-button')), findsNothing);
    expect(find.text('START'), findsNothing);
    expect(find.byKey(const Key('run-status-label')), findsNothing);
    expect(find.byKey(const Key('ghost-status-label')), findsNothing);
    expect(find.byKey(const Key('live-run-metrics-panel')), findsNothing);
    expect(find.byKey(const Key('pause-run-button')), findsNothing);
    expect(find.byKey(const Key('resume-run-button')), findsNothing);
    expect(deviceLocationClient.lastKnownFetchCount, 0);
    expect(deviceLocationClient.currentFetchCount, 0);
  });

  testWidgets('hides running controls while the map surface is not ready', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          disableStartupWeightPromptOverride,
          runMapControlsReadyProvider.overrideWithValue(false),
          staticMapStateOverride(
            fallbackMapCenter: const MapCoordinate(
              latitude: 37.0,
              longitude: 127.0,
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

    expect(find.byKey(const Key('run-map')), findsOneWidget);
    expect(find.byKey(const Key('run-interval-button')), findsNothing);
    expect(find.byKey(const Key('ghost-control-chip')), findsNothing);
    expect(find.byKey(const Key('current-location-button')), findsNothing);
    expect(find.byKey(const Key('start-stop-button')), findsNothing);
    expect(find.text('START'), findsNothing);
  });

  testWidgets(
    'shows the map immediately while initial location is still pending',
    (WidgetTester tester) async {
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
      await openRunningTab(tester);

      expect(find.byKey(const Key('run-map')), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsNothing);
      expect(find.byKey(const Key('runner-marker-layer')), findsNothing);

      delayedCurrentSample.complete(sample(latitude: 37.55, longitude: 126.97));
      await pumpUntilFound(
        tester,
        find.byKey(const Key('runner-marker-layer')),
      );

      expect(find.byKey(const Key('run-map')), findsOneWidget);
      expect(find.byKey(const Key('runner-marker-layer')), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsNothing);
    },
  );

  testWidgets('shows the runner marker when a cached device location exists', (
    WidgetTester tester,
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
        ],
        child: const RunliniApp(),
      ),
    );
    await tester.pump();
    await openRunningTab(tester);
    await pumpUntilFound(tester, find.byKey(const Key('runner-marker-layer')));

    expect(find.byKey(const Key('run-map')), findsOneWidget);
    expect(find.byKey(const Key('runner-marker-layer')), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsNothing);
  });

  testWidgets(
    'shows the fallback map without waiting for the startup timeout',
    (WidgetTester tester) async {
      final pendingCurrentSample = Completer<LiveLocationSample?>();

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
      await openRunningTab(tester);

      expect(find.byKey(const Key('run-map')), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsNothing);
      expect(find.byKey(const Key('runner-marker-layer')), findsNothing);

      pendingCurrentSample.complete(null);
      await tester.pump();
    },
  );

  testWidgets('shows the map fallback when initial location bootstrap fails', (
    WidgetTester tester,
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
    await openRunningTab(tester);
    await pumpUntilFound(tester, find.byKey(const Key('run-map')));

    expect(find.byKey(const Key('run-map')), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsNothing);
    expect(find.byKey(const Key('runner-marker-layer')), findsNothing);
  });
}

class _CountingDeviceLocationClient implements DeviceLocationClient {
  int lastKnownFetchCount = 0;
  int currentFetchCount = 0;

  @override
  Future<LiveLocationSample?> fetchLastKnownSample() async {
    lastKnownFetchCount += 1;
    return null;
  }

  @override
  Future<LiveLocationSample?> fetchCurrentSample() async {
    currentFetchCount += 1;
    return null;
  }
}
