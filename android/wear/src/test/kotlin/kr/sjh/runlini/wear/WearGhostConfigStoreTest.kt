package kr.sjh.runlini.wear

import org.junit.Assert.assertEquals
import org.junit.Assert.assertNull
import org.junit.Test

class WearGhostConfigStoreTest {
    @Test
    fun storeSavesAndLoadsRunnableGhostConfig() {
        val persistence = FakeGhostConfigPersistence()
        val store = WearGhostConfigStore(persistence)

        val config = store.save(ghostConfigJson())

        assertEquals("ghost-1", config?.id)
        assertEquals("한강 5K", store.current()?.sourceSummary)
        assertEquals(2, store.current()?.points?.size)
    }

    @Test
    fun storeClearsConfigWithInsufficientRoute() {
        val persistence = FakeGhostConfigPersistence()
        val store = WearGhostConfigStore(persistence)

        val config = store.save(ghostConfigJson(points = onePointJson()))

        assertNull(config)
        assertNull(store.current())
    }

    @Test
    fun handlerClearsOnlyGhostConfigPathWhenDisabled() {
        val persistence = FakeGhostConfigPersistence()
        val store = WearGhostConfigStore(persistence)
        store.save(ghostConfigJson())

        PhoneGhostConfigHandler.handle(
            path = PhoneGhostConfigHandler.ConfigPath,
            enabled = false,
            json = null,
            store = store,
        )

        assertNull(store.current())
    }

    private fun ghostConfigJson(points: String = twoPointsJson()): String {
        return """
            {
              "id": "ghost-1",
              "startedAt": "2026-04-28T00:00:00.000Z",
              "durationMs": 600000,
              "distanceM": 2000.0,
              "sourceSummary": "한강 5K",
              "points": $points
            }
        """.trimIndent()
    }

    private fun twoPointsJson(): String {
        return """
            [
              {"lat":37.0,"lng":127.0,"timestampRelMs":0,"source":"deviceGps"},
              {"lat":37.001,"lng":127.001,"timestampRelMs":600000,"source":"deviceGps"}
            ]
        """.trimIndent()
    }

    private fun onePointJson(): String {
        return """
            [
              {"lat":37.0,"lng":127.0,"timestampRelMs":0,"source":"deviceGps"}
            ]
        """.trimIndent()
    }
}

private class FakeGhostConfigPersistence : GhostConfigPersistence {
    private var json: String? = null

    override fun read(): String? = json

    override fun write(json: String) {
        this.json = json
    }

    override fun clear() {
        json = null
    }
}
