import 'package:flutter/foundation.dart';
import 'package:runlini/features/ghost_racer/service/ghost_race_event_engine.dart';
import 'package:runlini/features/ghost_racer/types/ghost_race_frame.dart';
import 'package:runlini/features/run_tracking/service/run_interval_workout_calculator.dart';
import 'package:runlini/features/run_tracking/service/run_voice_cue_formatter.dart';
import 'package:runlini/features/run_tracking/types/live_run_metrics.dart';
import 'package:runlini/features/run_tracking/types/run_playback_state.dart';
import 'package:runlini/features/run_tracking/types/run_screen_status.dart';
import 'package:runlini/features/run_tracking/types/run_settings.dart';

enum RunVoiceCuePriority { low, normal, urgent }

@immutable
class RunVoiceCue {
  const RunVoiceCue({
    required this.text,
    required this.volume,
    this.priority = RunVoiceCuePriority.normal,
  });

  final String text;
  final double volume;
  final RunVoiceCuePriority priority;
}

@immutable
class RunVoiceCueSnapshot {
  const RunVoiceCueSnapshot({
    required this.playbackState,
    required this.metrics,
    required this.intervalFrame,
    required this.ghostFrame,
    required this.settings,
    required this.now,
    this.isGhostRun = false,
  });

  final RunPlaybackState playbackState;
  final LiveRunMetrics? metrics;
  final RunIntervalFrame? intervalFrame;
  final GhostRaceFrame? ghostFrame;
  final RunSettingsState settings;
  final DateTime now;
  final bool isGhostRun;
}

class RunVoiceCueCoordinator {
  String? _activeSessionId;
  int _lastSpokenKm = 0;
  String? _lastIntervalStepKey;
  final GhostRaceEventEngine _ghostEventEngine = GhostRaceEventEngine();

  List<RunVoiceCue> cuesFor(RunVoiceCueSnapshot snapshot) {
    final playback = snapshot.playbackState;
    final activeSessionId = playback.activeSessionId;
    if (!playback.hasActiveSession || activeSessionId == null) {
      reset();
      return const <RunVoiceCue>[];
    }
    if (_activeSessionId != activeSessionId) {
      reset();
      _activeSessionId = activeSessionId;
    }
    final metrics = snapshot.metrics;
    if (playback.status != RunScreenStatus.running ||
        metrics == null ||
        metrics.isPaused ||
        !snapshot.settings.voiceCueEnabled) {
      return const <RunVoiceCue>[];
    }

    final volume = snapshot.settings.voiceCueVolume.clamp(
      runVoiceCueVolumeMin,
      runVoiceCueVolumeMax,
    );
    final safeVolume = volume.toDouble();
    final ghostSpeechEnabled =
        snapshot.isGhostRun && snapshot.settings.ghostVoiceCueEnabled;

    final kmCue = _kilometerCue(
      metrics,
      snapshot.settings,
      ghostFrame: ghostSpeechEnabled ? snapshot.ghostFrame : null,
    );

    if (snapshot.isGhostRun) {
      final ghostEvents = _ghostEventEngine.eventsFor(
        sessionId: activeSessionId,
        frame: snapshot.ghostFrame,
        isRunning: true,
        now: snapshot.now,
        completionPending: playback.ghostCompletionPromptPending,
      );
      if (ghostSpeechEnabled) {
        final ghostCue = _highestPriorityGhostCue(
          ghostEvents,
          volume: safeVolume,
        );
        if (ghostCue != null) {
          return [ghostCue];
        }
      }
      if (kmCue != null) {
        return [
          RunVoiceCue(
            text: kmCue,
            volume: safeVolume,
            priority: RunVoiceCuePriority.low,
          ),
        ];
      }
      return const <RunVoiceCue>[];
    }

    final cues = <RunVoiceCue>[];
    if (kmCue != null) {
      cues.add(
        RunVoiceCue(
          text: kmCue,
          volume: safeVolume,
          priority: RunVoiceCuePriority.low,
        ),
      );
    }
    final intervalCue = _intervalCue(snapshot.intervalFrame);
    if (intervalCue != null) {
      cues.add(RunVoiceCue(text: intervalCue, volume: safeVolume));
    }
    return cues;
  }

