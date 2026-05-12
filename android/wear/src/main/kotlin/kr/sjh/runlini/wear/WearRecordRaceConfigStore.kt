package kr.sjh.runlini.wear

import android.content.Context
import org.json.JSONArray
import org.json.JSONObject
import java.io.File

interface RecordRaceConfigPersistence {
    fun read(): String?
    fun write(json: String)
    fun clear()
    fun readCache(): String? = null
    fun writeCache(json: String) = write(json)
    fun clearCache() = clear()
}

class WearRecordRaceConfigStore(private val persistence: RecordRaceConfigPersistence) {
    constructor(context: Context) : this(FileRecordRaceConfigPersistence(context))

    fun current(): WearRecordRaceConfig? {
        return loadCache().active
    }

    fun cached(): List<WearRecordRaceConfig> {
        return loadCache().configs
    }

    fun save(json: String): WearRecordRaceConfig? {
        val config = WearRecordRaceConfigJsonMapper.fromJson(json)
        if (!config.canRun) {
            clear()
            return null
        }
        val existing = cached().filterNot { cached -> cached.id == config.id }
        val configs = (listOf(config) + existing).take(MaxCachedRecordRaces)
        persistence.writeCache(
            WearRecordRaceConfigCacheJsonMapper.toJson(
                WearRecordRaceConfigCache(activeId = config.id, configs = configs),
            ),
        )
        return config
    }

    fun select(id: String): WearRecordRaceConfig? {
        val configs = cached()
        val selected = configs.firstOrNull { config -> config.id == id } ?: return null
        val reordered = (listOf(selected) + configs.filterNot { config -> config.id == id })
            .take(MaxCachedRecordRaces)
        persistence.writeCache(
            WearRecordRaceConfigCacheJsonMapper.toJson(
                WearRecordRaceConfigCache(activeId = selected.id, configs = reordered),
            ),
        )
        return selected
    }

    fun replace(configs: List<WearRecordRaceConfig>, activeId: String?): WearRecordRaceConfig? {
        val cache = WearRecordRaceConfigCache(activeId = activeId, configs = configs).normalized()
        if (cache.configs.isEmpty()) {
            clear()
            return null
        }
        persistence.writeCache(WearRecordRaceConfigCacheJsonMapper.toJson(cache))
        persistence.clear()
        return cache.active
    }

    fun clear() {
        persistence.clear()
        persistence.clearCache()
    }

    private fun loadCache(): WearRecordRaceConfigCache {
        val rawJsons = listOfNotNull(persistence.readCache(), persistence.read())
            .filter { json -> json.isNotBlank() }

        for (json in rawJsons) {
            val cache = runCatching {
                WearRecordRaceConfigCacheJsonMapper.fromJson(json)
            }.getOrNull()
            if (cache != null && cache.configs.isNotEmpty()) {
                return cache.normalized()
            }
        }

        for (json in rawJsons) {
            val legacy = runCatching {
                WearRecordRaceConfigJsonMapper.fromJson(json)
            }.getOrNull()?.takeIf { config -> config.canRun }
            if (legacy != null) {
                val cache = WearRecordRaceConfigCache(
                    activeId = legacy.id,
                    configs = listOf(legacy),
                )
                persistence.writeCache(WearRecordRaceConfigCacheJsonMapper.toJson(cache))
                return cache
            }
        }

        return WearRecordRaceConfigCache()
    }

    private companion object {
        const val MaxCachedRecordRaces = 3
    }
}

data class WearRecordRaceConfigCache(
    val activeId: String? = null,
    val configs: List<WearRecordRaceConfig> = emptyList(),
) {
    val active: WearRecordRaceConfig?
        get() = configs.firstOrNull { config -> config.id == activeId } ?: configs.firstOrNull()

    fun normalized(): WearRecordRaceConfigCache {
        val runnable = configs
            .filter { config -> config.canRun }
            .distinctBy { config -> config.id }
            .take(3)
        return WearRecordRaceConfigCache(
            activeId = activeId?.takeIf { id -> runnable.any { config -> config.id == id } }
                ?: runnable.firstOrNull()?.id,
            configs = runnable,
        )
    }
}

object WearRecordRaceConfigCacheJsonMapper {
    fun toJson(cache: WearRecordRaceConfigCache): String {
        val normalized = cache.normalized()
        return JSONObject()
            .put("activeId", normalized.activeId)
            .put(
                "configs",
                JSONArray(
                    normalized.configs.map { config ->
                        WearRecordRaceConfigJsonMapper.toJsonObject(config)
                    },
                ),
            )
            .toString()
    }

    fun fromJson(json: String): WearRecordRaceConfigCache {
        val objectJson = JSONObject(json)
        val configsJson = objectJson.getJSONArray("configs")
        val configs = buildList {
            for (index in 0 until configsJson.length()) {
                add(WearRecordRaceConfigJsonMapper.fromJson(configsJson.getJSONObject(index).toString()))
            }
        }
        return WearRecordRaceConfigCache(
            activeId = objectJson.optString("activeId").takeIf { id -> id.isNotBlank() },
            configs = configs,
        ).normalized()
    }
}

private class FileRecordRaceConfigPersistence(context: Context) : RecordRaceConfigPersistence {
    private val file = File(context.filesDir, "wear_record_race_config.json")
    private val legacyFile = File(context.filesDir, "wear_ghost_config.json")
    private val cacheFile = File(context.filesDir, "wear_record_race_config_cache.json")
    private val legacyCacheFile = File(context.filesDir, "wear_ghost_config_cache.json")

    override fun read(): String? {
        return readText(file) ?: readText(legacyFile)
    }

    override fun write(json: String) {
        file.parentFile?.mkdirs()
        file.writeText(json, Charsets.UTF_8)
    }

    override fun clear() {
        if (file.exists()) {
            file.delete()
        }
        if (legacyFile.exists()) {
            legacyFile.delete()
        }
    }

    override fun readCache(): String? {
        return readText(cacheFile) ?: readText(legacyCacheFile)
    }

    override fun writeCache(json: String) {
        cacheFile.parentFile?.mkdirs()
        cacheFile.writeText(json, Charsets.UTF_8)
    }

    override fun clearCache() {
        if (cacheFile.exists()) {
            cacheFile.delete()
        }
        if (legacyCacheFile.exists()) {
            legacyCacheFile.delete()
        }
    }

    private fun readText(file: File): String? {
        if (!file.exists()) return null
        return file.readText(Charsets.UTF_8).takeIf { it.isNotBlank() }
    }
}
