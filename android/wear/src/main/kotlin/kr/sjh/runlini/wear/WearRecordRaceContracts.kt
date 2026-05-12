package kr.sjh.runlini.wear

import org.json.JSONArray
import org.json.JSONObject

enum class WearRecordRaceStatus { Unavailable, Ahead, Behind, Level, OffRoute }

enum class WearRecordRaceProjectionSource { Global, Tracked, Held }

data class WearRecordRaceConfig(
    val id: String,
    val durationMs: Long,
    val distanceM: Double,
    val sourceSummary: String,
    val points: List<WearRunPoint>,
) {
    val canRun: Boolean
        get() = points.size >= 2
}

data class WearRecordRaceFrame(
    val status: WearRecordRaceStatus,
    val timeGapMs: Long,
    val distanceGapM: Double,
    val routeProgress: Double = 0.0,
    val distanceToFinishM: Double = Double.POSITIVE_INFINITY,
    val distanceFromRouteM: Double = Double.POSITIVE_INFINITY,
    val totalRouteDistanceM: Double = 0.0,
    val distanceToFinishPointM: Double = Double.POSITIVE_INFINITY,
    val startConfirmed: Boolean = true,
    val startCandidateCount: Int = 0,
    val startLastEvaluatedPointCount: Int = 0,
    val trackedDistanceAlongRouteM: Double? = null,
    val projectionSource: WearRecordRaceProjectionSource = WearRecordRaceProjectionSource.Global,
)

data class WearRunRecordRaceSummary(
    val result: String,
    val timeGapMs: Long,
    val distanceGapM: Double,
    val recordRaceSessionId: String,
    val recordRaceLabel: String,
) {
    fun toJson(): JSONObject {
        return JSONObject()
            .put("result", result)
            .put("timeGapMs", timeGapMs)
            .put("distanceGapM", distanceGapM)
            .put("recordRaceSessionId", recordRaceSessionId)
            .put("recordRaceLabel", recordRaceLabel)
    }

    companion object {
        fun from(config: WearRecordRaceConfig?, frame: WearRecordRaceFrame?): WearRunRecordRaceSummary? {
            if (config == null || frame == null || frame.status == WearRecordRaceStatus.Unavailable) {
                return null
            }
            return WearRunRecordRaceSummary(
                result = when (frame.status) {
                    WearRecordRaceStatus.Ahead -> "ahead"
                    WearRecordRaceStatus.Behind -> "behind"
                    WearRecordRaceStatus.Level -> "level"
                    WearRecordRaceStatus.OffRoute -> "offRoute"
                    WearRecordRaceStatus.Unavailable -> "level"
                },
                timeGapMs = frame.timeGapMs,
                distanceGapM = frame.distanceGapM,
                recordRaceSessionId = config.id,
                recordRaceLabel = config.sourceSummary,
            )
        }
    }
}

object WearRecordRaceConfigJsonMapper {
    fun fromJson(json: String): WearRecordRaceConfig {
        val objectJson = JSONObject(json)
        return WearRecordRaceConfig(
            id = objectJson.getString("id"),
            durationMs = objectJson.getLong("durationMs"),
            distanceM = objectJson.getDouble("distanceM"),
            sourceSummary = objectJson.getString("sourceSummary"),
            points = pointsFromJson(objectJson.getJSONArray("points")),
        )
    }

    fun toJsonObject(config: WearRecordRaceConfig): JSONObject {
        return JSONObject()
            .put("id", config.id)
            .put("durationMs", config.durationMs)
            .put("distanceM", config.distanceM)
            .put("sourceSummary", config.sourceSummary)
            .put("points", JSONArray(config.points.map(::pointToJson)))
    }

    private fun pointsFromJson(pointsJson: JSONArray): List<WearRunPoint> {
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
    }

    private fun JSONObject.optionalDouble(name: String): Double? {
        if (isNull(name)) return null
        return optDouble(name).takeIf { it.isFinite() }
    }

    private fun JSONObject.optionalInt(name: String): Int? {
        if (isNull(name)) return null
        return optInt(name)
    }
}
