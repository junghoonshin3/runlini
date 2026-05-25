// iOS와 Android에서 주요 앱 화면을 실제 위젯으로 점검하는 통합 테스트.
import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:runlini/app/runlini_app.dart';
import 'package:runlini/core/health/health_workout_recorder.dart';
import 'package:runlini/core/location/location_stream_client.dart';
import 'package:runlini/core/map/map_config_client.dart';
import 'package:runlini/core/voice/run_voice_cue_client.dart';
import 'package:runlini/core/wear/watch_interval_config_client.dart';
import 'package:runlini/core/wear/watch_record_race_config_client.dart';
import 'package:runlini/core/wear/watch_voice_settings_client.dart';
import 'package:runlini/core/wear/wear_draft_inbox_client.dart';
import 'package:runlini/features/dashboard/state/app_shell_providers.dart';
import 'package:runlini/features/health_sync/service/health_sync_service.dart';
import 'package:runlini/features/health_sync/state/health_sync_providers.dart';
import 'package:runlini/features/health_sync/types/health_sync_status.dart';
import 'package:runlini/features/run_tracking/repo/run_session_repository.dart';
import 'package:runlini/features/run_tracking/repo/run_settings_repository.dart';
import 'package:runlini/features/run_tracking/state/run_session_providers.dart';
import 'package:runlini/features/run_tracking/state/run_settings_providers.dart';
import 'package:runlini/features/run_tracking/state/run_start_countdown_providers.dart';
import 'package:runlini/features/run_tracking/state/run_voice_cue_providers.dart';
import 'package:runlini/features/run_tracking/state/run_watch_providers.dart';
import 'package:runlini/features/run_tracking/types/live_location_sample.dart';
import 'package:runlini/features/run_tracking/types/run_interval_workout.dart';
import 'package:runlini/features/run_tracking/types/run_point.dart';
import 'package:runlini/features/run_tracking/types/run_session.dart';
import 'package:runlini/features/run_tracking/types/run_session_summary.dart';
import 'package:runlini/features/run_tracking/types/run_settings.dart';
import 'package:runlini/features/run_tracking/types/run_shoe.dart';
import 'package:runlini/features/run_tracking/types/watch_record_race_config.dart';

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('opens all primary app screens on a mobile device', (
    WidgetTester tester,
  ) async {
    final sessions = _sampleSessions();
    final sessionRepository = _FakeRunSessionRepository(sessions);
    final settingsRepository = _FakeRunSettingsRepository(
      settings: const RunSettingsState(
        bodyWeightKg: 65,
        defaultShoeId: 'shoe-daily',
        locationTrackingPreset: RunLocationTrackingPreset.highAccuracy,
        showRecordRaceMarker: true,
      ),
      shoes: _sampleShoes(),
    );

    await _pumpRunlini(
      tester,
      sessionRepository: sessionRepository,
      settingsRepository: settingsRepository,
      startupWeightPromptEnabled: false,
    );

    await _expectScreen(tester, const Key('history-list'), 'history-home');
    await _expectNoFrameworkException(tester, 'history home');

    final todaySessionTile = find.byKey(
      const Key('history-session-session-today'),
    );
    await _scrollUntilVisible(tester, todaySessionTile);
    await tester.tap(todaySessionTile);
    await _expectScreen(
      tester,
      const Key('run-finish-review-panel'),
      'run-detail',
    );
    expect(find.text('Run Detail'), findsOneWidget);
    await _expectNoFrameworkException(tester, 'run detail');
    await tester.tap(find.byKey(const Key('run-detail-close-button')));
    await _expectScreen(tester, const Key('history-list'), 'history-return');

    await _tapBottomTab(tester, Icons.directions_run_rounded);
    await _expectScreen(tester, const Key('start-stop-button'), 'running-tab');
    _expectRunningMapSurface();
    expect(find.byKey(const Key('start-stop-button')), findsOneWidget);
    expect(find.byKey(const Key('current-location-button')), findsOneWidget);
    expect(find.byKey(const Key('record-race-control-chip')), findsOneWidget);
    await _expectNoFrameworkException(tester, 'running tab');

    await tester.tap(find.byKey(const Key('record-race-control-chip')));
    await _expectScreen(
      tester,
      const Key('record-race-session-sheet'),
      'record-race-picker',
    );
    expect(find.text('기록 선택'), findsOneWidget);
    await _expectNoFrameworkException(tester, 'record race picker');
    await tester.tap(
      find.byKey(const Key('record-race-session-select-session-today')),
    );
    await _expectScreen(
      tester,
      const Key('record-race-control-chip'),
      'record-race-selected',
    );

    await tester.tap(find.byKey(const Key('start-stop-button')));
    await _expectScreen(
      tester,
      const Key('run-start-countdown-overlay'),
      'run-countdown',
    );
    await _pumpUntilFound(tester, find.text('STOP'), maxPumps: 80);
    expect(find.byKey(const Key('pause-run-button')), findsOneWidget);
    await _expectNoFrameworkException(tester, 'active running');
    await tester.tap(find.byKey(const Key('start-stop-button')));
    await _expectScreen(
      tester,
      const Key('run-finish-review-panel'),
      'finish-review',
    );
    expect(find.byKey(const Key('save-run-button')), findsOneWidget);
    expect(find.byKey(const Key('discard-run-button')), findsOneWidget);
    await tester.tap(find.byKey(const Key('discard-run-button')));
    await _expectScreen(
      tester,
      const Key('confirm-discard-run-button'),
      'discard-dialog',
    );
    await tester.tap(find.byKey(const Key('confirm-discard-run-button')));
    await _expectScreen(tester, const Key('start-stop-button'), 'run-reset');

    await _tapBottomTab(tester, Icons.settings_rounded);
    await _expectScreen(tester, const Key('settings-tab-screen'), 'settings');
    expect(find.text('위치 업데이트'), findsOneWidget);
    await _expectNoFrameworkException(tester, 'settings tab');

    await _scrollUntilVisible(
      tester,
      find.byKey(const Key('manage-shoes-button')),
    );
    await tester.tap(find.byKey(const Key('manage-shoes-button')));
    await _expectScreen(
      tester,
      const Key('shoe-management-screen'),
      'shoe-management',
    );
    await _waitForRouteTransition(tester);
    expect(find.byKey(const Key('shoe-item-shoe-daily')), findsOneWidget);
    await _expectNoFrameworkException(tester, 'shoe management');

    await tester.tap(find.byKey(const Key('add-shoe-button')));
    await _expectScreen(tester, const Key('shoe-add-screen'), 'shoe-add');
    await _waitForRouteTransition(tester);
    expect(find.byKey(const Key('shoe-brand-field')), findsOneWidget);
    expect(find.byKey(const Key('shoe-name-field')), findsOneWidget);
    await _expectNoFrameworkException(tester, 'shoe add');
    await _goBack(tester);
    await _expectScreen(
      tester,
      const Key('shoe-management-screen'),
      'shoe-management-return',
    );
    await _waitForRouteTransition(tester);

    await tester.tap(find.byKey(const Key('edit-shoe-shoe-daily')));
    await _expectScreen(tester, const Key('shoe-add-screen'), 'shoe-edit');
    await _waitForRouteTransition(tester);
    expect(find.text('러닝화 수정'), findsWidgets);
    await _expectNoFrameworkException(tester, 'shoe edit');
    await _goBack(tester);
    await _expectScreen(
      tester,
      const Key('shoe-management-screen'),
      'shoe-management-after-edit',
    );
    await _waitForRouteTransition(tester);

    await tester.tap(find.byKey(const Key('shoe-courses-shoe-daily')));
    await _expectScreen(
      tester,
      const Key('shoe-courses-screen'),
      'shoe-courses',
    );
    await _waitForRouteTransition(tester);
    expect(find.byKey(const Key('shoe-course-session-today')), findsOneWidget);
    await _expectNoFrameworkException(tester, 'shoe courses');
    await _goBack(tester);
    await _expectScreen(
      tester,
      const Key('shoe-management-screen'),
      'shoe-management-after-courses',
    );
    await _waitForRouteTransition(tester);

    await tester.tap(find.byKey(const Key('delete-shoe-shoe-daily')));
    await _expectScreen(
      tester,
      const Key('confirm-delete-shoe-button'),
      'shoe-delete-dialog',
    );
    expect(find.text('러닝화 삭제'), findsOneWidget);
    await tester.tap(find.byKey(const Key('cancel-delete-shoe-button')));
    await _expectScreen(
      tester,
      const Key('shoe-management-screen'),
      'shoe-management-after-delete-dialog',
    );

    await _expectNoFrameworkException(tester, 'all primary screens');
    await _tryScreenshot(binding, 'all_primary_screens_complete');
  });

  testWidgets('opens the startup weight screen and returns to home', (
    WidgetTester tester,
  ) async {
    final settingsRepository = _FakeRunSettingsRepository(
      settings: const RunSettingsState(),
      shoes: const <RunShoe>[],
    );
    await _pumpRunlini(
      tester,
      sessionRepository: _FakeRunSessionRepository(const <RunSession>[]),
      settingsRepository: settingsRepository,
      startupWeightPromptEnabled: true,
    );

    await _expectScreen(
      tester,
      const Key('startup-weight-screen'),
      'startup-weight',
    );
    await tester.enterText(find.byKey(const Key('startup-weight-input')), '65');
    await tester.tap(find.byKey(const Key('startup-weight-save-button')));
    await _expectScreen(tester, const Key('history-list'), 'startup-to-home');
    await _expectNoFrameworkException(tester, 'startup weight');
    await _tryScreenshot(binding, 'startup_weight_complete');
  });
}

