import 'package:runlini/core/map/map_coordinate.dart';

enum GhostRaceStatus { ahead, behind, level, offRoute, unavailable }

class GhostRaceFrame {
  const GhostRaceFrame({
    required this.status,
    required this.timeGapMs,
    required this.distanceGapM,
    required this.ghostMarkerPoint,
    required this.isOffRoute,
  });

  const GhostRaceFrame.unavailable()
    : this(
        status: GhostRaceStatus.unavailable,
        timeGapMs: 0,
        distanceGapM: 0,
        ghostMarkerPoint: null,
        isOffRoute: false,
      );

  final GhostRaceStatus status;
  final int timeGapMs;
  final double distanceGapM;
  final MapCoordinate? ghostMarkerPoint;
  final bool isOffRoute;
}
