package kr.sjh.runlini.wear

import android.content.Context
import org.json.JSONArray
import org.json.JSONObject
import java.io.File

interface GhostConfigPersistence {
    fun read(): String?
    fun write(json: String)
    fun clear()
    fun readCache(): String? = null
    fun writeCache(json: String) = write(json)
    fun clearCache() = clear()
}

class WearGhostConfigStore(private val persistence: GhostConfigPersistence) {
    constructor(context: Context) : this(FileGhostConfigPersistence(context))

    fun current(): WearGhostConfig? {
        return loadCache().active
    }

    fun cached(): List<WearGhostConfig> {
        return loadCache().configs
    }

    fun save(json: String): WearGhostConfig? {
        val config = WearGhostConfigJsonMapper.fromJson(json)
        if (!config.canRun) {
            clear()
            return null
        }
        val existing = cached().filterNot { cached -> cached.id == config.id }
        val configs = (listOf(config) + existing).take(MaxCachedGhosts)
        persistence.writeCache(
            WearGhostConfigCacheJsonMapper.toJson(
                WearGhostConfigCache(activeId = config.id, configs = configs),
            ),
        )
        return config
    }

    fun select(id: String): WearGhostConfig? {
        val configs = cached()
        val selected = configs.firstOrNull { config -> config.id == id } ?: return null
        val reordered = (listOf(selected) + configs.filterNot { config -> config.id == id })
            .take(MaxCachedGhosts)
        persistence.writeCache(
            WearGhostConfigCacheJsonMapper.toJson(
                WearGhostConfigCache(activeId = selected.id, configs = reordered),
            ),
        )
        return selected
    }

    fun replace(configs: List<WearGhostConfig>, activeId: String?): WearGhostConfig? {
        val cache = WearGhostConfigCache(activeId = activeId, configs = configs).normalized()
        if (cache.configs.isEmpty()) {
            clear()
            return null
        }
        persistence.writeCache(WearGhostConfigCacheJsonMapper.toJson(cache))
        persistence.clear()
        return cache.active
    }

    fun clear() {
        persistence.clear()
        persistence.clearCache()
    }

    private fun loadCache(): WearGhostConfigCache {
        val rawJsons = listOfNotNull(persistence.readCache(), persistence.read())
            .filter { json -> json.isNotBlank() }

        for (json in rawJsons) {
            val cache = runCatching {
                WearGhostConfigCacheJsonMapper.fromJson(json)
            }.getOrNull()
            if (cache != null && cache.configs.isNotEmpty()) {
                return cache.normalized()
            }
        }

        for (json in rawJsons) {
            val legacy = runCatching {
                WearGhostConfigJsonMapper.fromJson(json)
            }.getOrNull()?.takeIf { config -> config.canRun }
            if (legacy != null) {
                val cache = WearGhostConfigCache(
                    activeId = legacy.id,
                    configs = listOf(legacy),
                )
                persistence.writeCache(WearGhostConfigCacheJsonMapper.toJson(cache))
                return cache
            }
        }

        return WearGhostConfigCache()
    }

    private companion object {
        const val MaxCachedGhosts = 3
    }
}

data class WearGhostConfigCache(
    val activeId: String? = null,
    val configs: List<WearGhostConfig> = emptyList(),
) {
    val active: WearGhostConfig?
        get() = configs.firstOrNull { config -> config.id == activeId } ?: configs.firstOrNull()

    fun normalized(): WearGhostConfigCache {
        val runnable = configs
            .filter { config -> config.canRun }
            .distinctBy { config -> config.id }
            .take(3)
        return WearGhostConfigCache(
            activeId = activeId?.takeIf { id -> runnable.any { config -> config.id == id } }
                ?: runnable.firstOrNull()?.id,
            configs = runnable,
        )
    }
}

object WearGhostConfigCacheJsonMapper {
    fun toJson(cache: WearGhostConfigCache): String {
        val normalized = cache.normalized()
        return JSONObject()
            .put("activeId", normalized.activeId)
            .put(
                "configs",
                JSONArray(
                    normalized.configs.map { config ->
                        WearGhostConfigJsonMapper.toJsonObject(config)
                    },
                ),
            )
            .toString()
    }

    fun fromJson(json: String): WearGhostConfigCache {
        val objectJson = JSONObject(json)
        val configsJson = objectJson.getJSONArray("configs")
        val configs = buildList {
            for (index in 0 until configsJson.length()) {
                add(WearGhostConfigJsonMapper.fromJson(configsJson.getJSONObject(index).toString()))
            }
        }
        return WearGhostConfigCache(
            activeId = objectJson.optString("activeId").takeIf { id -> id.isNotBlank() },
            configs = configs,
        ).normalized()
    }
}

private class FileGhostConfigPersistence(context: Context) : GhostConfigPersistence {
    private val legacyFile = File(context.filesDir, "wear_ghost_config.json")
    private val cacheFile = File(context.filesDir, "wear_ghost_config_cache.json")

    override fun read(): String? {
        if (!legacyFile.exists()) return null
        return legacyFile.readText(Charsets.UTF_8).takeIf { it.isNotBlank() }
    }

    override fun write(json: String) {
        legacyFile.parentFile?.mkdirs()
        legacyFile.writeText(json, Charsets.UTF_8)
    }

    override fun clear() {
        if (legacyFile.exists()) {
            legacyFile.delete()
        }
    }

    override fun readCache(): String? {
        if (!cacheFile.exists()) return null
        return cacheFile.readText(Charsets.UTF_8).takeIf { it.isNotBlank() }
    }

    override fun writeCache(json: String) {
        cacheFile.parentFile?.mkdirs()
        cacheFile.writeText(json, Charsets.UTF_8)
    }

    override fun clearCache() {
        if (cacheFile.exists()) {
            cacheFile.delete()
        }
    }
}
