package kr.sjh.runlini.wear

import org.junit.Assert.assertEquals
import org.junit.Assert.assertTrue
import org.junit.Test

class WearRecordRaceGapCalculatorTest {
    private val calculator = WearRecordRaceGapCalculator()
    private val config = WearRecordRaceConfig(
        id = "record-race-1",
        durationMs = 600_000L,
        distanceM = 1_000.0,
        sourceSummary = "한강 1K",
        points = listOf(
            WearRunPoint(latitude = 37.0, longitude = 127.0, timestampRelMs = 0L),
            WearRunPoint(latitude = 37.0, longitude = 127.01, timestampRelMs = 600_000L),
        ),
    )

    @Test
    fun calculatesAheadWhenRunnerIsFartherAlongRouteThanElapsed() {
        val frame = calculator.calculate(
            runnerPoint = WearRunPoint(
                latitude = 37.0,
                longitude = 127.006,
                timestampRelMs = 240_000L,
            ),
            recordRaceConfig = config,
            runnerElapsedMs = 240_000L,
        )

        assertEquals(WearRecordRaceStatus.Ahead, frame.status)
        assertTrue(frame.routeProgress > 0.55)
        assertTrue(frame.distanceToFinishM > 300.0)
        assertTrue(frame.totalRouteDistanceM > 800.0)
    }

    @Test
    fun calculatesBehindWhenRunnerIsBehindRouteProgress() {
        val frame = calculator.calculate(
            runnerPoint = WearRunPoint(
                latitude = 37.0,
                longitude = 127.002,
                timestampRelMs = 360_000L,
            ),
            recordRaceConfig = config,
            runnerElapsedMs = 360_000L,
        )

        assertEquals(WearRecordRaceStatus.Behind, frame.status)
    }

    @Test
    fun calculatesOffRouteWhenRunnerIsFarFromRecordRacePath() {
        val frame = calculator.calculate(
            runnerPoint = WearRunPoint(
                latitude = 37.01,
                longitude = 127.005,
                timestampRelMs = 300_000L,
            ),
            recordRaceConfig = config,
            runnerElapsedMs = 300_000L,
        )

        assertEquals(WearRecordRaceStatus.OffRoute, frame.status)
        assertTrue(frame.distanceFromRouteM > 35.0)
    }

    @Test
    fun confirmsStartAfterTwoForwardPointsNearRouteStart() {
        val first = calculator.evaluateStart(
            runnerPoints = listOf(
                WearRunPoint(latitude = 37.0, longitude = 127.0, timestampRelMs = 0L),
                WearRunPoint(latitude = 37.0, longitude = 127.0003, timestampRelMs = 10_000L),
            ),
            recordRaceConfig = config,
            alreadyConfirmed = false,
            previousCandidateCount = 0,
            lastEvaluatedPointCount = 0,
        )

        assertEquals(false, first.isConfirmed)
        assertEquals(1, first.candidateCount)

        val second = calculator.evaluateStart(
            runnerPoints = listOf(
                WearRunPoint(latitude = 37.0, longitude = 127.0, timestampRelMs = 0L),
                WearRunPoint(latitude = 37.0, longitude = 127.0003, timestampRelMs = 10_000L),
                WearRunPoint(latitude = 37.0, longitude = 127.0006, timestampRelMs = 20_000L),
            ),
            recordRaceConfig = config,
            alreadyConfirmed = false,
            previousCandidateCount = first.candidateCount,
            lastEvaluatedPointCount = first.lastEvaluatedPointCount,
        )

        assertEquals(true, second.isConfirmed)
        assertEquals(2, second.candidateCount)
    }

    @Test
    fun tracksLoopRouteProgressNearPreviousDistance() {
        val loopConfig = WearRecordRaceConfig(
            id = "loop",
            durationMs = 240_000L,
            distanceM = 444.0,
            sourceSummary = "loop",
            points = listOf(
                WearRunPoint(latitude = 0.0, longitude = 0.0, timestampRelMs = 0L),
                WearRunPoint(latitude = 0.0, longitude = 0.001, timestampRelMs = 60_000L),
                WearRunPoint(latitude = 0.001, longitude = 0.001, timestampRelMs = 120_000L),
                WearRunPoint(latitude = 0.001, longitude = 0.0, timestampRelMs = 180_000L),
                WearRunPoint(latitude = 0.0, longitude = 0.0, timestampRelMs = 240_000L),
            ),
        )

        val frame = calculator.calculate(
            runnerPoint = WearRunPoint(
                latitude = 0.00008,
                longitude = 0.0,
                timestampRelMs = 220_000L,
            ),
            recordRaceConfig = loopConfig,
            runnerElapsedMs = 220_000L,
            startConfirmed = true,
            previousDistanceAlongRouteM = 360.0,
        )

        assertTrue(frame.trackedDistanceAlongRouteM!! > 330.0)
        assertTrue(frame.routeProgress > 0.7)
    }
}
