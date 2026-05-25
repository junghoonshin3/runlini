package kr.sjh.runlini.wear

import org.junit.Assert.assertEquals
import org.junit.Assert.assertNull
import org.junit.Test

class WearRecordRaceConfigStoreTest {
    @Test
    fun storeSavesAndLoadsRunnableRecordRaceConfig() {
        val persistence = FakeRecordRaceConfigPersistence()
        val store = WearRecordRaceConfigStore(persistence)

        val config = store.save(recordRaceConfigJson())

        assertEquals("record-race-1", config?.id)
        assertEquals("한강 5K", store.current()?.sourceSummary)
        assertEquals(2, store.current()?.points?.size)
    }

    @Test
    fun storeKeepsThreeMostRecentRecordRaceConfigs() {
        val store = WearRecordRaceConfigStore(FakeRecordRaceConfigPersistence())

        store.save(recordRaceConfigJson(id = "record-race-1", sourceSummary = "첫 번째"))
        store.save(recordRaceConfigJson(id = "record-race-2", sourceSummary = "두 번째"))
        store.save(recordRaceConfigJson(id = "record-race-3", sourceSummary = "세 번째"))
        store.save(recordRaceConfigJson(id = "record-race-4", sourceSummary = "네 번째"))

        assertEquals(listOf("record-race-4", "record-race-3", "record-race-2"), store.cached().map { it.id })
        assertEquals("record-race-4", store.current()?.id)
    }

    @Test
    fun storeUpdatesDuplicateConfigWithoutCreatingAnotherEntry() {
        val store = WearRecordRaceConfigStore(FakeRecordRaceConfigPersistence())

        store.save(recordRaceConfigJson(id = "record-race-1", sourceSummary = "이전"))
        store.save(recordRaceConfigJson(id = "record-race-2", sourceSummary = "둘"))
        store.save(recordRaceConfigJson(id = "record-race-1", sourceSummary = "갱신"))

        assertEquals(listOf("record-race-1", "record-race-2"), store.cached().map { it.id })
        assertEquals("갱신", store.current()?.sourceSummary)
    }

    @Test
    fun storeSelectsRecordRaceAndMovesItToFront() {
        val store = WearRecordRaceConfigStore(FakeRecordRaceConfigPersistence())
        store.save(recordRaceConfigJson(id = "record-race-1"))
        store.save(recordRaceConfigJson(id = "record-race-2"))

        val selected = store.select("record-race-1")

        assertEquals("record-race-1", selected?.id)
        assertEquals(listOf("record-race-1", "record-race-2"), store.cached().map { it.id })
        assertEquals("record-race-1", store.current()?.id)
    }

    @Test
    fun storeMigratesLegacySingleConfigIntoCache() {
        val persistence = FakeRecordRaceConfigPersistence()
        persistence.write(recordRaceConfigJson(id = "legacy"))
        val store = WearRecordRaceConfigStore(persistence)

        assertEquals("legacy", store.current()?.id)
        assertEquals(listOf("legacy"), store.cached().map { it.id })
    }

    @Test
    fun storePreservesPointTimestamps() {
        val store = WearRecordRaceConfigStore(FakeRecordRaceConfigPersistence())

        store.save(recordRaceConfigJson())

        assertEquals(listOf(0L, 600_000L), store.current()?.points?.map { it.timestampRelMs })
    }

    @Test
    fun storeReplacesCacheFromBatchAndKeepsActiveId() {
        val store = WearRecordRaceConfigStore(FakeRecordRaceConfigPersistence())
        store.save(recordRaceConfigJson(id = "old"))
        val configs = listOf(
            WearRecordRaceConfigJsonMapper.fromJson(recordRaceConfigJson(id = "record-race-1")),
            WearRecordRaceConfigJsonMapper.fromJson(recordRaceConfigJson(id = "record-race-2")),
            WearRecordRaceConfigJsonMapper.fromJson(recordRaceConfigJson(id = "record-race-3")),
            WearRecordRaceConfigJsonMapper.fromJson(recordRaceConfigJson(id = "record-race-4")),
        )

        val active = store.replace(configs, activeId = "record-race-2")

        assertEquals("record-race-2", active?.id)
        assertEquals(listOf("record-race-1", "record-race-2", "record-race-3"), store.cached().map { it.id })
        assertEquals("record-race-2", store.current()?.id)
    }

