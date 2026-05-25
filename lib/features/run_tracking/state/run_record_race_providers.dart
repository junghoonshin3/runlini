import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:runlini/features/record_race/service/record_race_completion_detector.dart';
import 'package:runlini/features/record_race/service/record_race_gap_service.dart';
import 'package:runlini/features/record_race/state/record_race_providers.dart';
import 'package:runlini/features/record_race/types/record_race_frame.dart';
import 'package:runlini/features/run_tracking/service/run_record_race_recommendation_service.dart';
import 'package:runlini/features/run_tracking/state/run_live_metrics_providers.dart';
import 'package:runlini/features/run_tracking/state/run_playback_providers.dart';
import 'package:runlini/features/run_tracking/state/run_session_providers.dart';
import 'package:runlini/features/run_tracking/state/run_settings_providers.dart';
import 'package:runlini/features/run_tracking/types/run_map_view_state.dart';
import 'package:runlini/features/run_tracking/types/run_screen_status.dart';

final recordRaceGapServiceProvider = Provider<RecordRaceGapService>(
  (Ref ref) => const RecordRaceGapService(),
);

final recordRaceCompletionDetectorProvider =
    Provider<RecordRaceCompletionDetector>(
      (Ref ref) => const RecordRaceCompletionDetector(),
    );

final runRecordRaceRecommendationServiceProvider =
    Provider<RunRecordRaceRecommendationService>(
      (Ref ref) => const RunRecordRaceRecommendationService(),
    );

final runRecordRaceRecommendationProvider =
    FutureProvider<RunRecordRaceRecommendation?>((Ref ref) async {
      final settings = ref.watch(recordRaceSettingsProvider);
      if (settings.enabled) {
        return null;
      }

      final summaries = await ref.watch(runSessionSummaryListProvider.future);
      return ref
          .watch(runRecordRaceRecommendationServiceProvider)
          .recommend(
            summaries: summaries,
            now: ref.watch(runPlaybackClockProvider)(),
          );
    });

final recordRaceFrameProvider = Provider<RecordRaceFrame?>((Ref ref) {
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
  final selectedRecordRaceSession = staticState?.selectedRecordRaceSession;
  if (selectedRecordRaceSession == null) {
    return null;
  }

  ref.watch(liveRunMetricsTickerProvider);
  final now = ref.watch(runPlaybackClockProvider)();
  final service = ref.watch(recordRaceGapServiceProvider);
  final runnerDistanceM = ref
      .watch(runRouteSegmenterProvider)
      .segment(playbackInput.recordedPoints)
      .distanceM;
  final startDecision = service.evaluateStart(
    runnerPoints: playbackInput.recordedPoints,
    recordRaceSession: selectedRecordRaceSession,
    runnerDistanceM: runnerDistanceM,
  );
  return service.calculate(
    runnerPoint: playbackInput.recordedPoints.last,
    recordRaceSession: selectedRecordRaceSession,
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

final recordRaceAwareRunMapViewStateProvider = Provider<RunMapViewState>((
  Ref ref,
) {
  final mapViewState = ref.watch(runMapViewStateProvider);

  final recordRaceFrame = ref.watch(recordRaceFrameProvider);
  final showRecordRaceMarker =
      ref.watch(runSettingsControllerProvider).value?.showRecordRaceMarker ??
      false;
  final showActiveRecordRaceMarker =
      ref.watch(
        runPlaybackControllerProvider.select((state) => state.hasActiveSession),
      ) &&
      recordRaceFrame != null;
  final shouldShowRecordRaceMarker =
      showRecordRaceMarker || showActiveRecordRaceMarker;
  return mapViewState.copyWith(
    recordRaceMarkerPoint: shouldShowRecordRaceMarker
        ? recordRaceFrame?.recordRaceMarkerPoint
        : null,
    clearRecordRaceMarkerPoint: !shouldShowRecordRaceMarker,
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
