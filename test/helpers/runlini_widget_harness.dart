import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:runlini/core/health/health_workout_recorder.dart';
import 'package:runlini/core/location/location_stream_client.dart';
import 'package:runlini/core/map/map_coordinate.dart';
import 'package:runlini/features/dashboard/state/app_shell_providers.dart';
import 'package:runlini/features/run_tracking/repo/run_session_repository.dart';
import 'package:runlini/features/run_tracking/state/run_playback_providers.dart';
import 'package:runlini/features/run_tracking/types/live_location_sample.dart';
import 'package:runlini/features/run_tracking/types/run_map_static_state.dart';
import 'package:runlini/features/run_tracking/types/run_point.dart';
import 'package:runlini/features/run_tracking/types/run_session.dart';
import 'package:runlini/features/run_tracking/types/run_session_summary.dart';

final disableStartupWeightPromptOverride = startupWeightPromptEnabledProvider
    .overrideWithValue(false);

class SilentLocationStreamClient implements LocationStreamClient {
  const SilentLocationStreamClient();
  @override
  Future<LiveLocationSample?> fetchLastKnownSample() async => null;
  @override
  Future<LiveLocationSample?> fetchCurrentSample() async => null;
  @override
  Stream<LiveLocationSample> watchLocationSamples({
    LocationTrackingMode mode = LocationTrackingMode.passive,
    LocationTrackingConfig? config,
  }) => const Stream<LiveLocationSample>.empty();
}

class FakeDeviceLocationClient implements DeviceLocationClient {
  const FakeDeviceLocationClient({this.lastKnownSample});
  final LiveLocationSample? lastKnownSample;
  @override
  Future<LiveLocationSample?> fetchLastKnownSample() async => lastKnownSample;
  @override
  Future<LiveLocationSample?> fetchCurrentSample() async => null;
}

class SequencedDeviceLocationClient implements DeviceLocationClient {
  SequencedDeviceLocationClient({
    this.currentResponses = const <Future<LiveLocationSample?>>[],
  });

  final List<Future<LiveLocationSample?>> currentResponses;
  int _currentIndex = 0;

  @override
  Future<LiveLocationSample?> fetchLastKnownSample() async => null;

  @override
  Future<LiveLocationSample?> fetchCurrentSample() {
    if (_currentIndex >= currentResponses.length) {
      return Future<LiveLocationSample?>.value(null);
    }

    return currentResponses[_currentIndex++];
  }
}

class ThrowingDeviceLocationClient implements DeviceLocationClient {
  const ThrowingDeviceLocationClient();

  @override
  Future<LiveLocationSample?> fetchLastKnownSample() async {
    throw StateError('last known location failed');
  }

  @override
  Future<LiveLocationSample?> fetchCurrentSample() async {
    throw StateError('current location failed');
  }
}

class FakeHealthWorkoutRecorder implements HealthWorkoutRecorder {
  FakeHealthWorkoutRecorder({
    this.prepareCompleter,
    this.prepareResult = HealthRunPreparationResult.ready,
    this.finishResult = const HealthWorkoutExportResult.synced(),
  });

  final Completer<void>? prepareCompleter;
  final HealthRunPreparationResult prepareResult;
  final HealthWorkoutExportResult finishResult;
  int prepareCalls = 0;
  int beginCalls = 0;
  int finishCalls = 0;
  int cancelCalls = 0;
  int installCalls = 0;

  @override
  Future<HealthRunPreparationResult> prepareRunCapture() async {
    prepareCalls += 1;
    await prepareCompleter?.future;
    return prepareResult;
  }

  @override
  Future<void> beginRunCapture() async {
    beginCalls += 1;
  }

  @override
  Future<void> openHealthConnectInstall() async {
    installCalls += 1;
  }

  @override
  Future<void> cancelRunCapture() async {
    cancelCalls += 1;
  }

  @override
  Future<HealthWorkoutExportResult> finishRunCapture({
    required DateTime startedAt,
    required DateTime endedAt,
    required List<RunPoint> recordedPoints,
  }) async {
    finishCalls += 1;
    return finishResult;
  }
}

class FakeRunSessionRepository implements RunSessionRepository {
  FakeRunSessionRepository([List<RunSession> initialSessions = const []])
    : _sessions = List<RunSession>.from(initialSessions);

