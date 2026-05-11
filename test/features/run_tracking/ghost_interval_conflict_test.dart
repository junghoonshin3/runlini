import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:runlini/app/runlini_app.dart';
import 'package:runlini/core/location/location_stream_client.dart';
import 'package:runlini/core/map/map_coordinate.dart';
import 'package:runlini/features/run_tracking/state/run_interval_providers.dart';
import 'package:runlini/features/run_tracking/state/run_live_metrics_providers.dart';
import 'package:runlini/features/run_tracking/state/run_session_providers.dart';
import 'package:runlini/features/run_tracking/state/run_settings_providers.dart';
import 'package:runlini/features/run_tracking/state/run_start_countdown_providers.dart';
import 'package:runlini/features/run_tracking/types/live_run_metrics.dart';
import 'package:runlini/features/run_tracking/types/run_interval_workout.dart';
import 'package:runlini/features/run_tracking/types/run_settings.dart';

import '../../helpers/fake_run_settings_repository.dart';
import '../../helpers/runlini_widget_harness.dart';

void main() {
  testWidgets('selecting a ghost ignores a locked enabled interval', (
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
    await _selectFirstGhost(tester);
    await tester.pumpAndSettle();

    expect(
      find.byKey(const Key('ghost-interval-conflict-dialog')),
      findsNothing,
    );
    expect(repository.settings.intervalWorkout.enabled, isTrue);
    expect(find.text('Ghost Run On'), findsOneWidget);
  });

  testWidgets('locked interval button keeps a selected ghost on', (
    WidgetTester tester,
  ) async {
    final repository = FakeRunSettingsRepository();
    await _pumpRunningApp(tester, repository);

    await tester.tap(find.byKey(const Key('ghost-control-chip')));
    await pumpUntilFound(tester, find.byKey(const Key('ghost-session-sheet')));
    await _selectFirstGhost(tester);
    await pumpUntilFound(tester, find.text('Ghost Run On'));

    await tester.tap(find.byKey(const Key('run-interval-button')));
    await tester.pumpAndSettle();

    expect(find.text(runIntervalFeatureLockedMessage), findsOneWidget);
    expect(
      find.byKey(const Key('interval-ghost-conflict-dialog')),
      findsNothing,
    );
    expect(find.byKey(const Key('run-interval-sheet-scroll')), findsNothing);
    expect(find.text('Ghost Run On'), findsOneWidget);
  });

  testWidgets('start ignores locked stale interval state before countdown', (
    WidgetTester tester,
  ) async {
    final repository = FakeRunSettingsRepository(
      const RunSettingsState(
        locationTrackingPreset: RunLocationTrackingPreset.highAccuracy,
        intervalWorkout: RunIntervalWorkout(enabled: true),
      ),
    );
    await _pumpRunningApp(tester, repository, selectedGhost: true);

    await tester.tap(find.byKey(const Key('start-stop-button')));
    await tester.pump();

    expect(
      find.byKey(const Key('ghost-interval-conflict-dialog')),
      findsNothing,
    );
    expect(repository.settings.intervalWorkout.enabled, isTrue);
    expect(
      find.byKey(const Key('run-start-countdown-overlay')),
      findsOneWidget,
    );
    await tester.pump(const Duration(milliseconds: 30));
    await tester.pump();
  });

  test('interval frame is null while interval feature is locked', () async {
    final repository = FakeRunSettingsRepository(
      const RunSettingsState(
        intervalWorkout: RunIntervalWorkout(enabled: true),
      ),
    );
    final container = ProviderContainer(
      overrides: [
        runSettingsRepositoryProvider.overrideWithValue(repository),
        liveRunMetricsProvider.overrideWithValue(
          const LiveRunMetrics(
            distanceKm: 0.25,
            elapsedMs: 30000,
            averagePaceSecPerKm: 300,
            averageSpeedKmh: 12,
            caloriesKcal: 12,
            isPaused: false,
          ),
        ),
      ],
    );
    addTearDown(container.dispose);
    await container.read(runSettingsControllerProvider.future);

    expect(container.read(runIntervalFrameProvider), isNull);
    expect(repository.settings.intervalWorkout.enabled, isTrue);
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

Future<void> _selectFirstGhost(WidgetTester tester) async {
  await tester.ensureVisible(
    find.byKey(const Key('ghost-session-select-fixture_morning_tempo')),
  );
  await tester.pumpAndSettle();
  await tester.tap(
    find.byKey(const Key('ghost-session-select-fixture_morning_tempo')),
  );
  await tester.pumpAndSettle();
}
