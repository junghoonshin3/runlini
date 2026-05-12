import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:runlini/core/health/health_workout_recorder.dart';
import 'package:runlini/core/location/location_stream_client.dart';
import 'package:runlini/core/motion/run_motion_evidence_client.dart';
import 'package:runlini/features/dashboard/state/app_shell_providers.dart';
import 'package:runlini/features/dashboard/types/app_tab.dart';
import 'package:runlini/features/run_tracking/repo/run_session_repository.dart';
import 'package:runlini/features/run_tracking/repo/run_settings_repository.dart';
import 'package:runlini/features/run_tracking/state/run_playback_providers.dart';
import 'package:runlini/features/run_tracking/types/live_location_sample.dart';
import 'package:runlini/features/run_tracking/types/run_point.dart';
import 'package:runlini/features/run_tracking/types/run_session.dart';
import 'package:runlini/features/run_tracking/types/run_session_summary.dart';
import 'package:runlini/features/run_tracking/types/run_settings.dart';
import 'package:runlini/features/run_tracking/types/run_shoe.dart';

class TestDeviceLocationClient implements DeviceLocationClient {
  TestDeviceLocationClient({
    this.lastKnownResponses = const <Future<LiveLocationSample?>>[],
    this.currentResponses = const <Future<LiveLocationSample?>>[],
  });

  final List<Future<LiveLocationSample?>> lastKnownResponses;
  final List<Future<LiveLocationSample?>> currentResponses;
  int lastKnownFetchCount = 0;
  int currentFetchCount = 0;
  int _lastKnownIndex = 0;
  int _currentIndex = 0;

  @override
  Future<LiveLocationSample?> fetchLastKnownSample() {
    lastKnownFetchCount += 1;
    if (_lastKnownIndex >= lastKnownResponses.length) {
      return Future<LiveLocationSample?>.value(null);
    }

    return lastKnownResponses[_lastKnownIndex++];
  }

  @override
  Future<LiveLocationSample?> fetchCurrentSample() {
    currentFetchCount += 1;
    if (_currentIndex >= currentResponses.length) {
      return Future<LiveLocationSample?>.value(null);
    }

    return currentResponses[_currentIndex++];
  }
}

class TrackingLocationStreamClient implements LocationStreamClient {
  TrackingLocationStreamClient() {
    _controller = StreamController<LiveLocationSample>.broadcast(
      onListen: _handleListen,
      onCancel: _handleCancel,
    );
  }

  late final StreamController<LiveLocationSample> _controller;
  int _activeSubscriptions = 0;
  int watchCallCount = 0;
  final List<LocationTrackingMode> watchModes = <LocationTrackingMode>[];
  final List<LocationTrackingConfig?> watchConfigs =
      <LocationTrackingConfig?>[];

  int get activeSubscriptions => _activeSubscriptions;

  LocationTrackingMode? get lastWatchMode =>
      watchModes.isEmpty ? null : watchModes.last;

  LocationTrackingConfig? get lastWatchConfig =>
      watchConfigs.isEmpty ? null : watchConfigs.last;

  void _handleListen() {
    _activeSubscriptions += 1;
  }

  void _handleCancel() {
    _activeSubscriptions -= 1;
  }

  @override
  Future<LiveLocationSample?> fetchLastKnownSample() async => null;

  @override
  Future<LiveLocationSample?> fetchCurrentSample() async => null;

  @override
  Stream<LiveLocationSample> watchLocationSamples({
    LocationTrackingMode mode = LocationTrackingMode.passive,
    LocationTrackingConfig? config,
  }) {
    watchCallCount += 1;
    watchModes.add(mode);
    watchConfigs.add(config);
    return _controller.stream;
  }

  Future<void> emit(LiveLocationSample sample) async {
    _controller.add(sample);
    await Future<void>.delayed(Duration.zero);
  }

  Future<void> close() async {
    await _controller.close();
  }
}

class TrackingMotionEvidenceClient implements RunMotionEvidenceClient {
  final StreamController<RunMotionEvidence> _controller =
      StreamController<RunMotionEvidence>.broadcast();
  int watchCallCount = 0;

