import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:runlini/core/health/health_workout_recorder.dart';
import 'package:runlini/core/motion/run_motion_evidence_client.dart';
import 'package:runlini/features/run_tracking/service/run_auto_pause_detector.dart';
import 'package:runlini/features/run_tracking/service/run_playback_sample_fusion.dart';
import 'package:runlini/features/run_tracking/state/live_location_providers.dart';
import 'package:runlini/features/run_tracking/state/run_motion_evidence_providers.dart';
import 'package:runlini/features/run_tracking/state/run_playback_core_providers.dart';
import 'package:runlini/features/run_tracking/state/run_playback_support_providers.dart';
import 'package:runlini/features/run_tracking/state/run_session_providers.dart';
import 'package:runlini/features/run_tracking/state/run_settings_providers.dart';
import 'package:runlini/features/run_tracking/types/live_location_sample.dart';
import 'package:runlini/features/run_tracking/types/run_playback_state.dart';
import 'package:runlini/features/run_tracking/types/run_point.dart';
import 'package:runlini/features/run_tracking/types/run_screen_status.dart';
import 'package:runlini/features/run_tracking/types/run_session_ghost_summary.dart';
import 'package:runlini/features/run_tracking/types/run_settings.dart';

part 'run_playback_ingest_extension.dart';

