import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:runlini/app/runlini_app.dart';
import 'package:runlini/core/location/location_stream_client.dart';
import 'package:runlini/features/run_tracking/repo/run_settings_repository.dart';
import 'package:runlini/features/run_tracking/state/run_session_providers.dart';
import 'package:runlini/features/run_tracking/state/run_settings_providers.dart';
import 'package:runlini/features/run_tracking/types/run_settings.dart';
import 'package:runlini/features/run_tracking/types/run_shoe.dart';

import 'helpers/runlini_widget_harness.dart';

void main() {
  testWidgets(
    'blocks the app shell with a weight screen until weight is saved',
    (WidgetTester tester) async {
      final settingsRepository = _PromptSettingsRepository();

      await _pumpApp(tester, settingsRepository);
      await pumpUntilFound(
        tester,
        find.byKey(const Key('startup-weight-screen')),
      );

      expect(find.byKey(const Key('history-list')), findsNothing);
      expect(find.byIcon(Icons.list_alt_rounded), findsNothing);
      expect(find.byKey(const Key('run-map')), findsNothing);

      await tester.enterText(
        find.byKey(const Key('startup-weight-input')),
        '5',
      );
      await tester.tap(find.byKey(const Key('startup-weight-save-button')));
      await tester.pump();

      expect(find.text('20kg부터 250kg 사이로 입력해 주세요.'), findsOneWidget);
      expect(find.byKey(const Key('startup-weight-screen')), findsOneWidget);

      await tester.enterText(
        find.byKey(const Key('startup-weight-input')),
        '70',
      );
      await tester.tap(find.byKey(const Key('startup-weight-save-button')));
      await pumpUntilFound(tester, find.byKey(const Key('history-list')));

      expect(settingsRepository.settings.bodyWeightKg, 70);
      expect(find.byKey(const Key('startup-weight-screen')), findsNothing);
    },
  );

  testWidgets('does not ask for body weight when it already exists', (
    WidgetTester tester,
  ) async {
    final settingsRepository = _PromptSettingsRepository(
      const RunSettingsState(bodyWeightKg: 70),
    );

    await _pumpApp(tester, settingsRepository);
    await pumpUntilFound(tester, find.byKey(const Key('history-list')));

    expect(find.byKey(const Key('startup-weight-screen')), findsNothing);
  });
}

Future<void> _pumpApp(
  WidgetTester tester,
  _PromptSettingsRepository settingsRepository,
) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        runSettingsRepositoryProvider.overrideWithValue(settingsRepository),
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
  await tester.pump();
}

class _PromptSettingsRepository implements RunSettingsRepository {
  _PromptSettingsRepository([this.settings = const RunSettingsState()]);

  RunSettingsState settings;
  final List<RunShoe> _shoes = <RunShoe>[];

  @override
  Future<RunSettingsState> loadSettings() async => settings;

  @override
  Future<void> saveSettings(RunSettingsState settings) async {
    this.settings = settings;
  }

  @override
  Future<List<RunShoe>> listShoes() async => List<RunShoe>.unmodifiable(_shoes);

  @override
  Future<void> saveShoe(RunShoe shoe) async {
    _shoes.removeWhere((RunShoe existing) => existing.id == shoe.id);
    _shoes.add(shoe);
  }

  @override
  Future<void> retireShoe(String id) async {
    final index = _shoes.indexWhere((RunShoe shoe) => shoe.id == id);
    if (index == -1) {
      return;
    }
    _shoes[index] = _shoes[index].copyWith(retired: true);
  }

  @override
  Future<void> deleteShoe(String id) async {
    final index = _shoes.indexWhere((RunShoe shoe) => shoe.id == id);
    if (index == -1) {
      return;
    }
    _shoes[index] = _shoes[index].copyWith(retired: true, deleted: true);
  }
}
