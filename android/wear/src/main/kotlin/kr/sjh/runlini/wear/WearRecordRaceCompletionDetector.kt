package kr.sjh.runlini.wear

import kotlin.math.max
import kotlin.math.min

class WearRecordRaceCompletionDetector(
    private val finishProgressThreshold: Double = 0.98,
    private val offRouteThresholdM: Double = 35.0,
    private val finishPointRadiusM: Double = 25.0,
    private val finishProjectionWindowM: Double = 100.0,
    private val minimumRunnerDistanceRatio: Double = 0.9,
    private val requiredConsecutiveCandidates: Int = 2,
) {
    fun evaluate(
        frame: WearRecordRaceFrame,
        runnerDistanceM: Double,
        previousCandidateCount: Int,
    ): WearRecordRaceCompletionDecision {
        val candidate = isCandidate(frame, runnerDistanceM)
        val count = if (candidate) previousCandidateCount + 1 else 0
        return WearRecordRaceCompletionDecision(
            isCandidate = candidate,
            candidateCount = count,
            isComplete = count >= requiredConsecutiveCandidates,
        )
    }

    fun isCandidate(frame: WearRecordRaceFrame, runnerDistanceM: Double): Boolean {
        val totalDistance = frame.totalRouteDistanceM
        if (
            !frame.startConfirmed ||
            frame.status == WearRecordRaceStatus.Unavailable ||
            totalDistance <= 0.0 ||
            !totalDistance.isFinite()
        ) {
            return false
        }
        if (runnerDistanceM < totalDistance * minimumRunnerDistanceRatio) {
            return false
        }

        val tolerance = finishDistanceTolerance(totalDistance)
        val progressCandidate =
            frame.routeProgress >= finishProgressThreshold &&
                frame.distanceToFinishM <= tolerance
        val finishPointCandidate =
            frame.distanceToFinishPointM <= finishPointRadiusM &&
                frame.distanceToFinishM <= finishProjectionWindowM
        val isOffRoute =
            frame.status == WearRecordRaceStatus.OffRoute ||
                frame.distanceFromRouteM > offRouteThresholdM
        val offRouteFinishCandidate =
            finishPointCandidate ||
                (progressCandidate && frame.distanceToFinishPointM <= finishProjectionWindowM)
        if (isOffRoute && !offRouteFinishCandidate) {
            return false
        }
        return progressCandidate || finishPointCandidate
    }

    fun finishDistanceTolerance(totalRouteDistanceM: Double): Double {
        return max(25.0, min(60.0, totalRouteDistanceM * 0.005))
    }
}

data class WearRecordRaceCompletionDecision(
    val isCandidate: Boolean,
    val candidateCount: Int,
    val isComplete: Boolean,
)
