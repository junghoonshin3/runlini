import 'package:runlini/core/map/map_coordinate.dart';
import 'package:runlini/features/ghost_racer/service/ghost_route_model.dart';
import 'package:runlini/features/ghost_racer/service/run_session_interpolator.dart';
import 'package:runlini/features/ghost_racer/types/ghost_race_frame.dart';
import 'package:runlini/features/ghost_racer/types/ghost_race_projection_source.dart';
import 'package:runlini/features/run_tracking/types/run_point.dart';
import 'package:runlini/features/run_tracking/types/run_session.dart';

class GhostRaceGapService {
  const GhostRaceGapService({
    this.levelThresholdMs = 3000,
    this.levelDistanceThresholdM = 3,
    this.offRouteThresholdM = 35,
    this.startRadiusM = 45,
    this.startRouteWindowM = 250,
    this.startOffRouteThresholdM = 50,
    this.startFallbackDistanceM = 80,
    this.startFallbackMinRouteM = 40,
    this.startFallbackMaxRouteM = 400,
    this.requiredStartCandidates = 2,
    this.projectionBehindWindowM = 50,
    this.projectionAheadWindowM = 250,
  });

  final int levelThresholdMs;
  final double levelDistanceThresholdM;
  final double offRouteThresholdM;
  final double startRadiusM;
  final double startRouteWindowM;
  final double startOffRouteThresholdM;
  final double startFallbackDistanceM;
  final double startFallbackMinRouteM;
  final double startFallbackMaxRouteM;
  final int requiredStartCandidates;
  final double projectionBehindWindowM;
  final double projectionAheadWindowM;

  GhostRaceStartDecision evaluateStart({
    required List<RunPoint> runnerPoints,
    required RunSession ghostSession,
    double? runnerDistanceM,
  }) {
    if (runnerPoints.length < 2 || ghostSession.points.length < 2) {
      return const GhostRaceStartDecision.pending(0, 0);
    }

    final route = GhostRouteModel.from(ghostSession.points);
    if (route.segments.isEmpty) {
      return GhostRaceStartDecision.pending(0, runnerPoints.length);
    }

    var nextCount = 0;
    final anchorIndex = _startAnchorIndex(runnerPoints, ghostSession);
    if (anchorIndex != null) {
      for (
        var index = anchorIndex + 1;
        index < runnerPoints.length;
        index += 1
      ) {
        final previousProjection = route.projectGlobal(runnerPoints[index - 1]);
        final currentProjection = route.projectGlobal(runnerPoints[index]);
        final progressedForward =
            currentProjection.distanceAlongRouteM >
            previousProjection.distanceAlongRouteM + 1;
        final onEarlyRoute =
            currentProjection.distanceAlongRouteM > 0 &&
            currentProjection.distanceAlongRouteM <= startRouteWindowM &&
            currentProjection.distanceFromRouteM <= startOffRouteThresholdM;
        nextCount = progressedForward && onEarlyRoute ? nextCount + 1 : 0;
        if (nextCount >= requiredStartCandidates) {
          return GhostRaceStartDecision.confirmed(
            nextCount,
            runnerPoints.length,
          );
        }
      }
    }

    if (_hasAcceptedDistanceFallback(
      route: route,
      runnerPoint: runnerPoints.last,
      runnerDistanceM: runnerDistanceM,
    )) {
      return GhostRaceStartDecision.confirmed(
        requiredStartCandidates,
        runnerPoints.length,
      );
    }

    return GhostRaceStartDecision.pending(nextCount, runnerPoints.length);
  }

