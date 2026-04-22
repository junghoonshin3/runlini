import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:runlini/core/health/health_workout_recorder.dart';
import 'package:runlini/features/run_tracking/service/finished_run_session_builder.dart';
import 'package:runlini/features/run_tracking/state/live_location_providers.dart';
import 'package:runlini/features/run_tracking/state/run_playback_core_providers.dart';
import 'package:runlini/features/run_tracking/state/run_session_providers.dart';
import 'package:runlini/features/run_tracking/types/live_location_sample.dart';
import 'package:runlini/features/run_tracking/types/run_playback_state.dart';
import 'package:runlini/features/run_tracking/types/run_point.dart';
import 'package:runlini/features/run_tracking/types/run_screen_status.dart';
import 'package:runlini/features/run_tracking/types/run_session_ghost_summary.dart';

final finishedRunSessionBuilderProvider = Provider<FinishedRunSessionBuilder>(
  (Ref ref) => const FinishedRunSessionBuilder(),
);

class RunPlaybackController extends Notifier<RunPlaybackState> {
  @override
  RunPlaybackState build() => const RunPlaybackState.idle();

  Future<RunTrackingToggleResult> start() async {
    var seedSample = ref.read(liveLocationProvider);
    seedSample ??= await ref.read(liveLocationProvider.notifier).refresh();
    if (seedSample == null) {
      return RunTrackingToggleResult.unavailable;
    }

    final startedAt = ref.read(runPlaybackClockProvider)();
    state = RunPlaybackState(
      status: RunScreenStatus.running,
      currentPointIndex: 0,
      recordedPoints: <RunPoint>[seedSample.toRunPoint(elapsedMs: 0)],
      elapsedBeforePauseMs: 0,
      startedAt: startedAt,
      resumedAt: startedAt,
      activeSessionId: 'live_${startedAt.millisecondsSinceEpoch}',
    );
    ref.read(liveLocationProvider.notifier).setWorkoutTrackingEnabled(true);
    try {
      await ref.read(healthWorkoutRecorderProvider).beginRunCapture();
    } catch (error) {
      debugPrint('Runlini health export start failed: $error');
    }
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
    ref.read(liveLocationProvider.notifier).setWorkoutTrackingEnabled(false);
    if (startedAt == null) {
      state = const RunPlaybackState.idle();
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
          ghostSummary: ghostSummary,
        );
    state = state.copyWith(
      status: RunScreenStatus.reviewing,
      elapsedBeforePauseMs: durationMs,
      resumedAt: null,
      pendingFinishedSession: pendingSession,
    );
  }

  Future<void> saveFinishedRun() async {
    final pendingSession = state.pendingFinishedSession;
    if (state.status != RunScreenStatus.reviewing || pendingSession == null) {
      return;
    }

    try {
      await ref.read(runSessionRepositoryProvider).saveSession(pendingSession);
      ref.invalidate(runSessionListProvider);
      ref.invalidate(runSessionSummaryListProvider);
    } catch (error) {
      debugPrint('Runlini local run save failed: $error');
      return;
    }

    try {
      await ref
          .read(healthWorkoutRecorderProvider)
          .finishRunCapture(
            startedAt: pendingSession.startedAt,
            endedAt:
                pendingSession.endedAt ?? ref.read(runPlaybackClockProvider)(),
            recordedPoints: pendingSession.points,
          );
    } catch (error) {
      debugPrint('Runlini health export finish failed: $error');
    }

    state = const RunPlaybackState.idle();
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
    );
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
    );
    ref.read(liveLocationProvider.notifier).setWorkoutTrackingEnabled(true);
  }

  Future<RunTrackingToggleResult> toggle() async {
    if (state.hasActiveSession) {
      await stop();
      return RunTrackingToggleResult.stopped;
    }

    return start();
  }

  void ingestLiveSample(LiveLocationSample sample) {
    if (state.status != RunScreenStatus.running || state.startedAt == null) {
      return;
    }

    final nextPoints = ref.read(runPointSanitizerProvider).filter(<RunPoint>[
      ...state.recordedPoints,
      sample.toRunPoint(elapsedMs: state.elapsedAt(sample.capturedAt)),
    ]);
    if (nextPoints.length == state.recordedPoints.length) {
      return;
    }

    state = state.copyWith(
      recordedPoints: nextPoints,
      currentPointIndex: nextPoints.length - 1,
    );
  }
}

final runPlaybackControllerProvider =
    NotifierProvider<RunPlaybackController, RunPlaybackState>(
      RunPlaybackController.new,
    );