  void reset() {
    _activeSessionId = null;
    _lastSpokenKm = 0;
    _lastIntervalStepKey = null;
    _ghostEventEngine.reset();
  }

  String? _kilometerCue(
    LiveRunMetrics metrics,
    RunSettingsState settings, {
    GhostRaceFrame? ghostFrame,
  }) {
    if (!settings.kmVoiceCueEnabled) {
      return null;
    }
    final currentKm = metrics.distanceKm.floor();
    if (currentKm <= 0 || currentKm <= _lastSpokenKm) {
      return null;
    }
    _lastSpokenKm = currentKm;
    return RunVoiceCueFormatter.kilometerSummary(
      kilometer: currentKm,
      averagePaceSecPerKm: metrics.averagePaceSecPerKm,
      elapsedMs: metrics.elapsedMs,
      ghostGapMs: _ghostGapMsForSpeech(ghostFrame),
    );
  }

  String? _intervalCue(RunIntervalFrame? frame) {
    final step = frame?.step;
    if (step == null) {
      _lastIntervalStepKey = null;
      return null;
    }
    final key =
        '${step.kind.name}:${step.repeatIndex ?? 0}:${step.repeatCount}';
    if (key == _lastIntervalStepKey) {
      return null;
    }
    _lastIntervalStepKey = key;
    return RunVoiceCueFormatter.intervalStepLabel(step);
  }

  RunVoiceCue? _ghostCue(GhostRaceEvent event, {required double volume}) {
    final gap = RunVoiceCueFormatter.ghostGapSpeech(
      _ghostGapMsForSpeech(event.frame),
    );
    final text = switch (event.type) {
      GhostRaceEventType.offRoute => '경로를 벗어났어요',
      GhostRaceEventType.backOnRoute => '경로로 돌아왔어요',
      GhostRaceEventType.overtake =>
        gap == null ? '고스트를 추월했어요' : '고스트를 추월했어요. 지금은 $gap',
      GhostRaceEventType.lostLead =>
        gap == null ? '고스트에게 역전당했어요' : '고스트에게 역전당했어요. 지금은 $gap',
      GhostRaceEventType.last500m => '마지막 500미터',
      GhostRaceEventType.last200m => '마지막 200미터',
      GhostRaceEventType.completed =>
        RunVoiceCueFormatter.ghostCompletionFromGap(event.frame.timeGapMs),
    };
    return RunVoiceCue(
      text: text,
      volume: volume,
      priority: _ghostCuePriority(event.type),
    );
  }

  RunVoiceCue? _highestPriorityGhostCue(
    List<GhostRaceEvent> events, {
    required double volume,
  }) {
    GhostRaceEvent? selected;
    var selectedPriority = 1 << 30;
    for (final event in events) {
      final priority = _ghostEventPriority(event.type);
      if (priority < selectedPriority) {
        selected = event;
        selectedPriority = priority;
      }
    }
    if (selected == null) {
      return null;
    }
    return _ghostCue(selected, volume: volume);
  }

  RunVoiceCuePriority _ghostCuePriority(GhostRaceEventType type) {
    return switch (type) {
      GhostRaceEventType.offRoute ||
      GhostRaceEventType.backOnRoute ||
      GhostRaceEventType.completed => RunVoiceCuePriority.urgent,
      GhostRaceEventType.overtake ||
      GhostRaceEventType.lostLead ||
      GhostRaceEventType.last200m ||
      GhostRaceEventType.last500m => RunVoiceCuePriority.normal,
    };
  }

  int _ghostEventPriority(GhostRaceEventType type) {
    return switch (type) {
      GhostRaceEventType.completed => 0,
      GhostRaceEventType.offRoute || GhostRaceEventType.backOnRoute => 10,
      GhostRaceEventType.overtake || GhostRaceEventType.lostLead => 20,
      GhostRaceEventType.last200m => 30,
      GhostRaceEventType.last500m => 31,
    };
  }

  int? _ghostGapMsForSpeech(GhostRaceFrame? frame) {
    if (frame == null || frame.isOffRoute || !frame.startConfirmed) {
      return null;
    }
    return switch (frame.status) {
      GhostRaceStatus.ahead || GhostRaceStatus.behind => frame.timeGapMs,
      GhostRaceStatus.level ||
      GhostRaceStatus.offRoute ||
      GhostRaceStatus.unavailable => null,
    };
  }
}
