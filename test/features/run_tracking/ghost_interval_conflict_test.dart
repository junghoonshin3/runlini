import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:runlini/app/runlini_app.dart';
import 'package:runlini/core/location/location_stream_client.dart';
import 'package:runlini/core/map/map_coordinate.dart';
import 'package:runlini/features/ghost_racer/state/ghost_racer_providers.dart';
import 'package:runlini/features/run_tracking/state/run_interval_providers.dart';
import 'package:runlini/features/run_tracking/state/run_session_providers.dart';
import 'package:runlini/features/run_tracking/state/run_settings_providers.dart';
import 'package:runlini/features/run_tracking/state/run_start_countdown_providers.dart';
import 'package:runlini/features/run_tracking/types/run_interval_workout.dart';
import 'package:runlini/features/run_tracking/types/run_session_summary.dart';
import 'package:runlini/features/run_tracking/types/run_settings.dart';
import 'package:runlini/features/run_tracking/ui/history/run_session_summary_tile.dart';

import '../../helpers/fake_run_settings_repository.dart';
import '../../helpers/runlini_widget_harness.dart';

void main() {
  testWidgets('selecting a ghost can disable an active interval', (
    WidgetTester tester,
  ) async {
    final repository = FakeRunSettingsRepository(
      const RunSettingsState(
        intervalWorkout: RunIntervalWorkout(enabled: true),
      ),
    );
    await _pumpRunningApp(tester, repository);

    await tester.tap(find.byKey(const Key('ghost-control-chip')));
    await pumpUntilFound(tester, find.byKey(const Key('ghost-session-sheet')));
    _selectFirstGhost();
    await tester.pumpAndSettle();

    expect(
      find.byKey(const Key('ghost-interval-conflict-dialog')),
      findsOneWidget,
    );
    await tester.tap(
      find.byKey(const Key('disable-interval-for-ghost-button')),
    );
    await tester.pumpAndSettle();

    expect(repository.settings.intervalWorkout.enabled, isFalse);
    expect(find.text('Ghost Run On'), findsOneWidget);
  });

  testWidgets('cancelling a ghost conflict keeps interval on and ghost off', (
    WidgetTester tester,
  ) async {
    final repository = FakeRunSettingsRepository(
      const RunSettingsState(
        intervalWorkout: RunIntervalWorkout(enabled: true),
      ),
    );
    await _pumpRunningApp(tester, repository);

    await tester.tap(find.byKey(const Key('ghost-control-chip')));
    await pumpUntilFound(tester, find.byKey(const Key('ghost-session-sheet')));
    _selectFirstGhost();
    await tester.pumpAndSettle();

    await tester.tap(find.text('취소'));
    await tester.pumpAndSettle();

    expect(repository.settings.intervalWorkout.enabled, isTrue);
    expect(find.text('Ghost Run Off'), findsOneWidget);
  });

  testWidgets('enabling interval can clear a selected ghost', (
    WidgetTester tester,
  ) async {
    final repository = FakeRunSettingsRepository();
    await _pumpRunningApp(tester, repository);

    await tester.tap(find.byKey(const Key('ghost-control-chip')));
    await pumpUntilFound(tester, find.byKey(const Key('ghost-session-sheet')));
    _selectFirstGhost();
    await pumpUntilFound(tester, find.text('Ghost Run On'));

    await tester.tap(find.byKey(const Key('run-interval-button')));
    await pumpUntilFound(
      tester,
      find.byKey(const Key('run-interval-enabled-switch')),
    );
    await tester.ensureVisible(
      find.byKey(const Key('run-interval-enabled-switch')),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('run-interval-enabled-switch')));
    await tester.pumpAndSettle();

    expect(
      find.byKey(const Key('interval-ghost-conflict-dialog')),
      findsOneWidget,
    );
    await tester.tap(
      find.byKey(const Key('disable-ghost-for-interval-button')),
    );
    await tester.pumpAndSettle();

    expect(repository.settings.intervalWorkout.enabled, isTrue);
    await _bringIntervalTargetIntoView(
      tester,
      find.byKey(const Key('run-interval-done-button')),
    );
    await tester.tap(find.byKey(const Key('run-interval-done-button')));
    await tester.pumpAndSettle();
    expect(find.text('Ghost Run Off'), findsOneWidget);
  });

  testWidgets(
    'start resolves stale ghost and interval state before countdown',
    (WidgetTester tester) async {
      final repository = FakeRunSettingsRepository(
        const RunSettingsState(
          locationTrackingPreset: RunLocationTrackingPreset.highAccuracy,
          intervalWorkout: RunIntervalWorkout(enabled: true),
        ),
      );
      await _pumpRunningApp(tester, repository, selectedGhost: true);

      await tester.tap(find.byKey(const Key('start-stop-button')));
      await tester.pumpAndSettle();

      expect(
        find.byKey(const Key('ghost-interval-conflict-dialog')),
        findsOneWidget,
      );
      expect(
        find.byKey(const Key('run-start-countdown-overlay')),
        findsNothing,
      );

      await tester.tap(
        find.byKey(const Key('disable-interval-for-ghost-button')),
      );
      await tester.pump();

      expect(repository.settings.intervalWorkout.enabled, isFalse);
      expect(
        find.byKey(const Key('run-start-countdown-overlay')),
        findsOneWidget,
      );
      await tester.pump(const Duration(milliseconds: 30));
      await tester.pump();
    },
  );

  test('interval frame is null while a ghost session is selected', () async {
    final repository = FakeRunSettingsRepository(
      const RunSettingsState(
        intervalWorkout: RunIntervalWorkout(enabled: true),
      ),
    );
    final container = ProviderContainer(
      overrides: [runSettingsRepositoryProvider.overrideWithValue(repository)],
    );
    addTearDown(container.dispose);
    await container.read(runSettingsControllerProvider.future);
    container
        .read(ghostSettingsProvider.notifier)
        .selectSession(RunSessionSummary.fromSession(ghostSession()));

    expect(container.read(runIntervalFrameProvider), isNull);
  });
}

Future<void> _pumpRunningApp(
  WidgetTester tester,
  FakeRunSettingsRepository repository, {
  bool selectedGhost = false,
}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        disableStartupWeightPromptOverride,
        runSettingsRepositoryProvider.overrideWithValue(repository),
        runSessionRepositoryProvider.overrideWithValue(
          FakeRunSessionRepository(sampleRunSessions()),
        ),
        if (selectedGhost)
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

void _selectFirstGhost() {
  testerWidget<RunSessionSummaryTile>(
    find.byKey(const Key('ghost-session-item-fixture_han_river_push')),
  ).onTap!();
}

Future<void> _bringIntervalTargetIntoView(
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

T testerWidget<T extends Widget>(Finder finder) {
  final element = finder.evaluate().single;
  return element.widget as T;
}
