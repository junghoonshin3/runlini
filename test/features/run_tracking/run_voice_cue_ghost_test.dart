// 고스트런 음성 안내 정책을 검증하는 테스트
import 'package:flutter_test/flutter_test.dart';
import 'package:runlini/core/map/map_coordinate.dart';
import 'package:runlini/features/ghost_racer/types/ghost_race_frame.dart';
import 'package:runlini/features/run_tracking/service/run_interval_workout_calculator.dart';
import 'package:runlini/features/run_tracking/service/run_voice_cue_coordinator.dart';
import 'package:runlini/features/run_tracking/types/live_run_metrics.dart';
import 'package:runlini/features/run_tracking/types/run_interval_workout.dart';
import 'package:runlini/features/run_tracking/types/run_playback_state.dart';
import 'package:runlini/features/run_tracking/types/run_screen_status.dart';
import 'package:runlini/features/run_tracking/types/run_settings.dart';

void main() {
  test('does not speak ghost event cues when ghost voice is disabled', () {
    final coordinator = RunVoiceCueCoordinator();
    final startedAt = DateTime(2026, 5, 3);

    coordinator.cuesFor(
      _snapshot(
        metrics: _metrics(distanceKm: 0.5),
        ghostFrame: _ghost(GhostRaceStatus.offRoute, gapMs: 0),
        now: startedAt,
        isGhostRun: true,
      ),
    );
    final cues = coordinator.cuesFor(
      _snapshot(
        metrics: _metrics(distanceKm: 0.5),
        ghostFrame: _ghost(GhostRaceStatus.offRoute, gapMs: 0),
        now: startedAt.add(const Duration(seconds: 10)),
        isGhostRun: true,
      ),
    );

    expect(cues, isEmpty);
  });

  test('speaks kilometer summaries during ghost runs', () {
    final coordinator = RunVoiceCueCoordinator();

    final cues = coordinator.cuesFor(
      _snapshot(
        isGhostRun: true,
        metrics: _metrics(distanceKm: 1.01),
        ghostFrame: _ghost(GhostRaceStatus.ahead, gapMs: 12000),
        settings: const RunSettingsState(ghostVoiceCueEnabled: true),
      ),
    );

    expect(
      cues.single.text,
      '1킬로미터. 평균 페이스 5분 20초. 시간 5분 21초. 고스트보다 12초 앞서고 있어요',
    );
  });

  test('speaks plain kilometer summary when ghost voice is disabled', () {
    final coordinator = RunVoiceCueCoordinator();

    final cues = coordinator.cuesFor(
      _snapshot(
        isGhostRun: true,
        metrics: _metrics(distanceKm: 1.01),
        ghostFrame: _ghost(GhostRaceStatus.ahead, gapMs: 12000),
      ),
    );

    expect(cues.single.text, '1킬로미터. 평균 페이스 5분 20초. 시간 5분 21초');
    expect(cues.single.text, isNot(contains('고스트보다')));
  });

  test('does not include ghost gap before start is confirmed', () {
    final coordinator = RunVoiceCueCoordinator();

    final cues = coordinator.cuesFor(
      _snapshot(
        isGhostRun: true,
        metrics: _metrics(distanceKm: 1.01),
        ghostFrame: _ghost(
          GhostRaceStatus.ahead,
          gapMs: 12000,
          startConfirmed: false,
        ),
        settings: const RunSettingsState(ghostVoiceCueEnabled: true),
      ),
    );

    expect(cues.single.text, '1킬로미터. 평균 페이스 5분 20초. 시간 5분 21초');
    expect(cues.single.text, isNot(contains('고스트보다')));
  });

  test('speaks stable ghost events when ghost voice is enabled', () {
    final coordinator = RunVoiceCueCoordinator();
    final startedAt = DateTime(2026, 5, 3);
    final settings = const RunSettingsState(ghostVoiceCueEnabled: true);

    coordinator.cuesFor(
      _snapshot(
        isGhostRun: true,
        metrics: _metrics(distanceKm: 0.5),
        ghostFrame: _ghost(GhostRaceStatus.offRoute, gapMs: 0),
        settings: settings,
        now: startedAt,
      ),
    );
    final cues = coordinator.cuesFor(
      _snapshot(
        isGhostRun: true,
        metrics: _metrics(distanceKm: 0.5),
        ghostFrame: _ghost(GhostRaceStatus.offRoute, gapMs: 0),
        settings: settings,
        now: startedAt.add(const Duration(seconds: 10)),
      ),
    );

    expect(cues.single.text, '경로를 벗어났어요');
  });

  test('does not speak stable ghost events before start is confirmed', () {
    final coordinator = RunVoiceCueCoordinator();
    final startedAt = DateTime(2026, 5, 3);
    final settings = const RunSettingsState(ghostVoiceCueEnabled: true);

    coordinator.cuesFor(
      _snapshot(
        isGhostRun: true,
        metrics: _metrics(distanceKm: 0.5),
        ghostFrame: _ghost(
          GhostRaceStatus.offRoute,
          gapMs: 0,
          startConfirmed: false,
        ),
        settings: settings,
        now: startedAt,
      ),
    );
    final cues = coordinator.cuesFor(
      _snapshot(
        isGhostRun: true,
        metrics: _metrics(distanceKm: 0.5),
        ghostFrame: _ghost(
          GhostRaceStatus.offRoute,
          gapMs: 0,
          startConfirmed: false,
        ),
        settings: settings,
        now: startedAt.add(const Duration(seconds: 10)),
      ),
    );

    expect(cues, isEmpty);
  });

  test('does not speak interval cues during ghost runs', () {
    final coordinator = RunVoiceCueCoordinator();
    const frame = RunIntervalFrame(
      step: RunIntervalStep(
        kind: RunIntervalStepKind.work,
        target: RunIntervalTarget.time(60000),
        repeatIndex: 2,
        repeatCount: 8,
      ),
      nextStep: null,
      remainingMs: 42000,
      remainingM: null,
      progress: 0.3,
    );

    final cues = coordinator.cuesFor(
      _snapshot(
        isGhostRun: true,
        metrics: _metrics(distanceKm: 0.5),
        intervalFrame: frame,
        ghostFrame: _ghost(GhostRaceStatus.behind, gapMs: -12000),
        settings: const RunSettingsState(ghostVoiceCueEnabled: true),
      ),
    );

    expect(cues, isEmpty);
  });
}

