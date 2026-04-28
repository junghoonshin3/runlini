package kr.sjh.runlini.wear

import android.content.Context
import java.io.File

class WearPendingDraftStore(context: Context) : PendingDraftPersistence {
    private val directory = File(context.filesDir, "wear_pending_drafts")

    override fun list(): List<PendingWearDraft> {
        if (!directory.exists()) return emptyList()
        return directory.listFiles()
            ?.filter { file -> file.extension == "json" }
            ?.mapNotNull { file ->
                runCatching {
                    PendingWearDraft(
                        id = file.nameWithoutExtension,
                        json = file.readText(),
                    )
                }.getOrNull()
            }
            ?.sortedBy { draft -> draft.id }
            ?: emptyList()
    }

    override fun save(draft: PendingWearDraft) {
        directory.mkdirs()
        draftFile(draft.id).writeText(draft.json)
    }

    override fun delete(id: String) {
        draftFile(id).delete()
    }

    private fun draftFile(id: String): File {
        val safeId = id.replace(Regex("[^A-Za-z0-9._-]"), "_")
        return File(directory, "$safeId.json")
    }
}
