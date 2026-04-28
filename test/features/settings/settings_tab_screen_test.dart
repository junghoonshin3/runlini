import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:runlini/app/theme/app_theme.dart';
import 'package:runlini/features/run_tracking/repo/run_settings_repository.dart';
import 'package:runlini/features/run_tracking/state/run_session_providers.dart';
import 'package:runlini/features/run_tracking/state/run_settings_providers.dart';
import 'package:runlini/features/run_tracking/types/run_settings.dart';
import 'package:runlini/features/run_tracking/types/run_shoe.dart';
import 'package:runlini/features/settings/ui/settings_tab_screen.dart';

import '../../helpers/runlini_widget_harness.dart';

void main() {
  testWidgets('updates units, privacy, and running shoes', (tester) async {
    final repository = _FakeRunSettingsRepository();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          runSettingsRepositoryProvider.overrideWithValue(repository),
          runSessionListProvider.overrideWith((ref) async => const []),
        ],
        child: MaterialApp(
          theme: AppTheme.dark(),
          home: const Scaffold(body: SettingsTabScreen()),
        ),
      ),
    );
    await pumpUntilFound(tester, find.byKey(const Key('settings-tab-screen')));

    await tester.tap(find.byKey(const Key('countdown-seconds-5-button')));
    await tester.pumpAndSettle();
    expect(repository.settings.countdownSeconds, 5);

    await tester.tap(
      find.byKey(const Key('location-preset-highAccuracy-button')),
    );
    await tester.pumpAndSettle();
    expect(
      repository.settings.locationTrackingPreset,
      RunLocationTrackingPreset.highAccuracy,
    );

    await tester.tap(find.byKey(const Key('show-ghost-marker-switch')));
    await tester.pumpAndSettle();
    expect(repository.settings.showGhostMarker, isTrue);

    final saveWeightButton = find.byKey(const Key('save-runner-weight-button'));
    await tester.ensureVisible(saveWeightButton);
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('runner-weight-input')), '70');
    await tester.tap(saveWeightButton);
    await tester.pumpAndSettle();
    expect(repository.settings.bodyWeightKg, 70);

    await tester.tap(find.byKey(const Key('clear-runner-weight-button')));
    await tester.pumpAndSettle();
    expect(repository.settings.bodyWeightKg, isNull);

    await tester.tap(find.byKey(const Key('distance-unit-mi-button')));
    await tester.pumpAndSettle();
    expect(repository.settings.display.distanceUnit, RunDistanceUnit.mi);

    final weeklyGoalInput = find.byKey(const Key('weekly-distance-goal-input'));
    await tester.ensureVisible(weeklyGoalInput);
    await tester.pumpAndSettle();
    expect(find.text('12.4'), findsOneWidget);
    await tester.enterText(weeklyGoalInput, '10');
    await tester.enterText(
      find.byKey(const Key('monthly-distance-goal-input')),
      '25',
    );
    await tester.enterText(
      find.byKey(const Key('yearly-distance-goal-input')),
      '100',
    );
    final saveGoalsButton = find.byKey(const Key('save-distance-goals-button'));
    await tester.ensureVisible(saveGoalsButton);
    await tester.pumpAndSettle();
    await tester.tap(saveGoalsButton);
    await tester.pumpAndSettle();
    expect(repository.settings.distanceGoals.weeklyGoalM, closeTo(16093.44, 1));
    expect(repository.settings.distanceGoals.monthlyGoalM, closeTo(40233.6, 1));
    expect(repository.settings.distanceGoals.yearlyGoalM, closeTo(160934.4, 1));

    final hideRouteSwitchFinder = find
        .byKey(const Key('hide-route-map-switch'))
        .first;
    await tester.ensureVisible(hideRouteSwitchFinder);
    await tester.pumpAndSettle();
    await tester.tap(hideRouteSwitchFinder);
    await tester.pumpAndSettle();
    expect(repository.settings.privacy.hideRouteMap, isTrue);

    final addShoeButtonFinder = find.byKey(const Key('add-shoe-button')).first;
    await tester.ensureVisible(addShoeButtonFinder);
    await tester.pumpAndSettle();
    await tester.tap(addShoeButtonFinder);
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('shoe-name-field')), 'Pegasus');
    await tester.enterText(find.byKey(const Key('shoe-brand-field')), 'Nike');
    final saveShoeButton = find.byKey(const Key('save-shoe-button'));
    await tester.ensureVisible(saveShoeButton);
    await tester.tap(saveShoeButton);
    await tester.pumpAndSettle();

    expect(repository.shoes, hasLength(1));
    final firstShoe = repository.shoes.single;
    await tester.scrollUntilVisible(
      find.byKey(Key('shoe-item-${firstShoe.id}')),
      100,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    expect(find.text('Nike Pegasus'), findsOneWidget);
    expect(repository.settings.defaultShoeId, repository.shoes.single.id);

    final editFirstShoeFinder = find.byKey(Key('edit-shoe-${firstShoe.id}'));
    await tester.ensureVisible(editFirstShoeFinder);
    await tester.pumpAndSettle();
    await tester.tap(editFirstShoeFinder);
    await tester.pumpAndSettle();
    expect(find.text('러닝화 수정'), findsWidgets);
    await tester.enterText(
      find.byKey(const Key('shoe-name-field')),
      'Pegasus 41',
    );
    await tester.enterText(find.byKey(const Key('shoe-brand-field')), 'Nike');
    await tester.enterText(find.byKey(const Key('shoe-limit-field')), '750');
    await tester.tap(saveShoeButton);
    await tester.pumpAndSettle();
    expect(repository.shoes.single.name, 'Pegasus 41');
    expect(repository.shoes.single.distanceLimitKm, 750);
    expect(find.text('Nike Pegasus 41'), findsOneWidget);

    await tester.scrollUntilVisible(
      addShoeButtonFinder,
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    await tester.tap(addShoeButtonFinder);
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('shoe-name-field')), 'Boston');
    await tester.enterText(find.byKey(const Key('shoe-brand-field')), 'Adidas');
    await tester.ensureVisible(saveShoeButton);
    await tester.tap(saveShoeButton);
    await tester.pumpAndSettle();

    final secondShoe = repository.shoes.last;
    final defaultSecondShoeFinder = find.byKey(
      Key('default-shoe-${secondShoe.id}'),
    );
    await tester.scrollUntilVisible(
      defaultSecondShoeFinder,
      100,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    await tester.tap(defaultSecondShoeFinder);
    await tester.pumpAndSettle();
    expect(repository.settings.defaultShoeId, secondShoe.id);

    final retireSecondShoeFinder = find.byKey(
      Key('retire-shoe-${secondShoe.id}'),
    );
    await tester.ensureVisible(retireSecondShoeFinder);
    await tester.pumpAndSettle();
    await tester.tap(retireSecondShoeFinder);
    await tester.pumpAndSettle();
    expect(repository.shoes.last.retired, isTrue);
    expect(find.byKey(Key('shoe-item-${secondShoe.id}')), findsOneWidget);

    final coursesSecondShoeFinder = find.byKey(
      Key('shoe-courses-${secondShoe.id}'),
    );
    await tester.ensureVisible(coursesSecondShoeFinder);
    await tester.pumpAndSettle();
    await tester.tap(coursesSecondShoeFinder);
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('shoe-courses-screen')), findsOneWidget);
    expect(find.textContaining('0개 코스'), findsOneWidget);
    await tester.pageBack();
    await tester.pumpAndSettle();

    final deleteSecondShoeFinder = find.byKey(
      Key('delete-shoe-${secondShoe.id}'),
    );
    await tester.ensureVisible(deleteSecondShoeFinder);
    await tester.pumpAndSettle();
    await tester.tap(deleteSecondShoeFinder);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('confirm-delete-shoe-button')));
    await tester.pumpAndSettle();
    expect(repository.shoes.last.deleted, isTrue);
    expect(find.byKey(Key('shoe-item-${secondShoe.id}')), findsNothing);
  });
}

class _FakeRunSettingsRepository implements RunSettingsRepository {
  RunSettingsState settings = const RunSettingsState();
  final List<RunShoe> shoes = <RunShoe>[];

  @override
  Future<RunSettingsState> loadSettings() async => settings;

  @override
  Future<void> saveSettings(RunSettingsState settings) async {
    this.settings = settings;
  }

  @override
  Future<List<RunShoe>> listShoes() async => List<RunShoe>.unmodifiable(shoes);

  @override
  Future<void> saveShoe(RunShoe shoe) async {
    shoes.removeWhere((existing) => existing.id == shoe.id);
    shoes.add(shoe);
  }

  @override
  Future<void> retireShoe(String id) async {
    final index = shoes.indexWhere((shoe) => shoe.id == id);
    if (index >= 0) {
      shoes[index] = shoes[index].copyWith(retired: true);
    }
  }

  @override
  Future<void> deleteShoe(String id) async {
    final index = shoes.indexWhere((shoe) => shoe.id == id);
    if (index >= 0) {
      shoes[index] = shoes[index].copyWith(retired: true, deleted: true);
    }
  }
}
