package kr.sjh.runlini.wear

import android.content.Context
import org.json.JSONArray
import org.json.JSONObject
import java.io.File

interface ActiveRunPersistence {
    fun read(): String?
    fun write(json: String)
    fun clear()
}

class WearActiveRunStore(private val persistence: ActiveRunPersistence) {
    constructor(context: Context) : this(FileActiveRunPersistence(context))

    fun save(state: WearRunState, checkpointRealtimeMs: Long) {
        if (
            state.phase == WearRunPhase.Ready ||
            state.phase == WearRunPhase.CountingDown ||
            state.phase == WearRunPhase.Feedback
        ) {
            clear()
            return
        }
        persistence.write(
            WearActiveRunJsonMapper.toJson(
                state = state,
                checkpointRealtimeMs = checkpointRealtimeMs,
            ),
        )
    }

    fun restore(
        nowRealtimeMs: Long,
        pendingDraftCount: Int,
        fallbackGhostConfig: WearGhostConfig?,
    ): WearRunState? {
        val json = persistence.read() ?: return null
        return runCatching {
            WearActiveRunJsonMapper.fromJson(
                json = json,
                nowRealtimeMs = nowRealtimeMs,
                pendingDraftCount = pendingDraftCount,
                fallbackGhostConfig = fallbackGhostConfig,
            )
        }.getOrElse {
            clear()
            null
        }
    }

    fun clear() {
        persistence.clear()
    }
}

object WearActiveRunJsonMapper {
    fun toJson(state: WearRunState, checkpointRealtimeMs: Long): String {
        return JSONObject()
            .put("schemaVersion", 1)
            .put("checkpointRealtimeMs", checkpointRealtimeMs)
            .put("phase", state.phase.name)
            .put("sessionId", state.sessionId)
            .put("startedAtEpochMs", state.startedAtEpochMs)
            .put("endedAtEpochMs", state.endedAtEpochMs)
            .put("elapsedMs", state.elapsedMs)
            .put("distanceM", state.distanceM)
            .put("averagePaceSecPerKm", finiteDoubleOrNull(state.averagePaceSecPerKm))
            .put("currentPaceSecPerKm", finiteDoubleOrNull(state.currentPaceSecPerKm))
            .put("speedMps", finiteDoubleOrNull(state.speedMps))
            .put("cadenceSpm", finiteDoubleOrNull(state.cadenceSpm))
            .put("averageCadenceSpm", finiteDoubleOrNull(state.averageCadenceSpm))
            .put("cadenceSampleCount", state.cadenceSampleCount)
            .put("heartRateBpm", state.heartRateBpm)
            .put("caloriesKcal", finiteDoubleOrNull(state.caloriesKcal))
            .put("elapsedBeforeActiveSegmentMs", state.elapsedBeforeActiveSegmentMs)
            .put("activeSegmentStartedRealtimeMs", state.activeSegmentStartedRealtimeMs)
            .put("isGhostRun", state.isGhostRun)
            .put("ghostConfig", state.ghostConfig?.let(::ghostConfigToJson))
            .put("ghostFrame", state.ghostFrame?.let(::ghostFrameToJson))
            .put("statusMessage", state.statusMessage)
            .put("errorMessage", state.errorMessage)
            .put("points", JSONArray(state.points.map(::pointToJson)))
            .toString()
    }

    fun fromJson(
        json: String,
        nowRealtimeMs: Long,
        pendingDraftCount: Int,
        fallbackGhostConfig: WearGhostConfig?,
    ): WearRunState? {
        val objectJson = JSONObject(json)
        val phase = runCatching {
            WearRunPhase.valueOf(objectJson.getString("phase"))
        }.getOrDefault(WearRunPhase.Ready)
        if (
            phase == WearRunPhase.Ready ||
            phase == WearRunPhase.CountingDown ||
            phase == WearRunPhase.Feedback
        ) {
            return null
        }

        val checkpointRealtimeMs = objectJson.optLong("checkpointRealtimeMs", nowRealtimeMs)
        val savedElapsedMs = objectJson.optLong("elapsedMs", 0L)
        val restoredElapsedMs = if (phase == WearRunPhase.Running) {
            savedElapsedMs + (nowRealtimeMs - checkpointRealtimeMs).coerceAtLeast(0L)
        } else {
            savedElapsedMs
        }
        val storedGhostConfig = objectJson.optionalObject("ghostConfig")?.let { configJson ->
            WearGhostConfigJsonMapper.fromJson(configJson.toString())
        }
        val isGhostRun = objectJson.optBoolean("isGhostRun", storedGhostConfig != null)
        val ghostConfig = if (isGhostRun) storedGhostConfig else fallbackGhostConfig

        return WearRunState(
            phase = phase,
            sessionId = objectJson.optString("sessionId"),
            startedAtEpochMs = objectJson.optLong("startedAtEpochMs", 0L),
            endedAtEpochMs = objectJson.optionalLong("endedAtEpochMs"),
            elapsedMs = restoredElapsedMs,
            distanceM = objectJson.optionalDouble("distanceM") ?: 0.0,
            averagePaceSecPerKm = objectJson.optionalDouble("averagePaceSecPerKm"),
            currentPaceSecPerKm = objectJson.optionalDouble("currentPaceSecPerKm"),
            speedMps = objectJson.optionalDouble("speedMps"),
            cadenceSpm = objectJson.optionalDouble("cadenceSpm"),
            averageCadenceSpm = objectJson.optionalDouble("averageCadenceSpm"),
            cadenceSampleCount = objectJson.optInt("cadenceSampleCount", 0),
            heartRateBpm = objectJson.optionalInt("heartRateBpm"),
            caloriesKcal = objectJson.optionalDouble("caloriesKcal"),
            points = pointsFromJson(objectJson.optJSONArray("points")),
            elapsedBeforeActiveSegmentMs = restoredElapsedMs,
            activeSegmentStartedRealtimeMs = if (phase == WearRunPhase.Running) {
                nowRealtimeMs
            } else {
                null
            },
            pendingDraftCount = pendingDraftCount,
            ghostConfig = ghostConfig,
            isGhostRun = isGhostRun && ghostConfig != null,
            ghostFrame = objectJson.optionalObject("ghostFrame")?.let(::ghostFrameFromJson),
            statusMessage = objectJson.optionalString("statusMessage"),
            errorMessage = objectJson.optionalString("errorMessage"),
        )
    }

