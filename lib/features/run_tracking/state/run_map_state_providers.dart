import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:runlini/app/theme/app_colors.dart';
import 'package:runlini/core/map/map_coordinate.dart';
import 'package:runlini/core/map/map_polyline_segment.dart';
import 'package:runlini/core/map/map_route_endpoint_marker.dart';
import 'package:runlini/features/record_race/state/record_race_providers.dart';
import 'package:runlini/features/run_tracking/service/run_route_segmenter.dart';
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
  final recordRaceSettings = ref.watch(recordRaceSettingsProvider);
  RunSession? selectedRecordRaceSession;
  if (recordRaceSettings.enabled &&
      recordRaceSettings.selectedSessionId != null) {
    for (final session in sessions) {
      if (session.id == recordRaceSettings.selectedSessionId) {
        selectedRecordRaceSession = session;
        break;
      }
    }
  }

  final recordRacePolylinePoints = selectedRecordRaceSession == null
      ? const <MapCoordinate>[]
      : mapCoordinatesFromRunPoints(selectedRecordRaceSession.points);

  return RunMapStaticState(
    fallbackMapCenter: _fallbackMapCenter(sessions),
    recordRacePolylinePoints: recordRacePolylinePoints,
    recordRacePolylineSegments: selectedRecordRaceSession == null
        ? const []
        : ref
              .read(paceColoredRouteSegmentBuilderProvider)
              .buildRecordRaceSegments(selectedRecordRaceSession),
    recordRaceRouteEndpointMarkers: mapRouteEndpointMarkersFor(
      recordRacePolylinePoints,
    ),
    selectedRecordRaceSession: selectedRecordRaceSession,
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

  final route = ref
      .watch(runRouteSegmenterProvider)
      .segment(playbackState.recordedPoints);
  return _singleSegmentFallbackPoints(route);
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

List<MapCoordinate> _singleSegmentFallbackPoints(RunRouteSegments route) {
  if (route.segments.length != 1 || route.segments.single.length < 2) {
    return const <MapCoordinate>[];
  }
  return mapCoordinatesFromRunPoints(route.segments.single);
}

final runMapViewStateProvider = Provider<RunMapViewState>((Ref ref) {
  final staticState = ref.watch(runMapStaticStateProvider).value;

  final currentRunnerPolylinePoints = ref.watch(
    currentRunnerPolylinePointsProvider,
  );
  final currentRunnerPolylineSegments = ref.watch(
    currentRunnerPolylineSegmentsProvider,
  );
  final liveLocationPoint = ref.watch(liveLocationProvider)?.toMapCoordinate();
  final recordRacePolylinePoints =
      staticState?.recordRacePolylinePoints ?? const <MapCoordinate>[];
  final recordRaceMapCenter = recordRacePolylinePoints.isNotEmpty
      ? recordRacePolylinePoints.first
      : null;
  final fallbackMapCenter =
      staticState?.fallbackMapCenter ?? _defaultFallbackMapCenter;

  return RunMapViewState(
    mapCenter: liveLocationPoint ?? recordRaceMapCenter ?? fallbackMapCenter,
    runnerMarkerPoint: liveLocationPoint,
    recenterTargetPoint: liveLocationPoint,
    currentRunnerPolylinePoints: currentRunnerPolylinePoints,
    currentRunnerPolylineSegments: currentRunnerPolylineSegments,
    recordRacePolylinePoints: recordRacePolylinePoints,
    recordRacePolylineSegments:
        staticState?.recordRacePolylineSegments ?? const [],
    recordRaceRouteEndpointMarkers:
        staticState?.recordRaceRouteEndpointMarkers ??
        const <MapRouteEndpointMarker>[],
    selectedRecordRaceSession: staticState?.selectedRecordRaceSession,
  );
});
