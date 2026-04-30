package kr.sjh.runlini.wear

import java.util.UUID

class WearRunStateReducer {
    fun countdown(
        state: WearRunState,
        remainingSeconds: Int,
        ghostConfig: WearGhostConfig? = null,
    ): WearRunState {
        return state.copy(
            phase = WearRunPhase.CountingDown,
            countdownRemainingSeconds = remainingSeconds.coerceAtLeast(1),
            countdownStartGhostConfig = ghostConfig,
            statusMessage = null,
            errorMessage = null,
            feedbackType = null,
        )
    }

    fun start(
        state: WearRunState,
        epochMs: Long,
        realtimeMs: Long,
        ghostConfig: WearGhostConfig? = null,
    ): WearRunState {
        return state.copy(
            phase = WearRunPhase.Running,
            countdownRemainingSeconds = null,
            countdownStartGhostConfig = null,
            sessionId = UUID.randomUUID().toString(),
            startedAtEpochMs = epochMs,
            endedAtEpochMs = null,
            elapsedMs = 0,
            distanceM = 0.0,
            averagePaceSecPerKm = null,
            currentPaceSecPerKm = null,
            speedMps = null,
            cadenceSpm = null,
            averageCadenceSpm = null,
            cadenceSampleCount = 0,
            heartRateBpm = null,
            caloriesKcal = null,
            points = emptyList(),
            elapsedBeforeActiveSegmentMs = 0,
            activeSegmentStartedRealtimeMs = realtimeMs,
            pendingDraftCount = state.pendingDraftCount,
            ghostConfig = ghostConfig,
            isGhostRun = ghostConfig != null,
            ghostFrame = null,
            statusMessage = null,
            errorMessage = null,
            feedbackType = null,
        )
    }

    fun tick(state: WearRunState, realtimeMs: Long): WearRunState {
        if (state.phase != WearRunPhase.Running) return state
        return state.copy(elapsedMs = elapsedAt(state, realtimeMs))
    }

    fun pause(state: WearRunState, realtimeMs: Long): WearRunState {
        if (state.phase != WearRunPhase.Running) return state
        val elapsed = elapsedAt(state, realtimeMs)
        return state.copy(
            phase = WearRunPhase.Paused,
            elapsedMs = elapsed,
            elapsedBeforeActiveSegmentMs = elapsed,
            activeSegmentStartedRealtimeMs = null,
        )
    }

    fun resume(state: WearRunState, realtimeMs: Long): WearRunState {
        if (state.phase != WearRunPhase.Paused) return state
        return state.copy(
            phase = WearRunPhase.Running,
            activeSegmentStartedRealtimeMs = realtimeMs,
        )
    }

    fun review(state: WearRunState, epochMs: Long, realtimeMs: Long): WearRunState {
        if (!state.isActive) return state
        val elapsed = elapsedAt(state, realtimeMs)
        return state.copy(
            phase = WearRunPhase.Reviewing,
            endedAtEpochMs = epochMs,
            elapsedMs = elapsed,
            elapsedBeforeActiveSegmentMs = elapsed,
            activeSegmentStartedRealtimeMs = null,
        )
    }

    fun ready(
        message: String? = null,
        pendingDraftCount: Int = 0,
        ghostConfig: WearGhostConfig? = null,
        ghostConfigs: List<WearGhostConfig> = emptyList(),
        settings: WearRunSettings = WearRunSettings(),
    ): WearRunState {
        return WearRunState(
            settings = settings,
            pendingDraftCount = pendingDraftCount,
            ghostConfig = ghostConfig,
            ghostConfigs = ghostConfigs,
            statusMessage = message,
        )
    }

    fun feedback(
        type: WearRunFeedbackType,
        pendingDraftCount: Int = 0,
        ghostConfig: WearGhostConfig? = null,
        ghostConfigs: List<WearGhostConfig> = emptyList(),
        settings: WearRunSettings = WearRunSettings(),
    ): WearRunState {
        return WearRunState(
            phase = WearRunPhase.Feedback,
            settings = settings,
            pendingDraftCount = pendingDraftCount,
            ghostConfig = ghostConfig,
            ghostConfigs = ghostConfigs,
            feedbackType = type,
        )
    }

    fun fail(state: WearRunState, message: String): WearRunState {
        return state.copy(
            errorMessage = message,
            statusMessage = null,
            feedbackType = null,
        )
    }

    fun applyMetrics(
        state: WearRunState,
        sample: WearMetricSample,
        realtimeMs: Long,
    ): WearRunState {
        val localElapsed = elapsedAt(state, realtimeMs)
        val sensorElapsed = sample.activeDurationMs
        val elapsed = if (state.phase == WearRunPhase.Running) {
            maxOf(sensorElapsed ?: localElapsed, localElapsed, state.elapsedMs)
        } else {
            maxOf(sensorElapsed ?: state.elapsedMs, state.elapsedMs)
        }
        val distance = sample.distanceM ?: state.distanceM
        val averagePace = if (distance > 0 && elapsed > 0) {
            elapsed / 1000.0 / (distance / 1000.0)
        } else {
            state.averagePaceSecPerKm
        }
        val cadence = sample.cadenceSpm?.takeIf { it.isFinite() && it > 0 }
        val cadenceSampleCount = if (cadence == null) {
            state.cadenceSampleCount
        } else {
            state.cadenceSampleCount + 1
        }
        val averageCadence = if (cadence == null) {
            state.averageCadenceSpm
        } else {
            val previousTotal = (state.averageCadenceSpm ?: 0.0) * state.cadenceSampleCount
            (previousTotal + cadence) / cadenceSampleCount
        }
        val points = if (sample.points.isEmpty()) {
            state.points
        } else {
            (state.points + sample.points).distinctBy { point ->
                "${point.timestampRelMs}:${point.latitude}:${point.longitude}"
            }
        }
        return state.copy(
            elapsedMs = elapsed,
            distanceM = distance,
            averagePaceSecPerKm = averagePace,
            currentPaceSecPerKm = sample.paceSecPerKm ?: state.currentPaceSecPerKm,
            speedMps = sample.speedMps ?: state.speedMps,
            cadenceSpm = cadence ?: state.cadenceSpm,
            averageCadenceSpm = averageCadence,
            cadenceSampleCount = cadenceSampleCount,
            heartRateBpm = sample.heartRateBpm ?: state.heartRateBpm,
            caloriesKcal = sample.caloriesKcal ?: state.caloriesKcal,
            points = points,
            elapsedBeforeActiveSegmentMs = if (state.phase == WearRunPhase.Running) {
                elapsed
            } else {
                state.elapsedBeforeActiveSegmentMs
            },
            activeSegmentStartedRealtimeMs = if (state.phase == WearRunPhase.Running) {
                realtimeMs
            } else {
                state.activeSegmentStartedRealtimeMs
            },
        )
    }

    fun applyGhostFrame(state: WearRunState, frame: WearGhostFrame?): WearRunState {
        if (!state.isGhostRun) return state
        return state.copy(ghostFrame = frame)
    }

    private fun elapsedAt(state: WearRunState, realtimeMs: Long): Long {
        val started = state.activeSegmentStartedRealtimeMs ?: return state.elapsedMs
        return state.elapsedBeforeActiveSegmentMs + (realtimeMs - started).coerceAtLeast(0)
    }
}
