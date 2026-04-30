package kr.sjh.runlini.wear

import org.junit.Assert.assertEquals
import org.junit.Test

class WearRunStateReducerTest {
    @Test
    fun countdownStateIsNotActiveOrSaveable() {
        val state = WearRunStateReducer().countdown(
            WearRunState(),
            remainingSeconds = 3,
        )

        assertEquals(WearRunPhase.CountingDown, state.phase)
        assertEquals(3, state.countdownRemainingSeconds)
        assertEquals(false, state.isActive)
        assertEquals(false, state.canSave)
    }

    @Test
    fun startClearsCountdownFields() {
        val reducer = WearRunStateReducer()
        val countdown = reducer.countdown(
            WearRunState(),
            remainingSeconds = 2,
            ghostConfig = ghostConfig(),
        )

        val state = reducer.start(
            countdown,
            epochMs = 1_000L,
            realtimeMs = 10L,
            ghostConfig = countdown.countdownStartGhostConfig,
        )

        assertEquals(WearRunPhase.Running, state.phase)
        assertEquals(null, state.countdownRemainingSeconds)
        assertEquals(null, state.countdownStartGhostConfig)
        assertEquals(true, state.isGhostRun)
    }

    @Test
    fun applyMetricsMapsSensorUpdatesIntoUiState() {
        val reducer = WearRunStateReducer()
        val started = reducer.start(WearRunState(), epochMs = 1_000L, realtimeMs = 10L)
        val state = reducer.applyMetrics(
            started,
            WearMetricSample(
                activeDurationMs = 62_000L,
                distanceM = 250.0,
                paceSecPerKm = 248.0,
                speedMps = 4.03,
                cadenceSpm = 172.0,
                heartRateBpm = 142,
                caloriesKcal = 18.4,
                points = listOf(
                    WearRunPoint(
                        latitude = 37.5665,
                        longitude = 126.9780,
                        timestampRelMs = 62_000L,
                        paceSecPerKm = 248.0,
                        speedMps = 4.03,
                        horizontalAccuracyM = 6.0,
                        elevationM = 12.0,
                        heartRateBpm = 142,
                    ),
                ),
            ),
            realtimeMs = 62_010L,
        )

        assertEquals(WearRunPhase.Running, state.phase)
        assertEquals(62_000L, state.elapsedMs)
        assertEquals(250.0, state.distanceM, 0.01)
        assertEquals(248.0, state.averagePaceSecPerKm ?: 0.0, 0.01)
        assertEquals(248.0, state.currentPaceSecPerKm ?: 0.0, 0.01)
        assertEquals(4.03, state.speedMps ?: 0.0, 0.01)
        assertEquals(172.0, state.cadenceSpm ?: 0.0, 0.01)
        assertEquals(172.0, state.averageCadenceSpm ?: 0.0, 0.01)
        assertEquals(142, state.heartRateBpm)
        assertEquals(18.4, state.caloriesKcal ?: 0.0, 0.01)
        assertEquals(1, state.points.size)
        assertEquals(37.5665, state.points.first().latitude, 0.0001)
    }

    @Test
    fun applyMetricsAveragesCadenceAndKeepsValueWhenMissing() {
        val reducer = WearRunStateReducer()
        val started = reducer.start(WearRunState(), epochMs = 1_000L, realtimeMs = 10L)
        val first = reducer.applyMetrics(
            started,
            WearMetricSample(cadenceSpm = 170.0),
            realtimeMs = 1_010L,
        )
        val second = reducer.applyMetrics(
            first,
            WearMetricSample(cadenceSpm = 174.0),
            realtimeMs = 2_010L,
        )
        val missing = reducer.applyMetrics(
            second,
            WearMetricSample(),
            realtimeMs = 3_010L,
        )

        assertEquals(174.0, missing.cadenceSpm ?: 0.0, 0.01)
        assertEquals(172.0, missing.averageCadenceSpm ?: 0.0, 0.01)
        assertEquals(2, missing.cadenceSampleCount)
    }

    @Test
    fun readyStateExposesPendingDraftCount() {
        val state = WearRunStateReducer().ready(
            pendingDraftCount = 2,
        )

        assertEquals(WearRunPhase.Ready, state.phase)
        assertEquals(2, state.pendingDraftCount)
        assertEquals(null, state.statusMessage)
    }

    @Test
    fun savedFeedbackStateIsNotActiveOrSaveable() {
        val state = WearRunStateReducer().feedback(
            type = WearRunFeedbackType.Saved,
            pendingDraftCount = 2,
        )

        assertEquals(WearRunPhase.Feedback, state.phase)
        assertEquals(WearRunFeedbackType.Saved, state.feedbackType)
        assertEquals(2, state.pendingDraftCount)
        assertEquals(false, state.isActive)
        assertEquals(false, state.canSave)
    }

    @Test
    fun discardedFeedbackStateIsNotActiveOrSaveable() {
        val state = WearRunStateReducer().feedback(
            type = WearRunFeedbackType.Discarded,
        )

        assertEquals(WearRunPhase.Feedback, state.phase)
        assertEquals(WearRunFeedbackType.Discarded, state.feedbackType)
        assertEquals(false, state.isActive)
        assertEquals(false, state.canSave)
    }

    @Test
    fun startCanAttachGhostConfigForGhostRun() {
        val ghostConfig = ghostConfig()

        val state = WearRunStateReducer().start(
            WearRunState(),
            epochMs = 1_000L,
            realtimeMs = 10L,
            ghostConfig = ghostConfig,
        )

        assertEquals(true, state.isGhostRun)
        assertEquals("ghost-1", state.ghostConfig?.id)
    }

    private fun ghostConfig(): WearGhostConfig {
        return WearGhostConfig(
            id = "ghost-1",
            durationMs = 600_000L,
            distanceM = 1_000.0,
            sourceSummary = "한강 1K",
            points = listOf(
                WearRunPoint(37.0, 127.0, 0L),
                WearRunPoint(37.0, 127.01, 600_000L),
            ),
        )
    }

    @Test
    fun staleHealthServicesElapsedDoesNotFreezeLocalTimer() {
        val reducer = WearRunStateReducer()
        val started = reducer.start(WearRunState(), epochMs = 1_000L, realtimeMs = 10L)
        val ticked = reducer.tick(started, realtimeMs = 5_010L)

        val state = reducer.applyMetrics(
            ticked,
            WearMetricSample(activeDurationMs = 0L),
            realtimeMs = 6_010L,
        )

        assertEquals(6_000L, state.elapsedMs)
        assertEquals(6_000L, state.elapsedBeforeActiveSegmentMs)
    }
}
