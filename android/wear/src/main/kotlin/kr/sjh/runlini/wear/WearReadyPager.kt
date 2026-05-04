package kr.sjh.runlini.wear

import androidx.compose.foundation.ExperimentalFoundationApi
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.pager.HorizontalPager
import androidx.compose.foundation.pager.rememberPagerState
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.unit.dp

@OptIn(ExperimentalFoundationApi::class)
@Composable
internal fun WearReadyPager(
    state: WearRunState,
    actions: WearRunActions,
) {
    val pages = WearReadyPageModel.pagesFor(state)
    val pagerState = rememberPagerState(
        initialPage = WearReadyPageModel.initialPageFor(pages),
        pageCount = { pages.size },
    )
    Box(modifier = Modifier.fillMaxSize()) {
        HorizontalPager(
            state = pagerState,
            modifier = Modifier.fillMaxSize(),
        ) { pageIndex ->
            when (pages[pageIndex]) {
                WearReadyPage.Ready -> WearReadyScreen(
                    state = state,
                    onStart = actions.onStart,
                    onGhostStart = actions.onGhostStart,
                    reservePageIndicator = true,
                )
                WearReadyPage.Ghosts -> WearGhostPickerScreen(
                    state = state,
                    onSelect = actions.onGhostSelect,
                )
                WearReadyPage.Settings -> WearSettingsScreen(
                    settings = state.settings,
                    onCountdownEnabledChange = actions.onCountdownEnabledChange,
                    onAutoPauseEnabledChange = actions.onAutoPauseEnabledChange,
                    onVibrationEnabledChange = actions.onVibrationEnabledChange,
                    onKmAlertEnabledChange = actions.onKmAlertEnabledChange,
                    onVoiceCueEnabledChange = actions.onVoiceCueEnabledChange,
                    onVoiceCueVolumeChange = actions.onVoiceCueVolumeChange,
                    onGhostVoiceCueEnabledChange = actions.onGhostVoiceCueEnabledChange,
                    onIntervalWorkoutChange = actions.onIntervalWorkoutChange,
                )
            }
        }
        WearPageIndicator(
            pageCount = pages.size,
            selectedIndex = pagerState.currentPage,
            modifier = Modifier
                .align(Alignment.BottomCenter)
                .padding(bottom = 6.dp),
        )
    }
}
