// Wear 고스트런 이벤트 엔진의 안정화 정책을 검증한다
package kr.sjh.runlini.wear

import org.junit.Assert.assertEquals
import org.junit.Test

class WearGhostRaceEventEngineTest {
    @Test
    fun offRouteRequiresStableWindowAndEmitsOnce() {
        val engine = WearGhostRaceEventEngine()

        assertEquals(
            emptyList<WearGhostRaceEvent>(),
            engine.eventsFor(frame = frame(WearGhostStatus.OffRoute), isRunning = true, nowMs = 0L),
        )
        assertEquals(
            emptyList<WearGhostRaceEvent>(),
            engine.eventsFor(frame = frame(WearGhostStatus.OffRoute), isRunning = true, nowMs = 9_000L),
        )

        assertEquals(
            listOf(WearGhostRaceEventType.OffRoute),
            engine.eventsFor(frame = frame(WearGhostStatus.OffRoute), isRunning = true, nowMs = 10_000L)
                .map { it.type },
        )
        assertEquals(
            emptyList<WearGhostRaceEvent>(),
            engine.eventsFor(frame = frame(WearGhostStatus.OffRoute), isRunning = true, nowMs = 20_000L),
        )
    }

    @Test
    fun backOnRouteEmitsAfterStableRecovery() {
        val engine = WearGhostRaceEventEngine()
        engine.eventsFor(frame = frame(WearGhostStatus.OffRoute), isRunning = true, nowMs = 0L)
        engine.eventsFor(frame = frame(WearGhostStatus.OffRoute), isRunning = true, nowMs = 10_000L)

        assertEquals(
            emptyList<WearGhostRaceEvent>(),
            engine.eventsFor(frame = frame(WearGhostStatus.Ahead), isRunning = true, nowMs = 15_000L),
        )
        assertEquals(
            listOf(WearGhostRaceEventType.BackOnRoute),
            engine.eventsFor(frame = frame(WearGhostStatus.Ahead), isRunning = true, nowMs = 25_000L)
                .map { it.type },
        )
    }

    @Test
    fun leadChangesEmitAfterStableWindow() {
        val engine = WearGhostRaceEventEngine()
        engine.eventsFor(frame = frame(WearGhostStatus.Behind), isRunning = true, nowMs = 0L)
        engine.eventsFor(frame = frame(WearGhostStatus.Behind), isRunning = true, nowMs = 15_000L)
        engine.eventsFor(frame = frame(WearGhostStatus.Ahead), isRunning = true, nowMs = 20_000L)

        assertEquals(
            listOf(WearGhostRaceEventType.Overtake),
            engine.eventsFor(frame = frame(WearGhostStatus.Ahead), isRunning = true, nowMs = 35_000L)
                .map { it.type },
        )
    }

    @Test
    fun finalStretchAndCompletionEmitOnce() {
        val engine = WearGhostRaceEventEngine()

        assertEquals(
            listOf(WearGhostRaceEventType.Last500m),
            engine.eventsFor(
                frame = frame(WearGhostStatus.Ahead, distanceToFinishM = 500.0),
                isRunning = true,
                nowMs = 0L,
            ).map { it.type },
        )
        assertEquals(
            listOf(WearGhostRaceEventType.Last200m),
            engine.eventsFor(
                frame = frame(WearGhostStatus.Ahead, distanceToFinishM = 200.0),
                isRunning = true,
                nowMs = 1_000L,
            ).map { it.type },
        )
        assertEquals(
            listOf(WearGhostRaceEventType.Completed),
            engine.eventsFor(
                frame = frame(WearGhostStatus.Ahead, distanceToFinishM = 20.0),
                isRunning = true,
                nowMs = 2_000L,
                completionPending = true,
            ).map { it.type },
        )
    }

    @Test
    fun eventsAreSuppressedBeforeStartIsConfirmed() {
        val engine = WearGhostRaceEventEngine()

        engine.eventsFor(
            frame = frame(WearGhostStatus.OffRoute, startConfirmed = false),
            isRunning = true,
            nowMs = 0L,
        )

        assertEquals(
            emptyList<WearGhostRaceEvent>(),
            engine.eventsFor(
                frame = frame(WearGhostStatus.OffRoute, startConfirmed = false),
                isRunning = true,
                nowMs = 10_000L,
            ),
        )
    }

    private fun frame(
        status: WearGhostStatus,
        distanceToFinishM: Double = 600.0,
        startConfirmed: Boolean = true,
    ): WearGhostFrame {
        return WearGhostFrame(
            status = status,
            timeGapMs = 12_000L,
            distanceGapM = 24.0,
            routeProgress = 0.7,
            distanceToFinishM = distanceToFinishM,
            distanceFromRouteM = if (status == WearGhostStatus.OffRoute) 50.0 else 4.0,
            totalRouteDistanceM = 1_200.0,
            distanceToFinishPointM = distanceToFinishM,
            startConfirmed = startConfirmed,
        )
    }
}
