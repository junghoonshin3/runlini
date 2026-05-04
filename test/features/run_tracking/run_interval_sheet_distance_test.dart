import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:runlini/features/run_tracking/repo/run_settings_repository.dart';
import 'package:runlini/features/run_tracking/state/run_settings_providers.dart';
import 'package:runlini/features/run_tracking/types/run_interval_workout.dart';
import 'package:runlini/features/run_tracking/types/run_settings.dart';
import 'package:runlini/features/run_tracking/types/run_shoe.dart';
import 'package:runlini/features/run_tracking/ui/running/run_interval_sheet.dart';
import 'package:runlini/features/run_tracking/ui/running/run_interval_sheet_components.dart';

void main() {
  testWidgets('supports distance targets for work and recovery', (
    WidgetTester tester,
  ) async {
    final repository = _FakeRunSettingsRepository();
    await _pumpIntervalSheetHarness(tester, repository);

    await tester.tap(find.byKey(const Key('open-interval-sheet')));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('run-interval-질주-mode-distance')));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('run-interval-질주-direct-distance')),
      '400',
    );
    await _bringSheetTargetIntoView(
      tester,
      find.byKey(const Key('run-interval-질주-direct-apply')),
    );
    await tester.tap(find.byKey(const Key('run-interval-질주-direct-apply')));
    await tester.pumpAndSettle();

    expect(
      repository.settings.intervalWorkout.work.type,
      RunIntervalTargetType.distance,
    );
    expect(repository.settings.intervalWorkout.work.distanceM, 400);

    await _bringSheetTargetIntoView(
      tester,
      find.byKey(const Key('run-interval-휴식-mode-distance')),
    );
    await tester.tap(find.byKey(const Key('run-interval-휴식-mode-distance')));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('run-interval-휴식-direct-distance')),
      '200',
    );
    await _bringSheetTargetIntoView(
      tester,
      find.byKey(const Key('run-interval-휴식-direct-apply')),
    );
    await tester.tap(find.byKey(const Key('run-interval-휴식-direct-apply')));
    await tester.pumpAndSettle();

    expect(
      repository.settings.intervalWorkout.recovery.type,
      RunIntervalTargetType.distance,
    );
    expect(repository.settings.intervalWorkout.recovery.distanceM, 200);
  });

  testWidgets('allows mixed distance work and timed recovery', (
    WidgetTester tester,
  ) async {
    final repository = _FakeRunSettingsRepository();
    await _pumpIntervalSheetHarness(tester, repository);

    await tester.tap(find.byKey(const Key('open-interval-sheet')));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('run-interval-질주-mode-distance')));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('run-interval-질주-direct-distance')),
      '400',
    );
    await _bringSheetTargetIntoView(
      tester,
      find.byKey(const Key('run-interval-질주-direct-apply')),
    );
    await tester.tap(find.byKey(const Key('run-interval-질주-direct-apply')));
    await tester.pumpAndSettle();

    await _bringSheetTargetIntoView(
      tester,
      find.byKey(const Key('run-interval-휴식-mode-time')),
    );
    await tester.tap(find.byKey(const Key('run-interval-휴식-mode-time')));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('run-interval-휴식-direct-minutes')),
      '1',
    );
    await tester.enterText(
      find.byKey(const Key('run-interval-휴식-direct-seconds')),
      '0',
    );
    await _bringSheetTargetIntoView(
      tester,
      find.byKey(const Key('run-interval-휴식-direct-apply')),
    );
    await tester.tap(find.byKey(const Key('run-interval-휴식-direct-apply')));
    await tester.pumpAndSettle();

    final workout = repository.settings.intervalWorkout;
    expect(workout.work.distanceM, 400);
    expect(workout.recovery.durationMs, 60000);
    expect(runIntervalWorkoutSummary(workout), contains('질주 400m'));
    expect(runIntervalWorkoutSummary(workout), contains('휴식 1분'));
  });

  testWidgets('hides presets and horizontal option chips', (
    WidgetTester tester,
  ) async {
    final repository = _FakeRunSettingsRepository();
    await _pumpIntervalSheetHarness(tester, repository);

    await tester.tap(find.byKey(const Key('open-interval-sheet')));
    await tester.pumpAndSettle();

    expect(find.text('프리셋'), findsNothing);
    expect(find.text('30초/30초'), findsNothing);
    expect(find.text('800m/400m'), findsNothing);
    expect(find.byKey(const Key('run-interval-preset-options')), findsNothing);
    expect(find.byKey(const Key('run-interval-질주-options')), findsNothing);
    expect(find.byKey(const Key('run-interval-휴식-options')), findsNothing);
    expect(find.text('오픈'), findsNothing);
    expect(find.text('끄기'), findsNothing);
  });

  testWidgets('direct input saves custom time and distance targets', (
    WidgetTester tester,
  ) async {
    final repository = _FakeRunSettingsRepository();
    await _pumpIntervalSheetHarness(tester, repository);

    await tester.tap(find.byKey(const Key('open-interval-sheet')));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const Key('run-interval-질주-direct-minutes')),
      '1',
    );
    await tester.enterText(
      find.byKey(const Key('run-interval-질주-direct-seconds')),
      '20',
    );
    await _bringSheetTargetIntoView(
      tester,
      find.byKey(const Key('run-interval-질주-direct-apply')),
    );
    await tester.tap(find.byKey(const Key('run-interval-질주-direct-apply')));
    await tester.pumpAndSettle();

    expect(repository.settings.intervalWorkout.work.durationMs, 80000);

    await _bringSheetTargetIntoView(
      tester,
      find.byKey(const Key('run-interval-휴식-mode-distance')),
    );
    await tester.tap(find.byKey(const Key('run-interval-휴식-mode-distance')));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('run-interval-휴식-direct-distance')),
      '350',
    );
    await _bringSheetTargetIntoView(
      tester,
      find.byKey(const Key('run-interval-휴식-direct-apply')),
    );
    await tester.tap(find.byKey(const Key('run-interval-휴식-direct-apply')));
    await tester.pumpAndSettle();

    final workout = repository.settings.intervalWorkout;
    expect(workout.recovery.distanceM, 350);
    expect(runIntervalWorkoutSummary(workout), contains('질주 1:20'));
    expect(runIntervalWorkoutSummary(workout), contains('휴식 350m'));
  });

  testWidgets('direct input clamps custom interval values', (
    WidgetTester tester,
  ) async {
    final repository = _FakeRunSettingsRepository();
    await _pumpIntervalSheetHarness(tester, repository);

    await tester.tap(find.byKey(const Key('open-interval-sheet')));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const Key('run-interval-질주-direct-minutes')),
      '0',
    );
    await tester.enterText(
      find.byKey(const Key('run-interval-질주-direct-seconds')),
      '1',
    );
    await _bringSheetTargetIntoView(
      tester,
      find.byKey(const Key('run-interval-질주-direct-apply')),
    );
    await tester.tap(find.byKey(const Key('run-interval-질주-direct-apply')));
    await tester.pumpAndSettle();

    expect(repository.settings.intervalWorkout.work.durationMs, 10000);

    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();
    await _bringSheetTargetIntoView(
      tester,
      find.byKey(const Key('run-interval-질주-mode-distance')),
    );
    await tester.tap(find.byKey(const Key('run-interval-질주-mode-distance')));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('run-interval-질주-direct-distance')),
      '20000',
    );
    await _bringSheetTargetIntoView(
      tester,
      find.byKey(const Key('run-interval-질주-direct-apply')),
    );
    await tester.tap(find.byKey(const Key('run-interval-질주-direct-apply')));
    await tester.pumpAndSettle();

    expect(repository.settings.intervalWorkout.work.distanceM, 10000);
  });
}

Future<void> _pumpIntervalSheetHarness(
  WidgetTester tester,
  _FakeRunSettingsRepository repository,
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

class _FakeRunSettingsRepository implements RunSettingsRepository {
  _FakeRunSettingsRepository();

  RunSettingsState settings = const RunSettingsState();

  @override
  Future<RunSettingsState> loadSettings() async => settings;

  @override
  Future<void> saveSettings(RunSettingsState settings) async {
    this.settings = settings;
  }

  @override
  Future<List<RunShoe>> listShoes() async => const <RunShoe>[];

  @override
  Future<void> saveShoe(RunShoe shoe) async {}

  @override
  Future<void> retireShoe(String id) async {}

  @override
  Future<void> deleteShoe(String id) async {}
}
