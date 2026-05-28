// Android 주요 화면의 전역 레이아웃 깨짐을 점검하는 위젯 테스트.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:runlini/app/runlini_app.dart';
import 'package:runlini/core/health/health_workout_recorder.dart';
import 'package:runlini/core/location/location_stream_client.dart';
import 'package:runlini/core/map/map_config_client.dart';
import 'package:runlini/core/map/map_coordinate.dart';
import 'package:runlini/core/voice/run_voice_cue_client.dart';
import 'package:runlini/features/dashboard/ui/runlini_home_screen.dart';
import 'package:runlini/features/health_sync/service/health_sync_service.dart';
import 'package:runlini/features/health_sync/state/health_sync_providers.dart';
import 'package:runlini/features/health_sync/types/health_sync_status.dart';
import 'package:runlini/features/run_tracking/state/run_session_providers.dart';
import 'package:runlini/features/run_tracking/state/run_settings_providers.dart';
import 'package:runlini/features/run_tracking/state/run_start_countdown_providers.dart';
import 'package:runlini/features/run_tracking/state/run_voice_cue_providers.dart';
import 'package:runlini/features/run_tracking/types/run_point.dart';
import 'package:runlini/features/run_tracking/types/run_session.dart';
import 'package:runlini/features/run_tracking/types/run_settings.dart';
import 'package:runlini/features/run_tracking/types/run_shoe.dart';

import 'helpers/fake_run_settings_repository.dart';
import 'helpers/runlini_widget_harness.dart';

void main() {
  testWidgets('primary screens fit compact Android viewport', (tester) async {
    await _configureViewport(
      tester,
      size: const Size(360, 640),
      textScaleFactor: 1.0,
    );

    await _pumpAuditedApp(tester);
    await _auditPrimaryFlow(tester);
  });

  testWidgets('primary screens tolerate enlarged Android text', (tester) async {
    await _configureViewport(
      tester,
      size: const Size(390, 844),
      textScaleFactor: 1.3,
    );

    await _pumpAuditedApp(tester);
    await _auditPrimaryFlow(tester);
  });
}

Future<void> _configureViewport(
  WidgetTester tester, {
  required Size size,
  required double textScaleFactor,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  tester.platformDispatcher.textScaleFactorTestValue = textScaleFactor;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
}

Future<void> _pumpAuditedApp(WidgetTester tester) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        disableStartupWeightPromptOverride,
        startupSyncDelayProvider.overrideWithValue(const Duration(days: 1)),
        runSessionRepositoryProvider.overrideWithValue(
          FakeRunSessionRepository(sampleRunSessions()),
        ),
        runSettingsRepositoryProvider.overrideWithValue(
          FakeRunSettingsRepository(
            const RunSettingsState(
              bodyWeightKg: 65,
              defaultShoeId: 'shoe-daily',
              showRecordRaceMarker: true,
            ),
            [
              RunShoe(
                id: 'shoe-daily',
                brand: 'Runlini',
                name: 'Daily Trainer Long Name',
                distanceLimitKm: 800,
                retired: false,
                createdAt: DateTime(2026, 4, 1),
              ),
            ],
          ),
        ),
        runMapControlsReadyProvider.overrideWithValue(true),
        staticMapStateOverride(
          fallbackMapCenter: const MapCoordinate(latitude: 37, longitude: 127),
        ),
        deviceLocationClientProvider.overrideWithValue(
          FakeDeviceLocationClient(
            lastKnownSample: sample(latitude: 37.55, longitude: 126.97),
          ),
        ),
        locationStreamClientProvider.overrideWithValue(
          const SilentLocationStreamClient(),
        ),
        healthSyncServiceProvider.overrideWithValue(
          const _FakeHealthSyncService(),
        ),
        healthWorkoutRecorderProvider.overrideWithValue(
          const _FakeHealthWorkoutRecorder(),
        ),
        runVoiceCueClientProvider.overrideWithValue(
          const NoOpRunVoiceCueClient(),
        ),
        runStartCountdownSecondsProvider.overrideWithValue(1),
        runStartCountdownStepDurationProvider.overrideWithValue(
          const Duration(milliseconds: 10),
        ),
      ],
      child: const RunliniApp(),
    ),
  );
  addTearDown(() async => tester.pumpWidget(const SizedBox.shrink()));
}