RunVoiceCueSnapshot _snapshot({
  RunPlaybackState? playbackState,
  LiveRunMetrics? metrics,
  RunIntervalFrame? intervalFrame,
  GhostRaceFrame? ghostFrame,
  RunSettingsState settings = const RunSettingsState(),
  DateTime? now,
  bool isGhostRun = false,
}) {
  return RunVoiceCueSnapshot(
    playbackState: playbackState ?? _playback(),
    metrics: metrics ?? _metrics(),
    intervalFrame: intervalFrame,
    ghostFrame: ghostFrame,
    settings: settings,
    now: now ?? DateTime(2026, 5, 3),
    isGhostRun: isGhostRun,
  );
}

RunPlaybackState _playback({RunScreenStatus status = RunScreenStatus.running}) {
  return RunPlaybackState(
    status: status,
    currentPointIndex: 0,
    recordedPoints: const [],
    elapsedBeforePauseMs: 0,
    startedAt: DateTime(2026, 5, 3),
    resumedAt: DateTime(2026, 5, 3),
    activeSessionId: 'run-a',
  );
}

LiveRunMetrics _metrics({double distanceKm = 1.01}) {
  return LiveRunMetrics(
    distanceKm: distanceKm,
    elapsedMs: 321000,
    averagePaceSecPerKm: 320,
    averageSpeedKmh: 11.2,
    caloriesKcal: 45,
    isPaused: false,
  );
}

GhostRaceFrame _ghost(
  GhostRaceStatus status, {
  required int gapMs,
  bool startConfirmed = true,
  double distanceToFinishM = 600,
}) {
  return GhostRaceFrame(
    status: status,
    timeGapMs: gapMs,
    distanceGapM: 30,
    ghostMarkerPoint: const MapCoordinate(latitude: 37, longitude: 127),
    isOffRoute: status == GhostRaceStatus.offRoute,
    routeProgress: 0.5,
    distanceToFinishM: distanceToFinishM,
    distanceFromRouteM: status == GhostRaceStatus.offRoute ? 40 : 4,
    totalRouteDistanceM: 1000,
    distanceToFinishPointM: distanceToFinishM,
    startConfirmed: startConfirmed,
  );
}
