import 'package:flutter/foundation.dart';
import 'package:runlini/features/ghost_racer/types/ghost_race_frame.dart';
import 'package:runlini/features/run_tracking/service/run_interval_workout_calculator.dart';
import 'package:runlini/features/run_tracking/service/run_voice_cue_formatter.dart';
import 'package:runlini/features/run_tracking/types/live_run_metrics.dart';
import 'package:runlini/features/run_tracking/types/run_playback_state.dart';
import 'package:runlini/features/run_tracking/types/run_screen_status.dart';
import 'package:runlini/features/run_tracking/types/run_settings.dart';

@immutable
class RunVoiceCue {
  const RunVoiceCue({required this.text, required this.volume});

  final String text;
  final double volume;
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
  static const Duration _offRouteStableDuration = Duration(seconds: 10);
  static const Duration _crossingStableDuration = Duration(seconds: 15);

  String? _activeSessionId;
  int _lastSpokenKm = 0;
  String? _lastIntervalStepKey;
  GhostRaceStatus? _ghostCandidateStatus;
  DateTime? _ghostCandidateSince;
  GhostRaceStatus? _lastStableRaceStatus;
  bool _offRouteCueSpoken = false;
  bool _returnCueSpoken = false;
  String? _ghostCompletionCueSessionId;

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

    final cues = <RunVoiceCue>[];
    final volume = snapshot.settings.voiceCueVolume.clamp(
      runVoiceCueVolumeMin,
      runVoiceCueVolumeMax,
    );
    final safeVolume = volume.toDouble();

    final kmCue = _kilometerCue(
      metrics,
      snapshot.settings,
      snapshot.isGhostRun ? snapshot.ghostFrame : null,
    );
    if (kmCue != null) {
      cues.add(RunVoiceCue(text: kmCue, volume: safeVolume));
    }
    final intervalCue = snapshot.isGhostRun
        ? null
        : _intervalCue(snapshot.intervalFrame);
    if (intervalCue != null) {
      cues.add(RunVoiceCue(text: intervalCue, volume: safeVolume));
    }
    if (snapshot.isGhostRun && snapshot.settings.ghostVoiceCueEnabled) {
      final ghostCue = _ghostEventCue(snapshot);
      if (ghostCue != null) {
        cues.add(RunVoiceCue(text: ghostCue, volume: safeVolume));
      }
      final completionCue = _ghostCompletionCue(snapshot);
      if (completionCue != null) {
        cues.add(RunVoiceCue(text: completionCue, volume: safeVolume));
      }
    }
    return cues;
  }

  RunVoiceCue? ghostStartCueFor({
    required bool isGhostRun,
    required RunSettingsState settings,
  }) {
    if (!isGhostRun ||
        !settings.voiceCueEnabled ||
        !settings.ghostVoiceCueEnabled) {
      return null;
    }
    final volume = settings.voiceCueVolume.clamp(
      runVoiceCueVolumeMin,
      runVoiceCueVolumeMax,
    );
    return RunVoiceCue(
      text: RunVoiceCueFormatter.ghostStart(),
      volume: volume.toDouble(),
    );
  }

  void reset() {
    _activeSessionId = null;
    _lastSpokenKm = 0;
    _lastIntervalStepKey = null;
    _ghostCandidateStatus = null;
    _ghostCandidateSince = null;
    _lastStableRaceStatus = null;
    _offRouteCueSpoken = false;
    _returnCueSpoken = false;
    _ghostCompletionCueSessionId = null;
  }

  String? _kilometerCue(
    LiveRunMetrics metrics,
    RunSettingsState settings,
    GhostRaceFrame? ghostFrame,
  ) {
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
      ghostGapMs: _ghostGapForKilometerCue(ghostFrame),
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

  int? _ghostGapForKilometerCue(GhostRaceFrame? frame) {
    if (frame == null ||
        frame.status == GhostRaceStatus.offRoute ||
        frame.status == GhostRaceStatus.unavailable) {
      return null;
    }
    if (frame.timeGapMs == 0) {
      return null;
    }
    return frame.timeGapMs;
  }

  String? _ghostEventCue(RunVoiceCueSnapshot snapshot) {
    final frame = snapshot.ghostFrame;
    if (frame == null || frame.status == GhostRaceStatus.unavailable) {
      return null;
    }
    final status = frame.status;
    final now = snapshot.now;
    if (_ghostCandidateStatus != status) {
      _ghostCandidateStatus = status;
      _ghostCandidateSince = now;
      return null;
    }

    final stableFor = now.difference(_ghostCandidateSince ?? now);
    if (status == GhostRaceStatus.offRoute) {
      if (!_offRouteCueSpoken && stableFor >= _offRouteStableDuration) {
        _offRouteCueSpoken = true;
        return '경로를 벗어났어요';
      }
      return null;
    }

    if (_offRouteCueSpoken &&
        !_returnCueSpoken &&
        stableFor >= _offRouteStableDuration) {
      _returnCueSpoken = true;
      return '경로로 돌아왔어요';
    }

    if (stableFor < _crossingStableDuration) {
      return null;
    }
    if (status == GhostRaceStatus.level) {
      _lastStableRaceStatus = status;
      return null;
    }
    if (status != GhostRaceStatus.ahead && status != GhostRaceStatus.behind) {
      return null;
    }

    final previousStableStatus = _lastStableRaceStatus;
    _lastStableRaceStatus = status;
    if (previousStableStatus == null || previousStableStatus == status) {
      return null;
    }
    return switch (status) {
      GhostRaceStatus.ahead => '고스트를 앞섰어요',
      GhostRaceStatus.behind => '고스트에게 뒤처졌어요',
      GhostRaceStatus.level ||
      GhostRaceStatus.offRoute ||
      GhostRaceStatus.unavailable => null,
    };
  }

  String? _ghostCompletionCue(RunVoiceCueSnapshot snapshot) {
    final activeSessionId = snapshot.playbackState.activeSessionId;
    final summary = snapshot.playbackState.ghostCompletionSummary;
    if (activeSessionId == null ||
        summary == null ||
        _ghostCompletionCueSessionId == activeSessionId) {
      return null;
    }
    _ghostCompletionCueSessionId = activeSessionId;
    return RunVoiceCueFormatter.ghostCompletion(summary);
  }
}
