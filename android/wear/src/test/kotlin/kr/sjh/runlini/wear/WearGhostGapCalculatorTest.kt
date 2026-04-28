package kr.sjh.runlini.wear

import org.junit.Assert.assertEquals
import org.junit.Test

class WearGhostGapCalculatorTest {
    private val calculator = WearGhostGapCalculator()
    private val config = WearGhostConfig(
        id = "ghost-1",
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
            ghostConfig = config,
            runnerElapsedMs = 240_000L,
        )

        assertEquals(WearGhostStatus.Ahead, frame.status)
    }

    @Test
    fun calculatesBehindWhenRunnerIsBehindRouteProgress() {
        val frame = calculator.calculate(
            runnerPoint = WearRunPoint(
                latitude = 37.0,
                longitude = 127.002,
                timestampRelMs = 360_000L,
            ),
            ghostConfig = config,
            runnerElapsedMs = 360_000L,
        )

        assertEquals(WearGhostStatus.Behind, frame.status)
    }

    @Test
    fun calculatesOffRouteWhenRunnerIsFarFromGhostPath() {
        val frame = calculator.calculate(
            runnerPoint = WearRunPoint(
                latitude = 37.01,
                longitude = 127.005,
                timestampRelMs = 300_000L,
            ),
            ghostConfig = config,
            runnerElapsedMs = 300_000L,
        )

        assertEquals(WearGhostStatus.OffRoute, frame.status)
    }
}
