import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:runlini/core/health/health_workout_recorder.dart';
import 'package:runlini/core/location/location_stream_client.dart';
import 'package:runlini/core/map/map_coordinate.dart';
import 'package:runlini/features/run_tracking/repo/run_session_repository.dart';
import 'package:runlini/features/run_tracking/state/run_playback_providers.dart';
import 'package:runlini/features/run_tracking/types/live_location_sample.dart';
import 'package:runlini/features/run_tracking/types/run_map_static_state.dart';
import 'package:runlini/features/run_tracking/types/run_point.dart';
import 'package:runlini/features/run_tracking/types/run_session.dart';

class SilentLocationStreamClient implements LocationStreamClient {
  const SilentLocationStreamClient();

  @override
  Future<LiveLocationSample?> fetchLastKnownSample() async => null;

  @override
  Future<LiveLocationSample?> fetchCurrentSample() async => null;

  @override
  Stream<LiveLocationSample> watchLocationSamples({
    LocationTrackingMode mode = LocationTrackingMode.passive,
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
  FakeHealthWorkoutRecorder({this.prepareCompleter});

  final Completer<void>? prepareCompleter;
  int prepareCalls = 0;
  int beginCalls = 0;
  int finishCalls = 0;
  int cancelCalls = 0;

  @override
  Future<void> prepareRunCapture() async {
    prepareCalls += 1;
    await prepareCompleter?.future;
  }

  @override
  Future<void> beginRunCapture() async {
    beginCalls += 1;
  }

  @override
  Future<void> cancelRunCapture() async {
    cancelCalls += 1;
  }

  @override
  Future<void> finishRunCapture({
    required DateTime startedAt,
    required DateTime endedAt,
    required List<RunPoint> recordedPoints,
  }) async {
    finishCalls += 1;
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
  Future<void> saveSession(RunSession session) async {
    _sessions.removeWhere((existing) => existing.id == session.id);
    _sessions.add(session);
  }

  @override
  Future<void> deleteSession(String id) async {
    _sessions.removeWhere((existing) => existing.id == id);
  }
}

LiveLocationSample sample({
  required double latitude,
  required double longitude,
  DateTime? capturedAt,
}) {
  return LiveLocationSample(
    latitude: latitude,
    longitude: longitude,
    capturedAt: capturedAt ?? DateTime(2026, 4, 20, 6),
    source: RunPointSource.deviceGps,
  );
}

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

dynamic staticMapStateOverride({
  required MapCoordinate fallbackMapCenter,
  RunSession? selectedGhostSession,
}) {
  return runMapStaticStateProvider.overrideWith((Ref ref) async {
    return RunMapStaticState(
      fallbackMapCenter: fallbackMapCenter,
      ghostPolylinePoints: selectedGhostSession == null
          ? const <MapCoordinate>[]
          : selectedGhostSession.points
                .map(
                  (RunPoint point) => MapCoordinate(
                    latitude: point.latitude,
                    longitude: point.longitude,
                  ),
                )
                .toList(growable: false),
      selectedGhostSession: selectedGhostSession,
    );
  });
}

RunSession ghostSession() {
  return RunSession(
    id: 'ghost-route',
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
  final startedAt = DateTime.utc(2026, 4, 19, 6);
  return <RunSession>[
    _sampleRunSession(
      id: 'fixture_morning_tempo',
      startedAt: startedAt,
      latOffset: 0,
      lngOffset: 0,
    ),
    _sampleRunSession(
      id: 'fixture_han_river_push',
      startedAt: startedAt.subtract(const Duration(days: 1)),
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
    endedAt: startedAt.add(const Duration(minutes: 10)),
    distanceM: 1000,
    durationMs: 600000,
    sourceSummary: 'fixture:test',
    points: points,
  );
}
