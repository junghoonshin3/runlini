import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:runlini/app/theme/app_theme.dart';
import 'package:runlini/core/health/health_workout_recorder.dart';
import 'package:runlini/features/run_tracking/repo/run_settings_repository.dart';
import 'package:runlini/features/run_tracking/state/run_session_providers.dart';
import 'package:runlini/features/run_tracking/state/run_settings_providers.dart';
import 'package:runlini/features/run_tracking/types/run_point.dart';
import 'package:runlini/features/run_tracking/types/run_session.dart';
import 'package:runlini/features/run_tracking/types/run_settings.dart';
import 'package:runlini/features/run_tracking/types/run_shoe.dart';
import 'package:runlini/features/run_tracking/ui/detail/run_session_detail_screen.dart';

import '../../helpers/runlini_widget_harness.dart';

void main() {
  testWidgets('sends an app-local run to Health from detail', (tester) async {
    final session = _runSession();
    final sessionRepository = FakeRunSessionRepository([session]);
    final recorder = FakeHealthWorkoutRecorder();
    await _pumpDetail(
      tester,
      session: session,
      sessionRepository: sessionRepository,
      recorder: recorder,
    );

    final sendButton = find.byKey(const Key('send-health-workout-button'));
    await tester.ensureVisible(sendButton);
    await tester.pumpAndSettle();
    await tester.tap(sendButton);
    await tester.pumpAndSettle();

    expect(recorder.finishCalls, 1);
    expect(
      (await sessionRepository.findById(session.id))!.syncStatus,
      RunSessionSyncStatus.synced,
    );
    expect(find.textContaining('보냈어요.'), findsOneWidget);
  });

  testWidgets('adds a shoe from run detail and attaches it to the run', (
    tester,
  ) async {
    final session = _runSession(points: const []);
    final sessionRepository = FakeRunSessionRepository([session]);
    final settingsRepository = _FakeRunSettingsRepository();
    await _pumpDetail(
      tester,
      session: session,
      sessionRepository: sessionRepository,
      settingsRepository: settingsRepository,
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

Future<void> _pumpDetail(
  WidgetTester tester, {
  required RunSession session,
  required FakeRunSessionRepository sessionRepository,
  _FakeRunSettingsRepository? settingsRepository,
  FakeHealthWorkoutRecorder? recorder,
}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        runSessionRepositoryProvider.overrideWithValue(sessionRepository),
        runSettingsRepositoryProvider.overrideWithValue(
          settingsRepository ?? _FakeRunSettingsRepository(),
        ),
        if (recorder != null)
          healthWorkoutRecorderProvider.overrideWithValue(recorder),
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
}

RunSession _runSession({List<RunPoint>? points}) {
  final startedAt = DateTime(2026, 4, 26, 7);
  return RunSession(
    id: 'run-a',
    startedAt: startedAt,
    endedAt: startedAt.add(const Duration(minutes: 30)),
    distanceM: 5000,
    durationMs: 30 * 60 * 1000,
    sourceSummary: 'app',
    points: points ?? _points,
  );
}

const _points = <RunPoint>[
  RunPoint(
    latitude: 37.51,
    longitude: 127.01,
    timestampRelMs: 0,
    source: RunPointSource.deviceGps,
  ),
  RunPoint(
    latitude: 37.52,
    longitude: 127.02,
    timestampRelMs: 30 * 60 * 1000,
    source: RunPointSource.deviceGps,
  ),
];

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
