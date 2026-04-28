package kr.sjh.runlini.wear

data class PendingWearDraft(val id: String, val json: String)

interface PendingDraftPersistence {
    fun list(): List<PendingWearDraft>
    fun save(draft: PendingWearDraft)
    fun delete(id: String)
}

class PendingDraftQueue(private val persistence: PendingDraftPersistence) {
    fun enqueue(draft: WearRunDraftPayload): PendingWearDraft {
        val pending = PendingWearDraft(
            id = draft.id,
            json = WearRunDraftJsonMapper.toJson(draft),
        )
        persistence.save(pending)
        return pending
    }

    fun pending(): List<PendingWearDraft> {
        return persistence.list()
    }

    fun pendingCount(): Int {
        return pending().size
    }

    fun markSent(id: String) {
        persistence.delete(id)
    }

    fun markAcknowledged(id: String) {
        persistence.delete(id)
    }
}
