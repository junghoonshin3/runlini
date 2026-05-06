import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:runlini/features/ghost_racer/types/ghost_race_frame.dart';
import 'package:runlini/features/run_tracking/service/run_interval_workout_calculator.dart';
import 'package:runlini/features/run_tracking/types/live_run_metrics.dart';
import 'package:runlini/features/run_tracking/types/run_interval_workout.dart';
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
  String? _activeSessionId;
  int _lastSpokenKm = 0;
  String? _lastIntervalStepKey;

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
        snapshot.isGhostRun ||
        !snapshot.settings.voiceCueEnabled) {
      return const <RunVoiceCue>[];
    }

    final cues = <RunVoiceCue>[];
    final volume = snapshot.settings.voiceCueVolume.clamp(
      runVoiceCueVolumeMin,
      runVoiceCueVolumeMax,
    );
    final safeVolume = volume.toDouble();

    final kmCue = _kilometerCue(metrics, snapshot.settings);
    if (kmCue != null) {
      cues.add(RunVoiceCue(text: kmCue, volume: safeVolume));
    }
    final intervalCue = _intervalCue(snapshot.intervalFrame);
    if (intervalCue != null) {
      cues.add(RunVoiceCue(text: intervalCue, volume: safeVolume));
    }
    final ghostCue = _ghostCue();
    if (ghostCue != null) {
      cues.add(RunVoiceCue(text: ghostCue, volume: safeVolume));
    }
    return cues;
  }

  void reset() {
    _activeSessionId = null;
    _lastSpokenKm = 0;
    _lastIntervalStepKey = null;
  }

  String? _kilometerCue(LiveRunMetrics metrics, RunSettingsState settings) {
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
    return _intervalStepLabel(step);
  }

  String? _ghostCue() {
    return null;
  }
}

class RunVoiceCueFormatter {
  const RunVoiceCueFormatter._();

  static String kilometerSummary({
    required int kilometer,
    required double? averagePaceSecPerKm,
    required int elapsedMs,
  }) {
    final parts = <String>['$kilometer킬로미터'];
    final pace = paceSpeech(averagePaceSecPerKm);
    if (pace != null) {
      parts.add('평균 페이스 $pace');
    }
    final elapsed = elapsedSpeech(elapsedMs);
    if (elapsed != null) {
      parts.add('시간 $elapsed');
    }
    return parts.join(', ');
  }

  static String? paceSpeech(double? paceSecPerKm) {
    final pace = paceSecPerKm?.takeIfFinitePositive();
    if (pace == null) {
      return null;
    }
    final totalSeconds = pace.round().clamp(1, 24 * 60 * 60).toInt();
    final minutes = totalSeconds ~/ 60;
    final seconds = totalSeconds % 60;
    if (seconds == 0) {
      return '$minutes분';
    }
    return '$minutes분 $seconds초';
  }

  static String? elapsedSpeech(int elapsedMs) {
    if (elapsedMs <= 0) {
      return null;
    }
    final totalSeconds = math.max(1, elapsedMs ~/ 1000);
    final hours = totalSeconds ~/ 3600;
    final minutes = (totalSeconds % 3600) ~/ 60;
    final seconds = totalSeconds % 60;
    final parts = <String>[];
    if (hours > 0) {
      parts.add('$hours시간');
    }
    if (minutes > 0) {
      parts.add('$minutes분');
    }
    if (seconds > 0 || parts.isEmpty) {
      parts.add('$seconds초');
    }
    return parts.join(' ');
  }
}

String _intervalStepLabel(RunIntervalStep step) {
  final base = switch (step.kind) {
    RunIntervalStepKind.warmup => '워밍업',
    RunIntervalStepKind.work => '질주',
    RunIntervalStepKind.recovery => '휴식',
    RunIntervalStepKind.cooldown => '쿨다운',
    RunIntervalStepKind.finished => '완료',
  };
  final repeatIndex = step.repeatIndex;
  if (repeatIndex == null) {
    return base;
  }
  return '$base $repeatIndex/${step.repeatCount}';
}

extension on double {
  double? takeIfFinitePositive() {
    if (!isFinite || this <= 0) {
      return null;
    }
    return this;
  }
}
