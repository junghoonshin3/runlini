import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:runlini/features/ghost_racer/service/ghost_race_gap_service.dart';
import 'package:runlini/features/ghost_racer/types/ghost_race_frame.dart';
import 'package:runlini/features/run_tracking/state/run_live_metrics_providers.dart';
import 'package:runlini/features/run_tracking/state/run_playback_providers.dart';
import 'package:runlini/features/run_tracking/state/run_settings_providers.dart';
import 'package:runlini/features/run_tracking/types/run_map_view_state.dart';

final ghostRaceGapServiceProvider = Provider<GhostRaceGapService>(
  (Ref ref) => const GhostRaceGapService(),
);

final ghostRaceFrameProvider = Provider<GhostRaceFrame?>((Ref ref) {
  final playbackState = ref.watch(runPlaybackControllerProvider);
  if (!playbackState.hasActiveSession || playbackState.recordedPoints.isEmpty) {
    return null;
  }

  final staticState = ref.watch(runMapStaticStateProvider).value;
  final selectedGhostSession = staticState?.selectedGhostSession;
  if (selectedGhostSession == null) {
    return null;
  }

  ref.watch(liveRunMetricsTickerProvider);
  final now = ref.watch(runPlaybackClockProvider)();
  return ref
      .watch(ghostRaceGapServiceProvider)
      .calculate(
        runnerPoint: playbackState.recordedPoints.last,
        ghostSession: selectedGhostSession,
        runnerElapsedMs: playbackState.elapsedAt(now),
      );
});

final ghostAwareRunMapViewStateProvider = Provider<RunMapViewState>((Ref ref) {
  final mapViewState = ref.watch(runMapViewStateProvider);

  final ghostRaceFrame = ref.watch(ghostRaceFrameProvider);
  final showGhostMarker =
      ref.watch(runSettingsControllerProvider).value?.showGhostMarker ?? false;
  return mapViewState.copyWith(
    ghostMarkerPoint: showGhostMarker ? ghostRaceFrame?.ghostMarkerPoint : null,
    clearGhostMarkerPoint: !showGhostMarker,
  );
});
