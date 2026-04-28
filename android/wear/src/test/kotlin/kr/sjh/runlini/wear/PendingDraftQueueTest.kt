package kr.sjh.runlini.wear

import org.junit.Assert.assertEquals
import org.junit.Assert.assertTrue
import org.junit.Test
import kotlinx.coroutines.runBlocking
import java.time.Instant

class PendingDraftQueueTest {
    @Test
    fun enqueueKeepsDraftUntilMarkedSent() {
        val persistence = MemoryDraftPersistence()
        val queue = PendingDraftQueue(persistence)
        val draft = WearRunDraftPayload(
            id = "draft-1",
            startedAt = Instant.parse("2026-04-28T01:00:00Z"),
            endedAt = Instant.parse("2026-04-28T01:10:00Z"),
            durationMs = 600_000L,
            distanceM = 2_000.0,
            points = emptyList(),
            sourceDeviceName = "Wear emulator",
            caloriesKcal = null,
        )

        queue.enqueue(draft)

        assertEquals(listOf("draft-1"), queue.pending().map { it.id })

        queue.markSent("draft-1")

        assertTrue(queue.pending().isEmpty())
    }

    @Test
    fun sendPendingKeepsDraftUntilPhoneAck() = runBlocking {
        val persistence = MemoryDraftPersistence()
        val queue = PendingDraftQueue(persistence)
        queue.enqueue(_draft("draft-1"))
        val transport = RecordingDraftTransport()
        val sender = WearDraftSender(transport)

        val sent = sender.sendPending(queue)

        assertEquals(1, sent)
        assertEquals(listOf("draft-1"), queue.pending().map { it.id })
        assertEquals(
            listOf("/runlini/wear/drafts/draft-1"),
            transport.attempts.map { it.path },
        )

        queue.markAcknowledged("draft-1")

        assertTrue(queue.pending().isEmpty())
    }

    @Test
    fun phoneAckHandlerDeletesOnlyMatchingDraft() {
        val persistence = MemoryDraftPersistence()
        val queue = PendingDraftQueue(persistence)
        queue.enqueue(_draft("draft-1"))
        queue.enqueue(_draft("draft-2"))

        val handled = PhoneDraftAckHandler.handlePath(
            "/runlini/phone/draft_acks/draft-1",
            queue,
        )

        assertTrue(handled)
        assertEquals(listOf("draft-2"), queue.pending().map { it.id })
    }

    private class MemoryDraftPersistence : PendingDraftPersistence {
        private val drafts = linkedMapOf<String, PendingWearDraft>()

        override fun list(): List<PendingWearDraft> {
            return drafts.values.toList()
        }

        override fun save(draft: PendingWearDraft) {
            drafts[draft.id] = draft
        }

        override fun delete(id: String) {
            drafts.remove(id)
        }
    }

    private class RecordingDraftTransport : WearDraftTransport {
        val attempts = mutableListOf<Attempt>()

        override suspend fun putDraft(
            path: String,
            draftId: String,
            json: String,
            attemptedAtEpochMs: Long,
        ) {
            attempts += Attempt(path, draftId, json, attemptedAtEpochMs)
        }
    }

    private data class Attempt(
        val path: String,
        val draftId: String,
        val json: String,
        val attemptedAtEpochMs: Long,
    )

    private fun _draft(id: String): WearRunDraftPayload {
        return WearRunDraftPayload(
            id = id,
            startedAt = Instant.parse("2026-04-28T01:00:00Z"),
            endedAt = Instant.parse("2026-04-28T01:10:00Z"),
            durationMs = 600_000L,
            distanceM = 2_000.0,
            points = emptyList(),
            sourceDeviceName = "Wear emulator",
            caloriesKcal = null,
        )
    }
}
