import 'dart:math' as math;

import 'package:runlini/features/ghost_racer/types/ghost_race_frame.dart';

class GhostRaceCompletionDetector {
  const GhostRaceCompletionDetector({
    this.finishProgressThreshold = 0.98,
    this.offRouteThresholdM = 35,
    this.finishPointRadiusM = 25,
    this.finishProjectionWindowM = 100,
    this.minimumRunnerDistanceRatio = 0.9,
    this.requiredConsecutiveCandidates = 2,
  });

  final double finishProgressThreshold;
  final double offRouteThresholdM;
  final double finishPointRadiusM;
  final double finishProjectionWindowM;
  final double minimumRunnerDistanceRatio;
  final int requiredConsecutiveCandidates;

  GhostRaceCompletionDecision evaluate({
    required GhostRaceFrame frame,
    required double runnerDistanceM,
    required int previousCandidateCount,
  }) {
    final candidate = isCandidate(
      frame: frame,
      runnerDistanceM: runnerDistanceM,
    );
    final candidateCount = candidate ? previousCandidateCount + 1 : 0;
    return GhostRaceCompletionDecision(
      isCandidate: candidate,
      candidateCount: candidateCount,
      isComplete: candidateCount >= requiredConsecutiveCandidates,
    );
  }

  bool isCandidate({
    required GhostRaceFrame frame,
    required double runnerDistanceM,
  }) {
    final totalDistance = frame.totalRouteDistanceM;
    if (!frame.startConfirmed ||
        frame.status == GhostRaceStatus.unavailable ||
        frame.isOffRoute ||
        !totalDistance.isFinite ||
        totalDistance <= 0) {
      return false;
    }
    if (runnerDistanceM < totalDistance * minimumRunnerDistanceRatio) {
      return false;
    }
    if (frame.distanceFromRouteM > offRouteThresholdM) {
      return false;
    }

    final tolerance = finishDistanceTolerance(totalDistance);
    final progressCandidate =
        frame.routeProgress >= finishProgressThreshold &&
        frame.distanceToFinishM <= tolerance;
    final finishPointCandidate =
        frame.distanceToFinishPointM <= finishPointRadiusM &&
        frame.distanceToFinishM <= finishProjectionWindowM;
    return progressCandidate || finishPointCandidate;
  }

  double finishDistanceTolerance(double totalRouteDistanceM) {
    return math.max(25.0, math.min(60.0, totalRouteDistanceM * 0.005));
  }
}

class GhostRaceCompletionDecision {
  const GhostRaceCompletionDecision({
    required this.isCandidate,
    required this.candidateCount,
    required this.isComplete,
  });

  final bool isCandidate;
  final int candidateCount;
  final bool isComplete;
}