Future<void> _pumpRunlini(
  WidgetTester tester, {
  required _FakeRunSessionRepository sessionRepository,
  required _FakeRunSettingsRepository settingsRepository,
  required bool startupWeightPromptEnabled,
}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        startupWeightPromptEnabledProvider.overrideWithValue(
          startupWeightPromptEnabled,
        ),
        runSessionRepositoryProvider.overrideWithValue(sessionRepository),
        runSettingsRepositoryProvider.overrideWithValue(settingsRepository),
        healthSyncServiceProvider.overrideWithValue(_FakeHealthSyncService()),
        mapConfigClientProvider.overrideWithValue(
          const _FakeMapConfigClient(configured: false),
        ),
        runMapControlsReadyProvider.overrideWithValue(true),
        deviceLocationClientProvider.overrideWithValue(
          const _FakeDeviceLocationClient(),
        ),
        locationStreamClientProvider.overrideWithValue(
          const _FakeLocationStreamClient(),
        ),
        healthWorkoutRecorderProvider.overrideWithValue(
          const _FakeHealthWorkoutRecorder(),
        ),
        runVoiceCueClientProvider.overrideWithValue(
          const NoOpRunVoiceCueClient(),
        ),
        runStartCountdownSecondsProvider.overrideWithValue(1),
        runStartCountdownStepDurationProvider.overrideWithValue(
          const Duration(milliseconds: 160),
        ),
        wearDraftInboxClientProvider.overrideWithValue(
          const _FakeWearDraftInboxClient(),
        ),
        watchIntervalConfigClientProvider.overrideWithValue(
          const _NoOpWatchIntervalConfigClient(),
        ),
        watchVoiceSettingsClientProvider.overrideWithValue(
          const _NoOpWatchVoiceSettingsClient(),
        ),
        watchRecordRaceConfigClientProvider.overrideWithValue(
          const _NoOpWatchRecordRaceConfigClient(),
        ),
      ],
      child: const RunliniApp(),
    ),
  );
}

