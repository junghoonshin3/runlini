package kr.sjh.runlini.wear

import androidx.compose.runtime.Composable

@Composable
internal fun WearRunScreen(
    state: WearRunState,
    controller: HealthServicesRunController,
) {
    when (state.phase) {
        WearRunPhase.Ready -> WearReadyScreen(
            state = state,
            onStart = controller::startRun,
            onGhostStart = controller::startGhostRun,
            onRetryPending = controller::retryPendingDrafts,
        )
        WearRunPhase.Running -> WearActiveRunPager(
            state = state,
            onPause = controller::pauseRun,
            onStop = controller::stopRun,
        )
        WearRunPhase.Paused -> WearPausedScreen(
            state = state,
            onResume = controller::resumeRun,
            onStop = controller::stopRun,
        )
        WearRunPhase.Reviewing -> WearFinishReviewScreen(
            state = state,
            onSave = controller::saveDraft,
            onDiscard = controller::discardDraft,
        )
    }
}
