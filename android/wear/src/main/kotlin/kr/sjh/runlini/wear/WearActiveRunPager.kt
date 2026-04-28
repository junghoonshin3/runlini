package kr.sjh.runlini.wear

import androidx.compose.foundation.ExperimentalFoundationApi
import androidx.compose.foundation.border
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.PaddingValues
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.lazy.LazyColumn
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
    LazyColumn(
        modifier = Modifier.fillMaxSize(),
        contentPadding = PaddingValues(horizontal = 18.dp, vertical = 16.dp),
        horizontalAlignment = Alignment.CenterHorizontally,
        verticalArrangement = Arrangement.Center,
    ) {
        item {
            WearHeroMetric(
                label = "DIST",
                value = WearRunFormatters.distance(state.distanceM),
                valueColor = RunliniWearColors.VoltGreen,
            )
        }
        item { Spacer(modifier = Modifier.height(10.dp)) }
        item {
            Text(
                text = WearRunFormatters.elapsed(state.elapsedMs),
                color = RunliniWearColors.Chalk,
                fontSize = 32.sp,
                fontWeight = FontWeight.Black,
                textAlign = TextAlign.Center,
                maxLines = 1,
            )
        }
        item { Spacer(modifier = Modifier.height(10.dp)) }
        item {
            WearMetricTile(
                label = "NOW",
                value = WearRunFormatters.pace(state.currentPaceSecPerKm),
                valueColor = RunliniWearColors.Chalk,
            )
        }
        item { Spacer(modifier = Modifier.height(6.dp)) }
        item {
            WearMetricTile(
                label = "AVG",
                value = WearRunFormatters.pace(state.averagePaceSecPerKm),
            )
        }
    }
}

@Composable
private fun WearGhostPage(state: WearRunState) {
    val frame = state.ghostFrame
    val color = ghostColor(frame?.status)
    LazyColumn(
        modifier = Modifier.fillMaxSize(),
        contentPadding = PaddingValues(horizontal = 18.dp, vertical = 16.dp),
        horizontalAlignment = Alignment.CenterHorizontally,
        verticalArrangement = Arrangement.Center,
    ) {
        item {
            Text(
                text = WearRunFormatters.ghostStatusLabel(frame?.status),
                color = color,
                fontSize = 22.sp,
                fontWeight = FontWeight.Black,
                textAlign = TextAlign.Center,
                maxLines = 1,
                overflow = TextOverflow.Ellipsis,
            )
        }
        item { Spacer(modifier = Modifier.height(8.dp)) }
        item {
            WearHeroMetric(
                label = "GAP",
                value = WearRunFormatters.ghostGap(frame),
                valueColor = color,
            )
        }
        state.ghostConfig?.sourceSummary?.let { summary ->
            item { Spacer(modifier = Modifier.height(8.dp)) }
            item {
                Text(
                    text = summary,
                    color = RunliniWearColors.Muted,
                    fontSize = 11.sp,
                    fontWeight = FontWeight.Black,
                    textAlign = TextAlign.Center,
                    maxLines = 1,
                    overflow = TextOverflow.Ellipsis,
                )
            }
        }
    }
}

@Composable
private fun WearDetailsPage(state: WearRunState) {
    LazyColumn(
        modifier = Modifier.fillMaxSize(),
        contentPadding = PaddingValues(horizontal = 14.dp, vertical = 16.dp),
        horizontalAlignment = Alignment.CenterHorizontally,
        verticalArrangement = Arrangement.Center,
    ) {
        item {
            Text(
                text = "DETAIL",
                color = RunliniWearColors.Chalk,
                fontSize = 18.sp,
                fontWeight = FontWeight.Black,
                textAlign = TextAlign.Center,
            )
        }
        item { Spacer(modifier = Modifier.height(8.dp)) }
        item {
            WearMetricTile(
                label = "HR",
                value = WearRunFormatters.heartRate(state.heartRateBpm),
            )
        }
        item { Spacer(modifier = Modifier.height(6.dp)) }
        item {
            WearMetricTile(
                label = "CAL",
                value = WearRunFormatters.calories(state.caloriesKcal),
            )
        }
        item { Spacer(modifier = Modifier.height(6.dp)) }
        item {
            WearMetricTile(
                label = "SPD",
                value = WearRunFormatters.speed(state.speedMps),
            )
        }
        item { Spacer(modifier = Modifier.height(6.dp)) }
        item {
            WearMetricTile(
                label = "DIST",
                value = WearRunFormatters.distance(state.distanceM),
            )
        }
    }
}

@Composable
private fun WearRunControlsPage(
    onPause: () -> Unit,
    onStop: () -> Unit,
) {
    Column(
        modifier = Modifier
            .fillMaxSize()
            .padding(horizontal = 18.dp, vertical = 20.dp),
        horizontalAlignment = Alignment.CenterHorizontally,
        verticalArrangement = Arrangement.Center,
    ) {
        Text(
            text = "CONTROL",
            color = RunliniWearColors.Chalk,
            fontSize = 20.sp,
            fontWeight = FontWeight.Black,
            textAlign = TextAlign.Center,
        )
        Spacer(modifier = Modifier.height(12.dp))
        WearActionButton(
            label = "PAUSE",
            color = RunliniWearColors.Chalk,
            textColor = RunliniWearColors.Black,
            modifier = Modifier.fillMaxWidth(),
            onClick = onPause,
        )
        Spacer(modifier = Modifier.height(10.dp))
        WearActionButton(
            label = "STOP",
            color = RunliniWearColors.ElectricRed,
            textColor = RunliniWearColors.Chalk,
            modifier = Modifier.fillMaxWidth(),
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