Future<void> _tapBottomTab(WidgetTester tester, IconData icon) async {
  await tester.pumpAndSettle(const Duration(milliseconds: 100));
  await tester.tap(
    find.descendant(
      of: find.byKey(const Key('runlini-bottom-navigation')),
      matching: find.byIcon(icon),
    ),
  );
  await tester.pumpAndSettle(const Duration(milliseconds: 100));
}

Future<void> _goBack(WidgetTester tester) async {
  await tester.binding.handlePopRoute();
  await tester.pumpAndSettle(const Duration(milliseconds: 100));
}

Future<void> _waitForRouteTransition(WidgetTester tester) async {
  await tester.pump(const Duration(milliseconds: 350));
}

void _expectRunningMapSurface() {
  if (Platform.isAndroid) {
    expect(find.byKey(const Key('android-map-config-error')), findsOneWidget);
    return;
  }

  expect(find.byKey(const Key('run-map')), findsOneWidget);
}

Future<void> _expectScreen(
  WidgetTester tester,
  Key key,
  String screenshotName,
) async {
  final finder = find.byKey(key);
  await _pumpUntilFound(tester, finder);
  expect(finder, findsOneWidget);
  await _tryScreenshot(
    IntegrationTestWidgetsFlutterBinding.instance,
    screenshotName,
  );
}

Future<void> _pumpUntilFound(
  WidgetTester tester,
  Finder finder, {
  int maxPumps = 60,
}) async {
  for (var index = 0; index < maxPumps; index += 1) {
    await tester.pump(const Duration(milliseconds: 100));
    if (finder.evaluate().isNotEmpty) {
      return;
    }
  }
}

