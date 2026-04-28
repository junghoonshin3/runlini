import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:runlini/app/theme/app_theme.dart';
import 'package:runlini/features/run_tracking/repo/run_settings_repository.dart';
import 'package:runlini/features/run_tracking/state/run_session_providers.dart';
import 'package:runlini/features/run_tracking/state/run_settings_providers.dart';
import 'package:runlini/features/run_tracking/types/run_session.dart';
import 'package:runlini/features/run_tracking/types/run_settings.dart';
import 'package:runlini/features/run_tracking/types/run_shoe.dart';
import 'package:runlini/features/run_tracking/ui/detail/run_session_detail_screen.dart';

import '../../helpers/runlini_widget_harness.dart';

void main() {
  testWidgets('adds a shoe from run detail and attaches it to the run', (
    tester,
  ) async {
    final session = RunSession(
      id: 'run-a',
      startedAt: DateTime(2026, 4, 26, 7),
      distanceM: 5000,
      durationMs: 30 * 60 * 1000,
      sourceSummary: 'app',
      points: const [],
    );
    final sessionRepository = FakeRunSessionRepository([session]);
    final settingsRepository = _FakeRunSettingsRepository();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          runSessionRepositoryProvider.overrideWithValue(sessionRepository),
          runSettingsRepositoryProvider.overrideWithValue(settingsRepository),
        ],
        child: MaterialApp(
          theme: AppTheme.dark(),
          home: RunSessionDetailScreen(session: session),
        ),
      ),
    );
    await pumpUntilFound(
      tester,
      find.byKey(const Key('history-run-detail-screen')),
    );

    final assignButton = find.byKey(const Key('detail-assign-shoe-button'));
    await tester.ensureVisible(assignButton);
    await tester.pumpAndSettle();
    await tester.tap(assignButton);
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('detail-add-shoe-button')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('shoe-brand-field')), 'Nike');
    await tester.enterText(find.byKey(const Key('shoe-name-field')), 'Pegasus');
    await tester.tap(find.byKey(const Key('save-shoe-button')));
    await tester.pumpAndSettle();

    expect(settingsRepository.shoes, hasLength(1));
    expect(
      sessionRepository.savedSessions.single.shoeId,
      settingsRepository.shoes.single.id,
    );
    expect(find.text('Nike Pegasus'), findsOneWidget);
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
  Future<void> retireShoe(String id) async {}

  @override
  Future<void> deleteShoe(String id) async {}
}
