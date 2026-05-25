// Wear 기록 레이스 이벤트 안정화와 중복 억제를 담당하는 엔진
package kr.sjh.runlini.wear

enum class WearRecordRaceEventType {
    OffRoute,
    BackOnRoute,
    Overtake,
    LostLead,
    Last500m,
    Last200m,
    Completed,
}

data class WearRecordRaceEvent(
    val type: WearRecordRaceEventType,
    val frame: WearRecordRaceFrame,
)

class WearRecordRaceEventEngine(
    private val offRouteStableMs: Long = 10_000L,
    private val leadStableMs: Long = 15_000L,
) {
    private var sessionId: String? = null
    private var offRouteSinceMs: Long? = null
    private var backOnRouteSinceMs: Long? = null
    private var offRouteAlerted: Boolean = false
    private var backOnRouteAlerted: Boolean = false
    private var leadCandidate: WearRecordRaceStatus? = null
    private var leadCandidateSinceMs: Long? = null
    private var stableLeadStatus: WearRecordRaceStatus? = null
    private var last500mAlerted: Boolean = false
    private var last200mAlerted: Boolean = false
    private var completedAlerted: Boolean = false

    fun eventsFor(
        sessionId: String = "active",
        frame: WearRecordRaceFrame?,
        isRunning: Boolean,
        nowMs: Long,
        completionPending: Boolean = false,
    ): List<WearRecordRaceEvent> {
        if (this.sessionId != sessionId) {
            reset()
            this.sessionId = sessionId
        }
        if (
            !isRunning ||
            frame == null ||
            !frame.startConfirmed ||
            frame.status == WearRecordRaceStatus.Unavailable
        ) {
            return emptyList()
        }

        val events = mutableListOf<WearRecordRaceEvent>()
        events += routeEvents(frame, nowMs)
        events += leadEvents(frame, nowMs)
        events += finalStretchEvents(frame)
        if (completionPending && !completedAlerted) {
            completedAlerted = true
            events += WearRecordRaceEvent(WearRecordRaceEventType.Completed, frame)
        }
        return events
    }

    fun reset() {
        sessionId = null
        offRouteSinceMs = null
        backOnRouteSinceMs = null
        offRouteAlerted = false
        backOnRouteAlerted = false
        leadCandidate = null
        leadCandidateSinceMs = null
        stableLeadStatus = null
        last500mAlerted = false
        last200mAlerted = false
        completedAlerted = false
    }

    private fun routeEvents(frame: WearRecordRaceFrame, nowMs: Long): List<WearRecordRaceEvent> {
        if (frame.status == WearRecordRaceStatus.OffRoute) {
            backOnRouteSinceMs = null
            backOnRouteAlerted = false
            if (offRouteSinceMs == null) offRouteSinceMs = nowMs
            if (!offRouteAlerted && nowMs - (offRouteSinceMs ?: nowMs) >= offRouteStableMs) {
                offRouteAlerted = true
                return listOf(WearRecordRaceEvent(WearRecordRaceEventType.OffRoute, frame))
            }
            return emptyList()
        }

        offRouteSinceMs = null
        if (offRouteAlerted && !backOnRouteAlerted) {
            if (backOnRouteSinceMs == null) backOnRouteSinceMs = nowMs
            if (nowMs - (backOnRouteSinceMs ?: nowMs) >= offRouteStableMs) {
                backOnRouteAlerted = true
                offRouteAlerted = false
                return listOf(WearRecordRaceEvent(WearRecordRaceEventType.BackOnRoute, frame))
            }
        }
        return emptyList()
    }

    private fun leadEvents(frame: WearRecordRaceFrame, nowMs: Long): List<WearRecordRaceEvent> {
        val status = frame.status
        if (status != WearRecordRaceStatus.Ahead && status != WearRecordRaceStatus.Behind) {
            leadCandidate = null
            leadCandidateSinceMs = null
            return emptyList()
        }
        if (leadCandidate != status) {
            leadCandidate = status
            leadCandidateSinceMs = nowMs
            return emptyList()
        }

        val since = leadCandidateSinceMs ?: nowMs
        if (nowMs - since < leadStableMs || stableLeadStatus == status) {
            return emptyList()
        }

        val previous = stableLeadStatus
        stableLeadStatus = status
        if (previous == null) return emptyList()
        val type = if (status == WearRecordRaceStatus.Ahead) {
            WearRecordRaceEventType.Overtake
        } else {
            WearRecordRaceEventType.LostLead
        }
        return listOf(WearRecordRaceEvent(type, frame))
    }

    private fun finalStretchEvents(frame: WearRecordRaceFrame): List<WearRecordRaceEvent> {
        if (
            frame.status == WearRecordRaceStatus.OffRoute ||
            !frame.distanceToFinishM.isFinite() ||
            frame.totalRouteDistanceM <= 0.0
        ) {
            return emptyList()
        }
        val events = mutableListOf<WearRecordRaceEvent>()
        if (
            !last500mAlerted &&
            frame.totalRouteDistanceM > 500.0 &&
            frame.distanceToFinishM <= 500.0
        ) {
            last500mAlerted = true
            events += WearRecordRaceEvent(WearRecordRaceEventType.Last500m, frame)
        }
        if (
            !last200mAlerted &&
            frame.totalRouteDistanceM > 200.0 &&
            frame.distanceToFinishM <= 200.0
        ) {
            last200mAlerted = true
            events += WearRecordRaceEvent(WearRecordRaceEventType.Last200m, frame)
        }
        return events
    }
}
