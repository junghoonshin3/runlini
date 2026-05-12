package kr.sjh.runlini.wear

import java.util.UUID

class WearRunStateReducer {
    fun countdown(
        state: WearRunState,
        remainingSeconds: Int,
        recordRaceConfig: WearRecordRaceConfig? = null,
    ): WearRunState {
        return state.copy(
            phase = WearRunPhase.CountingDown,
            countdownRemainingSeconds = remainingSeconds.coerceAtLeast(1),
            countdownStartRecordRaceConfig = recordRaceConfig,
            statusMessage = null,
            errorMessage = null,
            feedbackType = null,
        )
    }

    fun start(
        state: WearRunState,
        epochMs: Long,
        realtimeMs: Long,
        recordRaceConfig: WearRecordRaceConfig? = null,
    ): WearRunState {
        return state.copy(
            phase = WearRunPhase.Running,
            countdownRemainingSeconds = null,
            countdownStartRecordRaceConfig = null,
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
            recordRaceConfig = recordRaceConfig,
            isRecordRaceRun = recordRaceConfig != null,
            recordRaceFrame = null,
            recordRaceStartConfirmed = false,
            recordRaceStartCandidateCount = 0,
            recordRaceStartLastEvaluatedPointCount = 0,
            recordRaceTrackedDistanceAlongRouteM = null,
            recordRaceCompletionCandidateCount = 0,
            recordRaceCompletionPrompt = false,
            recordRaceCompletionDismissed = false,
            recordRaceCompletionFrame = null,
            intervalFrame = null,
            pauseReason = null,
            statusMessage = null,
            errorMessage = null,
            feedbackType = null,
        )
    }

    fun tick(state: WearRunState, realtimeMs: Long): WearRunState {
        if (state.phase != WearRunPhase.Running) return state
        val elapsed = elapsedAt(state, realtimeMs)
        return state.copy(
            elapsedMs = elapsed,
            intervalFrame = intervalFrame(state, elapsed, state.distanceM),
        )
    }

    fun pause(
        state: WearRunState,
        realtimeMs: Long,
        reason: WearPauseReason = WearPauseReason.Manual,
    ): WearRunState {
        if (state.phase != WearRunPhase.Running) return state
        val elapsed = elapsedAt(state, realtimeMs)
        return state.copy(
            phase = WearRunPhase.Paused,
            elapsedMs = elapsed,
            elapsedBeforeActiveSegmentMs = elapsed,
            activeSegmentStartedRealtimeMs = null,
            pauseReason = reason,
        )
    }

    fun resume(state: WearRunState, realtimeMs: Long): WearRunState {
        if (state.phase != WearRunPhase.Paused) return state
        return state.copy(
            phase = WearRunPhase.Running,
            activeSegmentStartedRealtimeMs = realtimeMs,
            pauseReason = null,
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
            pauseReason = null,
        )
    }

    fun ready(
        message: String? = null,
        pendingDraftCount: Int = 0,
        recordRaceConfig: WearRecordRaceConfig? = null,
        recordRaceConfigs: List<WearRecordRaceConfig> = emptyList(),
        settings: WearRunSettings = WearRunSettings(),
    ): WearRunState {
        return WearRunState(
            settings = settings,
            pendingDraftCount = pendingDraftCount,
            recordRaceConfig = recordRaceConfig,
            recordRaceConfigs = recordRaceConfigs,
            statusMessage = message,
        )
    }

    fun feedback(
        type: WearRunFeedbackType,
        pendingDraftCount: Int = 0,
        recordRaceConfig: WearRecordRaceConfig? = null,
        recordRaceConfigs: List<WearRecordRaceConfig> = emptyList(),
        settings: WearRunSettings = WearRunSettings(),
    ): WearRunState {
        return WearRunState(
            phase = WearRunPhase.Feedback,
            settings = settings,
            pendingDraftCount = pendingDraftCount,
            recordRaceConfig = recordRaceConfig,
            recordRaceConfigs = recordRaceConfigs,
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
            intervalFrame = intervalFrame(state, elapsed, distance),
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

    fun applyRecordRaceFrame(state: WearRunState, frame: WearRecordRaceFrame?): WearRunState {
        if (!state.isRecordRaceRun) return state
        return state.copy(
            recordRaceFrame = frame,
            recordRaceStartConfirmed = frame?.startConfirmed ?: state.recordRaceStartConfirmed,
            recordRaceStartCandidateCount = frame?.startCandidateCount ?: state.recordRaceStartCandidateCount,
            recordRaceStartLastEvaluatedPointCount =
                frame?.startLastEvaluatedPointCount ?: state.recordRaceStartLastEvaluatedPointCount,
            recordRaceTrackedDistanceAlongRouteM =
                frame?.trackedDistanceAlongRouteM ?: state.recordRaceTrackedDistanceAlongRouteM,
        )
    }

    fun applyRecordRaceCompletionDecision(
        state: WearRunState,
        decision: WearRecordRaceCompletionDecision,
        frame: WearRecordRaceFrame?,
    ): WearRunState {
        if (
            !state.isRecordRaceRun ||
            state.recordRaceCompletionPrompt ||
            state.recordRaceCompletionDismissed
        ) {
            return state
        }
        if (decision.isComplete && frame != null) {
            return state.copy(
                recordRaceCompletionCandidateCount = decision.candidateCount,
                recordRaceCompletionPrompt = true,
                recordRaceCompletionFrame = frame,
            )
        }
        return state.copy(recordRaceCompletionCandidateCount = decision.candidateCount)
    }

    fun continueAfterRecordRaceCompletion(state: WearRunState): WearRunState {
        if (!state.isActive) return state
        return state.copy(
            recordRaceCompletionPrompt = false,
            recordRaceCompletionDismissed = true,
        )
    }

    private fun elapsedAt(state: WearRunState, realtimeMs: Long): Long {
        val started = state.activeSegmentStartedRealtimeMs ?: return state.elapsedMs
        return state.elapsedBeforeActiveSegmentMs + (realtimeMs - started).coerceAtLeast(0)
    }

    private fun intervalFrame(
        state: WearRunState,
        elapsedMs: Long,
        distanceM: Double,
    ): WearIntervalFrame? {
        if (state.isRecordRaceRun) return null
        return WearIntervalWorkoutCalculator().calculate(
            workout = state.settings.intervalWorkout,
            elapsedMs = elapsedMs,
            distanceM = distanceM,
        )
    }
}
