package kr.sjh.runlini.wear

import androidx.compose.runtime.Composable

@Composable
internal fun WearRunScreen(
    state: WearRunState,
    actions: WearRunActions,
) {
    when (state.phase) {
        WearRunPhase.Ready -> WearReadyScreen(
            state = state,
            onStart = actions.onStart,
            onGhostStart = actions.onGhostStart,
            onRetryPending = actions.onRetryPending,
        )
        WearRunPhase.Running -> WearActiveRunPager(
            state = state,
            onPause = actions.onPause,
            onStop = actions.onStop,
        )
        WearRunPhase.Paused -> WearPausedScreen(
            state = state,
            onResume = actions.onResume,
            onStop = actions.onStop,
        )
        WearRunPhase.Reviewing -> WearFinishReviewScreen(
            state = state,
            onSave = actions.onSave,
            onDiscard = actions.onDiscard,
        )
    }
}

internal data class WearRunActions(
    val onStart: () -> Unit,
    val onGhostStart: () -> Unit,
    val onRetryPending: () -> Unit,
    val onPause: () -> Unit,
    val onStop: () -> Unit,
    val onResume: () -> Unit,
    val onSave: () -> Unit,
    val onDiscard: () -> Unit,
) {
    companion object {
        val NoOp = WearRunActions(
            onStart = {},
            onGhostStart = {},
            onRetryPending = {},
            onPause = {},
            onStop = {},
            onResume = {},
            onSave = {},
            onDiscard = {},
        )
    }
}