    @Test
    fun storeReplaceClearsCacheWhenBatchIsEmpty() {
        val store = WearRecordRaceConfigStore(FakeRecordRaceConfigPersistence())
        store.save(recordRaceConfigJson())

        val active = store.replace(emptyList(), activeId = null)

        assertNull(active)
        assertNull(store.current())
        assertEquals(emptyList<String>(), store.cached().map { it.id })
    }

    @Test
    fun batchHandlerReplacesCacheAndPreservesTimestamps() {
        val store = WearRecordRaceConfigStore(FakeRecordRaceConfigPersistence())
        val batchJson = WearRecordRaceConfigCacheJsonMapper.toJson(
            WearRecordRaceConfigCache(
                activeId = "record-race-2",
                configs = listOf(
                    WearRecordRaceConfigJsonMapper.fromJson(recordRaceConfigJson(id = "record-race-1")),
                    WearRecordRaceConfigJsonMapper.fromJson(recordRaceConfigJson(id = "record-race-2")),
                ),
            ),
        )

        PhoneRecordRaceConfigHandler.handle(
            path = PhoneRecordRaceConfigHandler.ConfigsPath,
            enabled = true,
            json = batchJson,
            store = store,
        )

        assertEquals(listOf("record-race-1", "record-race-2"), store.cached().map { it.id })
        assertEquals("record-race-2", store.current()?.id)
        assertEquals(listOf(0L, 600_000L), store.current()?.points?.map { it.timestampRelMs })
    }

    @Test
    fun storeClearsConfigWithInsufficientRoute() {
        val persistence = FakeRecordRaceConfigPersistence()
        val store = WearRecordRaceConfigStore(persistence)

        val config = store.save(recordRaceConfigJson(points = onePointJson()))

        assertNull(config)
        assertNull(store.current())
    }

    @Test
    fun handlerKeepsSingleConfigPathWorking() {
        val store = WearRecordRaceConfigStore(FakeRecordRaceConfigPersistence())

        PhoneRecordRaceConfigHandler.handle(
            path = PhoneRecordRaceConfigHandler.ConfigPath,
            enabled = true,
            json = recordRaceConfigJson(id = "single"),
            store = store,
        )

        assertEquals("single", store.current()?.id)
    }

    @Test
    fun handlerKeepsLegacySingleConfigPathWorking() {
        val store = WearRecordRaceConfigStore(FakeRecordRaceConfigPersistence())

        PhoneRecordRaceConfigHandler.handle(
            path = "/runlini/phone/ghost_config",
            enabled = true,
            json = recordRaceConfigJson(id = "legacy-single"),
            store = store,
        )

        assertEquals("legacy-single", store.current()?.id)
    }

    @Test
    fun handlerKeepsLegacyBatchConfigPathWorking() {
        val store = WearRecordRaceConfigStore(FakeRecordRaceConfigPersistence())
        val batchJson = WearRecordRaceConfigCacheJsonMapper.toJson(
            WearRecordRaceConfigCache(
                activeId = "legacy-batch-2",
                configs = listOf(
                    WearRecordRaceConfigJsonMapper.fromJson(recordRaceConfigJson(id = "legacy-batch-1")),
                    WearRecordRaceConfigJsonMapper.fromJson(recordRaceConfigJson(id = "legacy-batch-2")),
                ),
            ),
        )

        PhoneRecordRaceConfigHandler.handle(
            path = "/runlini/phone/ghost_configs",
            enabled = true,
            json = batchJson,
            store = store,
        )

        assertEquals(listOf("legacy-batch-1", "legacy-batch-2"), store.cached().map { it.id })
        assertEquals("legacy-batch-2", store.current()?.id)
    }

    @Test
    fun batchHandlerClearsCacheWhenDisabled() {
        val store = WearRecordRaceConfigStore(FakeRecordRaceConfigPersistence())
        store.save(recordRaceConfigJson())

        PhoneRecordRaceConfigHandler.handle(
            path = PhoneRecordRaceConfigHandler.ConfigsPath,
            enabled = false,
            json = null,
            store = store,
        )

        assertNull(store.current())
    }

    @Test
    fun handlerClearsOnlyRecordRaceConfigPathWhenDisabled() {
        val persistence = FakeRecordRaceConfigPersistence()
        val store = WearRecordRaceConfigStore(persistence)
        store.save(recordRaceConfigJson())

        PhoneRecordRaceConfigHandler.handle(
            path = PhoneRecordRaceConfigHandler.ConfigPath,
            enabled = false,
            json = null,
            store = store,
        )

        assertNull(store.current())
    }

    private fun recordRaceConfigJson(
        id: String = "record-race-1",
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

private class FakeRecordRaceConfigPersistence : RecordRaceConfigPersistence {
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
