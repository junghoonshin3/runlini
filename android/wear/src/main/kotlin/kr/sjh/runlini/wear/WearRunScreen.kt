package kr.sjh.runlini.wear

import androidx.compose.runtime.Composable

@Composable
internal fun WearRunScreen(
    state: WearRunState,
    actions: WearRunActions,
) {
    when (state.phase) {
        WearRunPhase.Ready -> WearReadyPager(
            state = state,
            actions = actions,
        )
        WearRunPhase.CountingDown -> WearCountdownScreen(state = state)
        WearRunPhase.Running,
        WearRunPhase.Paused,
        -> WearActiveRunPager(
            state = state,
            onPause = actions.onPause,
            onResume = actions.onResume,
            onStop = actions.onStop,
        )
        WearRunPhase.Reviewing -> WearFinishReviewScreen(
            state = state,
            onSave = actions.onSave,
            onDiscard = actions.onDiscard,
        )
        WearRunPhase.Feedback -> WearCompletionFeedbackScreen(state = state)
    }
}

internal data class WearRunActions(
    val onStart: () -> Unit,
    val onGhostStart: () -> Unit,
    val onPause: () -> Unit,
    val onStop: () -> Unit,
    val onResume: () -> Unit,
    val onSave: () -> Unit,
    val onDiscard: () -> Unit,
    val onCountdownEnabledChange: (Boolean) -> Unit,
    val onAutoPauseEnabledChange: (Boolean) -> Unit,
    val onVibrationEnabledChange: (Boolean) -> Unit,
    val onKmAlertEnabledChange: (Boolean) -> Unit,
    val onVoiceCueEnabledChange: (Boolean) -> Unit,
    val onVoiceCueVolumeChange: (Float) -> Unit,
    val onGhostVoiceCueEnabledChange: (Boolean) -> Unit,
    val onIntervalWorkoutChange: (WearIntervalWorkout) -> Unit,
    val onGhostSelect: (String) -> Unit,
) {
    companion object {
        val NoOp = WearRunActions(
            onStart = {},
            onGhostStart = {},
            onPause = {},
            onStop = {},
            onResume = {},
            onSave = {},
            onDiscard = {},
            onCountdownEnabledChange = {},
            onAutoPauseEnabledChange = {},
            onVibrationEnabledChange = {},
            onKmAlertEnabledChange = {},
            onVoiceCueEnabledChange = {},
            onVoiceCueVolumeChange = {},
            onGhostVoiceCueEnabledChange = {},
            onIntervalWorkoutChange = {},
            onGhostSelect = {},
        )
    }
}
