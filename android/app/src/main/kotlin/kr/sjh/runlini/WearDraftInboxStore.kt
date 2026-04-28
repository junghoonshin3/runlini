package kr.sjh.runlini

import android.content.Context
import java.io.File

class WearDraftInboxStore(context: Context) {
    private val directory = File(context.filesDir, DirectoryName)

    fun pending(): List<Map<String, String>> {
        synchronized(Lock) {
            if (!directory.exists()) return emptyList()
            return directory.listFiles()
                ?.filter { file -> file.extension == "json" }
                ?.mapNotNull { file ->
                    runCatching {
                        mapOf(
                            "id" to file.nameWithoutExtension,
                            "json" to file.readText(Charsets.UTF_8),
                        )
                    }.getOrNull()
                }
                ?.sortedBy { draft -> draft["id"] }
                ?: emptyList()
        }
    }

    fun save(id: String, json: String) {
        synchronized(Lock) {
            directory.mkdirs()
            draftFile(id).writeText(json, Charsets.UTF_8)
        }
    }

    fun ack(id: String) {
        synchronized(Lock) {
            draftFile(id).delete()
        }
    }

    private fun draftFile(id: String): File {
        val safeId = id.replace(Regex("[^A-Za-z0-9._-]"), "_")
        return File(directory, "$safeId.json")
    }

    companion object {
        private const val DirectoryName = "wear_draft_inbox"
        private val Lock = Any()
    }
}