class RunPlaybackController extends Notifier<RunPlaybackState>
    with RunPlaybackLiveSampleIngest {
  @override
  RunPlaybackState build() {
    ref.listen(runSettingsControllerProvider, (previous, next) {
      final autoPauseEnabled = next.value?.autoPauseEnabled;
      if (autoPauseEnabled != null) {
        _applyAutoPauseSetting(autoPauseEnabled);
      }
    });
    ref.listen(runMotionEvidenceProvider, (previous, next) {
      _accumulateCadenceSteps(next);
    });
    return const RunPlaybackState.idle();
  }

  Future<RunTrackingToggleResult> start() async {
    var seedSample = ref.read(liveLocationProvider);
    seedSample ??= await ref.read(liveLocationProvider.notifier).refresh();
    if (seedSample == null) {
      return RunTrackingToggleResult.unavailable;
    }

    final startedAt = ref.read(runPlaybackClockProvider)();
    final settings =
        ref.read(runSettingsControllerProvider).value ??
        const RunSettingsState();
    final seedPoint = seedSample.toRunPoint(elapsedMs: 0);
    _resetCadenceTracking();
    state = RunPlaybackState(
      status: RunScreenStatus.running,
      currentPointIndex: 0,
      recordedPoints: <RunPoint>[seedPoint],
      rawPoints: <RunPoint>[seedPoint],
      elapsedBeforePauseMs: 0,
      startedAt: startedAt,
      resumedAt: startedAt,
      activeSessionId: 'live_${startedAt.millisecondsSinceEpoch}',
      intervalManualAdvanceCount: 0,
      autoPauseEnabled: settings.autoPauseEnabled,
    );
    ref.read(runMotionEvidenceProvider.notifier).setTrackingEnabled(true);
    ref.read(liveLocationProvider.notifier).setWorkoutTrackingEnabled(true);
    return RunTrackingToggleResult.started;
  }

  Future<void> stop({RunSessionGhostSummary? ghostSummary}) async {
    if (!state.hasActiveSession) {
      try {
        await ref.read(healthWorkoutRecorderProvider).cancelRunCapture();
      } catch (error) {
        debugPrint('Runlini health export cleanup failed: $error');
      }
      return;
    }

    final startedAt = state.startedAt;
    ref.read(runMotionEvidenceProvider.notifier).setTrackingEnabled(false);
    ref.read(liveLocationProvider.notifier).setWorkoutTrackingEnabled(false);
    if (startedAt == null) {
      state = const RunPlaybackState.idle();
      _resetCadenceTracking();
      try {
        await ref.read(healthWorkoutRecorderProvider).cancelRunCapture();
      } catch (error) {
        debugPrint('Runlini health export cleanup failed: $error');
      }
      return;
    }

    final endedAt = ref.read(runPlaybackClockProvider)();
    final recordedPoints = List<RunPoint>.from(state.recordedPoints);
    final durationMs = state.elapsedAt(endedAt);
    final bodyWeightKg = ref
        .read(runSettingsControllerProvider)
        .value
        ?.bodyWeightKg;
    final pendingSession = ref
        .read(finishedRunSessionBuilderProvider)
        .build(
          id:
              state.activeSessionId ??
              'live_${startedAt.millisecondsSinceEpoch}',
          startedAt: startedAt,
          endedAt: endedAt,
          durationMs: durationMs,
          recordedPoints: recordedPoints,
          bodyWeightKg: bodyWeightKg,
          cadenceStepCount: state.cadenceStepCount,
          ghostSummary: ghostSummary,
        );
    state = state.copyWith(
      status: RunScreenStatus.reviewing,
      elapsedBeforePauseMs: durationMs,
      resumedAt: null,
      pendingFinishedSession: pendingSession,
    );
  }

  Future<HealthWorkoutExportResult?> saveFinishedRun() async {
    final pendingSession = state.pendingFinishedSession;
    if (state.status != RunScreenStatus.reviewing || pendingSession == null) {
      return null;
    }

    final defaultShoeId = ref
        .read(runSettingsControllerProvider)
        .value
        ?.defaultShoeId;
    final sessionToSave = pendingSession.copyWith(shoeId: defaultShoeId);

    try {
      await ref.read(runSessionRepositoryProvider).saveSession(sessionToSave);
      ref.invalidate(runSessionListProvider);
      ref.invalidate(runSessionSummaryListProvider);
    } catch (error) {
      debugPrint('Runlini local run save failed: $error');
      return null;
    }

    const exportResult = HealthWorkoutExportResult.skipped(
      'Health backup is available from Settings.',
    );

    final syncedSession = ref
        .read(runHealthExportStatusMapperProvider)
        .apply(
          session: sessionToSave,
          result: exportResult,
          now: ref.read(runPlaybackClockProvider)(),
        );
    try {
      await ref.read(runSessionRepositoryProvider).saveSession(syncedSession);
      ref.invalidate(runSessionListProvider);
      ref.invalidate(runSessionSummaryListProvider);
    } catch (error) {
      debugPrint('Runlini health export status save failed: $error');
    }

    state = const RunPlaybackState.idle();
    _resetCadenceTracking();
    return exportResult;
  }

  Future<void> discardFinishedRun() async {
    if (state.status != RunScreenStatus.reviewing) {
      return;
    }

    try {
      await ref.read(healthWorkoutRecorderProvider).cancelRunCapture();
    } catch (error) {
      debugPrint('Runlini health export cleanup failed: $error');
    }

    state = const RunPlaybackState.idle();
    _resetCadenceTracking();
  }

  Future<void> pause() async {
    if (state.status != RunScreenStatus.running) {
      return;
    }

    state = state.copyWith(
      status: RunScreenStatus.paused,
      elapsedBeforePauseMs: state.elapsedAt(
        ref.read(runPlaybackClockProvider)(),
      ),
      resumedAt: null,
      pauseReason: RunPauseReason.manual,
    );
    _markCadenceEvidenceSeen(ref.read(runMotionEvidenceProvider));
    ref.read(runMotionEvidenceProvider.notifier).setTrackingEnabled(false);
    ref.read(liveLocationProvider.notifier).setWorkoutTrackingEnabled(false);
  }

  Future<void> resume() async {
    if (state.status != RunScreenStatus.paused || state.startedAt == null) {
      return;
    }

    final resumedAt = ref.read(runPlaybackClockProvider)();
    state = state.copyWith(
      status: RunScreenStatus.running,
      resumedAt: resumedAt,
      pauseReason: null,
    );
    _markCadenceEvidenceSeen(ref.read(runMotionEvidenceProvider));
    ref.read(runMotionEvidenceProvider.notifier).setTrackingEnabled(true);
    ref.read(liveLocationProvider.notifier).setWorkoutTrackingEnabled(true);
  }

  Future<RunTrackingToggleResult> toggle() async {
    if (state.hasActiveSession) {
      await stop();
      return RunTrackingToggleResult.stopped;
    }

    return start();
  }

  void advanceInterval() {
    if (!state.hasActiveSession) {
      return;
    }
    state = state.copyWith(
      intervalManualAdvanceCount: state.intervalManualAdvanceCount + 1,
    );
  }

  void updateGhostCompletion({
    required int candidateCount,
    RunSessionGhostSummary? completedSummary,
  }) {
    if (!state.hasActiveSession || state.status != RunScreenStatus.running) {
      return;
    }
    if (state.ghostCompletionPromptDismissed ||
        state.ghostCompletionPromptPending) {
      return;
    }
    if (completedSummary != null) {
      state = state.copyWith(
        ghostCompletionCandidateCount: candidateCount,
        ghostCompletionPromptPending: true,
        ghostCompletionSummary: completedSummary,
      );
      return;
    }
    if (candidateCount != state.ghostCompletionCandidateCount) {
      state = state.copyWith(ghostCompletionCandidateCount: candidateCount);
    }
  }

  void continueAfterGhostCompletion() {
    if (!state.hasActiveSession) {
      return;
    }
    state = state.copyWith(
      ghostCompletionPromptPending: false,
      ghostCompletionPromptDismissed: true,
    );
  }

  void _applyAutoPauseSetting(bool enabled) {
    if (!state.hasActiveSession || state.autoPauseEnabled == enabled) {
      return;
    }

    if (!enabled && state.isAutoPaused) {
      state = state.copyWith(
        status: RunScreenStatus.running,
        resumedAt: ref.read(runPlaybackClockProvider)(),
        pauseReason: null,
        autoPauseEnabled: false,
      );
      return;
    }

    state = state.copyWith(autoPauseEnabled: enabled);
  }
}

final runPlaybackControllerProvider =
    NotifierProvider<RunPlaybackController, RunPlaybackState>(
      RunPlaybackController.new,
    );
