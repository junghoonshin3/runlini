package kr.sjh.runlini.wear

import org.junit.Assert.assertEquals
import org.junit.Test

class WearRunStateReducerTest {
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
        assertEquals(142, state.heartRateBpm)
        assertEquals(18.4, state.caloriesKcal ?: 0.0, 0.01)
        assertEquals(1, state.points.size)
        assertEquals(37.5665, state.points.first().latitude, 0.0001)
    }

    @Test
    fun readyStateExposesPendingDraftCount() {
        val state = WearRunStateReducer().ready(
            message = "다시 전송함 · 폰 확인 대기",
            pendingDraftCount = 2,
        )

        assertEquals(WearRunPhase.Ready, state.phase)
        assertEquals(2, state.pendingDraftCount)
        assertEquals("다시 전송함 · 폰 확인 대기", state.statusMessage)
    }

    @Test
    fun startCanAttachGhostConfigForGhostRun() {
        val ghostConfig = WearGhostConfig(
            id = "ghost-1",
            durationMs = 600_000L,
            distanceM = 1_000.0,
            sourceSummary = "한강 1K",
            points = listOf(
                WearRunPoint(37.0, 127.0, 0L),
                WearRunPoint(37.0, 127.01, 600_000L),
            ),
        )

        val state = WearRunStateReducer().start(
            WearRunState(),
            epochMs = 1_000L,
            realtimeMs = 10L,
            ghostConfig = ghostConfig,
        )

        assertEquals(true, state.isGhostRun)
        assertEquals("ghost-1", state.ghostConfig?.id)
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
