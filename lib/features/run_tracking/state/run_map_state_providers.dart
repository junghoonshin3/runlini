import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:runlini/app/theme/app_colors.dart';
import 'package:runlini/core/map/map_coordinate.dart';
import 'package:runlini/core/map/map_polyline_segment.dart';
import 'package:runlini/core/map/map_route_endpoint_marker.dart';
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

  final ghostPolylinePoints = selectedGhostSession == null
      ? const <MapCoordinate>[]
      : mapCoordinatesFromRunPoints(selectedGhostSession.points);

  return RunMapStaticState(
    fallbackMapCenter: _fallbackMapCenter(sessions),
    ghostPolylinePoints: ghostPolylinePoints,
    ghostPolylineSegments: selectedGhostSession == null
        ? const []
        : ref
              .read(paceColoredRouteSegmentBuilderProvider)
              .buildGhostSegments(selectedGhostSession),
    ghostRouteEndpointMarkers: mapRouteEndpointMarkersFor(ghostPolylinePoints),
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

final currentRunnerPolylineSegmentsProvider =
    Provider<List<MapPolylineSegment>>((Ref ref) {
      final playbackState = ref.watch(runPlaybackControllerProvider);
      final route = ref
          .watch(runRouteSegmenterProvider)
          .segment(playbackState.recordedPoints);
      return route.segments
          .where((segment) => segment.length >= 2)
          .map(
            (segment) => MapPolylineSegment(
              points: mapCoordinatesFromRunPoints(segment),
              color: AppColors.voltGreen,
            ),
          )
          .toList(growable: false);
    });

final runMapViewStateProvider = Provider<RunMapViewState>((Ref ref) {
  final staticState = ref.watch(runMapStaticStateProvider).value;

  final currentRunnerPolylinePoints = ref.watch(
    currentRunnerPolylinePointsProvider,
  );
  final currentRunnerPolylineSegments = ref.watch(
    currentRunnerPolylineSegmentsProvider,
  );
  final liveLocationPoint = ref.watch(liveLocationProvider)?.toMapCoordinate();
  final ghostPolylinePoints =
      staticState?.ghostPolylinePoints ?? const <MapCoordinate>[];
  final ghostMapCenter = ghostPolylinePoints.isNotEmpty
      ? ghostPolylinePoints.first
      : null;
  final fallbackMapCenter =
      staticState?.fallbackMapCenter ?? _defaultFallbackMapCenter;

  return RunMapViewState(
    mapCenter: liveLocationPoint ?? ghostMapCenter ?? fallbackMapCenter,
    runnerMarkerPoint: liveLocationPoint,
    recenterTargetPoint: liveLocationPoint,
    currentRunnerPolylinePoints: currentRunnerPolylinePoints,
    currentRunnerPolylineSegments: currentRunnerPolylineSegments,
    ghostPolylinePoints: ghostPolylinePoints,
    ghostPolylineSegments: staticState?.ghostPolylineSegments ?? const [],
    ghostRouteEndpointMarkers:
        staticState?.ghostRouteEndpointMarkers ??
        const <MapRouteEndpointMarker>[],
    selectedGhostSession: staticState?.selectedGhostSession,
  );
});
