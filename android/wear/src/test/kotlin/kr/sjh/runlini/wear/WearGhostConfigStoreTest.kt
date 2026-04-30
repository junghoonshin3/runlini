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
    fun storeKeepsThreeMostRecentGhostConfigs() {
        val store = WearGhostConfigStore(FakeGhostConfigPersistence())

        store.save(ghostConfigJson(id = "ghost-1", sourceSummary = "첫 번째"))
        store.save(ghostConfigJson(id = "ghost-2", sourceSummary = "두 번째"))
        store.save(ghostConfigJson(id = "ghost-3", sourceSummary = "세 번째"))
        store.save(ghostConfigJson(id = "ghost-4", sourceSummary = "네 번째"))

        assertEquals(listOf("ghost-4", "ghost-3", "ghost-2"), store.cached().map { it.id })
        assertEquals("ghost-4", store.current()?.id)
    }

    @Test
    fun storeUpdatesDuplicateConfigWithoutCreatingAnotherEntry() {
        val store = WearGhostConfigStore(FakeGhostConfigPersistence())

        store.save(ghostConfigJson(id = "ghost-1", sourceSummary = "이전"))
        store.save(ghostConfigJson(id = "ghost-2", sourceSummary = "둘"))
        store.save(ghostConfigJson(id = "ghost-1", sourceSummary = "갱신"))

        assertEquals(listOf("ghost-1", "ghost-2"), store.cached().map { it.id })
        assertEquals("갱신", store.current()?.sourceSummary)
    }

    @Test
    fun storeSelectsGhostAndMovesItToFront() {
        val store = WearGhostConfigStore(FakeGhostConfigPersistence())
        store.save(ghostConfigJson(id = "ghost-1"))
        store.save(ghostConfigJson(id = "ghost-2"))

        val selected = store.select("ghost-1")

        assertEquals("ghost-1", selected?.id)
        assertEquals(listOf("ghost-1", "ghost-2"), store.cached().map { it.id })
        assertEquals("ghost-1", store.current()?.id)
    }

    @Test
    fun storeMigratesLegacySingleConfigIntoCache() {
        val persistence = FakeGhostConfigPersistence()
        persistence.write(ghostConfigJson(id = "legacy"))
        val store = WearGhostConfigStore(persistence)

        assertEquals("legacy", store.current()?.id)
        assertEquals(listOf("legacy"), store.cached().map { it.id })
    }

    @Test
    fun storePreservesPointTimestamps() {
        val store = WearGhostConfigStore(FakeGhostConfigPersistence())

        store.save(ghostConfigJson())

        assertEquals(listOf(0L, 600_000L), store.current()?.points?.map { it.timestampRelMs })
    }

    @Test
    fun storeReplacesCacheFromBatchAndKeepsActiveId() {
        val store = WearGhostConfigStore(FakeGhostConfigPersistence())
        store.save(ghostConfigJson(id = "old"))
        val configs = listOf(
            WearGhostConfigJsonMapper.fromJson(ghostConfigJson(id = "ghost-1")),
            WearGhostConfigJsonMapper.fromJson(ghostConfigJson(id = "ghost-2")),
            WearGhostConfigJsonMapper.fromJson(ghostConfigJson(id = "ghost-3")),
            WearGhostConfigJsonMapper.fromJson(ghostConfigJson(id = "ghost-4")),
        )

        val active = store.replace(configs, activeId = "ghost-2")

        assertEquals("ghost-2", active?.id)
        assertEquals(listOf("ghost-1", "ghost-2", "ghost-3"), store.cached().map { it.id })
        assertEquals("ghost-2", store.current()?.id)
    }

    @Test
    fun storeReplaceClearsCacheWhenBatchIsEmpty() {
        val store = WearGhostConfigStore(FakeGhostConfigPersistence())
        store.save(ghostConfigJson())

        val active = store.replace(emptyList(), activeId = null)

        assertNull(active)
        assertNull(store.current())
        assertEquals(emptyList<String>(), store.cached().map { it.id })
    }

    @Test
    fun batchHandlerReplacesCacheAndPreservesTimestamps() {
        val store = WearGhostConfigStore(FakeGhostConfigPersistence())
        val batchJson = WearGhostConfigCacheJsonMapper.toJson(
            WearGhostConfigCache(
                activeId = "ghost-2",
                configs = listOf(
                    WearGhostConfigJsonMapper.fromJson(ghostConfigJson(id = "ghost-1")),
                    WearGhostConfigJsonMapper.fromJson(ghostConfigJson(id = "ghost-2")),
                ),
            ),
        )

        PhoneGhostConfigHandler.handle(
            path = PhoneGhostConfigHandler.ConfigsPath,
            enabled = true,
            json = batchJson,
            store = store,
        )

        assertEquals(listOf("ghost-1", "ghost-2"), store.cached().map { it.id })
        assertEquals("ghost-2", store.current()?.id)
        assertEquals(listOf(0L, 600_000L), store.current()?.points?.map { it.timestampRelMs })
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
    fun batchHandlerKeepsLegacySingleConfigPathWorking() {
        val store = WearGhostConfigStore(FakeGhostConfigPersistence())

        PhoneGhostConfigHandler.handle(
            path = PhoneGhostConfigHandler.ConfigPath,
            enabled = true,
            json = ghostConfigJson(id = "single"),
            store = store,
        )

        assertEquals("single", store.current()?.id)
    }

    @Test
    fun batchHandlerClearsCacheWhenDisabled() {
        val store = WearGhostConfigStore(FakeGhostConfigPersistence())
        store.save(ghostConfigJson())

        PhoneGhostConfigHandler.handle(
            path = PhoneGhostConfigHandler.ConfigsPath,
            enabled = false,
            json = null,
            store = store,
        )

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

    private fun ghostConfigJson(
        id: String = "ghost-1",
        sourceSummary: String = "한강 5K",
        points: String = twoPointsJson(),
    ): String {
        return """
            {
              "id": "$id",
              "startedAt": "2026-04-28T00:00:00.000Z",
              "durationMs": 600000,
              "distanceM": 2000.0,
              "sourceSummary": "$sourceSummary",
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
    private var cacheJson: String? = null

    override fun read(): String? = json

    override fun write(json: String) {
        this.json = json
    }

    override fun clear() {
        json = null
    }

    override fun readCache(): String? = cacheJson

    override fun writeCache(json: String) {
        cacheJson = json
    }

    override fun clearCache() {
        cacheJson = null
    }
}
