package kr.sjh.runlini.wear

import org.junit.Assert.assertEquals
import org.junit.Test

class WearAutoPauseDetectorTest {
    @Test
    fun pausesAfterStationaryWindow() {
        val detector = WearAutoPauseDetector()
        val state = runningState()

        detector.onSample(state, sample(point(0L, 37.0, speed = 0.0)))
        detector.onSample(state, sample(point(4_000L, 37.00002, speed = 0.0)))
        val decision = detector.onSample(
            state,
            sample(point(8_000L, 37.00004, speed = 0.0)),
        )

        assertEquals(WearAutoPauseDecision.Pause, decision)
    }

    @Test
    fun resumesAfterStableMovementFromAutoPause() {
        val detector = WearAutoPauseDetector()
        val state = runningState().copy(
            phase = WearRunPhase.Paused,
            pauseReason = WearPauseReason.Auto,
        )

        detector.onSample(state, sample(point(12_000L, 37.0003, speed = 1.4)))
        val decision = detector.onSample(
            state,
            sample(point(16_000L, 37.0005, speed = 1.4)),
        )

        assertEquals(WearAutoPauseDecision.Resume, decision)
    }

    @Test
    fun cadenceKnownBlocksGpsOnlyResume() {
        val detector = WearAutoPauseDetector()
        val state = runningState().copy(
            phase = WearRunPhase.Paused,
            pauseReason = WearPauseReason.Auto,
        )

        detector.onSample(state, sample(point(10_000L, 37.0001, speed = 0.0), cadenceSpm = 0.0))
        detector.onSample(state, sample(point(12_000L, 37.0003, speed = 1.4), cadenceSpm = 0.0))
        val decision = detector.onSample(
            state,
            sample(point(16_000L, 37.0005, speed = 1.4), cadenceSpm = 0.0),
        )

        assertEquals(WearAutoPauseDecision.None, decision)
    }

    @Test
    fun cadenceEvidenceAllowsResume() {
        val detector = WearAutoPauseDetector()
        val state = runningState().copy(
            phase = WearRunPhase.Paused,
            pauseReason = WearPauseReason.Auto,
        )

        detector.onSample(state, sample(point(12_000L, 37.0003, speed = 1.4), cadenceSpm = 120.0))
        val decision = detector.onSample(
            state,
            sample(point(16_000L, 37.0005, speed = 1.4), cadenceSpm = 120.0),
        )

        assertEquals(WearAutoPauseDecision.Resume, decision)
    }

    @Test
    fun doesNotResumeManualPause() {
        val detector = WearAutoPauseDetector()
        val state = runningState().copy(
            phase = WearRunPhase.Paused,
            pauseReason = WearPauseReason.Manual,
        )

        detector.onSample(state, sample(point(12_000L, 37.0003, speed = 1.4)))
        val decision = detector.onSample(
            state,
            sample(point(16_000L, 37.0005, speed = 1.4)),
        )

        assertEquals(WearAutoPauseDecision.None, decision)
    }

    @Test
    fun filtersStationaryDriftFromMetricSample() {
        val detector = WearAutoPauseDetector()
        val state = runningState()
        val filtered = detector.filterStationaryDrift(
            state,
            sample(point(2_000L, 37.00002, speed = 0.0), distanceM = 20.0),
        )

        assertEquals(null, filtered.distanceM)
        assertEquals(emptyList<WearRunPoint>(), filtered.points)
    }

    private fun runningState(): WearRunState {
        return WearRunState(
            phase = WearRunPhase.Running,
            settings = WearRunSettings(autoPauseEnabled = true),
            points = listOf(point(0L, 37.0, speed = 0.0)),
        )
    }

    private fun sample(
        point: WearRunPoint,
        distanceM: Double = 0.0,
        cadenceSpm: Double? = null,
    ): WearMetricSample {
        return WearMetricSample(
            distanceM = distanceM,
            cadenceSpm = cadenceSpm,
            points = listOf(point),
        )
    }

    private fun point(
        timestampMs: Long,
        latitude: Double,
        speed: Double?,
    ): WearRunPoint {
        return WearRunPoint(
            latitude = latitude,
            longitude = 127.0,
            timestampRelMs = timestampMs,
            speedMps = speed,
            horizontalAccuracyM = 8.0,
        )
    }
}