Future<void> _scrollUntilVisible(WidgetTester tester, Finder finder) async {
  if (finder.evaluate().isEmpty) {
    await tester.scrollUntilVisible(
      finder,
      320,
      scrollable: find.byType(Scrollable).first,
    );
  } else {
    await tester.ensureVisible(finder);
  }
  await tester.pump(const Duration(milliseconds: 120));
}

Future<void> _expectNoFrameworkException(
  WidgetTester tester,
  String checkpoint,
) async {
  final exception = tester.takeException();
  if (exception != null) {
    fail('Unexpected Flutter exception at $checkpoint: $exception');
  }
}

Future<void> _tryScreenshot(
  IntegrationTestWidgetsFlutterBinding binding,
  String name,
) async {
  debugPrint(
    'UI checkpoint verified without screenshot: $name (${binding.runtimeType}).',
  );
}

List<RunShoe> _sampleShoes() {
  return [
    RunShoe(
      id: 'shoe-daily',
      brand: 'Runlini',
      name: 'Daily Trainer',
      distanceLimitKm: 800,
      retired: false,
      createdAt: DateTime.utc(2026, 4, 1),
    ),
  ];
}

List<RunSession> _sampleSessions() {
  final today = DateUtils.dateOnly(DateTime.now());
  return [
    _session(
      id: 'session-today',
      startedAt: today.add(const Duration(hours: 7)),
      shoeId: 'shoe-daily',
      latOffset: 0,
      lngOffset: 0,
    ),
    _session(
      id: 'session-yesterday',
      startedAt: today
          .subtract(const Duration(days: 1))
          .add(const Duration(hours: 6)),
      shoeId: 'shoe-daily',
      latOffset: 0.01,
      lngOffset: 0.01,
    ),
  ];
}

RunSession _session({
  required String id,
  required DateTime startedAt,
  required String shoeId,
  required double latOffset,
  required double lngOffset,
}) {
  return RunSession(
    id: id,
    startedAt: startedAt,
    endedAt: startedAt.add(const Duration(minutes: 10)),
    distanceM: 1200,
    durationMs: 600000,
    caloriesKcal: 72,
    sourceSummary: 'integration:test',
    shoeId: shoeId,
    points: [
      RunPoint(
        latitude: 37.5 + latOffset,
        longitude: 127.0 + lngOffset,
        timestampRelMs: 0,
        paceSecPerKm: 420,
        source: RunPointSource.simulated,
      ),
      RunPoint(
        latitude: 37.501 + latOffset,
        longitude: 127.001 + lngOffset,
        timestampRelMs: 600000,
        paceSecPerKm: 410,
        source: RunPointSource.simulated,
      ),
    ],
  );
}

class _FakeRunSessionRepository implements RunSessionRepository {
  _FakeRunSessionRepository(List<RunSession> sessions)
    : _sessions = List<RunSession>.from(sessions);

  final List<RunSession> _sessions;

  @override
  Future<void> deleteSession(String id) async {
    _sessions.removeWhere((RunSession session) => session.id == id);
  }

  @override
  Future<RunSession?> findById(String id) async {
    for (final session in _sessions) {
      if (session.id == id) {
        return session;
      }
    }
    return null;
  }

  @override
  Future<bool> isDeletedExternalSession(RunSession session) async => false;

  @override
  Future<List<RunSession>> listSessions() async =>
      List<RunSession>.unmodifiable(_sessions);

  @override
  Future<List<RunSessionSummary>> listSessionSummaries() async =>
      _sessions.map(RunSessionSummary.fromSession).toList(growable: false);

  @override
  Future<void> saveSession(RunSession session) async {
    _sessions.removeWhere((RunSession existing) => existing.id == session.id);
    _sessions.add(session);
  }
}

class _FakeRunSettingsRepository implements RunSettingsRepository {
  _FakeRunSettingsRepository({
    required RunSettingsState settings,
    required List<RunShoe> shoes,
  }) : _settings = settings,
       _shoes = List<RunShoe>.from(shoes);

  RunSettingsState _settings;
  final List<RunShoe> _shoes;

  @override
  Future<void> deleteShoe(String id) async {
    final index = _shoes.indexWhere((RunShoe shoe) => shoe.id == id);
    if (index >= 0) {
      _shoes[index] = _shoes[index].copyWith(deleted: true);
    }
  }

  @override
  Future<List<RunShoe>> listShoes() async => List<RunShoe>.unmodifiable(_shoes);

  @override
  Future<RunSettingsState> loadSettings() async => _settings;