  GhostRaceFrame calculate({
    required RunPoint runnerPoint,
    required RunSession ghostSession,
    required int runnerElapsedMs,
    bool startConfirmed = true,
    int startCandidateCount = 0,
    int startLastEvaluatedPointCount = 0,
    double? runnerDistanceM,
  }) {
    if (ghostSession.points.isEmpty) {
      return const GhostRaceFrame.unavailable();
    }

    final route = GhostRouteModel.from(ghostSession.points);
    final ghostPoint = interpolateRunPoint(
      session: ghostSession,
      elapsedMs: runnerElapsedMs,
    );
    if (route.segments.isEmpty) {
      final distanceGapM = _distanceBetween(runnerPoint, ghostPoint);
      final isLevel = distanceGapM <= levelDistanceThresholdM;
      return GhostRaceFrame(
        status: isLevel ? GhostRaceStatus.level : GhostRaceStatus.offRoute,
        timeGapMs: 0,
        distanceGapM: distanceGapM,
        ghostMarkerPoint: ghostPoint.toMapCoordinate(),
        isOffRoute: distanceGapM >= offRouteThresholdM,
        routeProgress: isLevel ? 1 : 0,
        distanceToFinishM: isLevel ? 0 : distanceGapM,
        distanceFromRouteM: distanceGapM,
        totalRouteDistanceM: 0,
        distanceToFinishPointM: distanceGapM,
        startConfirmed: startConfirmed,
        startCandidateCount: startCandidateCount,
        startLastEvaluatedPointCount: startLastEvaluatedPointCount,
        projectionSource: GhostRaceProjectionSource.global,
      );
    }

    final projection = route.projectTracked(
      runnerPoint: runnerPoint,
      anchorDistanceAlongRouteM: runnerDistanceM,
      behindWindowM: projectionBehindWindowM,
      aheadWindowM: projectionAheadWindowM,
      onRouteThresholdM: offRouteThresholdM,
    );
    final ghostDistanceAtElapsed = route.distanceAtElapsed(runnerElapsedMs);
    final timeGapMs = projection.elapsedMs - runnerElapsedMs;
    final distanceGapM =
        projection.distanceAlongRouteM - ghostDistanceAtElapsed;
    final isOffRoute = projection.distanceFromRouteM >= offRouteThresholdM;

    return GhostRaceFrame(
      status: _statusFor(isOffRoute: isOffRoute, timeGapMs: timeGapMs),
      timeGapMs: timeGapMs,
      distanceGapM: distanceGapM.abs() <= levelDistanceThresholdM
          ? 0
          : distanceGapM,
      ghostMarkerPoint: ghostPoint.toMapCoordinate(),
      isOffRoute: isOffRoute,
      routeProgress: route.progressFor(projection.distanceAlongRouteM),
      distanceToFinishM: route.distanceToFinish(projection.distanceAlongRouteM),
      distanceFromRouteM: projection.distanceFromRouteM,
      totalRouteDistanceM: route.totalDistanceM,
      distanceToFinishPointM: _distanceBetween(
        runnerPoint,
        ghostSession.points.last,
      ),
      startConfirmed: startConfirmed,
      startCandidateCount: startCandidateCount,
      startLastEvaluatedPointCount: startLastEvaluatedPointCount,
      trackedDistanceAlongRouteM: startConfirmed
          ? projection.distanceAlongRouteM
          : runnerDistanceM,
      projectionSource: projection.source,
    );
  }

  GhostRaceStatus _statusFor({
    required bool isOffRoute,
    required int timeGapMs,
  }) {
    if (isOffRoute) {
      return GhostRaceStatus.offRoute;
    }

    if (timeGapMs.abs() <= levelThresholdMs) {
      return GhostRaceStatus.level;
    }

    return timeGapMs > 0 ? GhostRaceStatus.ahead : GhostRaceStatus.behind;
  }

  static double _distanceBetween(RunPoint left, RunPoint right) {
    return GhostRouteModel.distanceBetween(left, right);
  }

  int? _startAnchorIndex(List<RunPoint> points, RunSession ghostSession) {
    final routeStart = ghostSession.points.first;
    for (var index = 0; index < points.length; index += 1) {
      if (_distanceBetween(points[index], routeStart) <= startRadiusM) {
        return index;
      }
    }
    return null;
  }

  bool _hasAcceptedDistanceFallback({
    required GhostRouteModel route,
    required RunPoint runnerPoint,
    required double? runnerDistanceM,
  }) {
    final distance = runnerDistanceM ?? 0;
    if (distance < startFallbackDistanceM) {
      return false;
    }

    final projection = route.projectGlobal(runnerPoint);
    return projection.distanceFromRouteM <= startOffRouteThresholdM &&
        projection.distanceAlongRouteM >= startFallbackMinRouteM &&
        projection.distanceAlongRouteM <= startFallbackMaxRouteM;
  }
}

class GhostRaceStartDecision {
  const GhostRaceStartDecision({
    required this.isConfirmed,
    required this.candidateCount,
    required this.lastEvaluatedPointCount,
  });

  const GhostRaceStartDecision.pending(
    int candidateCount,
    int lastEvaluatedPointCount,
  ) : this(
        isConfirmed: false,
        candidateCount: candidateCount,
        lastEvaluatedPointCount: lastEvaluatedPointCount,
      );

  const GhostRaceStartDecision.confirmed(
    int candidateCount,
    int lastEvaluatedPointCount,
  ) : this(
        isConfirmed: true,
        candidateCount: candidateCount,
        lastEvaluatedPointCount: lastEvaluatedPointCount,
      );

  final bool isConfirmed;
  final int candidateCount;
  final int lastEvaluatedPointCount;
}
