package kr.sjh.runlini.wear

import org.json.JSONObject
import org.junit.Assert.assertEquals
import org.junit.Test
import java.time.Instant

class WearRunDraftJsonMapperTest {
    @Test
    fun toJsonProducesDartCompatibleWatchRunDraft() {
        val draft = WearRunDraftPayload(
            id = "draft-1",
            startedAt = Instant.parse("2026-04-28T01:00:00Z"),
            endedAt = Instant.parse("2026-04-28T01:05:00Z"),
            durationMs = 300_000L,
            distanceM = 1_000.5,
            sourceDeviceName = "Pixel Watch",
            caloriesKcal = 72.4,
            averageCadenceSpm = 171.8,
            ghostSummary = WearRunGhostSummary(
                result = "ahead",
                timeGapMs = 12_000L,
                distanceGapM = 32.0,
                ghostSessionId = "ghost-1",
                ghostLabel = "한강 5K",
            ),
            points = listOf(
                WearRunPoint(
                    latitude = 37.1,
                    longitude = 127.2,
                    timestampRelMs = 3_000L,
                    paceSecPerKm = 300.0,
                    speedMps = 3.33,
                    horizontalAccuracyM = 5.5,
                    elevationM = 44.0,
                    heartRateBpm = 138,
                    cadenceSpm = 172.0,
                ),
            ),
        )

        val json = JSONObject(WearRunDraftJsonMapper.toJson(draft))
        val point = json.getJSONArray("points").getJSONObject(0)
        val ghost = json.getJSONObject("ghostSummary")

        assertEquals("draft-1", json.getString("id"))
        assertEquals("wearOs", json.getString("platform"))
        assertEquals("2026-04-28T01:00:00Z", json.getString("startedAt"))
        assertEquals("2026-04-28T01:05:00Z", json.getString("endedAt"))
        assertEquals(300_000L, json.getLong("durationMs"))
        assertEquals(1_000.5, json.getDouble("distanceM"), 0.01)
        assertEquals("draft-1", json.getString("externalWorkoutId"))
        assertEquals("Pixel Watch", json.getString("sourceDeviceName"))
        assertEquals(72.4, json.getDouble("caloriesKcal"), 0.01)
        assertEquals(171.8, json.getDouble("averageCadenceSpm"), 0.01)
        assertEquals("ahead", ghost.getString("result"))
        assertEquals(12_000L, ghost.getLong("timeGapMs"))
        assertEquals("ghost-1", ghost.getString("ghostSessionId"))
        assertEquals(37.1, point.getDouble("lat"), 0.0001)
        assertEquals(127.2, point.getDouble("lng"), 0.0001)
        assertEquals(3_000L, point.getLong("timestampRelMs"))
        assertEquals(172.0, point.getDouble("cadenceSpm"), 0.01)
        assertEquals("wearOs", point.getString("source"))
    }
}
