import 'package:runlini/core/map/map_coordinate.dart';

enum GhostRaceStatus { ahead, behind, level, offRoute, unavailable }

class GhostRaceFrame {
  const GhostRaceFrame({
    required this.status,
    required this.timeGapMs,
    required this.distanceGapM,
    required this.ghostMarkerPoint,
    required this.isOffRoute,
    required this.routeProgress,
    required this.distanceToFinishM,
    required this.distanceFromRouteM,
    required this.totalRouteDistanceM,
    required this.distanceToFinishPointM,
  });

  const GhostRaceFrame.unavailable()
    : this(
        status: GhostRaceStatus.unavailable,
        timeGapMs: 0,
        distanceGapM: 0,
        ghostMarkerPoint: null,
        isOffRoute: false,
        routeProgress: 0,
        distanceToFinishM: double.infinity,
        distanceFromRouteM: double.infinity,
        totalRouteDistanceM: 0,
        distanceToFinishPointM: double.infinity,
      );

  final GhostRaceStatus status;
  final int timeGapMs;
  final double distanceGapM;
  final MapCoordinate? ghostMarkerPoint;
  final bool isOffRoute;
  final double routeProgress;
  final double distanceToFinishM;
  final double distanceFromRouteM;
  final double totalRouteDistanceM;
  final double distanceToFinishPointM;
}
