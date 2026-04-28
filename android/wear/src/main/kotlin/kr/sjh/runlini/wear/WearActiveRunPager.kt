package kr.sjh.runlini.wear

import androidx.compose.foundation.ExperimentalFoundationApi
import androidx.compose.foundation.border
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.pager.HorizontalPager
import androidx.compose.foundation.pager.rememberPagerState
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.wear.compose.material3.Text

@OptIn(ExperimentalFoundationApi::class)
@Composable
internal fun WearActiveRunPager(
    state: WearRunState,
    onPause: () -> Unit,
    onStop: () -> Unit,
) {
    val pages = WearActiveRunPageModel.pagesFor(state)
    val pagerState = rememberPagerState(pageCount = { pages.size })
    Box(modifier = Modifier.fillMaxSize()) {
        HorizontalPager(
            state = pagerState,
            modifier = Modifier.fillMaxSize(),
        ) { pageIndex ->
            when (pages[pageIndex]) {
                WearActiveRunPage.Core -> WearCorePage(state)
                WearActiveRunPage.Ghost -> WearGhostPage(state)
                WearActiveRunPage.Details -> WearDetailsPage(state)
                WearActiveRunPage.Controls -> WearRunControlsPage(
                    onPause = onPause,
                    onStop = onStop,
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

@Composable
private fun WearCorePage(state: WearRunState) {
    WearRunPageFrame(reservePageIndicator = true) { spec ->
        state.ghostFrame?.let { frame ->
            WearStatusPill(
                label = WearRunFormatters.ghostResult(frame),
                color = ghostColor(frame.status),
            )
            Spacer(modifier = Modifier.height(8.dp))
        }

        WearPrimaryMetric(
            label = "거리",
            value = WearRunFormatters.distance(state.distanceM),
            valueColor = RunliniWearColors.VoltGreen,
            profile = spec.profile,
        )
        Spacer(modifier = Modifier.height(10.dp))
        Row(
            modifier = Modifier.fillMaxWidth(),
            horizontalArrangement = Arrangement.spacedBy(8.dp),
        ) {
            WearCompactMetric(
                label = "시간",
                value = WearRunFormatters.elapsed(state.elapsedMs),
                modifier = Modifier.weight(1f),
            )
            WearCompactMetric(
                label = "현재 페이스",
                value = WearRunFormatters.pace(state.currentPaceSecPerKm),
                modifier = Modifier.weight(1f),
            )
        }
    }
}

@Composable
private fun WearGhostPage(state: WearRunState) {
    val frame = state.ghostFrame
    val color = ghostColor(frame?.status)
    WearRunPageFrame(reservePageIndicator = true) { spec ->
        WearStatusPill(
            label = WearRunFormatters.ghostStatusLabel(frame?.status),
            color = color,
        )
        Spacer(modifier = Modifier.height(8.dp))
        WearPrimaryMetric(
            label = "격차",
            value = WearRunFormatters.ghostGap(frame),
            valueColor = color,
            profile = spec.profile,
        )
        state.ghostConfig?.sourceSummary?.let { summary ->
            Spacer(modifier = Modifier.height(8.dp))
            Text(
                text = summary,
                color = RunliniWearColors.Muted,
                fontSize = 10.sp,
                fontWeight = FontWeight.Black,
                textAlign = TextAlign.Center,
                maxLines = 1,
                overflow = TextOverflow.Ellipsis,
            )
        }
    }
}

@Composable
private fun WearDetailsPage(state: WearRunState) {
    WearRunPageFrame(reservePageIndicator = true) {
        Row(
            modifier = Modifier.fillMaxWidth(),
            horizontalArrangement = Arrangement.spacedBy(8.dp),
        ) {
            WearCompactMetric(
                label = "심박수",
                value = WearRunFormatters.heartRate(state.heartRateBpm),
                modifier = Modifier.weight(1f),
            )
            WearCompactMetric(
                label = "칼로리",
                value = WearRunFormatters.calories(state.caloriesKcal),
                modifier = Modifier.weight(1f),
            )
        }
        Spacer(modifier = Modifier.height(8.dp))
        Row(
            modifier = Modifier.fillMaxWidth(),
            horizontalArrangement = Arrangement.spacedBy(8.dp),
        ) {
            WearCompactMetric(
                label = "평균 페이스",
                value = WearRunFormatters.pace(state.averagePaceSecPerKm),
                modifier = Modifier.weight(1f),
            )
            WearCompactMetric(
                label = "케이던스",
                value = WearRunFormatters.cadence(state.cadenceSpm),
                modifier = Modifier.weight(1f),
            )
        }
        Spacer(modifier = Modifier.height(8.dp))
        Row(
            modifier = Modifier.fillMaxWidth(),
            horizontalArrangement = Arrangement.spacedBy(8.dp),
        ) {
            WearCompactMetric(
                label = "속도",
                value = WearRunFormatters.speed(state.speedMps),
                modifier = Modifier.fillMaxWidth(),
            )
        }
    }
}

@Composable
private fun WearRunControlsPage(
    onPause: () -> Unit,
    onStop: () -> Unit,
) {
    WearRunPageFrame(reservePageIndicator = true) { spec ->
        val buttonHeight = if (spec.profile == WearLayoutProfile.Regular) {
            52.dp
        } else {
            48.dp
        }
        WearActionButton(
            label = "일시정지",
            color = RunliniWearColors.Chalk,
            textColor = RunliniWearColors.Black,
            modifier = Modifier.fillMaxWidth(),
            height = buttonHeight,
            onClick = onPause,
        )
        Spacer(modifier = Modifier.height(10.dp))
        WearActionButton(
            label = "종료",
            color = RunliniWearColors.ElectricRed,
            textColor = RunliniWearColors.Chalk,
            modifier = Modifier.fillMaxWidth(),
            height = buttonHeight,
            onClick = onStop,
        )
    }
}

@Composable
internal fun WearGhostStatusPanel(
    state: WearRunState,
    modifier: Modifier = Modifier,
) {
    val frame = state.ghostFrame
    val color = ghostColor(frame?.status)
    Box(
        modifier = modifier
            .fillMaxWidth()
            .border(2.dp, color, RoundedCornerShape(2.dp))
            .padding(horizontal = 10.dp, vertical = 8.dp),
        contentAlignment = Alignment.Center,
    ) {
        Text(
            text = WearRunFormatters.ghostResult(frame),
            color = color,
            fontSize = 18.sp,
            fontWeight = FontWeight.Black,
            textAlign = TextAlign.Center,
            maxLines = 1,
            overflow = TextOverflow.Ellipsis,
        )
    }
}