  final List<RunSession> _sessions;

  List<RunSession> get savedSessions =>
      List<RunSession>.unmodifiable(_sessions);

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
  Future<List<RunSession>> listSessions() async =>
      List<RunSession>.unmodifiable(_sessions);

  @override
  Future<List<RunSessionSummary>> listSessionSummaries() async =>
      _sessions.map(RunSessionSummary.fromSession).toList(growable: false);

  @override
  Future<void> saveSession(RunSession session) async {
    _sessions.removeWhere((existing) => existing.id == session.id);
    _sessions.add(session);
  }

  @override
  Future<void> deleteSession(String id) async =>
      _sessions.removeWhere((existing) => existing.id == id);

  @override
  Future<bool> isDeletedExternalSession(RunSession session) async => false;
}

LiveLocationSample sample({
  required double latitude,
  required double longitude,
  DateTime? capturedAt,
}) => LiveLocationSample(
  latitude: latitude,
  longitude: longitude,
  capturedAt: capturedAt ?? DateTime(2026, 4, 20, 6),
  source: RunPointSource.deviceGps,
);

Future<void> pumpUntilFound(
  WidgetTester tester,
  Finder finder, {
  int maxPumps = 120,
  Duration step = const Duration(milliseconds: 50),
}) async {
  for (var index = 0; index < maxPumps; index += 1) {
    await tester.pump(step);
    if (finder.evaluate().isNotEmpty) {
      return;
    }
  }
}

Future<void> openHistoryTab(WidgetTester tester) async =>
    _tapBottomTab(tester, Icons.list_alt_rounded);

Future<void> openRunningTab(WidgetTester tester) async =>
    _tapBottomTab(tester, Icons.directions_run_rounded);

Future<void> _tapBottomTab(WidgetTester tester, IconData icon) async {
  await tester.tap(find.byIcon(icon));
  await tester.pump();
}

dynamic staticMapStateOverride({
  required MapCoordinate fallbackMapCenter,
  RunSession? selectedRecordRaceSession,
}) {
  return runMapStaticStateProvider.overrideWith((Ref ref) async {
    return RunMapStaticState(
      fallbackMapCenter: fallbackMapCenter,
      recordRacePolylinePoints: selectedRecordRaceSession == null
          ? const <MapCoordinate>[]
          : selectedRecordRaceSession.points
                .map(
                  (RunPoint point) => MapCoordinate(
                    latitude: point.latitude,
                    longitude: point.longitude,
                  ),
                )
                .toList(growable: false),
      selectedRecordRaceSession: selectedRecordRaceSession,
    );
  });
}

RunSession recordRaceSession() {
  return RunSession(
    id: 'record-race-route',
    startedAt: DateTime.utc(2026, 4, 19, 6),
    endedAt: DateTime.utc(2026, 4, 19, 6, 10),
    distanceM: 1000,
    durationMs: 600000,
    sourceSummary: 'test',
    points: const [
      RunPoint(
        latitude: 0,
        longitude: 0,
        timestampRelMs: 0,
        source: RunPointSource.simulated,
      ),
      RunPoint(
        latitude: 0,
        longitude: 0.009,
        timestampRelMs: 600000,
        source: RunPointSource.simulated,
      ),
    ],
  );
}

List<RunSession> sampleRunSessions() {
  final today = DateUtils.dateOnly(DateTime.now());
  return <RunSession>[
    _sampleRunSession(
      id: 'fixture_morning_tempo',
      startedAt: today.add(const Duration(hours: 6)),
      latOffset: 0,
      lngOffset: 0,
    ),
    _sampleRunSession(
      id: 'fixture_han_river_push',
      startedAt: today.add(const Duration(hours: -18)),
      latOffset: 0.01,
      lngOffset: 0.01,
    ),
  ];
}

RunSession _sampleRunSession({
  required String id,
  required DateTime startedAt,
  required double latOffset,
  required double lngOffset,
}) {
  final points = <RunPoint>[
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
  ];
  return RunSession(
    id: id,
    startedAt: startedAt,
    distanceM: 1000,
    durationMs: 600000,
    sourceSummary: 'device:gps',
    points: points,
  );
}
