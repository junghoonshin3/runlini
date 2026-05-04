package kr.sjh.runlini.wear

import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertTrue
import org.junit.Test

class WearAutoPauseSettingsApplierTest {
    private val applier = WearAutoPauseSettingsApplier()

    @Test
    fun activeRunSettingsUpdateAppliesAutoPauseValueImmediately() {
        val result = applier.apply(
            state = runningState().copy(
                settings = WearRunSettings(autoPauseEnabled = true),
            ),
            settings = WearRunSettings(autoPauseEnabled = false),
            realtimeMs = 12_000L,
        )

        assertEquals(WearRunPhase.Running, result.state.phase)
        assertFalse(result.state.settings.autoPauseEnabled)
        assertFalse(result.shouldResumeExercise)
    }

    @Test
    fun turningOffAutoPauseResumesAutoPausedState() {
        val result = applier.apply(
            state = runningState().copy(
                phase = WearRunPhase.Paused,
                pauseReason = WearPauseReason.Auto,
                settings = WearRunSettings(autoPauseEnabled = true),
            ),
            settings = WearRunSettings(autoPauseEnabled = false),
            realtimeMs = 12_000L,
        )

        assertEquals(WearRunPhase.Running, result.state.phase)
        assertEquals(null, result.state.pauseReason)
        assertFalse(result.state.settings.autoPauseEnabled)
        assertTrue(result.shouldResumeExercise)
    }

    @Test
    fun turningOffAutoPauseDoesNotResumeManualPause() {
        val result = applier.apply(
            state = runningState().copy(
                phase = WearRunPhase.Paused,
                pauseReason = WearPauseReason.Manual,
                settings = WearRunSettings(autoPauseEnabled = true),
            ),
            settings = WearRunSettings(autoPauseEnabled = false),
            realtimeMs = 12_000L,
        )

        assertEquals(WearRunPhase.Paused, result.state.phase)
        assertEquals(WearPauseReason.Manual, result.state.pauseReason)
        assertFalse(result.state.settings.autoPauseEnabled)
        assertFalse(result.shouldResumeExercise)
    }

    @Test
    fun turningOnAutoPauseUpdatesActiveRun() {
        val result = applier.apply(
            state = runningState().copy(
                settings = WearRunSettings(autoPauseEnabled = false),
            ),
            settings = WearRunSettings(autoPauseEnabled = true),
            realtimeMs = 12_000L,
        )

        assertEquals(WearRunPhase.Running, result.state.phase)
        assertTrue(result.state.settings.autoPauseEnabled)
        assertFalse(result.shouldResumeExercise)
    }

    private fun runningState(): WearRunState {
        return WearRunState(
            phase = WearRunPhase.Running,
            elapsedMs = 8_000L,
            elapsedBeforeActiveSegmentMs = 8_000L,
            activeSegmentStartedRealtimeMs = 10_000L,
        )
    }
}
