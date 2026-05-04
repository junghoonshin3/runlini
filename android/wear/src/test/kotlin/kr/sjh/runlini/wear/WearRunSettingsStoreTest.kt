package kr.sjh.runlini.wear

import org.junit.Assert.assertEquals
import org.junit.Test

class WearRunSettingsStoreTest {
    @Test
    fun storeReturnsDefaultsWhenEmpty() {
        val store = WearRunSettingsStore(FakeSettingsPersistence())

        assertEquals(WearRunSettings(), store.current())
    }

    @Test
    fun storeSavesAndLoadsSettings() {
        val persistence = FakeSettingsPersistence()
        val store = WearRunSettingsStore(persistence)
        val settings = WearRunSettings(
            countdownEnabled = false,
            vibrationEnabled = false,
            kmAlertEnabled = true,
            voiceCueEnabled = false,
            voiceCueVolume = 0.6f,
            ghostVoiceCueEnabled = true,
        )

        store.save(settings)

        assertEquals(settings, store.current())
    }

    @Test
    fun storeFallsBackToDefaultsForCorruptJson() {
        val persistence = FakeSettingsPersistence()
        persistence.write("{broken")
        val store = WearRunSettingsStore(persistence)

        assertEquals(WearRunSettings(), store.current())
    }

    @Test
    fun storeMigratesMissingVoiceSettingsToDefaults() {
        val persistence = FakeSettingsPersistence()
        persistence.write(
            """
            {
              "countdownEnabled": false,
              "vibrationEnabled": false,
              "kmAlertEnabled": true
            }
            """.trimIndent(),
        )
        val store = WearRunSettingsStore(persistence)

        assertEquals(
            WearRunSettings(
                countdownEnabled = false,
                vibrationEnabled = false,
                kmAlertEnabled = true,
                voiceCueEnabled = true,
                voiceCueVolume = 1.0f,
                ghostVoiceCueEnabled = false,
            ),
            store.current(),
        )
    }

    @Test
    fun storeClampsVoiceVolume() {
        val persistence = FakeSettingsPersistence()
        persistence.write("""{"voiceCueVolume": 2.0}""")
        val store = WearRunSettingsStore(persistence)

        assertEquals(1.0f, store.current().voiceCueVolume)
    }

    @Test
    fun startPolicySkipsCountdownWhenSettingIsOff() {
        assertEquals(
            false,
            WearRunStartPolicy.shouldUseCountdown(
                WearRunSettings(countdownEnabled = false),
            ),
        )
        assertEquals(
            true,
            WearRunStartPolicy.shouldUseCountdown(
                WearRunSettings(countdownEnabled = true),
            ),
        )
    }
}

private class FakeSettingsPersistence : WearRunSettingsPersistence {
    private var json: String? = null

    override fun read(): String? = json

    override fun write(json: String) {
        this.json = json
    }
}
