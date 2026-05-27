// START 카운트다운 중 하단 컨트롤 종료 모션을 검증한다.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:runlini/app/runlini_app.dart';
import 'package:runlini/app/ui/runlini_motion.dart';
import 'package:runlini/core/location/location_stream_client.dart';
import 'package:runlini/core/map/map_coordinate.dart';
import 'package:runlini/features/run_tracking/state/run_start_countdown_providers.dart';

import 'helpers/runlini_widget_harness.dart';

void main() {
  testWidgets(
    'start keeps the countdown immediate while bottom controls exit disabled',
    (WidgetTester tester) async {
      await _pumpRunningApp(tester);

      await tester.tap(find.byKey(const Key('start-stop-button')));
      await tester.pump();

      expect(
        find.byKey(const Key('run-start-countdown-overlay')),
        findsOneWidget,
      );
      expect(find.byKey(const Key('start-stop-button')), findsOneWidget);
      expect(find.byKey(const Key('run-interval-button')), findsOneWidget);
      expect(find.byKey(const Key('current-location-button')), findsOneWidget);

      final intervalCenter = tester.getCenter(
        find.byKey(const Key('run-interval-button')),
      );
      await tester.tapAt(intervalCenter);
      await tester.pump();

      expect(find.byKey(const Key('run-interval-sheet')), findsNothing);
      expect(
        find.byKey(const Key('run-start-countdown-overlay')),
        findsOneWidget,
      );

      await tester.pump(
        RunliniMotion.shortTransition + const Duration(milliseconds: 1),
      );
      await tester.pump();

      expect(find.byKey(const Key('start-stop-button')), findsNothing);
      expect(find.byKey(const Key('run-interval-button')), findsNothing);
      expect(find.byKey(const Key('current-location-button')), findsNothing);
      expect(tester.hasRunningAnimations, isTrue);

      await tester.pumpAndSettle();
    },
  );

  testWidgets('start removes bottom controls immediately with reduce motion', (
    WidgetTester tester,
  ) async {
    tester.binding.platformDispatcher.accessibilityFeaturesTestValue =
        const FakeAccessibilityFeatures(disableAnimations: true);
    addTearDown(
      tester.binding.platformDispatcher.clearAccessibilityFeaturesTestValue,
    );

    await _pumpRunningApp(tester);

    await tester.tap(find.byKey(const Key('start-stop-button')));
    await tester.pump();

    expect(
      find.byKey(const Key('run-start-countdown-overlay')),
      findsOneWidget,
    );
    expect(find.byKey(const Key('start-stop-button')), findsNothing);
    expect(find.byKey(const Key('run-interval-button')), findsNothing);
    expect(find.byKey(const Key('current-location-button')), findsNothing);

    await tester.pump(const Duration(seconds: 3));
    await tester.pump();
  });

  testWidgets('failed start restores bottom controls enabled', (
    WidgetTester tester,
  ) async {
    await _pumpRunningApp(
      tester,
      deviceLocationClient: SequencedDeviceLocationClient(),
      countdownStep: const Duration(milliseconds: 10),
    );

    await tester.tap(find.byKey(const Key('start-stop-button')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 30));
    await tester.pump(RunliniMotion.shortTransition);

    expect(find.byKey(const Key('run-start-countdown-overlay')), findsNothing);
    expect(find.byKey(const Key('start-stop-button')), findsOneWidget);
    expect(find.byKey(const Key('run-interval-button')), findsOneWidget);
    expect(find.byKey(const Key('current-location-button')), findsOneWidget);
    expect(
      tester
          .widget<FilledButton>(find.byKey(const Key('start-stop-button')))
          .onPressed,
      isNotNull,
    );
    expect(
      tester
          .widget<OutlinedButton>(find.byKey(const Key('run-interval-button')))
          .onPressed,
      isNotNull,
    );
    expect(
      tester
          .widget<IconButton>(find.byKey(const Key('current-location-button')))
          .onPressed,
      isNotNull,
    );
  });
}

Future<void> _pumpRunningApp(
  WidgetTester tester, {
  DeviceLocationClient deviceLocationClient = const FakeDeviceLocationClient(
    lastKnownSample: null,
  ),
  Duration countdownStep = const Duration(seconds: 1),
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
          deviceLocationClient is FakeDeviceLocationClient &&
                  deviceLocationClient.lastKnownSample == null
              ? FakeDeviceLocationClient(
                  lastKnownSample: sample(latitude: 37.55, longitude: 126.97),
                )
              : deviceLocationClient,
        ),
        locationStreamClientProvider.overrideWithValue(
          const SilentLocationStreamClient(),
        ),
        runStartCountdownStepDurationProvider.overrideWithValue(countdownStep),
      ],
      child: const RunliniApp(),
    ),
  );
  await tester.pump();
  await openRunningTab(tester);
  await pumpUntilFound(tester, find.byKey(const Key('run-map')));
}
