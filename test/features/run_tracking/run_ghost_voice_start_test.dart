import 'package:flutter_test/flutter_test.dart';
import 'package:runlini/core/map/map_coordinate.dart';
import 'package:runlini/features/ghost_racer/types/ghost_race_frame.dart';
import 'package:runlini/features/run_tracking/service/run_voice_cue_coordinator.dart';
import 'package:runlini/features/run_tracking/types/live_run_metrics.dart';
import 'package:runlini/features/run_tracking/types/run_playback_state.dart';
import 'package:runlini/features/run_tracking/types/run_screen_status.dart';
import 'package:runlini/features/run_tracking/types/run_settings.dart';

void main() {
  test('ghost start cue follows master and ghost voice settings', () {
    final coordinator = RunVoiceCueCoordinator();

    final cue = coordinator.ghostStartCueFor(
      isGhostRun: true,
      settings: const RunSettingsState(
        ghostVoiceCueEnabled: true,
        voiceCueVolume: 0.4,
      ),
    );

    expect(cue?.text, '고스트런 시작');
    expect(cue?.volume, 0.4);
    expect(
      coordinator.ghostStartCueFor(
        isGhostRun: false,
        settings: const RunSettingsState(ghostVoiceCueEnabled: true),
      ),
      isNull,
    );
    expect(
      coordinator.ghostStartCueFor(
        isGhostRun: true,
        settings: const RunSettingsState(ghostVoiceCueEnabled: false),
      ),
      isNull,
    );
    expect(
      coordinator.ghostStartCueFor(
        isGhostRun: true,
        settings: const RunSettingsState(
          voiceCueEnabled: false,
          ghostVoiceCueEnabled: true,
        ),
      ),
      isNull,
    );
  });

  test('does not speak kilometer summary below one kilometer', () {
    final coordinator = RunVoiceCueCoordinator();

    final cues = coordinator.cuesFor(
      _snapshot(
        isGhostRun: true,
        metrics: _metrics(distanceKm: 0.99),
        ghostFrame: _ghost(GhostRaceStatus.ahead, gapMs: 12000),
      ),
    );

    expect(cues, isEmpty);
  });
}

RunVoiceCueSnapshot _snapshot({
  required LiveRunMetrics metrics,
  GhostRaceFrame? ghostFrame,
  bool isGhostRun = false,
}) {
  return RunVoiceCueSnapshot(
    playbackState: _playback(),
    metrics: metrics,
    intervalFrame: null,
    ghostFrame: ghostFrame,
    settings: const RunSettingsState(),
    now: DateTime(2026, 5, 3),
    isGhostRun: isGhostRun,
  );
}

RunPlaybackState _playback() {
  return RunPlaybackState(
    status: RunScreenStatus.running,
    currentPointIndex: 0,
    recordedPoints: const [],
    elapsedBeforePauseMs: 0,
    startedAt: DateTime(2026, 5, 3),
    resumedAt: DateTime(2026, 5, 3),
    activeSessionId: 'run-a',
  );
}

LiveRunMetrics _metrics({required double distanceKm}) {
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
