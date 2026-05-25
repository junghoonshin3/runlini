import 'package:flutter/foundation.dart';
import 'package:runlini/features/record_race/service/record_race_event_engine.dart';
import 'package:runlini/features/record_race/types/record_race_frame.dart';
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
    required this.recordRaceFrame,
    required this.settings,
    required this.now,
    this.isRecordRaceRun = false,
  });

  final RunPlaybackState playbackState;
  final LiveRunMetrics? metrics;
  final RunIntervalFrame? intervalFrame;
  final RecordRaceFrame? recordRaceFrame;
  final RunSettingsState settings;
  final DateTime now;
  final bool isRecordRaceRun;
}

class RunVoiceCueCoordinator {
  String? _activeSessionId;
  int _lastSpokenKm = 0;
  String? _lastIntervalStepKey;
  final RecordRaceEventEngine _recordRaceEventEngine = RecordRaceEventEngine();

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
    final recordRaceSpeechEnabled =
        snapshot.isRecordRaceRun && snapshot.settings.recordRaceVoiceCueEnabled;

    final kmCue = _kilometerCue(
      metrics,
      snapshot.settings,
      recordRaceFrame: recordRaceSpeechEnabled
          ? snapshot.recordRaceFrame
          : null,
    );

    if (snapshot.isRecordRaceRun) {
      final recordRaceEvents = _recordRaceEventEngine.eventsFor(
        sessionId: activeSessionId,
        frame: snapshot.recordRaceFrame,
        isRunning: true,
        now: snapshot.now,
        completionPending: playback.recordRaceCompletionPromptPending,
      );
      if (recordRaceSpeechEnabled) {
        final recordRaceCue = _highestPriorityRecordRaceCue(
          recordRaceEvents,
          volume: safeVolume,
        );
        if (recordRaceCue != null) {
          return [recordRaceCue];
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
    _recordRaceEventEngine.reset();
  }

  String? _kilometerCue(
    LiveRunMetrics metrics,
    RunSettingsState settings, {
    RecordRaceFrame? recordRaceFrame,
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
      recordRaceGapMs: _recordRaceGapMsForSpeech(recordRaceFrame),
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

  RunVoiceCue? _recordRaceCue(RecordRaceEvent event, {required double volume}) {
    final gap = RunVoiceCueFormatter.recordRaceGapSpeech(
      _recordRaceGapMsForSpeech(event.frame),
    );
    final text = switch (event.type) {
      RecordRaceEventType.offRoute => '경로를 벗어났어요',
      RecordRaceEventType.backOnRoute => '경로로 돌아왔어요',
      RecordRaceEventType.overtake =>
        gap == null ? '기록 레이스를 추월했어요' : '기록 레이스를 추월했어요. 지금은 $gap',
      RecordRaceEventType.lostLead =>
        gap == null ? '기록 레이스에게 역전당했어요' : '기록 레이스에게 역전당했어요. 지금은 $gap',
      RecordRaceEventType.last500m => '마지막 500미터',
      RecordRaceEventType.last200m => '마지막 200미터',
      RecordRaceEventType.completed =>
        RunVoiceCueFormatter.recordRaceCompletionFromGap(event.frame.timeGapMs),
    };
    return RunVoiceCue(
      text: text,
      volume: volume,
      priority: _recordRaceCuePriority(event.type),
    );
  }

  RunVoiceCue? _highestPriorityRecordRaceCue(
    List<RecordRaceEvent> events, {
    required double volume,
  }) {
    RecordRaceEvent? selected;
    var selectedPriority = 1 << 30;
    for (final event in events) {
      final priority = _recordRaceEventPriority(event.type);
      if (priority < selectedPriority) {
        selected = event;
        selectedPriority = priority;
      }
    }
    if (selected == null) {
      return null;
    }
    return _recordRaceCue(selected, volume: volume);
  }

  RunVoiceCuePriority _recordRaceCuePriority(RecordRaceEventType type) {
    return switch (type) {
      RecordRaceEventType.offRoute ||
      RecordRaceEventType.backOnRoute ||
      RecordRaceEventType.completed => RunVoiceCuePriority.urgent,
      RecordRaceEventType.overtake ||
      RecordRaceEventType.lostLead ||
      RecordRaceEventType.last200m ||
      RecordRaceEventType.last500m => RunVoiceCuePriority.normal,
    };
  }

  int _recordRaceEventPriority(RecordRaceEventType type) {
    return switch (type) {
      RecordRaceEventType.completed => 0,
      RecordRaceEventType.offRoute || RecordRaceEventType.backOnRoute => 10,
      RecordRaceEventType.overtake || RecordRaceEventType.lostLead => 20,
      RecordRaceEventType.last200m => 30,
      RecordRaceEventType.last500m => 31,
    };
  }

  int? _recordRaceGapMsForSpeech(RecordRaceFrame? frame) {
    if (frame == null || frame.isOffRoute || !frame.startConfirmed) {
      return null;
    }
    return switch (frame.status) {
      RecordRaceStatus.ahead || RecordRaceStatus.behind => frame.timeGapMs,
      RecordRaceStatus.level ||
      RecordRaceStatus.offRoute ||
      RecordRaceStatus.unavailable => null,
    };
  }
}
