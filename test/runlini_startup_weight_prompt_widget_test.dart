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
  testWidgets('opens the app shell without body weight', (
    WidgetTester tester,
  ) async {
    final settingsRepository = _PromptSettingsRepository();

    await _pumpApp(tester, settingsRepository);
    await pumpUntilFound(tester, find.byKey(const Key('history-list')));

    expect(settingsRepository.settings.bodyWeightKg, isNull);
    expect(find.byKey(const Key('startup-weight-screen')), findsNothing);
    expect(find.byIcon(Icons.list_alt_rounded), findsOneWidget);
  });

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
