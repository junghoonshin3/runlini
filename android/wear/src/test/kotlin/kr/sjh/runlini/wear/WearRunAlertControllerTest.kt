package kr.sjh.runlini.wear

import org.junit.Assert.assertEquals
import org.junit.Test

class WearRunAlertControllerTest {
    @Test
    fun kmAlertVibratesOncePerNewKilometer() {
        val haptics = FakeWearRunHaptics()
        val controller = WearRunAlertController(haptics)
        val settings = WearRunSettings(
            vibrationEnabled = true,
            kmAlertEnabled = true,
        )

        controller.onDistanceChanged(999.0, 300.0, settings)
        controller.onDistanceChanged(1_000.0, 300.0, settings)
        controller.onDistanceChanged(1_500.0, 300.0, settings)
        controller.onDistanceChanged(2_001.0, 300.0, settings)

        assertEquals(2, haptics.ticks)
    }

    @Test
    fun kmAlertDoesNothingWhenVibrationOrAlertIsOff() {
        val haptics = FakeWearRunHaptics()
        val controller = WearRunAlertController(haptics)

        controller.onDistanceChanged(
            1_200.0,
            300.0,
            WearRunSettings(vibrationEnabled = false, kmAlertEnabled = true),
        )
        controller.onDistanceChanged(
            2_200.0,
            300.0,
            WearRunSettings(vibrationEnabled = true, kmAlertEnabled = false),
        )

        assertEquals(0, haptics.ticks)
    }

    @Test
    fun resetAllowsNewRunToAlertAgain() {
        val haptics = FakeWearRunHaptics()
        val controller = WearRunAlertController(haptics)
        val settings = WearRunSettings(kmAlertEnabled = true)

        controller.onDistanceChanged(1_001.0, 300.0, settings)
        controller.reset()
        controller.onDistanceChanged(1_001.0, 300.0, settings)

        assertEquals(2, haptics.ticks)
    }

    @Test
    fun voiceCueSpeaksOncePerNewKilometer() {
        val speech = FakeWearRunSpeech()
        val controller = WearRunAlertController(
            haptics = FakeWearRunHaptics(),
            speech = speech,
        )

        controller.onDistanceChanged(1_000.0, 320.0, WearRunSettings())
        controller.onDistanceChanged(1_500.0, 320.0, WearRunSettings())
        controller.onDistanceChanged(2_000.0, null, WearRunSettings())

        assertEquals(
            listOf(
                "1킬로미터, 평균 페이스 5분 20초",
                "2킬로미터",
            ),
            speech.spoken,
        )
    }

    @Test
    fun voiceCueDoesNothingWhenSettingIsOff() {
        val speech = FakeWearRunSpeech()
        val controller = WearRunAlertController(
            haptics = FakeWearRunHaptics(),
            speech = speech,
        )

        controller.onDistanceChanged(
            1_000.0,
            320.0,
            WearRunSettings(voiceCueEnabled = false),
        )

        assertEquals(emptyList<String>(), speech.spoken)
    }

    @Test
    fun ghostVoiceSpeaksStatusChangesWithDebounce() {
        var now = 0L
        val speech = FakeWearRunSpeech()
        val controller = WearRunAlertController(
            haptics = FakeWearRunHaptics(),
            speech = speech,
            nowMs = { now },
        )
        val settings = WearRunSettings(ghostVoiceCueEnabled = true)

        controller.onGhostFrame(
            WearGhostFrame(WearGhostStatus.Ahead, 12_000L, 30.0),
            settings,
            isGhostRun = true,
        )
        now = 10_000L
        controller.onGhostFrame(
            WearGhostFrame(WearGhostStatus.Behind, -8_000L, -20.0),
            settings,
            isGhostRun = true,
        )
        now = 31_000L
        controller.onGhostFrame(
            WearGhostFrame(WearGhostStatus.Behind, -8_000L, -20.0),
            settings,
            isGhostRun = true,
        )
        now = 62_000L
        controller.onGhostFrame(
            WearGhostFrame(WearGhostStatus.Behind, -15_000L, -40.0),
            settings,
            isGhostRun = true,
        )

        assertEquals(
            listOf("앞섬 12초", "뒤처짐 8초"),
            speech.spoken,
        )
    }

    @Test
    fun ghostVoiceDoesNothingWhenNotGhostOrSettingIsOff() {
        val speech = FakeWearRunSpeech()
        val controller = WearRunAlertController(
            haptics = FakeWearRunHaptics(),
            speech = speech,
        )

        controller.onGhostFrame(
            WearGhostFrame(WearGhostStatus.OffRoute, 0L, 50.0),
            WearRunSettings(ghostVoiceCueEnabled = true),
            isGhostRun = false,
        )
        controller.onGhostFrame(
            WearGhostFrame(WearGhostStatus.OffRoute, 0L, 50.0),
            WearRunSettings(ghostVoiceCueEnabled = false),
            isGhostRun = true,
        )

        assertEquals(emptyList<String>(), speech.spoken)
    }

    @Test
    fun shutdownForwardsToSpeech() {
        val speech = FakeWearRunSpeech()
        val controller = WearRunAlertController(
            haptics = FakeWearRunHaptics(),
            speech = speech,
        )

        controller.shutdown()

        assertEquals(1, speech.shutdowns)
    }
}

private class FakeWearRunHaptics : WearRunHaptics {
    var ticks = 0

    override fun tick() {
        ticks += 1
    }
}

private class FakeWearRunSpeech : WearRunSpeech {
    val spoken = mutableListOf<String>()
    var shutdowns = 0

    override fun speak(text: String) {
        spoken.add(text)
    }

    override fun shutdown() {
        shutdowns += 1
    }
}
