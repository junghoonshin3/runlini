import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:runlini/core/map/map_coordinate.dart';
import 'package:runlini/features/ghost_racer/state/ghost_racer_providers.dart';
import 'package:runlini/features/run_tracking/state/live_location_providers.dart';
import 'package:runlini/features/run_tracking/state/run_playback_controller_providers.dart';
import 'package:runlini/features/run_tracking/state/run_playback_core_providers.dart';
import 'package:runlini/features/run_tracking/state/run_session_providers.dart';
import 'package:runlini/features/run_tracking/types/run_map_static_state.dart';
import 'package:runlini/features/run_tracking/types/run_map_view_state.dart';
import 'package:runlini/features/run_tracking/types/run_session.dart';

const _defaultFallbackMapCenter = MapCoordinate(
  latitude: 37.5665,
  longitude: 126.9780,
);

class RunMapRecenterTickController extends Notifier<int> {
  @override
  int build() => 0;

  void trigger() {
    state = state + 1;
  }
}

final runMapRecenterTickProvider =
    NotifierProvider<RunMapRecenterTickController, int>(
      RunMapRecenterTickController.new,
    );

final runMapStaticStateProvider = FutureProvider<RunMapStaticState>((
  Ref ref,
) async {
  final sessions = await ref.watch(runSessionListProvider.future);
  final ghostSettings = ref.watch(ghostSettingsProvider);
  RunSession? selectedGhostSession;
  if (ghostSettings.enabled && ghostSettings.selectedSessionId != null) {
    for (final session in sessions) {
      if (session.id == ghostSettings.selectedSessionId) {
        selectedGhostSession = session;
        break;
      }
    }
  }

  return RunMapStaticState(
    fallbackMapCenter: _fallbackMapCenter(sessions),
    ghostPolylinePoints: selectedGhostSession == null
        ? const <MapCoordinate>[]
        : mapCoordinatesFromRunPoints(selectedGhostSession.points),
    ghostPolylineSegments: selectedGhostSession == null
        ? const []
        : ref
              .read(paceColoredRouteSegmentBuilderProvider)
              .buildGhostSegments(selectedGhostSession),
    selectedGhostSession: selectedGhostSession,
  );
});

MapCoordinate _fallbackMapCenter(List<RunSession> sessions) {
  for (final session in sessions) {
    if (session.points.isNotEmpty) {
      return session.points.first.toMapCoordinate();
    }
  }
  return _defaultFallbackMapCenter;
}

final currentRunnerPolylinePointsProvider = Provider<List<MapCoordinate>>((
  Ref ref,
) {
  final playbackState = ref.watch(runPlaybackControllerProvider);
  if (playbackState.recordedPoints.isEmpty) {
    return const <MapCoordinate>[];
  }

  return mapCoordinatesFromRunPoints(playbackState.recordedPoints);
});

final runMapViewStateProvider = Provider<RunMapViewState?>((Ref ref) {
  final staticState = ref.watch(runMapStaticStateProvider).value;
  if (staticState == null) {
    return null;
  }

  final currentRunnerPolylinePoints = ref.watch(
    currentRunnerPolylinePointsProvider,
  );
  final liveLocationPoint = ref.watch(liveLocationProvider)?.toMapCoordinate();
  final ghostMapCenter = staticState.ghostPolylinePoints.isNotEmpty
      ? staticState.ghostPolylinePoints.first
      : null;

  return RunMapViewState(
    mapCenter:
        liveLocationPoint ?? ghostMapCenter ?? staticState.fallbackMapCenter,
    runnerMarkerPoint: liveLocationPoint,
    recenterTargetPoint: liveLocationPoint,
    currentRunnerPolylinePoints: currentRunnerPolylinePoints,
    ghostPolylinePoints: staticState.ghostPolylinePoints,
    ghostPolylineSegments: staticState.ghostPolylineSegments,
    selectedGhostSession: staticState.selectedGhostSession,
  );
});
