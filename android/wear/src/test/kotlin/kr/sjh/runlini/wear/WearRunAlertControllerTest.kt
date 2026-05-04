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

        val settings = WearRunSettings(kmAlertEnabled = true)

        controller.onDistanceChanged(1_000.0, 320.0, settings, elapsedMs = 320_000L)
        controller.onDistanceChanged(1_500.0, 320.0, settings)
        controller.onDistanceChanged(2_000.0, null, settings, elapsedMs = 640_000L)

        assertEquals(
            listOf(
                "1킬로미터, 평균 페이스 5분 20초, 시간 5분 20초",
                "2킬로미터, 시간 10분 40초",
            ),
            speech.spoken,
        )
        assertEquals(listOf(1.0f, 1.0f), speech.volumes)
    }

    @Test
    fun voiceCueUsesConfiguredVolume() {
        val speech = FakeWearRunSpeech()
        val controller = WearRunAlertController(
            haptics = FakeWearRunHaptics(),
            speech = speech,
        )

        controller.onDistanceChanged(
            1_000.0,
            300.0,
            WearRunSettings(kmAlertEnabled = true, voiceCueVolume = 0.4f),
            elapsedMs = 300_000L,
        )

        assertEquals(listOf(0.4f), speech.volumes)
    }

    @Test
    fun voiceTestCueUsesConfiguredVolume() {
        val speech = FakeWearRunSpeech()
        val controller = WearRunAlertController(
            haptics = FakeWearRunHaptics(),
            speech = speech,
        )

        controller.playVoiceTestCue(0.35f)

        assertEquals(listOf("음량 테스트"), speech.spoken)
        assertEquals(listOf(0.35f), speech.volumes)
    }

    @Test
    fun voiceTestCueClampsVolume() {
        val speech = FakeWearRunSpeech()
        val controller = WearRunAlertController(
            haptics = FakeWearRunHaptics(),
            speech = speech,
        )

        controller.playVoiceTestCue(3.0f)

        assertEquals(listOf(1.0f), speech.volumes)
    }

    @Test
    fun voiceCueFormatsLongElapsedTime() {
        assertEquals(
            "12킬로미터, 평균 페이스 5분, 시간 1시간 2분 3초",
            WearRunVoiceCueFormatter.kilometerSummary(
                kilometer = 12,
                averagePaceSecPerKm = 300.0,
                elapsedMs = 3_723_000L,
            ),
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
            WearRunSettings(voiceCueEnabled = false, kmAlertEnabled = true),
        )

        assertEquals(emptyList<String>(), speech.spoken)
    }

    @Test
    fun voiceCueDoesNothingWhenKmAlertIsOff() {
        val speech = FakeWearRunSpeech()
        val controller = WearRunAlertController(
            haptics = FakeWearRunHaptics(),
            speech = speech,
        )

        controller.onDistanceChanged(
            1_000.0,
            320.0,
            WearRunSettings(voiceCueEnabled = true, kmAlertEnabled = false),
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
    val volumes = mutableListOf<Float>()
    var shutdowns = 0

    override fun speak(text: String, volume: Float) {
        spoken.add(text)
        volumes.add(volume)
    }

    override fun shutdown() {
        shutdowns += 1
    }
}
