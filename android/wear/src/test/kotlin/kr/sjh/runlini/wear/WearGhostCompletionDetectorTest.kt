package kr.sjh.runlini.wear

import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertTrue
import org.junit.Test

class WearGhostCompletionDetectorTest {
    private val detector = WearGhostCompletionDetector()

    @Test
    fun requiresTwoConsecutiveFinishCandidates() {
        val first = detector.evaluate(
            frame = frame(routeProgress = 0.99, distanceToFinishM = 12.0),
            runnerDistanceM = 950.0,
            previousCandidateCount = 0,
        )
        assertTrue(first.isCandidate)
        assertFalse(first.isComplete)

        val second = detector.evaluate(
            frame = frame(routeProgress = 0.99, distanceToFinishM = 10.0),
            runnerDistanceM = 980.0,
            previousCandidateCount = first.candidateCount,
        )
        assertTrue(second.isComplete)
    }

    @Test
    fun resetsCandidateCountWhenOffRoute() {
        val decision = detector.evaluate(
            frame = frame(
                status = WearGhostStatus.OffRoute,
                distanceFromRouteM = 40.0,
                routeProgress = 0.99,
                distanceToFinishM = 8.0,
            ),
            runnerDistanceM = 980.0,
            previousCandidateCount = 1,
        )

        assertFalse(decision.isCandidate)
        assertEquals(0, decision.candidateCount)
    }

    @Test
    fun blocksLoopFalseFinishBeforeEnoughDistance() {
        val decision = detector.evaluate(
            frame = frame(
                routeProgress = 0.99,
                distanceToFinishM = 8.0,
                distanceToFinishPointM = 5.0,
            ),
            runnerDistanceM = 300.0,
            previousCandidateCount = 1,
        )

        assertFalse(decision.isCandidate)
    }

    @Test
    fun acceptsLastPointRadiusNearFinishWindow() {
        val decision = detector.evaluate(
            frame = frame(
                routeProgress = 0.94,
                distanceToFinishM = 90.0,
                distanceToFinishPointM = 12.0,
            ),
            runnerDistanceM = 950.0,
            previousCandidateCount = 1,
        )

        assertTrue(decision.isComplete)
    }

    private fun frame(
        status: WearGhostStatus = WearGhostStatus.Ahead,
        routeProgress: Double = 0.5,
        distanceToFinishM: Double = 500.0,
        distanceFromRouteM: Double = 5.0,
        totalRouteDistanceM: Double = 1_000.0,
        distanceToFinishPointM: Double = 500.0,
    ): WearGhostFrame {
        return WearGhostFrame(
            status = status,
            timeGapMs = 10_000L,
            distanceGapM = 30.0,
            routeProgress = routeProgress,
            distanceToFinishM = distanceToFinishM,
            distanceFromRouteM = distanceFromRouteM,
            totalRouteDistanceM = totalRouteDistanceM,
            distanceToFinishPointM = distanceToFinishPointM,
        )
    }
}
