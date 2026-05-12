package kr.sjh.runlini.wear

import org.json.JSONArray
import org.json.JSONObject
import java.time.Instant
import java.util.UUID

enum class WearRunPhase { Ready, CountingDown, Running, Paused, Reviewing, Feedback }

enum class WearRunFeedbackType { Saved, Discarded }

enum class WearPauseReason { Manual, Auto }

data class WearRunPoint(
    val latitude: Double,
    val longitude: Double,
    val timestampRelMs: Long,
    val paceSecPerKm: Double? = null,
    val speedMps: Double? = null,
    val horizontalAccuracyM: Double? = null,
    val elevationM: Double? = null,
    val heartRateBpm: Int? = null,
    val cadenceSpm: Double? = null,
)

data class WearMetricSample(
    val activeDurationMs: Long? = null,
    val distanceM: Double? = null,
    val paceSecPerKm: Double? = null,
    val speedMps: Double? = null,
    val cadenceSpm: Double? = null,
    val heartRateBpm: Int? = null,
    val caloriesKcal: Double? = null,
    val points: List<WearRunPoint> = emptyList(),
)

data class WearRunState(
    val phase: WearRunPhase = WearRunPhase.Ready,
    val settings: WearRunSettings = WearRunSettings(),
    val countdownRemainingSeconds: Int? = null,
    val countdownStartRecordRaceConfig: WearRecordRaceConfig? = null,
    val sessionId: String = "",
    val startedAtEpochMs: Long = 0,
    val endedAtEpochMs: Long? = null,
    val elapsedMs: Long = 0,
    val distanceM: Double = 0.0,
    val averagePaceSecPerKm: Double? = null,
    val currentPaceSecPerKm: Double? = null,
    val speedMps: Double? = null,
    val cadenceSpm: Double? = null,
    val averageCadenceSpm: Double? = null,
    val cadenceSampleCount: Int = 0,
    val heartRateBpm: Int? = null,
    val caloriesKcal: Double? = null,
    val points: List<WearRunPoint> = emptyList(),
    val elapsedBeforeActiveSegmentMs: Long = 0,
    val activeSegmentStartedRealtimeMs: Long? = null,
    val pendingDraftCount: Int = 0,
    val recordRaceConfig: WearRecordRaceConfig? = null,
    val recordRaceConfigs: List<WearRecordRaceConfig> = emptyList(),
    val isRecordRaceRun: Boolean = false,
    val recordRaceFrame: WearRecordRaceFrame? = null,
    val recordRaceStartConfirmed: Boolean = false,
    val recordRaceStartCandidateCount: Int = 0,
    val recordRaceStartLastEvaluatedPointCount: Int = 0,
    val recordRaceTrackedDistanceAlongRouteM: Double? = null,
    val recordRaceCompletionCandidateCount: Int = 0,
    val recordRaceCompletionPrompt: Boolean = false,
    val recordRaceCompletionDismissed: Boolean = false,
    val recordRaceCompletionFrame: WearRecordRaceFrame? = null,
    val intervalFrame: WearIntervalFrame? = null,
    val pauseReason: WearPauseReason? = null,
    val statusMessage: String? = null,
    val errorMessage: String? = null,
    val feedbackType: WearRunFeedbackType? = null,
) {
    val isActive: Boolean
        get() = phase == WearRunPhase.Running || phase == WearRunPhase.Paused

    val canSave: Boolean
        get() = phase == WearRunPhase.Reviewing && elapsedMs > 0
}

data class WearRunDraftPayload(
    val id: String,
    val startedAt: Instant,
    val endedAt: Instant?,
    val durationMs: Long,
    val distanceM: Double,
    val points: List<WearRunPoint>,
    val sourceDeviceName: String,
    val caloriesKcal: Double?,
    val averageCadenceSpm: Double? = null,
    val recordRaceSummary: WearRunRecordRaceSummary? = null,
) {
    companion object {
        fun fromState(state: WearRunState, deviceName: String): WearRunDraftPayload {
            return WearRunDraftPayload(
                id = state.sessionId.ifBlank { UUID.randomUUID().toString() },
                startedAt = Instant.ofEpochMilli(state.startedAtEpochMs),
                endedAt = state.endedAtEpochMs?.let(Instant::ofEpochMilli),
                durationMs = state.elapsedMs,
                distanceM = state.distanceM,
                points = state.points,
                sourceDeviceName = deviceName,
                caloriesKcal = state.caloriesKcal,
                averageCadenceSpm = state.averageCadenceSpm,
                recordRaceSummary = WearRunRecordRaceSummary.from(
                    state.recordRaceConfig,
                    state.recordRaceCompletionFrame ?: state.recordRaceFrame,
                ),
            )
        }
    }
}

object WearRunDraftJsonMapper {
    fun toJson(draft: WearRunDraftPayload): String {
        return JSONObject()
            .put("id", draft.id)
            .put("platform", "wearOs")
            .put("startedAt", draft.startedAt.toString())
            .put("endedAt", draft.endedAt?.toString())
            .put("durationMs", draft.durationMs)
            .put("distanceM", draft.distanceM)
            .put("externalWorkoutId", draft.id)
            .put("sourceDeviceName", draft.sourceDeviceName)
            .put("caloriesKcal", draft.caloriesKcal)
            .put("averageCadenceSpm", draft.averageCadenceSpm)
            .put("recordRaceSummary", draft.recordRaceSummary?.toJson())
            .put("points", JSONArray(draft.points.map(::pointToJson)))
            .toString()
    }

    private fun pointToJson(point: WearRunPoint): JSONObject {
        return JSONObject()
            .put("lat", point.latitude)
            .put("lng", point.longitude)
            .put("timestampRelMs", point.timestampRelMs)
            .put("paceSecPerKm", point.paceSecPerKm)
            .put("speedMps", point.speedMps)
            .put("horizontalAccuracyM", point.horizontalAccuracyM)
            .put("elevationM", point.elevationM)
            .put("heartRateBpm", point.heartRateBpm)
            .put("cadenceSpm", point.cadenceSpm)
            .put("source", "wearOs")
    }
}