  @override
  Future<void> retireShoe(String id) async {
    final index = _shoes.indexWhere((RunShoe shoe) => shoe.id == id);
    if (index >= 0) {
      _shoes[index] = _shoes[index].copyWith(retired: true);
    }
  }

  @override
  Future<void> saveSettings(RunSettingsState settings) async {
    _settings = settings;
  }

  @override
  Future<void> saveShoe(RunShoe shoe) async {
    final index = _shoes.indexWhere(
      (RunShoe existing) => existing.id == shoe.id,
    );
    if (index >= 0) {
      _shoes[index] = shoe;
      return;
    }
    _shoes.add(shoe);
  }
}

class _FakeHealthSyncService implements HealthSyncService {
  @override
  Future<RunSession?> hydrateSession(RunSession primarySession) async =>
      primarySession;

  @override
  Future<HealthSyncStatus> syncRecentSessions({
    required bool requestAuthorization,
  }) async => const HealthSyncStatus.synced(0);
}

class _FakeMapConfigClient implements MapConfigClient {
  const _FakeMapConfigClient({required this.configured});

  final bool configured;

  @override
  Future<bool> isAndroidGoogleMapsConfigured() async => configured;
}

class _FakeDeviceLocationClient implements DeviceLocationClient {
  const _FakeDeviceLocationClient();

  @override
  Future<LiveLocationSample?> fetchCurrentSample() async => _locationSample();

  @override
  Future<LiveLocationSample?> fetchLastKnownSample() async => _locationSample();
}

class _FakeLocationStreamClient implements LocationStreamClient {
  const _FakeLocationStreamClient();

  @override
  Future<LiveLocationSample?> fetchCurrentSample() async => _locationSample();

  @override
  Future<LiveLocationSample?> fetchLastKnownSample() async => _locationSample();

  @override
  Stream<LiveLocationSample> watchLocationSamples({
    LocationTrackingMode mode = LocationTrackingMode.passive,
    LocationTrackingConfig? config,
  }) {
    return Stream<LiveLocationSample>.periodic(
      const Duration(milliseconds: 160),
      (_) => _locationSample(),
    ).take(3);
  }
}

LiveLocationSample _locationSample() {
  return LiveLocationSample(
    latitude: 37.5,
    longitude: 127.0,
    capturedAt: DateTime.now(),
    source: RunPointSource.simulated,
  );
}

class _FakeHealthWorkoutRecorder implements HealthWorkoutRecorder {
  const _FakeHealthWorkoutRecorder();

  @override
  Future<void> beginRunCapture() async {}

  @override
  Future<void> cancelRunCapture() async {}

  @override
  Future<HealthWorkoutExportResult> finishRunCapture({
    required DateTime startedAt,
    required DateTime endedAt,
    required List<RunPoint> recordedPoints,
  }) async {
    return const HealthWorkoutExportResult.skipped('integration test');
  }

  @override
  Future<void> openHealthConnectInstall() async {}

  @override
  Future<HealthRunPreparationResult> prepareRunCapture() async =>
      HealthRunPreparationResult.ready;
}

class _FakeWearDraftInboxClient implements WearDraftInboxClient {
  const _FakeWearDraftInboxClient();

  @override
  Future<void> ackWearDraft(String id) async {}

  @override
  Future<List<WearDraftEnvelope>> pendingWearDrafts() async =>
      const <WearDraftEnvelope>[];
}

class _NoOpWatchIntervalConfigClient implements WatchIntervalConfigClient {
  const _NoOpWatchIntervalConfigClient();

  @override
  Future<void> sendIntervalWorkout(RunIntervalWorkout workout) async {}
}

class _NoOpWatchVoiceSettingsClient implements WatchVoiceSettingsClient {
  const _NoOpWatchVoiceSettingsClient();

  @override
  Future<void> sendVoiceSettings({
    required bool voiceCueEnabled,
    required bool kmVoiceCueEnabled,
    required bool recordRaceVoiceCueEnabled,
    required bool autoPauseEnabled,
    required double volume,
    bool playTestCue = false,
  }) async {}
}

class _NoOpWatchRecordRaceConfigClient implements WatchRecordRaceConfigClient {
  const _NoOpWatchRecordRaceConfigClient();

  @override
  Future<void> clearRecordRaceConfig() async {}

  @override
  Future<void> sendRecordRaceConfig(WatchRecordRaceConfig config) async {}

  @override
  Future<void> sendRecordRaceConfigs({
    required String? activeId,
    required List<WatchRecordRaceConfig> configs,
  }) async {}
}
