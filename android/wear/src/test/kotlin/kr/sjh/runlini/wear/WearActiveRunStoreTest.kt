package kr.sjh.runlini.wear

import org.junit.Assert.assertEquals
import org.junit.Assert.assertNull
import org.junit.Assert.assertTrue
import org.junit.Test

class WearActiveRunStoreTest {
    @Test
    fun storeSavesAndRestoresRunningCheckpointWithElapsedAdvance() {
        val persistence = FakeActiveRunPersistence()
        val store = WearActiveRunStore(persistence)

        store.save(
            state = runningState(
                elapsedMs = 60_000L,
                phase = WearRunPhase.Running,
            ),
            checkpointRealtimeMs = 10_000L,
        )

        val restored = store.restore(
            nowRealtimeMs = 13_500L,
            pendingDraftCount = 2,
            fallbackGhostConfig = null,
        )

        assertEquals(WearRunPhase.Running, restored?.phase)
        assertEquals(63_500L, restored?.elapsedMs)
        assertEquals(63_500L, restored?.elapsedBeforeActiveSegmentMs)
        assertEquals(13_500L, restored?.activeSegmentStartedRealtimeMs)
        assertEquals(2, restored?.pendingDraftCount)
    }

    @Test
    fun storeRestoresPausedCheckpointWithoutElapsedAdvance() {
        val persistence = FakeActiveRunPersistence()
        val store = WearActiveRunStore(persistence)

        store.save(
            state = runningState(
                elapsedMs = 60_000L,
                phase = WearRunPhase.Paused,
            ),
            checkpointRealtimeMs = 10_000L,
        )

        val restored = store.restore(
            nowRealtimeMs = 13_500L,
            pendingDraftCount = 0,
            fallbackGhostConfig = null,
        )

        assertEquals(WearRunPhase.Paused, restored?.phase)
        assertEquals(60_000L, restored?.elapsedMs)
        assertNull(restored?.activeSegmentStartedRealtimeMs)
    }

    @Test
    fun storeRestoresReviewCheckpointWithoutElapsedAdvance() {
        val persistence = FakeActiveRunPersistence()
        val store = WearActiveRunStore(persistence)

        store.save(
            state = runningState(
                elapsedMs = 60_000L,
                phase = WearRunPhase.Reviewing,
            ),
            checkpointRealtimeMs = 10_000L,
        )

        val restored = store.restore(
            nowRealtimeMs = 20_000L,
            pendingDraftCount = 0,
            fallbackGhostConfig = null,
        )

        assertEquals(WearRunPhase.Reviewing, restored?.phase)
        assertEquals(60_000L, restored?.elapsedMs)
        assertNull(restored?.activeSegmentStartedRealtimeMs)
    }

    @Test
    fun storeClearsCorruptJson() {
        val persistence = FakeActiveRunPersistence()
        val store = WearActiveRunStore(persistence)
        persistence.write("{broken")

        assertNull(
            store.restore(
                nowRealtimeMs = 1_000L,
                pendingDraftCount = 0,
                fallbackGhostConfig = null,
            ),
        )
        assertNull(persistence.read())
    }

    @Test
    fun clearRemovesCheckpoint() {
        val persistence = FakeActiveRunPersistence()
        val store = WearActiveRunStore(persistence)
        store.save(runningState(), checkpointRealtimeMs = 1_000L)

        store.clear()

        assertNull(persistence.read())
    }

    @Test
    fun storeDoesNotPersistCountdownState() {
        val persistence = FakeActiveRunPersistence()
        val store = WearActiveRunStore(persistence)
        store.save(runningState(), checkpointRealtimeMs = 1_000L)

        store.save(
            WearRunState(
                phase = WearRunPhase.CountingDown,
                countdownRemainingSeconds = 3,
            ),
            checkpointRealtimeMs = 2_000L,
        )

        assertNull(persistence.read())
    }

    @Test
    fun storeDoesNotPersistFeedbackState() {
        val persistence = FakeActiveRunPersistence()
        val store = WearActiveRunStore(persistence)
        store.save(runningState(), checkpointRealtimeMs = 1_000L)

        store.save(
            WearRunState(
                phase = WearRunPhase.Feedback,
                feedbackType = WearRunFeedbackType.Saved,
            ),
            checkpointRealtimeMs = 2_000L,
        )

        assertNull(persistence.read())
    }

    @Test
    fun restoreKeepsGhostRunState() {
        val persistence = FakeActiveRunPersistence()
        val store = WearActiveRunStore(persistence)
        val ghostConfig = ghostConfig()

        store.save(
            runningState(
                ghostConfig = ghostConfig,
                ghostFrame = WearGhostFrame(
                    status = WearGhostStatus.Ahead,
                    timeGapMs = 12_000L,
                    distanceGapM = 24.0,
                ),
            ),
            checkpointRealtimeMs = 1_000L,
        )

        val restored = store.restore(
            nowRealtimeMs = 1_000L,
            pendingDraftCount = 0,
            fallbackGhostConfig = null,
        )

        assertTrue(restored?.isGhostRun == true)
        assertEquals("ghost-1", restored?.ghostConfig?.id)
        assertEquals(WearGhostStatus.Ahead, restored?.ghostFrame?.status)
    }

    private fun runningState(
        elapsedMs: Long = 10_000L,
        phase: WearRunPhase = WearRunPhase.Running,
        ghostConfig: WearGhostConfig? = null,
        ghostFrame: WearGhostFrame? = null,
    ): WearRunState {
        return WearRunState(
            phase = phase,
            sessionId = "run-1",
            startedAtEpochMs = 1_000L,
            endedAtEpochMs = if (phase == WearRunPhase.Reviewing) 61_000L else null,
            elapsedMs = elapsedMs,
            distanceM = 250.0,
            averagePaceSecPerKm = 240.0,
            currentPaceSecPerKm = 230.0,
            speedMps = 4.3,
            cadenceSpm = 172.0,
            averageCadenceSpm = 171.0,
            cadenceSampleCount = 2,
            heartRateBpm = 142,
            caloriesKcal = 20.0,
            points = listOf(WearRunPoint(37.0, 127.0, elapsedMs)),
            elapsedBeforeActiveSegmentMs = elapsedMs,
            activeSegmentStartedRealtimeMs = if (phase == WearRunPhase.Running) 1_000L else null,
            ghostConfig = ghostConfig,
            isGhostRun = ghostConfig != null,
            ghostFrame = ghostFrame,
        )
    }

    private fun ghostConfig(): WearGhostConfig {
        return WearGhostConfig(
            id = "ghost-1",
            durationMs = 600_000L,
            distanceM = 2_000.0,
            sourceSummary = "한강 2K",
            points = listOf(
                WearRunPoint(37.0, 127.0, 0L),
                WearRunPoint(37.001, 127.001, 60_000L),
            ),
        )
    }
}

private class FakeActiveRunPersistence : ActiveRunPersistence {
    private var json: String? = null

    override fun read(): String? = json

    override fun write(json: String) {
        this.json = json
    }

    override fun clear() {
        json = null
    }
}
