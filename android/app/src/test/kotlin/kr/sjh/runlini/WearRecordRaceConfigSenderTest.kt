package kr.sjh.runlini

import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertNull
import org.junit.Assert.assertTrue
import org.junit.Test

class WearRecordRaceConfigSenderTest {
    @Test
    fun sendConfigCreatesEnabledRecordRaceConfigItem() {
        val transport = FakeRecordRaceConfigTransport()
        val sender = WearRecordRaceConfigSender(transport)

        sender.sendConfig("record-race-1", """{"id":"record-race-1"}""")

        assertEquals(WearRecordRaceConfigSender.ConfigPath, transport.path)
        assertTrue(transport.enabled!!)
        assertEquals("record-race-1", transport.recordRaceSessionId)
        assertEquals("""{"id":"record-race-1"}""", transport.json)
    }

    @Test
    fun clearConfigCreatesDisabledRecordRaceConfigItem() {
        val transport = FakeRecordRaceConfigTransport()
        val sender = WearRecordRaceConfigSender(transport)

        sender.clearConfig()

        assertEquals(WearRecordRaceConfigSender.ConfigPath, transport.path)
        assertFalse(transport.enabled!!)
        assertNull(transport.recordRaceSessionId)
        assertNull(transport.json)
    }

    @Test
    fun sendConfigsCreatesBatchRecordRaceConfigsItem() {
        val transport = FakeRecordRaceConfigTransport()
        val sender = WearRecordRaceConfigSender(transport)

        sender.sendConfigs(
            activeId = "record-race-2",
            json = """{"activeId":"record-race-2","configs":[]}""",
        )

        assertEquals(WearRecordRaceConfigSender.ConfigsPath, transport.path)
        assertTrue(transport.enabled!!)
        assertEquals("record-race-2", transport.activeId)
        assertEquals("""{"activeId":"record-race-2","configs":[]}""", transport.json)
    }
}

private class FakeRecordRaceConfigTransport : WearRecordRaceConfigTransport {
    var path: String? = null
    var enabled: Boolean? = null
    var recordRaceSessionId: String? = null
    var activeId: String? = null
    var json: String? = null

    override fun putConfig(
        path: String,
        enabled: Boolean,
        recordRaceSessionId: String?,
        json: String?,
        updatedAtEpochMs: Long,
    ) {
        this.path = path
        this.enabled = enabled
        this.recordRaceSessionId = recordRaceSessionId
        this.json = json
    }

    override fun putConfigs(
        path: String,
        enabled: Boolean,
        activeId: String?,
        json: String,
        updatedAtEpochMs: Long,
    ) {
        this.path = path
        this.enabled = enabled
        this.activeId = activeId
        this.json = json
    }
}