    private fun pointToJson(point: WearRunPoint): JSONObject {
        return JSONObject()
            .put("lat", point.latitude)
            .put("lng", point.longitude)
            .put("timestampRelMs", point.timestampRelMs)
            .put("paceSecPerKm", finiteDoubleOrNull(point.paceSecPerKm))
            .put("speedMps", finiteDoubleOrNull(point.speedMps))
            .put("horizontalAccuracyM", finiteDoubleOrNull(point.horizontalAccuracyM))
            .put("elevationM", finiteDoubleOrNull(point.elevationM))
            .put("heartRateBpm", point.heartRateBpm)
    }

    private fun pointsFromJson(pointsJson: JSONArray?): List<WearRunPoint> {
        if (pointsJson == null) return emptyList()
        return buildList {
            for (index in 0 until pointsJson.length()) {
                val point = pointsJson.getJSONObject(index)
                add(
                    WearRunPoint(
                        latitude = point.getDouble("lat"),
                        longitude = point.getDouble("lng"),
                        timestampRelMs = point.getLong("timestampRelMs"),
                        paceSecPerKm = point.optionalDouble("paceSecPerKm"),
                        speedMps = point.optionalDouble("speedMps"),
                        horizontalAccuracyM = point.optionalDouble("horizontalAccuracyM"),
                        elevationM = point.optionalDouble("elevationM"),
                        heartRateBpm = point.optionalInt("heartRateBpm"),
                    ),
                )
            }
        }
    }

    private fun ghostConfigToJson(config: WearGhostConfig): JSONObject {
        return JSONObject()
            .put("id", config.id)
            .put("durationMs", config.durationMs)
            .put("distanceM", config.distanceM)
            .put("sourceSummary", config.sourceSummary)
            .put("points", JSONArray(config.points.map(::pointToJson)))
    }

    private fun ghostFrameToJson(frame: WearGhostFrame): JSONObject {
        return JSONObject()
            .put("status", frame.status.name)
            .put("timeGapMs", frame.timeGapMs)
            .put("distanceGapM", frame.distanceGapM)
    }

    private fun ghostFrameFromJson(frameJson: JSONObject): WearGhostFrame {
        return WearGhostFrame(
            status = runCatching {
                WearGhostStatus.valueOf(frameJson.getString("status"))
            }.getOrDefault(WearGhostStatus.Unavailable),
            timeGapMs = frameJson.optLong("timeGapMs", 0L),
            distanceGapM = frameJson.optionalDouble("distanceGapM") ?: 0.0,
        )
    }

    private fun JSONObject.optionalObject(name: String): JSONObject? {
        if (isNull(name)) return null
        return optJSONObject(name)
    }

    private fun JSONObject.optionalString(name: String): String? {
        if (isNull(name)) return null
        return optString(name).takeIf { it.isNotBlank() }
    }

    private fun JSONObject.optionalLong(name: String): Long? {
        if (isNull(name)) return null
        return optLong(name)
    }

    private fun JSONObject.optionalDouble(name: String): Double? {
        if (isNull(name)) return null
        return optDouble(name).takeIf { it.isFinite() }
    }

    private fun JSONObject.optionalInt(name: String): Int? {
        if (isNull(name)) return null
        return optInt(name)
    }

    private fun finiteDoubleOrNull(value: Double?): Double? {
        return value?.takeIf { it.isFinite() }
    }
}

private class FileActiveRunPersistence(context: Context) : ActiveRunPersistence {
    private val file = File(context.filesDir, "wear_active_run_checkpoint.json")

    override fun read(): String? {
        if (!file.exists()) return null
        return file.readText(Charsets.UTF_8).takeIf { it.isNotBlank() }
    }

    override fun write(json: String) {
        file.parentFile?.mkdirs()
        file.writeText(json, Charsets.UTF_8)
    }

    override fun clear() {
        if (file.exists()) {
            file.delete()
        }
    }
}
