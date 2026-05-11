import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:runlini/features/ghost_racer/service/ghost_race_completion_detector.dart';
import 'package:runlini/features/ghost_racer/service/ghost_race_gap_service.dart';
import 'package:runlini/features/ghost_racer/types/ghost_race_frame.dart';
import 'package:runlini/features/run_tracking/state/run_live_metrics_providers.dart';
import 'package:runlini/features/run_tracking/state/run_playback_providers.dart';
import 'package:runlini/features/run_tracking/state/run_settings_providers.dart';
import 'package:runlini/features/run_tracking/types/run_map_view_state.dart';
import 'package:runlini/features/run_tracking/types/run_screen_status.dart';

final ghostRaceGapServiceProvider = Provider<GhostRaceGapService>(
  (Ref ref) => const GhostRaceGapService(),
);

final ghostRaceCompletionDetectorProvider =
    Provider<GhostRaceCompletionDetector>(
      (Ref ref) => const GhostRaceCompletionDetector(),
    );

final ghostRaceFrameProvider = Provider<GhostRaceFrame?>((Ref ref) {
  final playbackInput = ref.watch(
    runPlaybackControllerProvider.select(
      (state) => (
        status: state.status,
        recordedPoints: state.recordedPoints,
        elapsedBeforePauseMs: state.elapsedBeforePauseMs,
        resumedAt: state.resumedAt,
        hasActiveSession: state.hasActiveSession,
      ),
    ),
  );
  if (!playbackInput.hasActiveSession || playbackInput.recordedPoints.isEmpty) {
    return null;
  }

  final staticState = ref.watch(runMapStaticStateProvider).value;
  final selectedGhostSession = staticState?.selectedGhostSession;
  if (selectedGhostSession == null) {
    return null;
  }

  ref.watch(liveRunMetricsTickerProvider);
  final now = ref.watch(runPlaybackClockProvider)();
  final service = ref.watch(ghostRaceGapServiceProvider);
  final runnerDistanceM = ref
      .watch(runRouteSegmenterProvider)
      .segment(playbackInput.recordedPoints)
      .distanceM;
  final startDecision = service.evaluateStart(
    runnerPoints: playbackInput.recordedPoints,
    ghostSession: selectedGhostSession,
    runnerDistanceM: runnerDistanceM,
  );
  return service.calculate(
    runnerPoint: playbackInput.recordedPoints.last,
    ghostSession: selectedGhostSession,
    runnerElapsedMs: _elapsedAt(
      hasActiveSession: playbackInput.hasActiveSession,
      status: playbackInput.status,
      elapsedBeforePauseMs: playbackInput.elapsedBeforePauseMs,
      resumedAt: playbackInput.resumedAt,
      now: now,
    ),
    startConfirmed: startDecision.isConfirmed,
    startCandidateCount: startDecision.candidateCount,
    startLastEvaluatedPointCount: startDecision.lastEvaluatedPointCount,
    runnerDistanceM: runnerDistanceM,
  );
});

final ghostAwareRunMapViewStateProvider = Provider<RunMapViewState>((Ref ref) {
  final mapViewState = ref.watch(runMapViewStateProvider);

  final ghostRaceFrame = ref.watch(ghostRaceFrameProvider);
  final showGhostMarker =
      ref.watch(runSettingsControllerProvider).value?.showGhostMarker ?? false;
  final showActiveGhostMarker =
      ref.watch(
        runPlaybackControllerProvider.select((state) => state.hasActiveSession),
      ) &&
      ghostRaceFrame != null;
  final shouldShowGhostMarker = showGhostMarker || showActiveGhostMarker;
  return mapViewState.copyWith(
    ghostMarkerPoint: shouldShowGhostMarker
        ? ghostRaceFrame?.ghostMarkerPoint
        : null,
    clearGhostMarkerPoint: !shouldShowGhostMarker,
  );
});

int _elapsedAt({
  required bool hasActiveSession,
  required RunScreenStatus status,
  required int elapsedBeforePauseMs,
  required DateTime? resumedAt,
  required DateTime now,
}) {
  if (!hasActiveSession) {
    return 0;
  }

  if (status == RunScreenStatus.running && resumedAt != null) {
    final segmentMs = now.difference(resumedAt).inMilliseconds;
    return elapsedBeforePauseMs + (segmentMs < 0 ? 0 : segmentMs);
  }

  return elapsedBeforePauseMs;
}
