package kr.sjh.runlini.wear

import android.content.Context
import java.io.File

interface GhostConfigPersistence {
    fun read(): String?
    fun write(json: String)
    fun clear()
}

class WearGhostConfigStore(private val persistence: GhostConfigPersistence) {
    constructor(context: Context) : this(FileGhostConfigPersistence(context))

    fun current(): WearGhostConfig? {
        val json = persistence.read() ?: return null
        return runCatching {
            WearGhostConfigJsonMapper.fromJson(json)
        }.getOrNull()?.takeIf { config -> config.canRun }
    }

    fun save(json: String): WearGhostConfig? {
        val config = WearGhostConfigJsonMapper.fromJson(json)
        if (!config.canRun) {
            clear()
            return null
        }
        persistence.write(json)
        return config
    }

    fun clear() {
        persistence.clear()
    }
}

private class FileGhostConfigPersistence(context: Context) : GhostConfigPersistence {
    private val file = File(context.filesDir, "wear_ghost_config.json")

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
