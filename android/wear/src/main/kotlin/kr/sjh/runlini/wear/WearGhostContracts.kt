package kr.sjh.runlini.wear

import org.json.JSONArray
import org.json.JSONObject

enum class WearGhostStatus { Unavailable, Ahead, Behind, Level, OffRoute }

data class WearGhostConfig(
    val id: String,
    val durationMs: Long,
    val distanceM: Double,
    val sourceSummary: String,
    val points: List<WearRunPoint>,
) {
    val canRun: Boolean
        get() = points.size >= 2
}

data class WearGhostFrame(
    val status: WearGhostStatus,
    val timeGapMs: Long,
    val distanceGapM: Double,
)

data class WearRunGhostSummary(
    val result: String,
    val timeGapMs: Long,
    val distanceGapM: Double,
    val ghostSessionId: String,
    val ghostLabel: String,
) {
    fun toJson(): JSONObject {
        return JSONObject()
            .put("result", result)
            .put("timeGapMs", timeGapMs)
            .put("distanceGapM", distanceGapM)
            .put("ghostSessionId", ghostSessionId)
            .put("ghostLabel", ghostLabel)
    }

    companion object {
        fun from(config: WearGhostConfig?, frame: WearGhostFrame?): WearRunGhostSummary? {
            if (config == null || frame == null || frame.status == WearGhostStatus.Unavailable) {
                return null
            }
            return WearRunGhostSummary(
                result = when (frame.status) {
                    WearGhostStatus.Ahead -> "ahead"
                    WearGhostStatus.Behind -> "behind"
                    WearGhostStatus.Level -> "level"
                    WearGhostStatus.OffRoute -> "offRoute"
                    WearGhostStatus.Unavailable -> "level"
                },
                timeGapMs = frame.timeGapMs,
                distanceGapM = frame.distanceGapM,
                ghostSessionId = config.id,
                ghostLabel = config.sourceSummary,
            )
        }
    }
}

object WearGhostConfigJsonMapper {
    fun fromJson(json: String): WearGhostConfig {
        val objectJson = JSONObject(json)
        return WearGhostConfig(
            id = objectJson.getString("id"),
            durationMs = objectJson.getLong("durationMs"),
            distanceM = objectJson.getDouble("distanceM"),
            sourceSummary = objectJson.getString("sourceSummary"),
            points = pointsFromJson(objectJson.getJSONArray("points")),
        )
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

    private fun JSONObject.optionalDouble(name: String): Double? {
        if (isNull(name)) return null
        return optDouble(name).takeIf { it.isFinite() }
    }

    private fun JSONObject.optionalInt(name: String): Int? {
        if (isNull(name)) return null
        return optInt(name)
    }
}
