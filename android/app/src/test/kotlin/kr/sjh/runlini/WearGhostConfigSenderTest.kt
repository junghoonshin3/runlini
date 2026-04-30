package kr.sjh.runlini

import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertNull
import org.junit.Assert.assertTrue
import org.junit.Test

class WearGhostConfigSenderTest {
    @Test
    fun sendConfigCreatesEnabledGhostConfigItem() {
        val transport = FakeGhostConfigTransport()
        val sender = WearGhostConfigSender(transport)

        sender.sendConfig("ghost-1", """{"id":"ghost-1"}""")

        assertEquals(WearGhostConfigSender.ConfigPath, transport.path)
        assertTrue(transport.enabled!!)
        assertEquals("ghost-1", transport.ghostSessionId)
        assertEquals("""{"id":"ghost-1"}""", transport.json)
    }

    @Test
    fun clearConfigCreatesDisabledGhostConfigItem() {
        val transport = FakeGhostConfigTransport()
        val sender = WearGhostConfigSender(transport)

        sender.clearConfig()

        assertEquals(WearGhostConfigSender.ConfigPath, transport.path)
        assertFalse(transport.enabled!!)
        assertNull(transport.ghostSessionId)
        assertNull(transport.json)
    }

    @Test
    fun sendConfigsCreatesBatchGhostConfigsItem() {
        val transport = FakeGhostConfigTransport()
        val sender = WearGhostConfigSender(transport)

        sender.sendConfigs(
            activeId = "ghost-2",
            json = """{"activeId":"ghost-2","configs":[]}""",
        )

        assertEquals(WearGhostConfigSender.ConfigsPath, transport.path)
        assertTrue(transport.enabled!!)
        assertEquals("ghost-2", transport.activeId)
        assertEquals("""{"activeId":"ghost-2","configs":[]}""", transport.json)
    }
}

private class FakeGhostConfigTransport : WearGhostConfigTransport {
    var path: String? = null
    var enabled: Boolean? = null
    var ghostSessionId: String? = null
    var activeId: String? = null
    var json: String? = null

    override fun putConfig(
        path: String,
        enabled: Boolean,
        ghostSessionId: String?,
        json: String?,
        updatedAtEpochMs: Long,
    ) {
        this.path = path
        this.enabled = enabled
        this.ghostSessionId = ghostSessionId
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