  @override
  Stream<RunMotionEvidence> watchMotionEvidence() {
    watchCallCount += 1;
    return _controller.stream;
  }

  Future<void> emit(RunMotionEvidence evidence) async {
    _controller.add(evidence);
    await Future<void>.delayed(Duration.zero);
  }

  Future<void> close() async {
    await _controller.close();
  }
}

class TestHealthWorkoutRecorder implements HealthWorkoutRecorder {
  int prepareCalls = 0;
  int beginCalls = 0;
  int finishCalls = 0;
  int cancelCalls = 0;
  int installCalls = 0;
  DateTime? lastStartedAt;
  DateTime? lastEndedAt;
  List<RunPoint> lastRecordedPoints = const <RunPoint>[];
  Object? beginError;
  Object? finishError;
  HealthWorkoutExportResult finishResult =
      const HealthWorkoutExportResult.synced(externalId: 'test-workout');

  @override
  Future<HealthRunPreparationResult> prepareRunCapture() async {
    prepareCalls += 1;
    return HealthRunPreparationResult.ready;
  }

  @override
  Future<void> beginRunCapture() async {
    beginCalls += 1;
    if (beginError != null) {
      throw beginError!;
    }
  }

  @override
  Future<void> cancelRunCapture() async {
    cancelCalls += 1;
  }

  @override
  Future<void> openHealthConnectInstall() async {
    installCalls += 1;
  }

  @override
  Future<HealthWorkoutExportResult> finishRunCapture({
    required DateTime startedAt,
    required DateTime endedAt,
    required List<RunPoint> recordedPoints,
  }) async {
    finishCalls += 1;
    lastStartedAt = startedAt;
    lastEndedAt = endedAt;
    lastRecordedPoints = List<RunPoint>.from(recordedPoints);
    if (finishError != null) {
      throw finishError!;
    }
    return finishResult;
  }
}

class TestRunSessionRepository implements RunSessionRepository {
  final List<RunSession> savedSessions = <RunSession>[];
  int listCalls = 0;
  int saveCalls = 0;

  @override
  Future<RunSession?> findById(String id) async {
    for (final session in savedSessions) {
      if (session.id == id) {
        return session;
      }
    }
    return null;
  }

  @override
  Future<List<RunSession>> listSessions() async {
    listCalls += 1;
    return List<RunSession>.unmodifiable(savedSessions);
  }

  @override
  Future<List<RunSessionSummary>> listSessionSummaries() async =>
      savedSessions.map(RunSessionSummary.fromSession).toList(growable: false);

  @override
  Future<void> saveSession(RunSession session) async {
    saveCalls += 1;
    savedSessions.removeWhere((existing) => existing.id == session.id);
    savedSessions.add(session);
  }

  @override
  Future<void> deleteSession(String id) async {
    savedSessions.removeWhere((existing) => existing.id == id);
  }

  @override
  Future<bool> isDeletedExternalSession(RunSession session) async => false;
}

class TestRunSettingsRepository implements RunSettingsRepository {
  TestRunSettingsRepository([this.settings = const RunSettingsState()]);

  RunSettingsState settings;

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

LiveLocationSample playbackSample({
  required double latitude,
  required double longitude,
  required DateTime capturedAt,
  double? paceSecPerKm,
  double? speedMps,
  double? horizontalAccuracyM,
}) {
  return LiveLocationSample(
    latitude: latitude,
    longitude: longitude,
    capturedAt: capturedAt,
    paceSecPerKm: paceSecPerKm,
    speedMps: speedMps,
    horizontalAccuracyM: horizontalAccuracyM,
    source: RunPointSource.deviceGps,
  );
}

Future<void> settleAsync() async {
  await Future<void>.delayed(Duration.zero);
  await Future<void>.delayed(Duration.zero);
}

Future<void> startVisibleLiveTracking(ProviderContainer container) async {
  container.read(appTabProvider.notifier).setTab(AppTab.running);
  await settleAsync();
  container.read(liveLocationProvider);
  await container.read(liveLocationProvider.notifier).syncTracking();
  await settleAsync();
}