Future<void> _auditPrimaryFlow(WidgetTester tester) async {
  await pumpUntilFound(tester, find.byKey(const Key('history-list')));
  _expectStableFrame(tester, 'history');

  await tester.scrollUntilVisible(
    find.byKey(const Key('history-session-fixture_morning_tempo')),
    360,
    scrollable: find.byType(Scrollable).first,
  );
  await tester.pump();
  await tester.tap(
    find.byKey(const Key('history-session-fixture_morning_tempo')),
  );
  await pumpUntilFound(
    tester,
    find.byKey(const Key('run-finish-review-panel')),
  );
  _expectStableFrame(tester, 'detail');
  await tester.tap(find.byKey(const Key('run-detail-close-button')));
  await tester.pumpAndSettle(const Duration(milliseconds: 100));
  await pumpUntilFound(tester, find.byKey(const Key('history-list')));

  await _tapBottomNavigationIcon(tester, Icons.directions_run_rounded);
  await pumpUntilFound(tester, find.byKey(const Key('start-stop-button')));
  await pumpUntilFound(
    tester,
    find.byKey(const Key('record-race-recommendation-card')),
  );
  _expectMinTouchSize(tester, const Key('current-location-button'));
  _expectMinTouchSize(tester, const Key('run-interval-button'));
  _expectStableFrame(tester, 'running idle');

  await tester.tap(
    find.byKey(const Key('record-race-recommendation-other-button')),
  );
  await pumpUntilFound(
    tester,
    find.byKey(const Key('record-race-session-sheet')),
  );
  _expectStableFrame(tester, 'record race picker');
  await tester.binding.handlePopRoute();
  await tester.pumpAndSettle(const Duration(milliseconds: 100));
  await pumpUntilFound(
    tester,
    find.byKey(const Key('record-race-recommendation-card')),
  );
  await tester.tap(
    find.byKey(const Key('record-race-recommendation-select-button')),
  );
  await tester.pumpAndSettle(const Duration(milliseconds: 100));
  await pumpUntilFound(
    tester,
    find.byKey(const Key('record-race-selected-card')),
  );
  _expectStableFrame(tester, 'record race selected');
  await tester.tap(find.byKey(const Key('record-race-selected-clear-button')));
  await pumpUntilFound(
    tester,
    find.byKey(const Key('record-race-recommendation-card')),
  );

  await tester.tap(find.byKey(const Key('start-stop-button')));
  await pumpUntilFound(tester, find.text('STOP'), maxPumps: 80);
  _expectMinTouchSize(tester, const Key('pause-run-button'));
  _expectStableFrame(tester, 'active running');
  await tester.tap(find.byKey(const Key('start-stop-button')));
  await pumpUntilFound(
    tester,
    find.byKey(const Key('run-finish-review-panel')),
  );
  _expectStableFrame(tester, 'finish review');
  await tester.tap(find.byKey(const Key('discard-run-button')));
  await pumpUntilFound(
    tester,
    find.byKey(const Key('confirm-discard-run-button')),
  );
  _expectStableFrame(tester, 'discard dialog');
  await tester.tap(find.byKey(const Key('confirm-discard-run-button')));
  await pumpUntilFound(tester, find.byKey(const Key('start-stop-button')));

  await _tapBottomNavigationIcon(tester, Icons.settings_rounded);
  final settingsTab = find.byKey(const Key('settings-tab-screen'));
  final manageShoesButton = find.byKey(const Key('manage-shoes-button'));
  await pumpUntilFound(tester, settingsTab);
  final settingsScrollable = find.descendant(
    of: settingsTab,
    matching: find.byType(Scrollable),
  );
  await tester.scrollUntilVisible(
    manageShoesButton,
    400,
    scrollable: settingsScrollable.first,
  );
  await Scrollable.ensureVisible(
    tester.element(manageShoesButton),
    alignment: 0.45,
  );
  await tester.pump();
  _expectMinTouchSize(tester, const Key('manage-shoes-button'));
  _expectStableFrame(tester, 'settings');
  await tester.tap(manageShoesButton);
  await pumpUntilFound(tester, find.byKey(const Key('shoe-management-screen')));
  _expectMinTouchSize(tester, const Key('add-shoe-button'));
  _expectStableFrame(tester, 'shoe management');
}

void _expectStableFrame(WidgetTester tester, String checkpoint) {
  final exception = tester.takeException();
  expect(exception, isNull, reason: checkpoint);
}

Future<void> _tapBottomNavigationIcon(
  WidgetTester tester,
  IconData icon,
) async {
  await tester.pumpAndSettle(const Duration(milliseconds: 100));
  await tester.tap(
    find.descendant(
      of: find.byKey(const Key('runlini-bottom-navigation')),
      matching: find.byIcon(icon),
    ),
  );
  await tester.pumpAndSettle(const Duration(milliseconds: 100));
}

void _expectMinTouchSize(WidgetTester tester, Key key) {
  final size = tester.getSize(find.byKey(key));
  expect(size.width, greaterThanOrEqualTo(44), reason: key.toString());
  expect(size.height, greaterThanOrEqualTo(44), reason: key.toString());
}

class _FakeHealthSyncService implements HealthSyncService {
  const _FakeHealthSyncService();

  @override
  Future<RunSession?> hydrateSession(RunSession primarySession) async =>
      primarySession;

  @override
  Future<HealthSyncStatus> syncRecentSessions({
    required bool requestAuthorization,
  }) async => const HealthSyncStatus.synced(0);
}

class _FakeHealthWorkoutRecorder implements HealthWorkoutRecorder {
  const _FakeHealthWorkoutRecorder();

  @override
  Future<HealthRunPreparationResult> prepareRunCapture() async =>
      HealthRunPreparationResult.ready;

  @override
  Future<void> openHealthConnectInstall() async {}

  @override
  Future<void> beginRunCapture() async {}

  @override
  Future<HealthWorkoutExportResult> finishRunCapture({
    required DateTime startedAt,
    required DateTime endedAt,
    required List<RunPoint> recordedPoints,
  }) async => const HealthWorkoutExportResult.skipped('ui audit');

  @override
  Future<void> cancelRunCapture() async {}
}
