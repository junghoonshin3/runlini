// Wear 기록 레이스 이벤트 엔진의 안정화 정책을 검증한다
package kr.sjh.runlini.wear

import org.junit.Assert.assertEquals
import org.junit.Test

class WearRecordRaceEventEngineTest {
    @Test
    fun offRouteRequiresStableWindowAndEmitsOnce() {
        val engine = WearRecordRaceEventEngine()

        assertEquals(
            emptyList<WearRecordRaceEvent>(),
            engine.eventsFor(frame = frame(WearRecordRaceStatus.OffRoute), isRunning = true, nowMs = 0L),
        )
        assertEquals(
            emptyList<WearRecordRaceEvent>(),
            engine.eventsFor(frame = frame(WearRecordRaceStatus.OffRoute), isRunning = true, nowMs = 9_000L),
        )

        assertEquals(
            listOf(WearRecordRaceEventType.OffRoute),
            engine.eventsFor(frame = frame(WearRecordRaceStatus.OffRoute), isRunning = true, nowMs = 10_000L)
                .map { it.type },
        )
        assertEquals(
            emptyList<WearRecordRaceEvent>(),
            engine.eventsFor(frame = frame(WearRecordRaceStatus.OffRoute), isRunning = true, nowMs = 20_000L),
        )
    }

    @Test
    fun backOnRouteEmitsAfterStableRecovery() {
        val engine = WearRecordRaceEventEngine()
        engine.eventsFor(frame = frame(WearRecordRaceStatus.OffRoute), isRunning = true, nowMs = 0L)
        engine.eventsFor(frame = frame(WearRecordRaceStatus.OffRoute), isRunning = true, nowMs = 10_000L)

        assertEquals(
            emptyList<WearRecordRaceEvent>(),
            engine.eventsFor(frame = frame(WearRecordRaceStatus.Ahead), isRunning = true, nowMs = 15_000L),
        )
        assertEquals(
            listOf(WearRecordRaceEventType.BackOnRoute),
            engine.eventsFor(frame = frame(WearRecordRaceStatus.Ahead), isRunning = true, nowMs = 25_000L)
                .map { it.type },
        )
    }

    @Test
    fun leadChangesEmitAfterStableWindow() {
        val engine = WearRecordRaceEventEngine()
        engine.eventsFor(frame = frame(WearRecordRaceStatus.Behind), isRunning = true, nowMs = 0L)
        engine.eventsFor(frame = frame(WearRecordRaceStatus.Behind), isRunning = true, nowMs = 15_000L)
        engine.eventsFor(frame = frame(WearRecordRaceStatus.Ahead), isRunning = true, nowMs = 20_000L)

        assertEquals(
            listOf(WearRecordRaceEventType.Overtake),
            engine.eventsFor(frame = frame(WearRecordRaceStatus.Ahead), isRunning = true, nowMs = 35_000L)
                .map { it.type },
        )
    }

    @Test
    fun finalStretchAndCompletionEmitOnce() {
        val engine = WearRecordRaceEventEngine()

        assertEquals(
            listOf(WearRecordRaceEventType.Last500m),
            engine.eventsFor(
                frame = frame(WearRecordRaceStatus.Ahead, distanceToFinishM = 500.0),
                isRunning = true,
                nowMs = 0L,
            ).map { it.type },
        )
        assertEquals(
            listOf(WearRecordRaceEventType.Last200m),
            engine.eventsFor(
                frame = frame(WearRecordRaceStatus.Ahead, distanceToFinishM = 200.0),
                isRunning = true,
                nowMs = 1_000L,
            ).map { it.type },
        )
        assertEquals(
            listOf(WearRecordRaceEventType.Completed),
            engine.eventsFor(
                frame = frame(WearRecordRaceStatus.Ahead, distanceToFinishM = 20.0),
                isRunning = true,
                nowMs = 2_000L,
                completionPending = true,
            ).map { it.type },
        )
    }

    @Test
    fun eventsAreSuppressedBeforeStartIsConfirmed() {
        val engine = WearRecordRaceEventEngine()

        engine.eventsFor(
            frame = frame(WearRecordRaceStatus.OffRoute, startConfirmed = false),
            isRunning = true,
            nowMs = 0L,
        )

        assertEquals(
            emptyList<WearRecordRaceEvent>(),
            engine.eventsFor(
                frame = frame(WearRecordRaceStatus.OffRoute, startConfirmed = false),
                isRunning = true,
                nowMs = 10_000L,
            ),
        )
    }

    private fun frame(
        status: WearRecordRaceStatus,
        distanceToFinishM: Double = 600.0,
        startConfirmed: Boolean = true,
    ): WearRecordRaceFrame {
        return WearRecordRaceFrame(
            status = status,
            timeGapMs = 12_000L,
            distanceGapM = 24.0,
            routeProgress = 0.7,
            distanceToFinishM = distanceToFinishM,
            distanceFromRouteM = if (status == WearRecordRaceStatus.OffRoute) 50.0 else 4.0,
            totalRouteDistanceM = 1_200.0,
            distanceToFinishPointM = distanceToFinishM,
            startConfirmed = startConfirmed,
        )
    }
}
