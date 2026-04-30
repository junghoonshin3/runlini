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
    onResume: () -> Unit,
    onStop: () -> Unit,
) {
    val pages = WearActiveRunPageModel.pagesFor(state)
    val initialPage = WearActiveRunPageModel.initialPageFor(pages)
    val pagerState = rememberPagerState(
        initialPage = initialPage,
        pageCount = { pages.size },
    )
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
                    state = state,
                    onPause = onPause,
                    onResume = onResume,
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

        val distanceHero = WearRunFormatters.distanceHero(state.distanceM)
        WearDistanceHeroMetric(
            label = "거리",
            value = distanceHero.value,
            unit = distanceHero.unit,
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
    state: WearRunState,
    onPause: () -> Unit,
    onResume: () -> Unit,
    onStop: () -> Unit,
) {
    val model = WearRunControlModelBuilder.from(state)
    WearRunPageFrame(
        verticalArrangement = Arrangement.SpaceBetween,
        reservePageIndicator = true,
    ) { spec ->
        val compact = spec.profile == WearLayoutProfile.Compact
        val controlSize = if (compact) 62.dp else 72.dp
        val bottomBalance = if (compact) 18.dp else 22.dp

        Text(
            text = "RUNLINI",
            color = RunliniWearColors.Chalk,
            fontSize = if (compact) 19.sp else 23.sp,
            fontWeight = FontWeight.Black,
            textAlign = TextAlign.Center,
        )

        Row(
            modifier = Modifier.fillMaxWidth(),
            horizontalArrangement = Arrangement.spacedBy(
                space = if (compact) 12.dp else 16.dp,
                alignment = Alignment.CenterHorizontally,
            ),
            verticalAlignment = Alignment.CenterVertically,
        ) {
            WearCircleButton(
                label = model.primaryLabel,
                color = if (model.primaryIsResume) {
                    RunliniWearColors.VoltGreen
                } else {
                    RunliniWearColors.Chalk
                },
                textColor = RunliniWearColors.Black,
                size = controlSize,
                icon = model.primaryIcon,
                onClick = if (model.primaryIsResume) onResume else onPause,
            )
            WearCircleButton(
                label = model.secondaryLabel,
                color = RunliniWearColors.ElectricRed,
                textColor = RunliniWearColors.Chalk,
                size = controlSize,
                icon = model.secondaryIcon,
                onClick = onStop,
            )
        }

        Spacer(modifier = Modifier.height(bottomBalance))
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
