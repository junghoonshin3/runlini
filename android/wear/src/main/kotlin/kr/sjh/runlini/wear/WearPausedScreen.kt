package kr.sjh.runlini.wear

import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.PaddingValues
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.wear.compose.material3.Text

@Composable
internal fun WearPausedScreen(
    state: WearRunState,
    onResume: () -> Unit,
    onStop: () -> Unit,
) {
    LazyColumn(
        modifier = Modifier.fillMaxSize(),
        contentPadding = PaddingValues(horizontal = 18.dp, vertical = 18.dp),
        horizontalAlignment = Alignment.CenterHorizontally,
        verticalArrangement = Arrangement.Center,
    ) {
        item {
            Text(
                text = "일시정지",
                color = RunliniWearColors.Chalk,
                fontSize = 22.sp,
                fontWeight = FontWeight.Black,
                textAlign = TextAlign.Center,
            )
        }
        item { Spacer(modifier = Modifier.height(8.dp)) }
        item {
            Text(
                text = WearRunFormatters.elapsed(state.elapsedMs),
                color = RunliniWearColors.Chalk,
                fontSize = 36.sp,
                fontWeight = FontWeight.Black,
                textAlign = TextAlign.Center,
            )
        }
        item { Spacer(modifier = Modifier.height(10.dp)) }
        item {
            WearMetricTile(
                label = "거리",
                value = WearRunFormatters.distance(state.distanceM),
            )
        }
        if (state.isGhostRun) {
            item { Spacer(modifier = Modifier.height(8.dp)) }
            item { WearGhostStatusPanel(state = state) }
        }
        item { Spacer(modifier = Modifier.height(12.dp)) }
        item {
            WearActionButton(
                label = "재개",
                color = RunliniWearColors.VoltGreen,
                textColor = RunliniWearColors.Black,
                modifier = Modifier.fillMaxWidth(),
                onClick = onResume,
            )
        }
        item { Spacer(modifier = Modifier.height(10.dp)) }
        item {
            WearActionButton(
                label = "종료",
                color = RunliniWearColors.ElectricRed,
                textColor = RunliniWearColors.Chalk,
                modifier = Modifier.fillMaxWidth(),
                onClick = onStop,
            )
        }
    }
}
