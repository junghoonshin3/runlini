import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:runlini/app/runlini_app.dart';
import 'package:runlini/core/location/location_stream_client.dart';
import 'package:runlini/core/map/map_coordinate.dart';
import 'package:runlini/features/run_tracking/state/run_session_providers.dart';
import 'package:runlini/features/run_tracking/state/run_settings_providers.dart';
import 'package:runlini/features/run_tracking/types/run_interval_workout.dart';
import 'package:runlini/features/run_tracking/types/run_settings.dart';
import 'package:runlini/features/run_tracking/ui/running/run_interval_sheet.dart';

import '../../helpers/fake_run_settings_repository.dart';
import '../../helpers/runlini_widget_harness.dart';

void main() {
  testWidgets('opens from the running tab without closing the app shell', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(390, 680);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final repository = FakeRunSettingsRepository();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          disableStartupWeightPromptOverride,
          runSettingsRepositoryProvider.overrideWithValue(repository),
          runSessionListProvider.overrideWith(
            (Ref ref) async => sampleRunSessions(),
          ),
          staticMapStateOverride(
            fallbackMapCenter: const MapCoordinate(
              latitude: 37.0,
              longitude: 127.0,
            ),
          ),
          deviceLocationClientProvider.overrideWithValue(
            const FakeDeviceLocationClient(),
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
    await pumpUntilFound(tester, find.byKey(const Key('run-interval-button')));
    expect(find.byKey(const Key('run-interval-entry-button')), findsNothing);

    await tester.tap(find.byKey(const Key('run-interval-button')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('run-map')), findsOneWidget);
    expect(find.byKey(const Key('run-interval-sheet-scroll')), findsOneWidget);

    await _bringSheetTargetIntoView(
      tester,
      find.byKey(const Key('run-interval-done-button')),
    );
    await tester.tap(find.byKey(const Key('run-interval-done-button')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('run-interval-sheet-scroll')), findsNothing);
  });

  testWidgets('renders and scrolls on a compact viewport without overflow', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(360, 480);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final repository = FakeRunSettingsRepository();
    await _pumpIntervalSheetHarness(tester, repository);

    await tester.tap(find.byKey(const Key('open-interval-sheet')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('run-interval-sheet-scroll')), findsOneWidget);

    await _bringSheetTargetIntoView(
      tester,
      find.byKey(const Key('run-interval-card-전후 준비')),
    );
    await _bringSheetTargetIntoView(
      tester,
      find.byKey(const Key('run-interval-done-button')),
    );

    expect(find.byKey(const Key('run-interval-card-전후 준비')), findsOneWidget);
    expect(find.byKey(const Key('run-interval-done-button')), findsOneWidget);
  });

  testWidgets('drags as a sheet and dismisses from the top', (
    WidgetTester tester,
  ) async {
    tester.view.padding = const FakeViewPadding(top: 84);
    tester.view.viewPadding = const FakeViewPadding(top: 84);
    addTearDown(tester.view.resetPadding);
    addTearDown(tester.view.resetViewPadding);

    final repository = FakeRunSettingsRepository();
    await _pumpIntervalSheetHarness(tester, repository);

    await tester.tap(find.byKey(const Key('open-interval-sheet')));
    await tester.pumpAndSettle();

    final draggable = find.byKey(const Key('run-interval-draggable-sheet'));
    expect(draggable, findsOneWidget);
    final handle = find.byKey(const Key('run-interval-drag-handle'));
    expect(find.byKey(const Key('run-interval-sheet-scroll')), findsOneWidget);
    expect(handle, findsOneWidget);

    expect(tester.getTopLeft(handle).dy, greaterThanOrEqualTo(28));

    await tester.drag(handle, const Offset(0, 620));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('run-interval-sheet-scroll')), findsNothing);
  });

  testWidgets('short pull down snaps interval sheet back to full height', (
    WidgetTester tester,
  ) async {
    tester.view.padding = const FakeViewPadding(top: 84);
    tester.view.viewPadding = const FakeViewPadding(top: 84);
    addTearDown(tester.view.resetPadding);
    addTearDown(tester.view.resetViewPadding);

    final repository = FakeRunSettingsRepository();
    await _pumpIntervalSheetHarness(tester, repository);

    await tester.tap(find.byKey(const Key('open-interval-sheet')));
    await tester.pumpAndSettle();

    final handle = find.byKey(const Key('run-interval-drag-handle'));
    final initialTop = tester.getTopLeft(handle).dy;

    await tester.drag(handle, const Offset(0, 80));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('run-interval-sheet-scroll')), findsOneWidget);
    expect(tester.getTopLeft(handle).dy, initialTop);
  });

  testWidgets('saves enabled, direct time target, and toggles immediately', (
    WidgetTester tester,
  ) async {
    final repository = FakeRunSettingsRepository();
    await _pumpIntervalSheetHarness(tester, repository);

    await tester.tap(find.byKey(const Key('open-interval-sheet')));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('run-interval-enabled-switch')));
    await tester.pumpAndSettle();

    expect(repository.settings.intervalWorkout.enabled, isTrue);

    await tester.enterText(
      find.byKey(const Key('run-interval-질주-direct-minutes')),
      '3',
    );
    await tester.enterText(
      find.byKey(const Key('run-interval-질주-direct-seconds')),
      '0',
    );
    await _bringSheetTargetIntoView(
      tester,
      find.byKey(const Key('run-interval-질주-direct-apply')),
    );
    await tester.tap(find.byKey(const Key('run-interval-질주-direct-apply')));
    await tester.pumpAndSettle();

    expect(repository.settings.intervalWorkout.work.durationMs, 180000);

    await _bringSheetTargetIntoView(
      tester,
      find.byKey(const Key('run-interval-repeat-increment')),
    );
    await tester.tap(find.byKey(const Key('run-interval-repeat-increment')));
    await tester.pumpAndSettle();

    expect(repository.settings.intervalWorkout.repeatCount, 9);

    await _bringSheetTargetIntoView(
      tester,
      find.byKey(const Key('run-interval-warmup-toggle')),
    );
    await tester.tap(find.byKey(const Key('run-interval-warmup-toggle')));
    await tester.pumpAndSettle();

    expect(
      repository.settings.intervalWorkout.warmup.type,
      RunIntervalTargetType.skip,
    );
  });

  testWidgets('repeat stepper clamps to 1 and 30', (WidgetTester tester) async {
    final repository = FakeRunSettingsRepository(
      const RunSettingsState(
        intervalWorkout: RunIntervalWorkout(repeatCount: 1),
      ),
    );
    await _pumpIntervalSheetHarness(tester, repository);

    await tester.tap(find.byKey(const Key('open-interval-sheet')));
    await tester.pumpAndSettle();

    await _bringSheetTargetIntoView(
      tester,
      find.byKey(const Key('run-interval-repeat-decrement')),
    );
    await tester.tap(find.byKey(const Key('run-interval-repeat-decrement')));
    await tester.pumpAndSettle();

    expect(repository.settings.intervalWorkout.repeatCount, 1);

    await tester.tap(find.byKey(const Key('run-interval-repeat-increment')));
    await tester.pumpAndSettle();

    expect(repository.settings.intervalWorkout.repeatCount, 2);

    repository.settings = const RunSettingsState(
      intervalWorkout: RunIntervalWorkout(repeatCount: 30),
    );
    await tester.pumpWidget(const SizedBox.shrink());
    await _pumpIntervalSheetHarness(tester, repository);
    await tester.tap(find.byKey(const Key('open-interval-sheet')));
    await tester.pumpAndSettle();

    await _bringSheetTargetIntoView(
      tester,
      find.byKey(const Key('run-interval-repeat-increment')),
    );
    await tester.tap(find.byKey(const Key('run-interval-repeat-increment')));
    await tester.pumpAndSettle();

    expect(repository.settings.intervalWorkout.repeatCount, 30);
  });
}

Future<void> _bringSheetTargetIntoView(
  WidgetTester tester,
  Finder finder,
) async {
  final scrollable = find.byKey(const Key('run-interval-sheet-scroll'));
  for (var index = 0; index < 8; index += 1) {
    if (finder.evaluate().isNotEmpty) {
      await tester.ensureVisible(finder);
      await tester.pumpAndSettle();
      return;
    }
    await tester.drag(scrollable, const Offset(0, -160));
    await tester.pumpAndSettle();
  }
}

Future<void> _pumpIntervalSheetHarness(
  WidgetTester tester,
  FakeRunSettingsRepository repository,
) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [runSettingsRepositoryProvider.overrideWithValue(repository)],
      child: MaterialApp(
        home: Scaffold(
          body: Consumer(
            builder: (context, ref, child) {
              return Center(
                child: ElevatedButton(
                  key: const Key('open-interval-sheet'),
                  onPressed: () => showRunIntervalSheet(context, ref),
                  child: const Text('open'),
                ),
              );
            },
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}
