import 'package:flutter_test/flutter_test.dart';
import 'package:runlini/features/run_tracking/service/run_interval_workout_calculator.dart';
import 'package:runlini/features/run_tracking/service/run_voice_cue_coordinator.dart';
import 'package:runlini/features/run_tracking/service/run_voice_cue_formatter.dart';
import 'package:runlini/features/run_tracking/types/live_run_metrics.dart';
import 'package:runlini/features/run_tracking/types/run_interval_workout.dart';
import 'package:runlini/features/run_tracking/types/run_playback_state.dart';
import 'package:runlini/features/run_tracking/types/run_screen_status.dart';
import 'package:runlini/features/run_tracking/types/run_settings.dart';

void main() {
  test('formats kilometer summary with average pace and elapsed time', () {
    expect(
      RunVoiceCueFormatter.kilometerSummary(
        kilometer: 1,
        averagePaceSecPerKm: 320,
        elapsedMs: 321000,
      ),
      '1킬로미터, 평균 페이스 5분 20초, 시간 5분 21초',
    );
  });

  test('formats kilometer summary with ghost gap', () {
    expect(
      RunVoiceCueFormatter.kilometerSummary(
        kilometer: 1,
        averagePaceSecPerKm: 320,
        elapsedMs: 321000,
        ghostGapMs: 12000,
      ),
      '1킬로미터, 평균 페이스 5분 20초, 시간 5분 21초, 고스트보다 12초 앞서요',
    );
  });

  test('speaks each kilometer once', () {
    final coordinator = RunVoiceCueCoordinator();
    final first = coordinator.cuesFor(
      _snapshot(metrics: _metrics(distanceKm: 1.01)),
    );
    final duplicate = coordinator.cuesFor(
      _snapshot(metrics: _metrics(distanceKm: 1.2)),
    );
    final second = coordinator.cuesFor(
      _snapshot(metrics: _metrics(distanceKm: 2.01)),
    );

    expect(first.single.text, startsWith('1킬로미터'));
    expect(duplicate, isEmpty);
    expect(second.single.text, startsWith('2킬로미터'));
  });

  test('does not speak while paused, idle, reviewing, or disabled', () {
    final coordinator = RunVoiceCueCoordinator();

    expect(
      coordinator.cuesFor(
        _snapshot(playbackState: _playback(status: RunScreenStatus.paused)),
      ),
      isEmpty,
    );
    expect(
      coordinator.cuesFor(
        _snapshot(playbackState: const RunPlaybackState.idle()),
      ),
      isEmpty,
    );
    expect(
      coordinator.cuesFor(
        _snapshot(playbackState: _playback(status: RunScreenStatus.reviewing)),
      ),
      isEmpty,
    );
    expect(
      coordinator.cuesFor(
        _snapshot(settings: const RunSettingsState(voiceCueEnabled: false)),
      ),
      isEmpty,
    );
  });

  test('speaks interval step changes once', () {
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

    final first = coordinator.cuesFor(_snapshot(intervalFrame: frame));
    final duplicate = coordinator.cuesFor(_snapshot(intervalFrame: frame));

    expect(first.map((cue) => cue.text), contains('질주 2/8'));
    expect(duplicate, isEmpty);
  });
}

RunVoiceCueSnapshot _snapshot({
  RunPlaybackState? playbackState,
  LiveRunMetrics? metrics,
  RunIntervalFrame? intervalFrame,
  RunSettingsState settings = const RunSettingsState(),
  DateTime? now,
  bool isGhostRun = false,
}) {
  return RunVoiceCueSnapshot(
    playbackState: playbackState ?? _playback(),
    metrics: metrics ?? _metrics(),
    intervalFrame: intervalFrame,
    ghostFrame: null,
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
