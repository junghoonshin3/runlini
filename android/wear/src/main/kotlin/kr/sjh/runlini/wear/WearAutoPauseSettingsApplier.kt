package kr.sjh.runlini.wear

data class WearAutoPauseSettingsApplyResult(
    val state: WearRunState,
    val shouldResumeExercise: Boolean,
)

class WearAutoPauseSettingsApplier(
    private val reducer: WearRunStateReducer = WearRunStateReducer(),
) {
    fun apply(
        state: WearRunState,
        settings: WearRunSettings,
        realtimeMs: Long,
    ): WearAutoPauseSettingsApplyResult {
        val stateWithSettings = state.copy(settings = settings)
        if (
            !settings.autoPauseEnabled &&
            state.phase == WearRunPhase.Paused &&
            state.pauseReason == WearPauseReason.Auto
        ) {
            return WearAutoPauseSettingsApplyResult(
                state = reducer.resume(stateWithSettings, realtimeMs),
                shouldResumeExercise = true,
            )
        }

        return WearAutoPauseSettingsApplyResult(
            state = stateWithSettings,
            shouldResumeExercise = false,
        )
    }
}
