package kr.sjh.runlini

import org.junit.Assert.assertEquals
import org.junit.Assert.assertTrue
import org.junit.Test

class WearDraftAckSenderTest {
    @Test
    fun sendAckCreatesExpectedAckPath() {
        val transport = RecordingAckTransport()
        val sender = WearDraftAckSender(transport)

        sender.sendAck("draft-1")

        assertEquals(listOf("/runlini/phone/draft_acks/draft-1"), transport.acks.map { it.path })
        assertEquals("draft-1", transport.acks.single().draftId)
        assertTrue(transport.acks.single().ackAtEpochMs > 0)
    }

    private class RecordingAckTransport : WearDraftAckTransport {
        val acks = mutableListOf<Ack>()

        override fun putAck(path: String, draftId: String, ackAtEpochMs: Long) {
            acks += Ack(path, draftId, ackAtEpochMs)
        }
    }

    private data class Ack(
        val path: String,
        val draftId: String,
        val ackAtEpochMs: Long,
    )
}
