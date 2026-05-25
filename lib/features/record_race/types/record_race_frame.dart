import 'package:runlini/core/map/map_coordinate.dart';
import 'package:runlini/features/record_race/types/record_race_projection_source.dart';

enum RecordRaceStatus { ahead, behind, level, offRoute, unavailable }

class RecordRaceFrame {
  const RecordRaceFrame({
    required this.status,
    required this.timeGapMs,
    required this.distanceGapM,
    required this.recordRaceMarkerPoint,
    required this.isOffRoute,
    required this.routeProgress,
    required this.distanceToFinishM,
    required this.distanceFromRouteM,
    required this.totalRouteDistanceM,
    required this.distanceToFinishPointM,
    this.startConfirmed = true,
    this.startCandidateCount = 0,
    this.startLastEvaluatedPointCount = 0,
    this.trackedDistanceAlongRouteM,
    this.projectionSource = RecordRaceProjectionSource.global,
  });

  const RecordRaceFrame.unavailable()
    : this(
        status: RecordRaceStatus.unavailable,
        timeGapMs: 0,
        distanceGapM: 0,
        recordRaceMarkerPoint: null,
        isOffRoute: false,
        routeProgress: 0,
        distanceToFinishM: double.infinity,
        distanceFromRouteM: double.infinity,
        totalRouteDistanceM: 0,
        distanceToFinishPointM: double.infinity,
        startConfirmed: false,
        startCandidateCount: 0,
        startLastEvaluatedPointCount: 0,
        trackedDistanceAlongRouteM: null,
        projectionSource: RecordRaceProjectionSource.held,
      );

  final RecordRaceStatus status;
  final int timeGapMs;
  final double distanceGapM;
  final MapCoordinate? recordRaceMarkerPoint;
  final bool isOffRoute;
  final double routeProgress;
  final double distanceToFinishM;
  final double distanceFromRouteM;
  final double totalRouteDistanceM;
  final double distanceToFinishPointM;
  final bool startConfirmed;
  final int startCandidateCount;
  final int startLastEvaluatedPointCount;
  final double? trackedDistanceAlongRouteM;
  final RecordRaceProjectionSource projectionSource;
}
