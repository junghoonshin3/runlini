import 'package:flutter_test/flutter_test.dart';
import 'package:runlini/core/map/map_coordinate.dart';
import 'package:runlini/features/ghost_racer/types/ghost_race_frame.dart';
import 'package:runlini/features/run_tracking/service/run_voice_cue_coordinator.dart';
import 'package:runlini/features/run_tracking/types/live_run_metrics.dart';
import 'package:runlini/features/run_tracking/types/run_playback_state.dart';
import 'package:runlini/features/run_tracking/types/run_screen_status.dart';
import 'package:runlini/features/run_tracking/types/run_session_ghost_summary.dart';
import 'package:runlini/features/run_tracking/types/run_settings.dart';

void main() {
  test('speaks kilometer summary during a ghost run', () {
    final coordinator = RunVoiceCueCoordinator();

    final cues = coordinator.cuesFor(
      _snapshot(
        isGhostRun: true,
        metrics: _metrics(distanceKm: 1.01),
        ghostFrame: _ghost(GhostRaceStatus.ahead, gapMs: 12000),
      ),
    );

    expect(cues.single.text, contains('1킬로미터'));
    expect(cues.single.text, contains('고스트보다 12초 앞서요'));
  });

  test('does not speak ghost kilometer when master or km voice is off', () {
    final coordinator = RunVoiceCueCoordinator();

    expect(
      coordinator.cuesFor(
        _snapshot(
          isGhostRun: true,
          metrics: _metrics(distanceKm: 1.01),
          settings: const RunSettingsState(voiceCueEnabled: false),
        ),
      ),
      isEmpty,
    );

    expect(
      coordinator.cuesFor(
        _snapshot(
          isGhostRun: true,
          metrics: _metrics(distanceKm: 2.01),
          settings: const RunSettingsState(kmVoiceCueEnabled: false),
        ),
      ),
      isEmpty,
    );
  });

  test('ghost voice setting controls off-route and return cues', () {
    final coordinator = RunVoiceCueCoordinator();
    final start = DateTime(2026, 5, 3);

    coordinator.cuesFor(
      _snapshot(
        isGhostRun: true,
        metrics: _metrics(distanceKm: 0.5),
        ghostFrame: _ghost(GhostRaceStatus.offRoute, gapMs: 0),
        settings: const RunSettingsState(ghostVoiceCueEnabled: true),
        now: start,
      ),
    );
    expect(
      coordinator.cuesFor(
        _snapshot(
          isGhostRun: true,
          metrics: _metrics(distanceKm: 0.5),
          ghostFrame: _ghost(GhostRaceStatus.offRoute, gapMs: 0),
          settings: const RunSettingsState(ghostVoiceCueEnabled: true),
          now: start.add(const Duration(seconds: 9)),
        ),
      ),
      isEmpty,
    );
    expect(
      coordinator
          .cuesFor(
            _snapshot(
              isGhostRun: true,
              metrics: _metrics(distanceKm: 0.5),
              ghostFrame: _ghost(GhostRaceStatus.offRoute, gapMs: 0),
              settings: const RunSettingsState(ghostVoiceCueEnabled: true),
              now: start.add(const Duration(seconds: 10)),
            ),
          )
          .map((cue) => cue.text),
      contains('경로를 벗어났어요'),
    );

    coordinator.cuesFor(
      _snapshot(
        isGhostRun: true,
        metrics: _metrics(distanceKm: 0.5),
        ghostFrame: _ghost(GhostRaceStatus.level, gapMs: 0),
        settings: const RunSettingsState(ghostVoiceCueEnabled: true),
        now: start.add(const Duration(seconds: 11)),
      ),
    );
    expect(
      coordinator
          .cuesFor(
            _snapshot(
              isGhostRun: true,
              metrics: _metrics(distanceKm: 0.5),
              ghostFrame: _ghost(GhostRaceStatus.level, gapMs: 0),
              settings: const RunSettingsState(ghostVoiceCueEnabled: true),
              now: start.add(const Duration(seconds: 21)),
            ),
          )
          .map((cue) => cue.text),
      contains('경로로 돌아왔어요'),
    );
  });

  test('speaks ghost crossing only after stable transition', () {
    final coordinator = RunVoiceCueCoordinator();
    final start = DateTime(2026, 5, 3);

    coordinator.cuesFor(
      _snapshot(
        isGhostRun: true,
        metrics: _metrics(distanceKm: 0.5),
        ghostFrame: _ghost(GhostRaceStatus.level, gapMs: 0),
        settings: const RunSettingsState(ghostVoiceCueEnabled: true),
        now: start,
      ),
    );
    coordinator.cuesFor(
      _snapshot(
        isGhostRun: true,
        metrics: _metrics(distanceKm: 0.5),
        ghostFrame: _ghost(GhostRaceStatus.level, gapMs: 0),
        settings: const RunSettingsState(ghostVoiceCueEnabled: true),
        now: start.add(const Duration(seconds: 15)),
      ),
    );

    expect(
      coordinator.cuesFor(
        _snapshot(
          isGhostRun: true,
          metrics: _metrics(distanceKm: 0.5),
          ghostFrame: _ghost(GhostRaceStatus.ahead, gapMs: 16000),
          settings: const RunSettingsState(ghostVoiceCueEnabled: true),
          now: start.add(const Duration(seconds: 16)),
        ),
      ),
      isEmpty,
    );
    expect(
      coordinator
          .cuesFor(
            _snapshot(
              isGhostRun: true,
              metrics: _metrics(distanceKm: 0.5),
              ghostFrame: _ghost(GhostRaceStatus.ahead, gapMs: 16000),
              settings: const RunSettingsState(ghostVoiceCueEnabled: true),
              now: start.add(const Duration(seconds: 31)),
            ),
          )
          .map((cue) => cue.text),
      contains('고스트를 앞섰어요'),
    );
  });

  test('speaks ghost completion once', () {
    final coordinator = RunVoiceCueCoordinator();
    final playback = _playback().copyWith(
      ghostCompletionSummary: const RunSessionGhostSummary(
        result: RunSessionGhostResult.ahead,
        timeGapMs: 32000,
        distanceGapM: 0,
        ghostSessionId: 'ghost-a',
        ghostLabel: 'Ghost',
      ),
    );

    final first = coordinator.cuesFor(
      _snapshot(
        isGhostRun: true,
        metrics: _metrics(distanceKm: 0.5),
        playbackState: playback,
        settings: const RunSettingsState(ghostVoiceCueEnabled: true),
      ),
    );
    final duplicate = coordinator.cuesFor(
      _snapshot(
        isGhostRun: true,
        metrics: _metrics(distanceKm: 0.5),
        playbackState: playback,
        settings: const RunSettingsState(ghostVoiceCueEnabled: true),
      ),
    );

    expect(first.map((cue) => cue.text), contains('고스트 코스 완료, 32초 빨랐어요'));
    expect(duplicate, isEmpty);
  });
}

RunVoiceCueSnapshot _snapshot({
  RunPlaybackState? playbackState,
  LiveRunMetrics? metrics,
  GhostRaceFrame? ghostFrame,
  RunSettingsState settings = const RunSettingsState(),
  DateTime? now,
  bool isGhostRun = false,
}) {
  return RunVoiceCueSnapshot(
    playbackState: playbackState ?? _playback(),
    metrics: metrics ?? _metrics(),
    intervalFrame: null,
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

GhostRaceFrame _ghost(GhostRaceStatus status, {required int gapMs}) {
  return GhostRaceFrame(
    status: status,
    timeGapMs: gapMs,
    distanceGapM: 30,
    ghostMarkerPoint: const MapCoordinate(latitude: 37, longitude: 127),
    isOffRoute: status == GhostRaceStatus.offRoute,
    routeProgress: 0.5,
    distanceToFinishM: 500,
    distanceFromRouteM: status == GhostRaceStatus.offRoute ? 40 : 4,
    totalRouteDistanceM: 1000,
    distanceToFinishPointM: 500,
  );
}
